// Stub upstream để thử toàn bộ chuỗi app → proxy → "AI" mà không cần khoá thật.
//
// Chạy: node server/stub-upstream.js
// Rồi:  AI_UPSTREAM=http://127.0.0.1:9999/explain GEMINI_API_KEY=demo node server/server.js
//
// Trả về đúng định dạng Gemini để không phải sửa gì phía app.

const http = require('node:http');

const PORT = Number(process.env.STUB_PORT || 9999);

http
  .createServer((req, res) => {
    let body = '';
    req.on('data', (chunk) => (body += chunk));
    req.on('end', () => {
      let prompt = '';
      try {
        prompt = JSON.parse(body)?.contents?.[0]?.parts?.[0]?.text || '';
      } catch {
        // bỏ qua, dùng prompt rỗng
      }
      const reply =
        '[Stub AI] Đây là câu trả lời từ server giữ khoá, không phải lời giải ' +
        'trong JSON. Prompt nhận được dài ' +
        prompt.length +
        ' ký tự.';
      const payload = {
        candidates: [{ content: { parts: [{ text: reply }] } }],
      };
      const text = JSON.stringify(payload);
      res.writeHead(200, {
        'Content-Type': 'application/json; charset=utf-8',
        'Content-Length': Buffer.byteLength(text),
      });
      res.end(text);
    });
  })
  .listen(PORT, () => console.log(`Stub AI nghe ở cổng ${PORT}`));
