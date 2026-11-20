// Vercel serverless: POST /api/explain và GET /api/explain (health).
//
// Biến môi trường cần khai trong dashboard Vercel (KHÔNG đưa vào repo):
//   GEMINI_API_KEY   khoá nhà cung cấp AI
//   AI_ACCESS_CODE   mã truy cập mà app gửi kèm
//
// Dùng lại đúng lõi của server/server.js nên luật chơi giống hệt bản local.
const { createCore } = require('../server/core');

const core = createCore();

module.exports = async (req, res) => {
  res.setHeader('Cache-Control', 'no-store');

  if (req.method === 'GET') {
    const { status, body } = core.health();
    res.status(status).json(body);
    return;
  }
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'method_not_allowed' });
    return;
  }

  // Vercel đã parse JSON; dựng lại chuỗi để dùng chung một đường xử lý.
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
  });
  res.status(status).json(body);
};
