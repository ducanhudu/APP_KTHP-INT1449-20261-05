# Tài liệu vấn đáp — Phần của Đoàn Vũ Phúc (AlanPhuc)

Tài liệu này giải thích **chỉ phần do bạn (Phúc) làm**: giải thích code chi tiết từng
dòng, luồng hoạt động, và bộ câu hỏi vấn đáp có thể bị hỏi kèm đáp án.

> Vai trò chính thức (ghi trong `final-report.md` §7): **"Phúc — sửa lỗi bản tích hợp"**.
> Khi demo trong buổi bảo vệ (theo `defense-script.md`), bạn trình bày **Camera học tập,
> AI giải thích và TTS**.

## Bản đồ phần của bạn

| Nhóm | File | Trạng thái |
| --- | --- | --- |
| **Backend AI** (proxy giữ khóa) | `server/core.js`, `server/server.js`, `server/stub-upstream.js`, `server/server.test.js`, `server/README.md`, `server/package.json` | Bạn tạo mới |
| **Deploy AI server** | `api/explain.js`, `vercel.json`, `Dockerfile`, `.dockerignore` | Bạn tạo mới |
| **App gọi AI** | `lib/ai_service.dart` | Bạn tạo mới |
| **Nhắc ôn hằng ngày** | `lib/reminder_service.dart`, `lib/reminder_tile.dart` | Bạn tạo mới |
| **Song ngữ giao diện (i18n)** | `lib/app_strings.dart` | Bạn tạo mới |
| **Trạng thái lỗi** | `lib/error_state.dart` | Bạn tạo mới |
| **Mic nhập câu hỏi** | `lib/speech_input_service.dart` + tích hợp vào `lib/camera_study_page.dart` | Bạn tạo mới + sửa |
| **CI/CD + ký release** | `.github/workflows/ci.yml`, `android/key.properties` | Bạn tạo mới |
| **Audit 300 câu** | `tool/audit_question_bank.py` | Bạn tạo mới |
| **Test** | `server/server.test.js`, `test/ai_service_test.dart`, `test/reminder_tile_test.dart`, `test/speech_input_test.dart`, `test/error_state_test.dart`, `test/exam_and_language_test.dart`, ... | Bạn tạo mới |

---

## 1. Backend AI — `server/` (phần quan trọng nhất)

Mục tiêu: **khóa Gemini chỉ nằm ở server**, app không bao giờ giữ khóa. App chỉ gửi
`{ "questionId": 1, "language": "vi" }`; server tự lấy câu hỏi từ JSON trong repo để
tạo prompt. Điều này chống lộ khóa và chống prompt injection (người dùng không tự bịa
được câu hỏi hay prompt).

### 1.1 `server/core.js` — lõi xử lý (không phụ thuộc HTTP)

File 154 dòng, tách lõi ra khỏi HTTP để dùng được ở 2 nơi: `server/server.js` (chạy
local) và `api/explain.js` (Vercel serverless).

**`createCore(options)`** (dòng 7–20) nhận các tham số đều có thể ghi đè để test:

| Tham số | Mặc định | Ý nghĩa |
| --- | --- | --- |
| `apiKey` | `GEMINI_API_KEY` | Khóa nhà cung cấp AI (chỉ ở server) |
| `accessCode` | `AI_ACCESS_CODE` | Mã truy cập demo của nhóm |
| `upstream` | `AI_UPSTREAM` hoặc URL Gemini `gemini-3.1-flash-lite` | Địa chỉ model thật |
| `fetchImpl` | `fetch` | Gọi mạng — **test truyền fetch giả** |
| `dailyLimit` | `AI_DAILY_LIMIT` hoặc 1000 | Hạn mức lần gọi/ngày |
| `minuteLimit` | `AI_MINUTE_LIMIT` hoặc 30 | Hạn mức request/phút/IP |
| `maxConcurrent` | 2 | Số yêu cầu AI đồng thời |
| `timeoutMs` | 55000 | Timeout gọi nhà cung cấp (55 giây) |
| `bank` | `Map` từ `assets/flutter_quiz_300.json` | Ngân hàng câu hỏi đáng tin |

> ⚠️ Lưu ý để trả lời vấn đáp: **mặc định trong code** là 30 req/phút/IP và 1000
> lần/ngày, nhưng README và báo cáo ghi mục tiêu triển khai là **6 req/phút/IP** và
> **100 lần/ngày**. Các hạn mức đọc từ biến môi trường (`AI_MINUTE_LIMIT`,
> `AI_DAILY_LIMIT`), nên bản deploy đặt giá trị chặt hơn mặc định. Hãy nói rõ "hạn mức
> cấu hình được qua biến môi trường".

**Trạng thái riêng từng instance** (dòng 22–25): `cache` (Map), `clients` (Map đếm
theo IP), `daily` (`{day, count}`), `active` (đếm yêu cầu đang chạy). Tách riêng để
test không dính cache của nhau.

**`authorized(authHeader)`** (dòng 29–35):
```js
return crypto.timingSafeEqual(hash(authHeader || ''), hash(`Bearer ${accessCode}`));
```
So sánh SHA-256 bằng `timingSafeEqual` → **chống tấn công timing** (so sánh chuỗi thường
trả kết quả sớm khi sai ký tự đầu, lộ thông tin độ dài/đầu chuỗi).

