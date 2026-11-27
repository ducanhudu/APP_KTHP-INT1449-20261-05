# AI proxy cho app Flutter Lab — chạy được trên mọi PaaS có Docker.
#
# Build từ thư mục gốc repo vì server đọc assets/flutter_quiz_300.json:
#   docker build -t flutterlab-ai-proxy .
#   docker run --rm -p 8080:8080 \
#     -e GEMINI_API_KEY=... -e AI_ACCESS_CODE=... flutterlab-ai-proxy
FROM node:22-alpine

WORKDIR /app

# Server tạo prompt từ chính ngân hàng câu hỏi trong repo.
COPY assets/flutter_quiz_300.json ./assets/flutter_quiz_300.json
COPY server ./server

ENV PORT=8080
EXPOSE 8080

# Không chạy bằng root.
USER node

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- "http://127.0.0.1:${PORT}/health" || exit 1

CMD ["node", "server/server.js"]
