// AI proxy cho Flutter Lab.
//
// Mục đích: giữ khoá API ở phía server, app chỉ gọi tới đây. Nhờ vậy repo
// không bao giờ chứa khoá, và khoá không nằm trong APK.
//
// Chạy:  GEMINI_API_KEY=... node server/server.js
// Kiểm tra: GET /health   Gọi AI: POST /explain (body giống Gemini)
//
// Không dùng thư viện ngoài nên không cần `npm install`.

const http = require('node:http');

const PORT = Number(process.env.PORT || 8787);
const API_KEY = process.env.GEMINI_API_KEY || '';

// Đổi được để test bằng stub hoặc dùng nhà cung cấp khác cùng định dạng.
const UPSTREAM =
  process.env.AI_UPSTREAM ||
  'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

const MAX_BODY_BYTES = 64 * 1024;

function json(res, status, payload) {
  const body = JSON.stringify(payload);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(body),
  });
  res.end(body);
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    let size = 0;
    req.on('data', (chunk) => {
      size += chunk.length;
      if (size > MAX_BODY_BYTES) {
        reject(new Error('body too large'));
        req.destroy();
        return;
      }
      chunks.push(chunk);
    });
    req.on('end', () => resolve(Buffer.concat(chunks).toString('utf8')));
    req.on('error', reject);
  });
}

const server = http.createServer(async (req, res) => {
  if (req.method === 'GET' && req.url === '/health') {
    return json(res, 200, {
      ok: true,
      keyConfigured: API_KEY.length > 0,
      upstream: UPSTREAM.replace(/key=[^&]+/, 'key=***'),
    });
  }

  if (req.method !== 'POST' || !req.url.startsWith('/explain')) {
    return json(res, 404, { error: 'not_found' });
  }

  if (!API_KEY) {
    // 503 để app biết mà rơi về lời giải gốc trong JSON.
    return json(res, 503, { error: 'missing_key' });
  }

  let body;
  try {
    body = await readBody(req);
    JSON.parse(body);
  } catch (error) {
    return json(res, 400, { error: 'bad_json' });
  }

  try {
    const url = UPSTREAM + (UPSTREAM.includes('?') ? '&' : '?') +
      'key=' + encodeURIComponent(API_KEY);
    const upstream = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body,
      signal: AbortSignal.timeout(15000),
    });
    const text = await upstream.text();
    res.writeHead(upstream.status, {
      'Content-Type': 'application/json; charset=utf-8',
      'Content-Length': Buffer.byteLength(text),
    });
    res.end(text);
  } catch (error) {
    // Không để lộ chi tiết khoá/URL ra ngoài.
    console.error('upstream error:', error.message);
    json(res, 502, { error: 'upstream_failed' });
  }
});

server.listen(PORT, () => {
  console.log(`AI proxy nghe ở cổng ${PORT}`);
  console.log(`Khoá đã cấu hình: ${API_KEY ? 'có' : 'CHƯA (sẽ trả 503)'}`);
  console.log(`Upstream: ${UPSTREAM}`);
});