**`handle({authHeader, rawBody, ip})`** — luồng chính, 6 tầng kiểm tra theo thứ tự:

1. **Chưa cấu hình** (thiếu key hoặc code) → `503 not_configured` (dòng 39–41).
2. **Xác thực** — sai mã → `401 unauthorized` (dòng 42–44).
3. **Hạn mức theo IP** (dòng 46–55):
   - Xóa các entry `clients` cũ hơn 60 giây.
   - `bucket = clients.get(ip) || {start: time, count: 0}`.
   - Nếu `bucket.count >= minuteLimit` hoặc (`clients.size >= 2000` và IP mới) → `429 rate_limited`.
   - Tăng `bucket.count`, ghi lại vào `clients`.
   - **Không tin `X-Forwarded-For`** (client tự khai được) — dùng `req.socket.remoteAddress`.
4. **Kích thước body** > 1024 byte → `413 body_too_large` (dòng 57–59).
5. **Parse & validate JSON** (dòng 61–77):
   - JSON hỏng → `400 bad_json`.
   - Chỉ chấp nhận đúng 2 khóa `questionId` + `language` (khóa lạ → từ chối).
   - `questionId` phải là số nguyên **có trong ngân hàng**; `language` ∈ `vi/en/bilingual`.
   - Sai → `400 invalid_question`. (Đây là lớp chống prompt injection.)
6. **Cache** (dòng 79–83): khóa `"questionId:language"`, nếu còn hạn (`time < expires`)
   → trả `200 {text}` ngay, **không gọi provider**.

Sau khi qua 6 tầng, mới thực sự gọi AI:

7. **Hạn mức ngày + đồng thời** (dòng 85–92): tính `day` theo ISO (UTC); reset khi sang
   ngày mới; `daily.count >= dailyLimit` → `429 daily_limit`; `active >= maxConcurrent`
   → `429 busy`.
8. **Tạo prompt** (dòng 94–107): prompt = câu hỏi (theo ngôn ngữ) + code snippet + 4 lựa
   chọn + đáp án đúng + lời giải tham chiếu. Server tự lấy từ JSON → prompt "đáng tin",
   người dùng không nhét nội dung được.
9. **Gọi provider** (dòng 109–125): gắn `key=apiKey` vào query; body Gemini:
   `contents[0].parts[0].text = prompt`, `generationConfig.maxOutputTokens = 600`,
   `thinkingConfig.thinkingBudget = 0` (tắt "suy nghĩ" để nhanh, rẻ). Dùng
   `AbortSignal.timeout(timeoutMs)`.
10. **Đọc kết quả** (dòng 126–138): `!response.ok` → `502 upstream_failed`; lấy
    `data.candidates[0].content.parts` lọc bỏ phần `thought`, nối các `text`; rỗng →
    `502 empty_response`; hợp lệ → lưu cache 30 phút, trả `200 {text}`.
11. **Lỗi** (dòng 139–143): mọi exception → `502 upstream_failed` (không lộ chi tiết lỗi
    ra ngoài); `finally` giảm `active`.

**`health()`** (dòng 146–149): trả `200 {ok:true, configured:Boolean(apiKey && accessCode)}`.

### 1.2 `server/server.js` — vỏ HTTP

- `createServer(options)` (dòng 5–36): `http.createServer`, đọc request, route:
  - `GET /health` → `core.health()`.
  - Không phải `POST /explain` → `404 not_found`.
  - Đọc thân, quá 4096 byte → `413 body_too_large`.
  - Gọi `core.handle({authHeader, rawBody, ip: socket.remoteAddress})`.
- `server.requestTimeout = server.headersTimeout = 10000` (dòng 33–34): giới hạn thời
  gian đọc request 10 giây.
- `require.main === module` → tự `listen(PORT || 8787)` (dòng 38–42).

### 1.3 `server/stub-upstream.js` — bộ giả lập nhà cung cấp

Trả đúng định dạng Gemini (`candidates[0].content.parts[0].text`) để thử toàn bộ chuỗi
app → proxy → "AI" **mà không tốn khóa thật**. Nội dung trả về bắt đầu `[Stub AI]` để
nhận biết đây không phải lời giải JSON. Chạy ở cổng `STUB_PORT` (mặc định 9999).

### 1.4 `server/server.test.js` — 6 test (chạy `node --test`, không gọi mạng thật)

| Test | Xác nhận điều gì |
| --- | --- |
| Reject missing/wrong access code | 401, **không gọi provider** (`calls.length == 0`) |
| Reject arbitrary prompts/unknown IDs/unsupported languages | 400 cho `{contents:[]}`, id 999, ngôn ngữ `fr`, payload chứa `prompt` |
| Build authoritative prompt + cache | 200, gọi provider đúng 1 lần cho 2 request giống nhau; prompt chứa `/C\. const/`; `maxOutputTokens == 600` |
| Enforce minute limit even for cached | `minuteLimit: 1` → request thứ 2 bị 429 dù đã cache |
| Enforce daily budget + reset next day | `dailyLimit: 1` → 429; cộng 86.400.000 ms (1 ngày) → 200 |
| Sanitize provider errors + fail closed | provider ném lỗi chứa "secret" → 502 và **không lộ "secret"**; thiếu cấu hình → 503 |

