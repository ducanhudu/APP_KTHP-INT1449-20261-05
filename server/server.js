// Only server-owned questions are sent to the AI provider.
const http = require('node:http');
const crypto = require('node:crypto');
const questions = require('../assets/flutter_quiz_300.json');

function createServer({
  apiKey = process.env.GEMINI_API_KEY || '',
  accessCode = process.env.AI_ACCESS_CODE || '',
  upstream = process.env.AI_UPSTREAM || 'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite:generateContent',
  fetchImpl = fetch, dailyLimit = 100, minuteLimit = 6,
  maxConcurrent = 2, timeoutMs = 55000, now = Date.now,
} = {}) {
  const bank = new Map(questions.map(q => [q.id, q]));
  const cache = new Map();
  const clients = new Map();
  let daily = { day: '', count: 0 };
  let active = 0;
  const hash = value => crypto.createHash('sha256').update(value).digest();
  const reply = (res, status, payload) => {
    res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8' });
    res.end(JSON.stringify(payload));
  };
  const server = http.createServer(async (req, res) => {
    if (req.method === 'GET' && req.url === '/health') {
      return reply(res, 200, { ok: true, configured: Boolean(apiKey && accessCode) });
    }
    if (req.method !== 'POST' || req.url !== '/explain') return reply(res, 404, { error: 'not_found' });
    if (!apiKey || !accessCode) return reply(res, 503, { error: 'not_configured' });
    if (!crypto.timingSafeEqual(hash(req.headers.authorization || ''), hash(`Bearer ${accessCode}`))) {
      return reply(res, 401, { error: 'unauthorized' });
    }
    // Ignore untrusted X-Forwarded-For. A reverse proxy shares its IP limit.
    const time = now();
    const ip = req.socket.remoteAddress;
    for (const [key, value] of clients) {
      if (time - value.start >= 60000) clients.delete(key);
    }
    const bucket = clients.get(ip) || { start: time, count: 0 };
    if (bucket.count >= minuteLimit || (clients.size >= 1000 && !clients.has(ip))) {
      return reply(res, 429, { error: 'rate_limited' });
    }
    bucket.count++;
    clients.set(ip, bucket);
    let input;
    try {
      const chunks = [];
      let bytes = 0;
      for await (const chunk of req) {
        bytes += chunk.length;
        if (bytes > 1024) return reply(res, 413, { error: 'body_too_large' });
        chunks.push(chunk);
      }
      input = JSON.parse(Buffer.concat(chunks).toString('utf8'));
      if (!input || Array.isArray(input) ||
          Object.keys(input).some(k => !['questionId', 'language'].includes(k)) ||
          !Number.isInteger(input.questionId) || !bank.has(input.questionId) ||
          !['vi', 'en', 'bilingual'].includes(input.language)) {
        return reply(res, 400, { error: 'invalid_question' });
      }
    } catch {
      return reply(res, 400, { error: 'bad_json' });
    }
    const key = `${input.questionId}:${input.language}`;
    const hit = cache.get(key);
    if (hit && time < hit.expires) return reply(res, 200, { text: hit.text });
    const day = new Date(time).toISOString().slice(0, 10);
    if (daily.day !== day) daily = { day, count: 0 };
    if (daily.count >= dailyLimit) return reply(res, 429, { error: 'daily_limit' });
    if (active >= maxConcurrent) return reply(res, 429, { error: 'busy' });
    const q = bank.get(input.questionId);
    const english = input.language === 'en';
    const lang = english ? 'English' : input.language === 'bilingual' ? 'Vietnamese and English' : 'Vietnamese';
    const prompt = `Explain this Flutter/Dart quiz question briefly in ${lang}. Use the supplied answer and reference.\n` +
      `${english ? q.question_en : q.question_vi}\n${q.code_snippet || ''}\n` +
      q.options.map(o => `${o.id}. ${english ? o.en : o.vi}`).join('\n') +
      `\nCorrect answer: ${q.correct_answer}\nReference: ${english ? q.explanation_en : q.explanation_vi}`;
    daily.count++;
    active++;
    try {
      const url = new URL(upstream);
      url.searchParams.set('key', apiKey);
      const response = await fetchImpl(url, {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: { maxOutputTokens: 600, thinkingConfig: { thinkingBudget: 0 } },
        }),
        signal: AbortSignal.timeout(timeoutMs),
      });
      if (!response.ok) return reply(res, 502, { error: 'upstream_failed' });
      const data = await response.json();
      const text = data.candidates?.[0]?.content?.parts
        ?.filter(p => !p.thought && typeof p.text === 'string').map(p => p.text).join('\n');
      if (!text?.trim()) return reply(res, 502, { error: 'empty_response' });
      cache.set(key, { text, expires: now() + 30 * 60 * 1000 });
      return reply(res, 200, { text });
    } catch {
      return reply(res, 502, { error: 'upstream_failed' });
    } finally { active--; }
  });
  server.requestTimeout = 10000;
  server.headersTimeout = 10000;
  return server;
}
if (require.main === module) {
  createServer().listen(Number(process.env.PORT || 8787), () => console.log('AI proxy started. See /health.'));
}
module.exports = { createServer };
