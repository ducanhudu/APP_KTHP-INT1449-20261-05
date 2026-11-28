// HTTP wrapper cho lõi trong server/core.js — dùng khi chạy local hoặc tự host.
const http = require('node:http');
const { createCore } = require('./core');
const { createAccountApi } = require('./accounts');

const ACCOUNT_BODY_LIMIT = 256 * 1024;
const AI_BODY_LIMIT = 4096;

function createServer(options = {}) {
  const core = createCore(options);
  const accounts = createAccountApi(options);
  const server = http.createServer(async (req, res) => {
    const reply = (status, body) => {
      const headers = {
        'Cache-Control': 'no-store',
        'X-Content-Type-Options': 'nosniff',
        'Content-Type': 'application/json; charset=utf-8',
      };
      if (status === 204) {
        res.writeHead(status, headers);
        return res.end();
      }
      res.writeHead(status, headers);
      res.end(JSON.stringify(body));
    };
    const pathname = new URL(req.url, 'http://localhost').pathname;
    if (req.method === 'GET' && (pathname === '/health' || pathname === '/api/health')) {
      const { status, body } = core.health();
      return reply(status, { ...body, accounts: accounts.enabled });
    }
    const accountRoute = pathname.startsWith('/api/auth/') || pathname.startsWith('/api/history');
    if (!accountRoute && !(req.method === 'POST' && pathname === '/explain')) {
      return reply(404, { error: 'not_found' });
    }
    const bodyLimit = accountRoute ? ACCOUNT_BODY_LIMIT : AI_BODY_LIMIT;
    const chunks = [];
    let bytes = 0;
    let tooLarge = false;
    for await (const chunk of req) {
      bytes += chunk.length;
      if (bytes > bodyLimit) {
        tooLarge = true;
        continue;
      }
      chunks.push(chunk);
    }
    if (tooLarge) return reply(413, { error: 'body_too_large' });
    const rawBody = Buffer.concat(chunks).toString('utf8');
    if (accountRoute && rawBody.length > 0 &&
        !/^application\/json(?:\s*;|$)/i.test(req.headers['content-type'] || '')) {
      return reply(415, { error: 'content_type_must_be_json' });
    }
    const ip = req.socket.remoteAddress || 'unknown';
    if (accountRoute) {
      try {
        const { status, body } = await accounts.handle({
          method: req.method,
          pathname,
          authHeader: req.headers.authorization || '',
          rawBody,
          ip,
        });
        return reply(status, body);
      } catch (error) {
        console.error('Account API request failed:', error.message);
        return reply(500, { error: 'internal_error' });
      }
    }
    const { status, body } = await core.handle({
      authHeader: req.headers.authorization || '',
      rawBody,
      // Bỏ qua X-Forwarded-For vì client tự khai được; sau reverse proxy mọi
      // request dùng chung một hạn mức theo IP của proxy.
      ip,
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