### 1.5 `server/README.md` — giới hạn bảo vệ (học thuộc để trả lời)

- Không mã / sai mã: **401**; câu không hợp lệ: **400**; body > 1 KB: **413**.
- Tối đa **6 request/phút/IP** (kể cả cache), **không tin `X-Forwarded-For`**.
- Tối đa **2 yêu cầu AI đồng thời**, **100 lần gọi provider/ngày UTC**.
- Giới hạn **600 token đầu ra**, timeout provider **55 giây**.
- **Cache 30 phút** theo (mã câu + ngôn ngữ), không cache lỗi, không tự retry.
- HTTP chỉ cho debug cục bộ; **APK release phải dùng HTTPS**.

### 1.6 Deploy AI server lên Internet — `api/explain.js` + `vercel.json` + `Dockerfile`

**Mục tiêu:** có một URL **HTTPS cố định** để build vào APK; ai cài APK cũng dùng được AI
mà không phải cấu hình gì. Lõi xử lý **chỉ viết một lần** (`server/core.js`) và tái sử dụng
ở mọi nơi: local (`server/server.js`) và serverless (`api/explain.js`).

| File | Vai trò |
| --- | --- |
| `api/explain.js` (39 dòng) | Hàm serverless cho Vercel: `GET` → health, `POST` → explain |
| `vercel.json` | Cấu hình Vercel: region `sin1` + rewrite `/explain`, `/health` |
| `Dockerfile` + `.dockerignore` | Đóng gói cho Render/Railway/Fly.io/Cloud Run/VPS |

**`api/explain.js`** — những điểm hay hỏi:

- `const core = createCore()` (dòng 10): **dùng lại đúng lõi** `server/core.js`, nên luật
  chơi giống hệt bản local (cùng 6 tầng kiểm tra, cache, hạn mức).
- `res.setHeader('Cache-Control', 'no-store')` (dòng 13): chặn CDN/cache trả lời cũ.
- `GET` → `core.health()`; `POST` → `core.handle(...)`; phương thức khác → `405`.
- Vercel **đã tự parse JSON body** nên phải `JSON.stringify(req.body)` dựng lại chuỗi để đi
  chung một đường xử lý với local (dòng 26–27).
- IP lấy từ `x-forwarded-for` (dòng 28–31): ở Vercel header này do **hạ tầng Vercel** đặt nên
  tin được; còn bản local dùng `socket.remoteAddress` vì XFF của client tự khai được.

**`vercel.json`**:

- `"regions": ["sin1"]` — chạy function ở **Singapore** để giảm độ trễ từ Việt Nam.
- `rewrites`: `/explain` → `/api/explain` và `/health` → `/api/explain` (URL gọn, app gọi
  `https://<host>/explain`, không lộ thư mục `/api/`).

**`Dockerfile`** (dùng cho Render/Railway/Fly.io/Cloud Run):

- `FROM node:22-alpine` (image nhỏ), `COPY assets/flutter_quiz_300.json` + `COPY server/` —
  server tạo prompt từ chính ngân hàng câu hỏi nên phải mang theo JSON.
- `ENV PORT=8080`, `EXPOSE 8080`, `USER node` (không chạy root), `HEALTHCHECK` gọi `/health`
  mỗi 30 giây.
- `.dockerignore` chỉ giữ `assets` + `server`, loại phần Flutter để image nhẹ, build nhanh.

**Nơi đã deploy thật (xem `docs/deploy-ai.md`):** Render
`https://flutterlab-ai-proxy.onrender.com` (gói Free, repo riêng `4lanP/flutterlab-ai-proxy`,
khoá đặt trong Environment). Gói free **ngủ sau ~15 phút** không dùng; request đầu tiên sau
khi ngủ mất 30–60 giây — trước demo phải gọi `/health` trước ~2 phút để đánh thức.

**Cold start:** Vercel free cũng "ngủ" function khi rảnh (request đầu +0,5–1 giây). Cache và
hạn mức nằm trong RAM **của từng instance**, nên mỗi instance đếm riêng và reset khi restart.

---

## 2. App gọi AI — `lib/ai_service.dart`

**`class AiResult`** (dòng 15–23): `text` (nội dung), `fromFallback` (true = lời giải gốc).

**`class AiService`** (toàn bộ `static`, dòng 27–120):

- `accessCode` đọc từ `String.fromEnvironment('AI_ACCESS_CODE')` (dòng 32) — có thể nhúng
  lúc build, nhưng thường người dùng nhập tay qua panel.
- `isConfigured = _baseUrl.isNotEmpty` (dòng 33).
- `_baseUrl` từ `String.fromEnvironment('AI_API_URL', defaultValue: '')` (dòng 36–39).
- `_timeout = Duration(seconds: 65)` (dòng 43) — timeout phía app (lớn hơn 55s của server
  để có biên độ).

**`explain({question, language, client, endpoint})`** (dòng 49–98) — luồng:

1. Tính `fallback` = `language.display(explanationVi, explanationEn)`.
2. Nếu URL rỗng (chưa cấu hình) → trả `AiResult(text: fallback, fromFallback: true)` ngay.
3. `POST` body JSON `{questionId, language: vi/en/bilingual}`; header
   `Content-Type: application/json`, kèm `Authorization: Bearer <accessCode>` nếu có.
