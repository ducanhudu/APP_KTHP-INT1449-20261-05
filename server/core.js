// Lõi xử lý của proxy AI — không phụ thuộc http để dùng được ở nhiều nơi:
// server/server.js (chạy local) và api/explain.js (Vercel serverless).
const crypto = require('node:crypto');
const questions = require('../assets/flutter_quiz_300.json');


function createCore({
  apiKey = process.env.GEMINI_API_KEY || '',
  accessCode = process.env.AI_ACCESS_CODE || '',
  upstream =
    process.env.AI_UPSTREAM ||
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite:generateContent',
  fetchImpl = fetch,
  dailyLimit = Number(process.env.AI_DAILY_LIMIT || 1000),
  minuteLimit = Number(process.env.AI_MINUTE_LIMIT || 30),
  maxConcurrent = 2,
  timeoutMs = 55000,
  now = Date.now,
  bank = new Map(questions.map((q) => [q.id, q])),
} = {}) {
  // Trạng thái riêng cho từng instance để test không dính cache của nhau.
  const cache = new Map();
  const clients = new Map();
  let daily = { day: '', count: 0 };
  let active = 0;

  const hash = (value) => crypto.createHash('sha256').update(value).digest();

  function authorized(authHeader) {
    if (!accessCode) return false;
    return crypto.timingSafeEqual(
      hash(authHeader || ''),
      hash(`Bearer ${accessCode}`),
    );
  }

  // Trả về { status, body } để nơi gọi tự quyết định cách ghi response.
  async function handle({ authHeader = '', rawBody = '', ip = 'unknown' } = {}) {
    if (!apiKey || !accessCode) {
      return { status: 503, body: { error: 'not_configured' } };
    }
    if (!authorized(authHeader)) {
      return { status: 401, body: { error: 'unauthorized' } };
    }

    const time = now();
    for (const [key, value] of clients) {
      if (time - value.start >= 60000) clients.delete(key);
    }
    const bucket = clients.get(ip) || { start: time, count: 0 };
    if (bucket.count >= minuteLimit || (clients.size >= 2000 && !clients.has(ip))) {
      return { status: 429, body: { error: 'rate_limited' } };
    }
    bucket.count++;
    clients.set(ip, bucket);

    if (Buffer.byteLength(rawBody) > 1024) {
      return { status: 413, body: { error: 'body_too_large' } };
    }

    let input;
    try {
      input = JSON.parse(rawBody);
    } catch {
      return { status: 400, body: { error: 'bad_json' } };
    }
    const keys = Object.keys(input || {});
    if (
      !input ||
      Array.isArray(input) ||
      keys.some((k) => !['questionId', 'language'].includes(k)) ||
      !Number.isInteger(input.questionId) ||
      !bank.has(input.questionId) ||
      !['vi', 'en', 'bilingual'].includes(input.language)
    ) {
      return { status: 400, body: { error: 'invalid_question' } };
    }

    const key = `${input.questionId}:${input.language}`;
    const hit = cache.get(key);
    if (hit && time < hit.expires) {
      return { status: 200, body: { text: hit.text } };
    }

    const day = new Date(time).toISOString().slice(0, 10);
    if (daily.day !== day) daily = { day, count: 0 };
    if (daily.count >= dailyLimit) {
      return { status: 429, body: { error: 'daily_limit' } };
    }
    if (active >= maxConcurrent) {
      return { status: 429, body: { error: 'busy' } };
    }

    const q = bank.get(input.questionId);
    const english = input.language === 'en';
    const lang = english
      ? 'English'
      : input.language === 'bilingual'
        ? 'Vietnamese and English'
        : 'Vietnamese';
    const prompt =
      `Explain this Flutter/Dart quiz question briefly in ${lang}. ` +
      `Use the supplied answer and reference.\n` +
      `${english ? q.question_en : q.question_vi}\n${q.code_snippet || ''}\n` +
      q.options.map((o) => `${o.id}. ${english ? o.en : o.vi}`).join('\n') +
      `\nCorrect answer: ${q.correct_answer}\nReference: ` +
      `${english ? q.explanation_en : q.explanation_vi}`;

    daily.count++;
    active++;
    try {
      const url = new URL(upstream);
      url.searchParams.set('key', apiKey);
      const response = await fetchImpl(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: {
            maxOutputTokens: 600,
            thinkingConfig: { thinkingBudget: 0 },
          },
        }),
        signal: AbortSignal.timeout(timeoutMs),
      });
      if (!response.ok) {
        return { status: 502, body: { error: 'upstream_failed' } };
      }
      const data = await response.json();
      const text = data.candidates?.[0]?.content?.parts
        ?.filter((p) => !p.thought && typeof p.text === 'string')
        .map((p) => p.text)
        .join('\n');
      if (!text?.trim()) {
        return { status: 502, body: { error: 'empty_response' } };
      }
      cache.set(key, { text, expires: now() + 30 * 60 * 1000 });
      return { status: 200, body: { text } };
    } catch {
      return { status: 502, body: { error: 'upstream_failed' } };
    } finally {
      active--;
    }
  }

  const health = () => ({
    status: 200,
    body: { ok: true, configured: Boolean(apiKey && accessCode) },
  });

  return { handle, health };
}

module.exports = { createCore };
