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
const crypto = require('node:crypto');

const PORT = Number(process.env.PORT || 8787);
const API_KEY = process.env.GEMINI_API_KEY || '';

// Đổi được để test bằng stub hoặc dùng nhà cung cấp khác cùng định dạng.
const UPSTREAM =
  process.env.AI_UPSTREAM ||
  'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite:generateContent';

const MAX_BODY_BYTES = 64 * 1024;
// Model AI thật có thể mất 30-60 giây khi tải cao; đổi bằng AI_TIMEOUT_MS.
const UPSTREAM_TIMEOUT_MS = Number(process.env.AI_TIMEOUT_MS || 60000);

// Cache theo nội dung câu hỏi: model thật có lúc trả lời 60-90 giây, trong khi
// app chờ tối đa 30 giây. Nhờ cache, lần hỏi đầu có thể chậm nhưng bấm "Hỏi lại"
// sẽ nhận ngay kết quả đã lưu. Đặt AI_CACHE_MS=0 để tắt.
const CACHE_MS = Number(process.env.AI_CACHE_MS ?? 30 * 60 * 1000);
const cache = new Map();

function cacheKey(body) {
  return crypto.createHash('sha256').update(body).digest('hex');
}

function cacheGet(key) {
  const hit = cache.get(key);
  if (!hit) return null;
  if (Date.now() > hit.expires) {
    cache.delete(key);
    return null;
  }
  return hit.text;
}

function cacheSet(key, text) {
  if (CACHE_MS <= 0) return;
  if (cache.size > 200) cache.clear();
  cache.set(key, { text, expires: Date.now() + CACHE_MS });
}

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
    const key = cacheKey(body);
    const cached = cacheGet(key);
    if (cached) {
      console.log(`${new Date().toISOString()} cache hit`);
      res.writeHead(200, {
        'Content-Type': 'application/json; charset=utf-8',
        'Content-Length': Buffer.byteLength(cached),
        'X-Cache': 'hit',
      });
      return res.end(cached);
    }

    // Tắt "suy nghĩ" của model: với câu hỏi trắc nghiệm, phần thinking chiếm
    // 200-300 token ẩn và là nguyên nhân chính khiến mỗi câu mất 6-90 giây.
    // Đo thực tế: bật thinking 6-90 giây, tắt thinking ~1,7 giây.
    const prepared = prepareBody(body);
    let { status, text } = await callUpstream(prepared.body);
    // Model không hỗ trợ thinkingConfig (ví dụ bản lite cũ) trả 400 → gọi lại
    // đúng body ban đầu, không chèn gì.
    if (status === 400 && prepared.injected) {
      ({ status, text } = await callUpstream(body));
    }
    if (status === 200) cacheSet(key, text);
    res.writeHead(status, {
      'Content-Type': 'application/json; charset=utf-8',
      'Content-Length': Buffer.byteLength(text),
      'X-Cache': 'miss',
    });
    res.end(text);
  } catch (error) {
    // Không để lộ chi tiết khoá/URL ra ngoài.
    console.error('upstream error:', error.message);
    json(res, 502, { error: 'upstream_failed' });
  }
});

// Chèn generationConfig.thinkingConfig.thinkingBudget = 0 nếu app chưa gửi.
// Đặt AI_THINKING=1 để giữ nguyên hành vi mặc định của model.
function prepareBody(raw) {
  if (process.env.AI_THINKING === '1') return { body: raw, injected: false };
  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch {
    return { body: raw, injected: false };
  }
  if (parsed?.generationConfig?.thinkingConfig) {
    return { body: raw, injected: false };
  }
  parsed.generationConfig = {
    ...(parsed.generationConfig || {}),
    thinkingConfig: { thinkingBudget: 0 },
  };
  return { body: JSON.stringify(parsed), injected: true };
}
// Gọi nhà cung cấp AI, tự thử lại khi bị 429/503 (model đang quá tải).
// Model thật thường trả 503 vài giây rồi mới nhận, nên một lần gọi là không đủ.
async function callUpstream(body) {
  const url =
    UPSTREAM + (UPSTREAM.includes('?') ? '&' : '?') +
    'key=' + encodeURIComponent(API_KEY);
  const delays = [0, 1500, 4000];
  let last = { status: 502, text: '{"error":"upstream_failed"}' };

  for (const delay of delays) {
    if (delay) await new Promise((r) => setTimeout(r, delay));
    const started = Date.now();
    try {
      const upstream = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body,
        signal: AbortSignal.timeout(UPSTREAM_TIMEOUT_MS),
      });
      const text = await upstream.text();
      console.log(
        `${new Date().toISOString()} ${upstream.status} ${Date.now() - started}ms`,
      );
      if (upstream.ok) return { status: upstream.status, text };
      last = { status: upstream.status, text };
      // Chỉ thử lại khi lỗi tạm thời.
      if (upstream.status !== 429 && upstream.status !== 503) return last;
    } catch (error) {
      console.error('upstream error:', error.message);
      last = { status: 502, text: '{"error":"upstream_failed"}' };
    }
  }
  return last;
}

server.listen(PORT, () => {
  console.log(`AI proxy nghe ở cổng ${PORT}`);
  console.log(`Khoá đã cấu hình: ${API_KEY ? 'có' : 'CHƯA (sẽ trả 503)'}`);
  console.log(`Upstream: ${UPSTREAM}`);
});