4. `request.timeout(_timeout)` — chờ tối đa 65 giây.
5. Status 200 → `_extractText(body)`; có text không rỗng → trả `fromFallback: false`.
6. **Mọi lỗi** (mạng, timeout, 401/429/502, parse lỗi) → trả fallback `fromFallback: true`.

**`_extractText(body)`** (dòng 103–119) hỗ trợ 2 kiểu backend:
- Gemini: `candidates[0].content.parts[0].text`.
- Backend tự viết: `{"text": ...}` hoặc `{"explanation": ...}`.

**Điểm thiết kế:** `client` và `endpoint` là tham số tùy chọn → test truyền `MockClient`
và URL giả, không cần mạng thật.

---

## 3. Luồng AI đầy đủ (app → proxy → Gemini → app)

```
[App] bấm "Hỏi AI" → AiService.explain(question, language)
  └─ không có AI_API_URL? → trả lời giải JSON ngay (offline)
  └─ có URL → POST {questionId, language} + Authorization: Bearer <code>
        │
        ▼
[Proxy] server/core.js handle()
  ├─ 503 nếu chưa set GEMINI_API_KEY / AI_ACCESS_CODE
  ├─ 401 nếu sai mã truy cập (timingSafeEqual SHA-256)
  ├─ 429 nếu vượt hạn mức phút/IP hoặc ngày/đồng thời
  ├─ 400 nếu questionId không có trong ngân hàng / language sai / thừa khóa
  ├─ 200 ngay nếu cache 30 phút còn hiệu lực
  └─ khác: tự tạo prompt (câu + code + 4 lựa chọn + đáp án + tham chiếu)
        │  POST Gemini + key (server) + AbortSignal.timeout(55s)
        ▼
[Gemini] trả candidates[0].content.parts[].text
        │
        ▼
[Proxy] cache 30 phút → 200 {text}
        │
        ▼
[App] _extractText → AiResult(fromFallback: false)
  └─ lỗi/timeout/401/429/502 → fallback explanationVi/En (fromFallback: true)
```

**Tóm tắt bảo mật** (hay bị hỏi): khóa Gemini chỉ ở server (biến môi trường), app chỉ
giữ mã truy cập demo trong RAM, prompt do server dựng từ JSON tin cậy (không cho người
dùng nhét prompt), đầu ra giới hạn 600 token, mọi lỗi quy về lời giải gốc.

---

## 4. Nhắc ôn hằng ngày — `lib/reminder_service.dart` + `lib/reminder_tile.dart`

### 4.1 `reminder_service.dart`

**`enum ReminderResult`** (dòng 9–18): `scheduled`, `permissionDenied`, `failed`.

**`abstract class ReminderService`** (dòng 24–36): `isEnabled()`, `enable({hour, minute})`,
`disable()`. Tách interface để widget/test không phụ thuộc plugin thật.

**`NotificationReminderService`** (dòng 39–149):

- Hằng số: `enabledKey = 'flutter_quiz_reminder_daily'`, `timeKey`,
  `notificationId = 1001` (dòng 43–45).
- `_ensureReady()` (dòng 50–65): khởi tạo timezone — `tz_data.initializeTimeZones()`,
  `FlutterTimezone.getLocalTimezone()`, `tz.setLocalLocation(...)`; nếu lấy múi giờ lỗi
  thì vẫn chạy với mặc định. Rồi `_plugin.initialize(...)` với icon `@mipmap/ic_launcher`.
- `_requestPermission()` (dòng 67–75): gọi `requestNotificationsPermission()` (Android).
- `enable({hour = 20, minute = 0})` (dòng 84–120):
  1. `_ensureReady()`.
  2. Xin quyền; từ chối → trả `permissionDenied`.
  3. `_plugin.cancel(notificationId)` — xóa lịch cũ trước.
  4. `_plugin.zonedSchedule(...)`:
     - thời điểm `_nextInstance(hour, minute)`,
     - `matchDateTimeComponents: DateTimeComponents.time` → **lặp đúng giờ mỗi ngày**,
     - `androidScheduleMode: inexactAllowWhileIdle` → vẫn chạy khi máy tiết kiệm pin,
     - channel `flutter_quiz_daily_reminder`.
  5. Lưu `enabledKey = true`, `timeKey = "HH:mm"` vào SharedPreferences.
- `disable()` (dòng 123–132): hủy lịch + `enabledKey = false`.
- `_nextInstance(hour, minute)` (dòng 134–148): lấy `TZDateTime` giờ đó hôm nay; nếu đã
  qua thì cộng 1 ngày.

### 4.2 `reminder_tile.dart`

`ReminderTile` (StatefulWidget) hiển thị `SwitchListTile.adaptive`:

- `_enabled` kiểu `bool?` (null = đang tải trạng thái từ prefs) → lúc đầu switch tắt và
  không bấm được.
- `_toggle(value)`: tắt → `service.disable()`; bật → `service.enable(hour: widget.hour)`.
- Ánh xạ kết quả sang SnackBar: `scheduled` → "Đã bật nhắc ôn", `permissionDenied` →
  "Chưa có quyền thông báo", `failed` → "Không đặt được lịch nhắc".

