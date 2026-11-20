// HTTP wrapper cho lõi trong server/core.js — dùng khi chạy local hoặc tự host.
const http = require('node:http');
const { createCore } = require('./core');

function createServer(options = {}) {
  const core = createCore(options);
  const server = http.createServer(async (req, res) => {
    const reply = (status, body) => {
      res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify(body));
    };
    if (req.method === 'GET' && req.url === '/health') {
      const { status, body } = core.health();
      return reply(status, body);
    }
    if (req.method !== 'POST' || req.url !== '/explain') {
      return reply(404, { error: 'not_found' });
    }
    let rawBody = '';
    for await (const chunk of req) {
      rawBody += chunk;
      if (rawBody.length > 4096) return reply(413, { error: 'body_too_large' });
    }
    const { status, body } = await core.handle({
      authHeader: req.headers.authorization || '',
      rawBody,
      // Bỏ qua X-Forwarded-For vì client tự khai được; sau reverse proxy mọi
      // request dùng chung một hạn mức theo IP của proxy.
      ip: req.socket.remoteAddress || 'unknown',
    });
    return reply(status, body);
  });
  server.requestTimeout = 10000;
  server.headersTimeout = 10000;
  return server;
}

if (require.main === module) {
  createServer().listen(Number(process.env.PORT || 8787), () =>
    console.log('AI proxy started. See /health.'),
  );
}

module.exports = { createServer };