// Vercel serverless: POST /api/ask for a learner's open-ended question.
const { createCore } = require('../server/core');

const core = createCore();

module.exports = async (req, res) => {
  res.setHeader('Cache-Control', 'no-store');
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'method_not_allowed' });
    return;
  }

  const rawBody =
    typeof req.body === 'string' ? req.body : JSON.stringify(req.body ?? {});
  const ip =
    req.headers['x-forwarded-for']?.split(',')[0]?.trim() ||
    req.socket?.remoteAddress ||
    'unknown';

  const { status, body } = await core.handle({
    authHeader: req.headers.authorization || '',
    rawBody,
    ip,
    mode: 'ask',
  });
  res.status(status).json(body);
};