**Nguyên tắc:** quyền thông báo **chỉ xin khi người dùng bật công tắc**, không xin lúc
mở app.

---

## 5. Song ngữ giao diện — `lib/app_strings.dart`

`AppStrings` chứa **toàn bộ nhãn giao diện** 2 bản: `AppStrings.vietnamese` (dòng 277)
và `AppStrings.english` (dòng 415).

- `static AppStrings of(QuestionLanguage language)` (dòng 274–275): trả `english` nếu
  chọn English, ngược lại trả `vietnamese`. Chế độ **song ngữ vẫn dùng nhãn Việt** vì nội
  dung câu hỏi đã có cả hai thứ tiếng.
- Nhiều trường là **hàm định dạng** (không phải chuỗi cố định), ví dụ:
  - `quizCounter(index, total, answered)` → `_viCounter/_enCounter`.
  - `scoreLine(correct, wrong, skipped)`.
  - `historyDuration(minutes, seconds)`.
  - `cardsDue(due)`, `cardsSaved(saved, due)`, `bankSummary(questions, topics)`.
  - `accuracyText(percent)`, `topicShort(topic)`.
- `_shortTopic(topic, names)` (dòng 638–642): `K01 · Dart căn bản` dạng rút gọn cho
  panel AI (dùng `padLeft(2, '0')`).

**Điểm hay hỏi:** tại sao dùng hàm chứ không phải chuỗi? Vì các chuỗi có **tham số động**
(số câu, phần trăm, phút/giây) — hàm nhận tham số rồi trả chuỗi theo ngôn ngữ.

---

## 6. Trạng thái lỗi — `lib/error_state.dart`

`ErrorState` (StatelessWidget, dòng 7–41): `Center` + `Column` gồm:
- Icon lỗi (màu `colorScheme.error`).
- `message` (text).
- `FilledButton.icon` "Thử lại" gọi `onRetry`.

**Mục đích:** mọi `FutureBuilder` bị lỗi đều có **lối thoát** (nút thử lại) thay vì chỉ
hiện một dòng chữ. Dùng chung cho toàn app.

---

## 7. Mic nhập câu hỏi — `lib/speech_input_service.dart` (+ tích hợp camera)

### 7.1 `speech_input_service.dart`

**`enum SpeechInputFailure`** (dòng 17): `permissionDenied`, `noMatch`, `busy`,
`unavailable`, `failed`.

**`class SpeechInputException`** (dòng 19–26): bọc `failure` để phân biệt lỗi trước khi
nghe (từ chối quyền, thiếu recognizer) với lỗi xảy ra trong lúc nghe.

**`abstract class SpeechInputService`** (dòng 29–48): `listen(...)`, `stop()`, `dispose()`.

**`NativeSpeechInputService`** (dòng 51–155):

- `listen({english, onWords, onFailure, onDone})` (dòng 59–97):
  1. Lần đầu `_speech.initialize(onError, onStatus)`; nếu `!ready` → gọi
     `_speech.hasPermission` để phân biệt **từ chối quyền** (`permissionDenied`) với
     **máy không có bộ nhận dạng** (`unavailable`).
  2. `_localeId(english)` (dòng 117–129): chọn locale bắt đầu `en`/`vi` (đổi `_` → `-`).
     Danh sách locale được **cache** (`_cachedLocales`) vì mỗi lần `locales()` là một
     lời gọi platform, gọi lại mỗi phiên sẽ làm micro khởi động chậm.
  3. `_speech.listen(...)` với `partialResults: true` (nhận kết quả tạm),
     `ListenMode.dictation`, `pauseFor: 3s` (dừng khi im 3 giây), `listenFor: 60s`,
     `cancelOnError: true` (lỗi vĩnh viễn tự hủy lượt nghe, tránh treo micro).
- `_handleStatus(status)` (dòng 138–143): **chỉ** `done` mới gọi `onDone`. `notListening`
  được phát ngay khi bộ nhận dạng ngừng nghe (trước khi kết quả cuối về) — nếu coi nó là
  kết thúc sẽ tắt cờ sớm, cho phép mở phiên mới trong lúc phiên cũ còn đang đóng.
- `_mapError(message)` (dòng 145–154): ánh xạ chuỗi lỗi → `SpeechInputFailure`
  ("permission" → permissionDenied, "no_match" → noMatch, "busy" → busy,
  "not_available"/"missing" → unavailable, ...).

### 7.2 Tích hợp vào `camera_study_page.dart`

Phần bạn sửa: `_toggleMic()` (dòng 251–355) cùng các trợ giúp `_stopListening()`
(dòng 235–241) và `_armListenWatchdog()` (dòng 215–228) — khi bấm mic:

- **Mỗi lần bấm là một phiên nghe mới**: biến đếm `_listenGeneration` tăng mỗi lần bật/tắt;
  callback của phiên cũ về muộn sẽ bị bỏ qua (so `generation != _listenGeneration`),
  không ghi đè lên nội dung người dùng vừa gõ/tìm.
- **Không mất chữ đang gõ**: nếu chưa tìm (`_searched == false`) thì `base =
  _text.text.trim()` và **ghép** chữ nói thêm; nếu đã tìm bằng chữ hiện tại thì câu mới
  **thay thế** câu cũ.
- **Không tự tìm** sau khi nói — chỉ khi `isFinal` mới hiện "Đã chép lời. Kiểm tra, sửa
  rồi bấm Tìm trong 300 câu"; người dùng tự bấm "Tìm" (đúng nguyên tắc bảo mật: chữ không
  tự gửi đi).
- **Chống kẹt "Đang nghe…"**: `_armListenWatchdog` hẹn giờ 10 giây; nếu plugin trả về mà
  không phát sự kiện nào (ví dụ bộ nhận dạng đang bận nên `listen()` trả `false`), tự thoát
  và báo lỗi thay vì treo micro.
- Cờ `_starting` chặn bấm thêm khi đang khởi động phiên, tránh `stop()` chạy trước `listen()`.

---

## 8. CI/CD — `.github/workflows/ci.yml`

**Trigger** (dòng 3–18): push vào `main`, `feature/**`, `feat/**`, `fix/**`, `docs/**`,
`test/**`, `chore/**`; pull request vào main; `workflow_dispatch` (chạy tay).

**`concurrency`** (dòng 23–25): cùng một `ref` thì hủy run cũ đang chạy (`cancel-in-progress`).

**4 job**:

| Job | Chạy gì |
| --- | --- |
| `ai-proxy-test` (dòng 28–36) | Node 22 → `node --test server/server.test.js` |
| `analyze-and-test` (dòng 38–66) | Flutter 3.47.6 → `dart format`, `flutter analyze`, `flutter test` |
| `data-audit` (dòng 68–82) | Python 3.12 → `python tool/audit_question_bank.py ...` |
| `android-build` (dòng 84–170) | Matrix Ubuntu + Windows → build APK debug + release + upload artifact |

Chi tiết `android-build`:
- Java 21 (Temurin), Android SDK 36 (`android-actions/setup-android`).
- Build debug: Linux **thử lại 3 lần** khi gặp Maven Central/Gradle 429 (dòng 121–132);
  Windows giữ lệnh đơn giản.
- Build release (Linux, cũng retry 3 lần).
- Ghi `SHA256SUMS.txt` + `SOURCE_COMMIT.txt` (dòng 153–158).
- Upload artifact `flutter-lab-release-<sha>` giữ 14 ngày (dòng 160–170).

**Điểm hay hỏi:** vì sao build test phải chạy **tuần tự**? Vì chạy song song
`flutter test` và `flutter build` có thể làm `GeneratedPluginRegistrant` bị sinh lại sai
chế độ (comment dòng 138–139). Và vì sao retry Maven Central? IP dùng chung của runner
bị rate-limit 429.

### Ký APK release (phần bạn làm)

- Keystore `android/app/upload-keystore.jks` (RSA 2048, 10.000 ngày), alias `flutterlab`.
- Cấu hình `android/key.properties` — **đã gitignore**, không commit.
- Thiếu `key.properties` (ví dụ trên CI) thì Gradle tự quay về debug signing để build
  vẫn chạy.
- Mất keystore/mật khẩu → không thể cập nhật đè bản đã phát hành.

---

## 9. Audit ngân hàng câu hỏi — `tool/audit_question_bank.py`

Script Python (không cần thư viện ngoài), chạy `python tool/audit_question_bank.py
assets/flutter_quiz_300.json`. Mã thoát **0 = đạt, 1 = có lỗi**.

Các kiểm tra (hàm `main`, dòng 60–267):

- **UTF-8** hợp lệ, phát hiện BOM, NFC (dấu tổ hợp NFD), ký tự điều khiển.
- **Cấp cao nhất là mảng**, đúng **300** phần tử.
- `id` là số nguyên, **liên tục 1..300**, không trùng.
- `code` đúng dạng `K\d{2}-\d{3}` và **khớp khối** (`K{topic:02d}-`).
- `topic` ∈ 1..20, `level` ∈ {Nhớ, Hiểu, Vận dụng}.
- `question_vi/question_en/explanation_vi/explanation_en` không rỗng; `vi != en`.
- `options` đúng 4, mã A–D, không trùng nội dung Việt.
- `correct_answer` nằm trong 4 lựa chọn.
- `source_url` bắt đầu `https://`.
- Thống kê: phân bố khối, mức độ, đáp án (cảnh báo nếu lệch > 12), số câu có code,
  độ dài lời giải, nguồn, nội dung trùng.
- `report()` (dòng 270–283): in GHI NHẬN (cảnh báo, không chặn) và LỖI (chặn).

> Lưu ý cuối file (dòng 287–290): `sys.stdout.reconfigure(encoding="utf-8")` để in tiếng
> Việt đúng trên console Windows (mặc định cp1252).

---

## 10. Bộ câu hỏi vấn đáp có thể bị hỏi

### A. Backend AI (trọng tâm)

**Q1. Tại sao cần một proxy AI riêng thay vì gọi Gemini trực tiếp từ app?**
Để khóa Gemini **chỉ nằm ở server** (biến môi trường). Nếu nhúng khóa trong app, kẻ
tấn công có thể giải mã APK lấy khóa. Proxy còn giúp kiểm soát quota, cache, và chống
prompt injection (app chỉ gửi `questionId` + `language`).

**Q2. App gửi gì lên server? Tại sao không gửi nội dung câu hỏi?**
App chỉ gửi `{"questionId": 1, "language": "vi"}`. Server tự lấy câu hỏi từ JSON trong
repo để tạo prompt → prompt "đáng tin", người dùng không thể nhét prompt tùy ý (payload
chứa khóa lạ bị từ chối 400).

**Q3. `authorized()` dùng gì để so mã? Vì sao?**
`crypto.timingSafeEqual(hash(authHeader), hash('Bearer ' + accessCode))` — so SHA-256 bằng
hàm so sánh thời gian hằng số, **chống tấn công timing**.

**Q4. Kể các mã lỗi của proxy và ý nghĩa.**
503 (chưa cấu hình), 401 (sai mã), 429 (rate limit / daily limit / busy), 413 (body quá
lớn), 400 (JSON hỏng / câu không hợp lệ), 404 (sai route), 502 (provider lỗi / rỗng).

**Q5. Hạn mức được kiểm tra theo thứ tự nào?**
Chưa cấu hình → xác thực → hạn mức phút/IP → body size → parse/validate → cache → hạn
mức ngày → đồng thời → gọi provider.

**Q6. Cache hoạt động thế nào? Khóa là gì?**
Khóa `"questionId:language"`, lưu `{text, expires}` trong `Map` của instance, 30 phút.
Cache **sau khi** provider trả kết quả hợp lệ; không cache lỗi. Hạn mức phút vẫn đếm cả
request trúng cache.

**Q7. Vì sao không tin header `X-Forwarded-For`?**
Client tự khai được header đó; tin nó thì kẻ tấn công đổi IP giả để né hạn mức. Thay vào
đó dùng `req.socket.remoteAddress`.

**Q8. `fetchImpl` trong test để làm gì?**
Là dependency injection: test truyền `fetch` giả (ghi lại body, trả Response giả) để
kiểm tra logic **không cần gọi Gemini thật**, không tốn quota.

**Q9. Prompt được tạo từ đâu, gồm những gì?**
Từ `assets/flutter_quiz_300.json`: câu hỏi (theo ngôn ngữ), `code_snippet`, 4 lựa chọn,
đáp án đúng, lời giải tham chiếu. Yêu cầu "giải thích ngắn gọn bằng <ngôn ngữ>".

**Q10. Nếu provider lỗi hoặc trả rỗng thì sao?**
Trả `502` với thông báo chung (không lộ chi tiết lỗi), app nhận lỗi → dùng lời giải JSON
(fallback), không treo.

### B. AiService (phía app)

**Q11. `AiService.explain` khi nào dùng fallback?**
Khi `AI_API_URL` chưa cấu hình, lỗi mạng, timeout 65 giây, status ≠ 200, hoặc response
không parse được → trả `AiResult(fromFallback: true)` với `explanationVi/En`.

**Q12. `_extractText` hỗ trợ những định dạng nào?**
Gemini (`candidates[0].content.parts[0].text`) và backend tự viết (`{"text"}` hoặc
`{"explanation"}`).

**Q13. Mã truy cập AI khác gì khóa Gemini?**
Mã truy cập là mã demo của nhóm để dùng proxy, chỉ giữ trong RAM app, có thể nhập qua
panel. Khóa Gemini nằm ở server, app không bao giờ thấy.

### C. Nhắc ôn

**Q14. `zonedSchedule` với `matchDateTimeComponents: DateTimeComponents.time` nghĩa là gì?**
Nghĩa là lịch lặp lại **đúng giờ đó mỗi ngày** (chỉ khớp thành phần giờ:phút, bỏ qua ngày).

**Q15. `_nextInstance` tính giờ kế tiếp thế nào?**
Lấy `TZDateTime` hôm nay tại `hour:minute`; nếu đã qua (`!isAfter(now)`) thì cộng 1 ngày.

**Q16. Vì sao cần `flutter_timezone` + `timezone`?**
Thông báo lặp theo giờ địa phương nên cần múi giờ thật của thiết bị; nếu lỗi thì dùng mặc
định, không làm app sập.

**Q17. Tại sao `notificationId` cố định 1001?**
Để `cancel()` và đặt lịch mới đè lên đúng thông báo cũ, tránh tạo nhiều lịch trùng.

**Q18. Sau khi reboot máy, lịch nhắc còn không? Vì sao?**
Có — `AndroidManifest.xml` khai báo `ScheduledNotificationBootReceiver` với intent-filter
`BOOT_COMPLETED` (và `MY_PACKAGE_REPLACED`), giúp khôi phục lịch sau reboot/cập nhật app.

### D. i18n, lỗi, mic

**Q19. `AppStrings.of()` chọn bộ nhãn thế nào? Chế độ song ngữ dùng gì?**
Trả `english` nếu chọn English, ngược lại `vietnamese`. Song ngữ dùng nhãn Việt vì nội
dung câu đã song ngữ.

**Q20. Vì sao nhiều trường trong `AppStrings` là hàm chứ không phải chuỗi?**
Vì có tham số động (số câu, phần trăm, phút/giây) — hàm nhận tham số rồi trả chuỗi.

**Q21. `ErrorState` giải quyết vấn đề gì?**
Mọi `FutureBuilder` lỗi đều có nút "Thử lại" (lối thoát), thay vì chỉ một dòng chữ.

**Q22. Khi micro bị từ chối quyền vs máy không có recognizer, app phân biệt thế nào?**
`_speech.initialize` trả `false` → gọi `_speech.hasPermission`: có quyền nhưng không sẵn
sàng → `unavailable`; không có quyền → `permissionDenied`.

**Q23. `partialResults` và `cancelOnError` nghĩa là gì?**
`partialResults: true` nhận kết quả tạm khi đang nói; `cancelOnError: true` tự hủy lượt
nghe khi gặp lỗi vĩnh viễn, tránh micro treo.

### E. CI / audit

**Q24. CI chạy những job gì?**
Test proxy (Node), analyze+test (Flutter), audit JSON (Python), build APK (matrix
Ubuntu/Windows + upload artifact).

**Q25. Vì sao build Android phải retry khi gặp Maven Central 429?**
IP dùng chung của GitHub runner bị rate-limit; retry 3 lần cách 30 giây để không đánh đỏ
build do lỗi tạm thời.

**Q26. `audit_question_bank.py` kiểm tra gì quan trọng nhất?**
Đúng 300 câu, id liên tục không trùng, mã `K##-###` khớp khối, 4 lựa chọn A–D, đáp án
nằm trong lựa chọn, chuỗi không rỗng, UTF-8/NFC. Thoát 0 = đạt, 1 = lỗi.

**Q27. Vì sao release APK phải dùng HTTPS còn debug có thể dùng HTTP?**
Release chạy trên máy thật qua mạng; HTTP bị nghe lén/sửa đổi. Debug cục bộ dùng
`adb reverse` hoặc localhost nên HTTP tạm chấp nhận.

### F. Deploy AI server

**Q28. `api/explain.js` và `server/server.js` khác gì nhau?**
Cả hai dùng chung `createCore()` từ `server/core.js` nên luật xử lý giống hệt. Khác ở vỏ:
`server.js` là HTTP server thuần Node chạy local (tự `listen`, IP lấy `socket.remoteAddress`);
`api/explain.js` là serverless cho Vercel (Vercel parse sẵn JSON nên phải `JSON.stringify`
lại; IP lấy từ `x-forwarded-for` do Vercel đặt nên tin được).

**Q29. Vì sao đặt region `sin1` (Singapore)?**
Singapore là region châu Á gần Việt Nam, giảm độ trễ khi app gọi từ Việt Nam.

**Q30. Rewrite `/explain` → `/api/explain` để làm gì?**
URL app gọi ngắn gọn (`https://<host>/explain`), không lộ cấu trúc thư mục `/api/`. `/health`
cũng trỏ vào cùng function (GET → health).

**Q31. Khoá Gemini và mã truy cập khi deploy để ở đâu?**
Đều đặt trong **Environment Variables** của Vercel/Render, KHÔNG commit vào repo, KHÔNG nhúng
vào APK. Riêng mã truy cập `AI_ACCESS_CODE` có thể nhúng lúc build (`--dart-define`) để người
nhận APK khỏi nhập tay, vì nó chỉ là cổng chặn lạm dụng, không phải khoá nhà cung cấp.

**Q32. Cold start là gì? Xử lý khi demo thế nào?**
PaaS gói free "ngủ" function khi rảnh để tiết kiệm tài nguyên; request đầu sau khi ngủ chậm
thêm (Render 30–60 giây, Vercel ~1 giây). Trước demo gọi `/health` trước ~2 phút để đánh thức.

---

## 11. Cheat-sheet nhanh

| File | Vai trò | Điểm cần nhớ |
| --- | --- | --- |
| `server/core.js` | Lõi proxy AI | timingSafeEqual, 6 tầng kiểm tra, cache 30p, prompt từ JSON |
| `server/server.js` | Vỏ HTTP | `/health`, `/explain`, requestTimeout 10s |
| `server/server.test.js` | 6 test | fetch giả, không gọi Gemini thật |
| `server/stub-upstream.js` | Giả Gemini | trả `[Stub AI]`, cổng 9999 |
| `api/explain.js` + `vercel.json` | Deploy Vercel | dùng lại `createCore`, region `sin1`, rewrite |
| `Dockerfile` + `.dockerignore` | Deploy Docker | `node:22-alpine`, `USER node`, HEALTHCHECK |
| `lib/ai_service.dart` | App gọi AI | fallback, timeout 65s, `_extractText` |
| `lib/reminder_service.dart` | Nhắc ôn | `zonedSchedule` + `DateTimeComponents.time` |
| `lib/reminder_tile.dart` | Công tắc nhắc | xin quyền đúng lúc bật |
| `lib/app_strings.dart` | i18n | `of()`, hàm định dạng |
| `lib/error_state.dart` | Lỗi có lối thoát | nút "Thử lại" |
| `lib/speech_input_service.dart` | Mic | `partialResults`, `cancelOnError`, locale en/vi |
| `.github/workflows/ci.yml` | CI | 4 job, retry Maven 429, artifact |
| `tool/audit_question_bank.py` | Audit 300 câu | exit 0/1 |

---

*Tài liệu này chỉ gói gọn phần của Đoàn Vũ Phúc (AlanPhuc). Khi trả lời vấn đáp, hãy mở
đúng file để đối chiếu số dòng. Chúc bạn thi tốt!*
