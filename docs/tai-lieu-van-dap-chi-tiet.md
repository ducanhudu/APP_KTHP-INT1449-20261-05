# Tài liệu vấn đáp — Ứng dụng "Flutter Lab" (flutter_quiz_app)

Tài liệu này giải thích **toàn bộ** mã nguồn của ứng dụng: từng file, từng khối
(class/component), từng hàm quan trọng, và các luồng hoạt động. Mục tiêu: khi thầy
hỏi bất kỳ đoạn code nào, bạn đều có câu trả lời có cấu trúc.

> Mẹo trả lời vấn đáp: luôn trả lời theo 3 lớp — **(1) nó là gì / ở đâu**,
> **(2) nó làm gì, từng bước**, **(3) vì sao lại viết như vậy (lí do thiết kế)**.

---

## Mục lục

1. [Tổng quan dự án](#1-tổng-quan-dự-án)
2. [Cấu trúc thư mục và vai trò từng file](#2-cấu-trúc-thư-mục-và-vai-trò-từng-file)
3. [Cấu hình dự án](#3-cấu-hình-dự-án)
4. [Dữ liệu: ngân hàng 300 câu hỏi](#4-dữ-liệu-ngân-hàng-300-câu-hỏi)
5. [Tầng Model & nghiệp vụ lõi](#5-tầng-model--nghiệp-vụ-lõi)
6. [Tầng lưu trữ (Storage)](#6-tầng-lưu-trữ-storage)
7. [Tầng dịch vụ (Services)](#7-tầng-dịch-vụ-services)
8. [Tầng giao diện (UI)](#8-tầng-giao-diện-ui)
9. [Các luồng hoạt động chính](#9-các-luồng-hoạt-động-chính)
10. [Bộ câu hỏi vấn đáp mẫu kèm đáp án](#10-bộ-câu-hỏi-vấn-đáp-mẫu-kèm-đáp-án)
11. [Bảng cheat-sheet nhanh](#11-bảng-cheat-sheet-nhanh)

---

## 1. Tổng quan dự án

| Hạng mục | Nội dung |
| --- | --- |
| Tên package | `flutter_quiz_app` |
| Mô tả | Ứng dụng Android ôn thi **Flutter và Dart** bằng **300 câu hỏi song ngữ** |
| Ngôn ngữ | Dart + Flutter (Material 3) |
| Nền tảng | Android (có cấu trúc cross-platform sẵn) |
| Phiên bản | 1.0.0+1 |
| Dart SDK | `^3.13.5` (đi kèm Flutter 3.47.6 stable) |
| Điểm vào | `lib/main.dart` → hàm `main()` → `runApp(const FlutterLab())` |

**Các tính năng chính của app:**

1. **Luyện tập** (practice): chọn khối kiến thức, số câu (3/5/10/15/20/30), ngôn ngữ.
2. **Thi thử** (mock exam): 50 câu, 50 phút, có đồng hồ đếm ngược, tự nộp khi hết giờ.
3. **Kết quả & làm lại câu sai**: thống kê theo khối, xem lại từng câu, làm lại câu sai.
4. **Flashcard SM-2** (Đề 33): lưu câu sai thành thẻ, ôn theo lịch lặp lại ngắt quãng.
5. **Phân tích điểm yếu** (adaptive practice): gợi ý khối yếu, sinh đề 10 câu theo điểm yếu.
6. **Lịch sử làm bài**: lưu tối đa 100 lượt, lọc luyện tập/thi thử, xem lại, xoá.
7. **AI giải thích** (Ngày 3): gọi API giải thích câu hỏi, có fallback lời giải gốc.
8. **TTS** (Ngày 3): đọc lời giải bằng giọng nói (vi/en).
9. **Camera học tập**: quét ảnh (OCR) và mã QR để tìm câu trong ngân hàng.
10. **Nhập giọng nói**: nói câu hỏi rồi tìm trong 300 câu.
11. **Nhắc ôn hằng ngày**: thông báo lúc 20:00 mỗi ngày.

**Nguyên tắc kiến trúc xuyên suốt dự án (rất hay bị hỏi):**

- **Tách interface khỏi hiện thực (Dependency Injection / Inversion)**: mọi dịch vụ
  có 1 `abstract class` + 1 bản "thật" + 1 bản "giả cho test". Ví dụ
  `CardStorage` / `SharedPrefsCardStorage` / `MemoryCardStorage`. Nhờ đó widget test
  chạy được mà không cần thiết bị thật.
- **State nâng lên (lift state up)**: `QuizHome` là nơi giữ trạng thái chính
  (ngôn ngữ, tab, chủ đề, số câu) và truyền xuống các màn hình con qua constructor.
- **Hàm khởi tạo có tham số mặc định dùng `const`**: cho phép test truyền bản giả.

---

## 2. Cấu trúc thư mục và vai trò từng file

```
app/
├── lib/                         # Toàn bộ mã Dart
│   ├── main.dart                # Điểm vào + QuizHome + QuizPage + ResultPage
│   ├── question.dart            # Model câu hỏi, kết quả, tạo đề, 20 khối kiến thức
│   ├── quiz_attempt.dart        # Model 1 lượt làm bài (lưu lịch sử)
│   ├── sm2.dart                 # Thuật toán SuperMemo-2 + model thẻ flashcard
│   ├── card_storage.dart        # Lưu/nạp bộ thẻ (SharedPreferences / RAM)
│   ├── history_storage.dart     # Lưu/nạp lịch sử làm bài
│   ├── weakness_analyzer.dart   # Phân tích điểm yếu + sinh đề thích ứng
│   ├── question_search.dart     # Chuẩn hoá văn bản + tìm kiếm + parse QR
│   ├── app_strings.dart         # Nhãn giao diện 2 ngôn ngữ (Việt/Anh)
│   ├── app_theme.dart           # Theme Material 3
│   ├── question_prompt.dart     # Widget hiển thị câu hỏi + code snippet
│   ├── error_state.dart         # Widget trạng thái lỗi có nút "Thử lại"
│   ├── reminder_service.dart    # Dịch vụ nhắc ôn hằng ngày
│   ├── reminder_tile.dart       # Công tắc bật/tắt nhắc ôn
│   ├── tts_service.dart         # Dịch vụ đọc giọng nói (TTS)
│   ├── ai_service.dart          # Dịch vụ gọi API AI giải thích
│   ├── study_image_service.dart # Nhận diện ảnh (OCR) + quét QR
│   ├── speech_input_service.dart# Nhận diện giọng nói
│   ├── today_overview.dart      # Màn hình "Hôm nay" (tab 0)
│   ├── flashcard_page.dart      # Màn hình ôn thẻ SM-2 (tab 2)
│   ├── history_page.dart        # Màn hình lịch sử làm bài
│   ├── learning_tools.dart      # Bảng chọn AI / camera + panel AI
│   └── camera_study_page.dart   # Màn hình camera học tập
├── assets/
│   └── flutter_quiz_300.json    # Ngân hàng 300 câu hỏi (asset đóng gói APK)
├── test/                        # 21 file test (unit + widget)
├── tool/audit_question_bank.py  # Script Python kiểm tra dữ liệu JSON
├── docs/                        # Báo cáo, ảnh chụp màn hình, tài liệu
└── android/                     # Cấu hình Android (manifest, MainActivity)
```

---

## 3. Cấu hình dự án

### 3.1 `pubspec.yaml`

Các dependency chia 2 nhóm (lưu ý comment trong file giải thích lí do hạ SDK):

**`dependencies` (dùng trong app):**

| Package | Phiên bản | Mục đích |
| --- | --- | --- |
| `flutter` | sdk | Khung giao diện |
| `shared_preferences` | ^2.2.2 | Lưu dữ liệu bền vững (bộ thẻ, lịch sử, cài đặt nhắc) |
| `flutter_local_notifications` | ^19.0.0 | Thông báo đẩy cục bộ (nhắc ôn) |
| `timezone` | ^0.10.0 | Tính múi giờ cho lịch thông báo |
| `flutter_timezone` | ^4.1.0 | Lấy múi giờ thật của thiết bị |
| `http` | ^1.2.0 | Gọi API AI (Ngày 3) |
| `flutter_tts` | ^4.2.0 | Đọc giọng nói (Ngày 3) |
| `image_picker` | ^1.2.4 | Chọn/chụp ảnh |
| `google_mlkit_text_recognition` | ^1.0.3 | OCR nhận diện chữ trong ảnh |
| `google_mlkit_barcode_scanning` | ^1.0.3 | Quét mã QR |
| `speech_to_text` | ^7.5.0 | Nhận diện giọng nói |

**`dev_dependencies` (chỉ cho phát triển/test):** `flutter_test`, `integration_test`, `flutter_lints`.

**`flutter.assets`**: khai báo `assets/flutter_quiz_300.json` → file được đóng gói vào
APK và đọc bằng `rootBundle` (không cần mạng).

### 3.2 `android/app/src/main/AndroidManifest.xml`

Đây là nơi khai báo **quyền (permission)** và **receiver thông báo**:

- `POST_NOTIFICATIONS` — quyền thông báo (Android 13+).
- `RECEIVE_BOOT_COMPLETED` — để đặt lại lịch nhắc sau khi khởi động máy.
- `INTERNET` — chỉ dùng cho nút "Hỏi AI".
- `RECORD_AUDIO` — chỉ xin khi bấm "Nhập bằng giọng nói".
- Hai `<receiver>` của `flutter_local_notifications`:
  - `ScheduledNotificationReceiver` — nhận lịch đặt.
  - `ScheduledNotificationBootReceiver` — đặt lại lịch sau khi reboot (intent-filter `BOOT_COMPLETED`, `MY_PACKAGE_REPLACED`, ...).
- `<activity>` với `launchMode="singleTop"`, `windowSoftInputMode="adjustResize"` (bàn phím đẩy layout lên).
- `<queries>`: khai báo để Android 11+ tìm thấy engine TTS (`TTS_SERVICE`) và bộ nhận
  diện giọng nói (`RecognitionService`), và action `PROCESS_TEXT`.

**Điểm quan trọng (comment trong file):** quyền runtime (thông báo, ghi âm) **không
hỏi lúc mở app**, mà chỉ hỏi đúng lúc người dùng bật tính năng tương ứng.

### 3.3 `MainActivity.kt`

```kotlin
package vn.flutterlab.flutter_quiz_app
import io.flutter.embedding.android.FlutterActivity
class MainActivity : FlutterActivity()
```

Chỉ là class Android entry point chuẩn của Flutter, kế thừa `FlutterActivity`,
không thêm logic gì.

---

## 4. Dữ liệu: ngân hàng 300 câu hỏi

File `assets/flutter_quiz_300.json` là một **mảng JSON** gồm 300 phần tử. Mỗi phần tử:

```json
{
  "id": 1,                        // số nguyên, duy nhất 1..300
  "code": "K01-001",              // mã tham chiếu K##-### (dùng để quét QR)
  "topic": 1,                     // khối kiến thức 1..20
  "level": "Nhớ",                 // Nhớ / Hiểu / Vận dụng
  "question_vi": "...",           // câu hỏi tiếng Việt
  "question_en": "...",           // câu hỏi tiếng Anh
  "code_snippet": "",             // đoạn mã minh hoạ (78 câu có)
  "options": [                    // đúng 4 lựa chọn A/B/C/D
    { "id": "A", "vi": "final", "en": "final" }
  ],
  "explanation_vi": "...",        // lời giải tiếng Việt
  "explanation_en": "...",        // lời giải tiếng Anh
  "correct_answer": "C",          // ID đáp án đúng
  "source_url": "https://..."     // nguồn tài liệu (app chưa đọc)
}
```

**20 khối kiến thức** (mảng `topicNames` trong `question.dart`, `K01`..`K20`):

Dart căn bản · Công cụ và môi trường · Widget và vòng đời · Bố cục giao diện ·
Material và Cupertino · Thiết kế thích ứng · Tương tác và biểu mẫu · Hình ảnh và
tài nguyên · Điều hướng · Hoạt ảnh · Trợ năng · Quản lý trạng thái · Dữ liệu và
bất đồng bộ · Kiến trúc ứng dụng · Package và plugin · Kiểm thử · Hiệu năng ·
Flutter đa nền tảng · Cấu hình và bảo mật · Flutter và AI.

**Kiểm tra tính hợp lệ** (hàm `decodeQuestions`, xem mục 5.1): đúng 300 câu, `id`
không trùng, `topic` trong 1..20, đúng 4 lựa chọn không trùng, đáp án nằm trong 4
lựa chọn, không trường bắt buộc nào rỗng. Nếu sai → ném `FormatException` ngay.

---

## 5. Tầng Model & nghiệp vụ lõi

### 5.1 `lib/question.dart` — Model câu hỏi và nghiệp vụ đề thi

Đây là file "xương sống" về dữ liệu. Các thành phần:

**`enum QuestionLanguage`** (3 giá trị: `vietnamese`, `english`, `bilingual`)

- Mỗi giá trị có `label` ("Tiếng Việt" / "English" / "Việt + English").
- Hàm `display(vietnamese, english)`: trả về chuỗi theo ngôn ngữ. Chế độ song ngữ
  (`bilingual`) ghép `"$vietnamese\n\n$english"` (nếu 2 chuỗi khác nhau).

**Hai mảng tên khối:** `topicNames` (Việt) và `topicNamesEn` (Anh), cùng thứ tự.

- `topicName(topic, language)` — chỉ tên khối (không mã).
- `topicLabel(topic, language)` — mã + tên, dạng `"K01 · Dart căn bản"`. Nếu topic
  ngoài 1..20 thì chỉ trả mã `"K##"` (dùng `padLeft(2, '0')`).

**`class Choice`**: 1 lựa chọn gồm `id` (A/B/C/D), `vi`, `en`.

**`class Question`**:

- Constructor `Question.fromJson(Map<String, Object?> json)` đọc từng trường.
  Chú ý `code` và `code_snippet` dùng `as String? ?? ''` (cho phép null/rỗng),
  còn các trường bắt buộc dùng `as` (ép kiểu cứng).
- `choices` được `List.unmodifiable(...)` — bất biến, chống sửa ngoài ý muốn.

**`decodeQuestions(String source)`** — nạp + kiểm tra ngân hàng:

1. `jsonDecode` rồi `cast<Map<String, Object?>>()`.
2. `map(Question.fromJson)` thành danh sách.
3. Kiểm tra bằng `questions.any(...)`: dùng `ids` (`Set<int>`) để phát hiện trùng;
   kiểm tra 4 lựa chọn duy nhất, `correctId` có nằm trong lựa chọn, không chuỗi
   bắt buộc nào rỗng (kể cả `choice.id/vi/en`).
4. Sai → `throw const FormatException('Ngân hàng câu hỏi không hợp lệ.')`.
5. Đúng → `List.unmodifiable(questions)`.

**`class QuizItem`**: 1 câu trong 1 đề. Constructor nhận `Random` rồi
`[...question.choices]..shuffle(random)` — **xáo trộn thứ tự lựa chọn** mỗi lần tạo
đề (chống học thuộc vị trí A/B/C/D). Lưu ý: thứ tự hiển thị dùng `item.choices`,
nhưng đáp án đúng vẫn so theo `choice.id`.

**`createQuiz(pool, count, {random})`**:

1. `pool.toList()..shuffle(rng)` — xáo câu.
2. `RangeError.checkValueInInterval(count, 1, questions.length, 'count')` — kiểm tra
   `count` hợp lệ (nếu không sẽ ném lỗi).
3. Lấy `take(count)` rồi tạo `QuizItem` cho mỗi câu.

**`class Score`**: đếm `correct / wrong / skipped`.

- `total = correct + wrong + skipped`.
- `percent = total == 0 ? 0 : (100 * correct / total).round()`.
- `add(question, answer)`: trả về `Score` mới (immutable) — nếu `answer ==
  correctId` tăng correct; nếu có answer nhưng khác correctId tăng wrong; nếu
  `answer == null` tăng skipped.

**`class QuizResult`**: kết quả 1 bài.

- Constructor lưu `items` (List bất biến) và `answers` (Map `int -> String`, bất
  biến) và `expired` (bài bị hết giờ).
- `wrongQuestions`: các câu **đã trả lời** nhưng sai (`answers.containsKey(id) &&
  answers[id] != correctId`). (Câu bỏ trống không tính là "sai" ở đây.)
- `score`: dùng `fold` cộng dồn từ `Score` rỗng.
- `byTopic`: `Map<int, Score>` — gộp kết quả theo `topic`, sắp xếp key tăng dần.

**`class QuestionCard`**: mô hình thẻ (từ kết quả xem lại). Có `id`, `questionId`,
`note`; hàm `resolve(bank)` tìm `Question` theo `questionId` (trả `null` nếu không
thấy).

**`createSampleResult(bank)`** — tạo kết quả mẫu (dùng cho nút "Xem lượt kết quả
mẫu"): lấy 3 câu đầu, tạo 1 câu đúng + 1 câu sai + 1 câu bỏ trống bằng cách bỏ
`q3.id` khỏi map `answers`.

### 5.2 `lib/quiz_attempt.dart` — Model 1 lượt làm bài

Đại diện **1 lượt đã hoàn thành** để lưu lịch sử.

- Constructor yêu cầu nhiều trường; `answers` và `questionIds` mặc định rỗng và
  được `Map.unmodifiable` / `List.unmodifiable`.
- `QuizAttempt.fromResult(...)`: chuyển từ `QuizResult`. `id` mặc định là
  `attempt_${now.millisecondsSinceEpoch}`; lưu tổng câu, đúng/sai/bỏ, thời lượng,
  `expired`, `answers` (map câu trả lời), `questionIds` (danh sách ID câu trong bài).
- `QuizAttempt.fromJson(...)`: đọc lại từ JSON — chú ý `answers` lưu dạng
  `Map<String, Object?>` nên phải `int.parse(entry.key)` để khôi phục key kiểu `int`.
- `percent` = `100 * correct / totalQuestions`.
- `toJson()`: xuất ngược, `answers` chuyển key `int` → `String`.

**Vì sao cần `questionIds` riêng?** Để khi xem lại 1 lượt cũ, app vẫn biết thứ tự
câu và có thể tạo lại `QuizResult` (xem `_reviewAttempt` trong `history_page.dart`).

### 5.3 `lib/sm2.dart` — Thuật toán SuperMemo-2 (SM-2)

Đây là phần **hay được hỏi kỹ nhất** vì liên quan thuật toán (Đề 33).

**`class Sm2Item`** — 1 thẻ ghi nhớ:

- `questionId`: ID câu gốc trong ngân hàng 300 câu.
- `repetitions`: số lần nhớ liên tiếp (grade ≥ 3).
- `interval`: khoảng cách đến lần ôn tiếp theo (ngày).
- `easeFactor`: hệ số độ dễ, mặc định **2.5**, tối thiểu **1.3**.
- `nextReviewDate`: ngày đến hạn ôn tiếp.
- `lastReviewedAt`: lần ôn gần nhất (null nếu chưa ôn).
- `Sm2Item.initial(...)`: tạo thẻ mới, `nextReviewDate` = hôm nay (ô mốc giờ 0).
- `isDue([now])`: so sánh theo **ngày** (bỏ giờ phút), trả `true` nếu hôm nay ≥ hạn.
- `toJson()`: chỉ thêm `lastReviewedAt` khi khác null (dùng `if` trong map).

**`class Sm2`** — bộ tính toán:

- Hằng số `minEaseFactor = 1.3`.
- Hàm `review({item, grade, reviewDate})` nhận điểm **grade từ 0..5**:
  - Kiểm tra `RangeError.checkValueInInterval(grade, 0, 5, 'grade')`.
  - **Bước 1 — tính EF mới** theo công thức SM-2:
    ```
    EF' = EF + (0.1 - (5 - grade) * (0.08 + (5 - grade) * 0.02))
    ```
    Nếu `EF' < 1.3` thì gán `1.3`. Làm tròn 2 chữ số (`(newEf * 100).roundToDouble() / 100`).
  - **Bước 2 — tính interval & repetitions**:
    - `grade >= 3` (nhớ thành công):
      - `repetitions == 0` → interval = **1 ngày**
      - `repetitions == 1` → interval = **6 ngày**
      - `repetitions >= 2` → interval = `(interval_trước * EF).round()`
      - `repetitions` tăng 1.
    - `grade < 3` (quên/sai): `repetitions = 0`, interval = **1 ngày** (reset chuỗi).
  - **Bước 3 — ngày kế tiếp**: `today.add(Duration(days: newInterval))`.
  - Trả về `Sm2Item` mới với `lastReviewedAt = now`.

**Ý nghĩa các mức grade (ghi trong docstring):** 5 = nhớ hoàn hảo, 4 = nhớ đúng sau
đắn đo, 3 = nhớ đúng nhưng khó khăn, 2 = sai nhưng đáp án dễ nhớ lại, 1 = sai và xem
đáp án mới nhớ, 0 = quên hoàn toàn.

### 5.4 `lib/weakness_analyzer.dart` — Phân tích điểm yếu & đề thích ứng

**`class TopicMastery`** — thống kê 1 khối:

- `accuracy = correctCount / totalAnswered` (0 nếu chưa làm).
- `accuracyPercent = (accuracy * 100).round()`.
- `errorRate = wrongCount / totalAnswered`.
- `isWeak` (điều kiện "khối yếu"):
  - `(totalAnswered >= 2 && accuracy < 0.7)` — làm ≥2 câu mà đúng <70%, **hoặc**
  - `(cardCount >= 2 && accuracy < 0.75)` — có ≥2 thẻ cần ôn và đúng <75%.
- `weaknessScore` (điểm yếu, càng cao càng cần ôn):
  ```
  (1 - accuracy) * 0.6 + errorRate * 0.25 + (cardCount > 0 ? 0.15 : 0.0)
  ```

**`class WeaknessAnalysisResult`**: chứa `topicStats` (map topic → mastery),
`rankedWeakTopics` (đã sắp xếp), `hasEnoughData`, `totalQuestionsAttempted`.
`topWeakTopics(n = 3)` trả về top N khối yếu nhất.

**`WeaknessAnalyzer.analyze(...)`** — các bước:

1. Tạo `questionMap` (id → Question).
2. Đếm thẻ theo khối (`cardsPerTopic`).
3. Lặp qua lịch sử: với mỗi câu đã làm, phân loại đúng/sai/bỏ trống theo `topic`.
   (Lưu ý: câu bỏ trống `answer == null` chỉ tăng `skipped`, **không** tăng `total`.)
4. Khởi tạo `TopicMastery` cho cả 20 khối.
5. `activeTopics` = các khối có dữ liệu (đã làm >0 hoặc có thẻ).
6. Sắp xếp giảm dần theo `weaknessScore`.
7. `weakTopics` = activeTopics mà `isWeak || accuracy < 0.75`.
8. `rankedWeakTopics` = weakTopics (nếu rỗng thì lấy activeTopics).
9. `hasEnoughData` = đã làm >0 câu **hoặc** có thẻ.

**`selectAdaptiveQuestions(...)`** — sinh đề 10 câu theo điểm yếu:

1. `targetTopics` = 3 khối yếu nhất.
2. `pastWrongIds` = các câu từng làm sai trong lịch sử.
3. `cardIds` = ID câu có trong bộ thẻ.
4. Ưu tiên lấy câu (trong `targetPool` đã shuffle):
   - **Ưu tiên 1**: câu từng sai thuộc khối yếu.
   - **Ưu tiên 2**: câu có thẻ thuộc khối yếu.
   - **Ưu tiên 3**: câu khác trong khối yếu.
5. Nếu chưa đủ `count`, bốc thêm từ toàn ngân hàng (ưu tiên câu từng sai trước).
6. Trả về danh sách đã `shuffle` lại.

### 5.5 `lib/question_search.dart` — Chuẩn hoá văn bản, tìm kiếm, parse QR

**`normalizeStudyText(value)`** — chuẩn hoá để so khớp OCR không cần dấu:

- `toLowerCase()`.
- Bỏ dấu tiếng Việt: map từng ký tự có dấu về ký tự gốc (à→a, đ→d, ...).
- Xoá dấu tổ hợp `[\u0300-\u036f]` (combining diacritics).
- Thay mọi thứ không phải `[a-z0-9_]` thành khoảng trắng, rồi `trim` và gộp nhiều
  khoảng trắng thành 1.

**`_stopWords`** — tập từ dừng (the, a, an, is, of, ... và cả vài từ Việt đã bỏ dấu
như "va", "cua", "trong", "nao", "mot"...). `_tokens(value)` tách từ, loại từ dừng,
trả `Set<String>`.

**`searchStudyQuestions(bank, query, {limit = 5})`**:

- Nếu query rỗng → trả `[]`.
- Với mỗi câu, duyệt 2 bản `q.vi` và `q.en`:
  - Nếu text câu ≥15 ký tự và query (đã chuẩn hoá) **chứa trọn** text → `score = 1`.
  - Ngược lại, tính độ trùng token:
    `score = 0.7 * overlap / tokens.length + 0.3 * overlap / words.length`.
    Bỏ qua nếu `overlap == 0` hoặc (query >2 token mà overlap <2).
- Giữ câu có `score >= 0.2`, sắp xếp giảm dần theo score (bằng nhau thì theo id tăng),
  lấy tối đa `limit`.

**`questionFromStudyQr(bank, value)`** — chỉ chấp nhận QR định dạng app quy định:

- Dạng URI: `flutterlab://question/81` với `scheme == flutterlab`, `host == question`,
  không userInfo, không port/query/fragment, path đúng 1 segment là số → lấy id.
- Hoặc mã tham chiếu đúng dạng `K##-###` (`RegExp(r'^K\d{2}-\d{3}$')`) khớp `referenceCode`.
- Trả về câu khớp, không thì `null`. (Quan trọng: **không mở website ngoài**, chỉ mở
  câu có sẵn trong ngân hàng.)

---

## 6. Tầng lưu trữ (Storage)

### 6.1 `lib/card_storage.dart` — Lưu bộ thẻ flashcard

**`abstract class CardStorage`** định nghĩa 5 thao tác: `loadCards`, `saveCards`,
`addCards`, `updateCard`, `removeCard`, `clear`.

**`SharedPrefsCardStorage`** (bản thật, bền vững):

- `storageKey = 'flutter_quiz_cards_sm2'`.
- `loadCards()`: đọc string từ SharedPreferences, `jsonDecode`, chống lỗi bằng
  `try/catch` (lỗi thì trả `[]` và `debugPrint`). Xử lý cả 2 kiểu phần tử
  `Map<String, Object?>` và `Map` (tương thích dữ liệu cũ).
- `saveCards(cards)`: `jsonEncode(cards.map(toJson).toList())` rồi `setString`.
- `addCards(questionIds, {now})`: đọc toàn bộ, dùng `existingIds` (Set) để **chống
  trùng**, chỉ thêm câu mới bằng `Sm2Item.initial`, trả về **số thẻ mới thêm**.
- `updateCard(item)`: thay thế theo `questionId` (nếu có), không thì thêm mới.
- `removeCard(questionId)`, `clear()` (xóa key khỏi prefs).

**`MemoryCardStorage`** (bản giả cho test): lưu trong `Map<int, Sm2Item> _cards`,
cùng giao diện, không cần plugin. Hàm `addCards` cũng trả số thẻ mới.

### 6.2 `lib/history_storage.dart` — Lưu lịch sử làm bài

**`abstract class HistoryStorage`**: `loadHistory`, `saveAttempt`, `deleteAttempt`,
`clearHistory`.

**`SharedPrefsHistoryStorage`**:

- Mặc định `key = 'flutter_lab_quiz_history_v1'`, `maxItems = 100`.
- `loadHistory()`: đọc JSON, sắp xếp **mới nhất trước** (`b.timestamp.compareTo(a.timestamp)`).
- `saveAttempt(attempt)`: thêm `attempt` lên đầu, **bỏ trùng id** (upsert), rồi
  `take(maxItems)` để giới hạn 100 lượt.
- `deleteAttempt(id)`, `clearHistory()`.

**`MemoryHistoryStorage`**: bản giả lưu `List`, `saveAttempt` cũng `insert(0)` + xoá trùng.

---

## 7. Tầng dịch vụ (Services)

### 7.1 `lib/reminder_service.dart` — Nhắc ôn hằng ngày

**`enum ReminderResult`**: `scheduled`, `permissionDenied`, `failed`.

**`abstract class ReminderService`**: `isEnabled()`, `enable({hour, minute})`,
`disable()`.

**`NotificationReminderService`**:

- Hằng số: `enabledKey`, `timeKey`, `notificationId = 1001`.
- `_ensureReady()`: khởi tạo timezone (`tz_data.initializeTimeZones()`,
  `FlutterTimezone.getLocalTimezone()`, `tz.setLocalLocation`), rồi
  `_plugin.initialize(...)` với icon `@mipmap/ic_launcher`.
- `_requestPermission()`: gọi `requestNotificationsPermission()` (Android).
- `enable()`:
  1. `_ensureReady()`, xin quyền (từ chối → trả `permissionDenied`).
  2. `_plugin.cancel(notificationId)` (xóa lịch cũ).
  3. `_plugin.zonedSchedule(...)` đặt lịch vào `_nextInstance(hour, minute)`, với
     `matchDateTimeComponents: DateTimeComponents.time` → **lặp lại đúng giờ mỗi ngày**,
     `androidScheduleMode: inexactAllowWhileIdle` (vẫn chạy khi máy ở chế độ chờ).
  4. Lưu `enabledKey = true`, `timeKey = "HH:mm"`.
- `disable()`: hủy lịch + đặt `enabledKey = false`.
- `_nextInstance(hour, minute)`: lấy giờ đó hôm nay; nếu đã qua thì cộng 1 ngày.

### 7.2 `lib/reminder_tile.dart` — Công tắc nhắc ôn (UI của dịch vụ trên)

- `ReminderTile` là `StatefulWidget`, có `service`, `hour = 20`, `strings`.
- `_enabled` kiểu `bool?` (null = đang tải) → lúc tải xong mới hiện giá trị thật.
- `_toggle(value)`:
  - Tắt: `service.disable()`, cập nhật UI, hiện SnackBar "Đã tắt nhắc ôn".
  - Bật: `service.enable(hour: widget.hour)`, ánh xạ kết quả sang thông báo
    (scheduled/denied/failed).
- `build`: dùng `SwitchListTile.adaptive`, `onChanged` là `null` khi `_enabled == null`
  hoặc `_busy` (đang thao tác) → vô hiệu hoá tạm.

### 7.3 `lib/tts_service.dart` — Đọc giọng nói

**`enum TtsState`**: `stopped`, `playing`, `error`.

**`class TtsService`**:

- Constructor gọi `_init()` đăng ký các handler của `flutter_tts`:
  - `setStartHandler` → `playing`
  - `setCompletionHandler` / `setCancelHandler` → `stopped`
  - `setErrorHandler` → nếu lỗi chứa "permission" thì `permissionDenied = true`, rồi `error`.
- `onStateChanged` là `Stream<TtsState>` (broadcast) để UI lắng nghe trạng thái.
- `speak(text, {language})`: chặn nếu `permissionDenied || _disposed`; `stop()` trước,
  `setLanguage('en-US' | 'vi-VN')`, `setSpeechRate(0.5)`, rồi `speak(text)`. Mỗi bước
  có `if (_disposed) return` để tránh chạy sau khi đã hủy.
- `stop()`, `dispose()` (đóng StreamController, `unawaited` stop).

### 7.4 `lib/ai_service.dart` — Gọi AI giải thích

**`class AiResult`**: `text` (nội dung), `fromFallback` (true nếu là lời giải gốc).

**`class AiService`** (toàn bộ `static`):

- `accessCode` đọc từ `String.fromEnvironment('AI_ACCESS_CODE')` (nhúng lúc build).
- `_baseUrl` đọc từ `String.fromEnvironment('AI_API_URL', defaultValue: '')`.
- `isConfigured = _baseUrl.isNotEmpty`.
- `_timeout = Duration(seconds: 65)` (model có thể trả lời 5–90s).
- `explain({question, language, client, endpoint})`:
  1. `fallback` = `language.display(explanationVi, explanationEn)`.
  2. Nếu URL rỗng → trả fallback ngay.
  3. Gửi `POST` JSON `{questionId, language: vi/en/bilingual}`, header
     `Content-Type: application/json`, kèm `Authorization: Bearer <code>` nếu có.
  4. `request.timeout(_timeout)`.
  5. Status 200 → `_extractText(body)`; nếu có text → trả `fromFallback: false`.
  6. Mọi lỗi/không hợp lệ → trả fallback `fromFallback: true`.
- `_extractText(body)`: hỗ trợ 2 kiểu backend:
  - Gemini: `candidates[0].content.parts[0].text`.
  - Backend tự viết: `{"text": ...}` hoặc `{"explanation": ...}`.

**Điểm thiết kế:** `client` và `endpoint` chỉ dùng trong test (thay mạng thật và URL
build-time), nên test không cần gọi mạng thật.

### 7.5 `lib/study_image_service.dart` — OCR + quét QR

**`enum StudyScanMode`**: `text`, `qr`.

**`class StudyImageReading`**: kết quả đọc gồm `text` và `codes` (danh sách chuỗi QR).

**`abstract class StudyImageService`**: `pick(source)`, `recoverLostImage()`, `read(path, mode)`.

**`NativeStudyImageService`**:

- `pick`: `_picker.pickImage(maxWidth/Height 2400, imageQuality 90,
  requestFullMetadata: false)` → trả `path`.
- `recoverLostImage()`: chỉ Android; `retrieveLostData()` (khôi phục ảnh bị mất khi
  Activity bị hệ điều hành hủy), trả path file đầu tiên.
- `read(path, mode)`:
  1. Nếu `File(path).length() > 12MB` → ném `FormatException('image_too_large')`.
  2. `InputImage.fromFilePath(path)`.
  3. QR: `BarcodeScanner(formats: [BarcodeFormat.qrCode])`, đọc `barcode.rawValue`.
  4. Text: `TextRecognizer(script: TextRecognitionScript.latin)`, lấy `.text`.
  5. Luôn `await scanner.close()` / `recognizer.close()` trong `finally`.

### 7.6 `lib/speech_input_service.dart` — Nhận diện giọng nói

**`enum SpeechInputFailure`**: `permissionDenied`, `noMatch`, `busy`, `unavailable`,
`failed`. **`class SpeechInputException`** bọc failure.

**`abstract class SpeechInputService`**: `listen(...)`, `stop()`, `dispose()`.

**`NativeSpeechInputService`**:

- `listen({english, onWords, onFailure, onDone})`:
  - Lần đầu `_speech.initialize(onError, onStatus)`; nếu `!ready` → phân biệt
    `hasPermission` để ném `permissionDenied` hay `unavailable`.
  - `_localeId(english)`: chọn locale bắt đầu bằng `en`/`vi` (đổi `_` → `-` để so).
  - `_speech.listen(...)` với `partialResults: true`, `ListenMode.dictation`,
    `pauseFor: 3s`, `listenFor: 60s`, `cancelOnError: true`.
- `_handleStatus`: khi `done`/`notListening` → gọi `onDone`.
- `_mapError(message)`: ánh xạ chuỗi lỗi thành `SpeechInputFailure`.

---

## 8. Tầng giao diện (UI)

### 8.1 `lib/main.dart` — Điểm vào & 3 màn hình chính

File lớn nhất (825 dòng), gồm 4 widget: `FlutterLab`, `QuizHome`, `QuizPage`, `ResultPage`.

**`main()`** → `runApp(const FlutterLab())`.

**`FlutterLab` (StatelessWidget)**:

- Tham số: `storage = const SharedPrefsCardStorage()`, `historyStorage = const
  SharedPrefsHistoryStorage()`, `reminder` (nullable).
- `build` → `MaterialApp(title, debugShowCheckedModeBanner: false, theme:
  buildAppTheme(), home: QuizHome(...))`.
- `export 'question_prompt.dart';` để các file khác import qua `main.dart` (history_page
  import `main.dart` để dùng `ResultPage`).

**`QuizHome` (StatefulWidget)** — "trái tim" của app, giữ trạng thái chính.

`_QuizHomeState` giữ các trường quan trọng:

- `s` getter = `AppStrings.of(language)` (nhãn theo ngôn ngữ).
- `bank` = `_loadBank()` (Future nạp 300 câu 1 lần).
- `cardsFuture` = `widget.storage.loadCards()`.
- `historyFuture` = `widget.historyStorage.loadHistory()`.
- `reminder` = `widget.reminder ?? NotificationReminderService()` (cho phép test truyền bản giả).
- `language = QuestionLanguage.vietnamese`, `selectedTab = 0`, `topic = 0`, `count = 10`, `_deckRevision = 0`.

Các phương thức:

- `_loadBank()`: `rootBundle.loadString('assets/flutter_quiz_300.json')` rồi `decodeQuestions`.
- `_refreshCards()`: `setState` nạp lại cards + history (sau khi làm bài/lưu thẻ/ôn).
- `_startAdaptivePractice(questions)`: phân tích điểm yếu → `selectAdaptiveQuestions`
  → `_runQuiz(adaptive, adaptive.length)` → `_refreshCards()`.
- `_openCamera()`: `showLearningTool(..., LearningTool.camera)` → `setState(_deckRevision++)`
  + `_refreshCards()`.
- `_retryBank()`: nạp lại ngân hàng khi màn hình lỗi.
- `_showResult(result)`: push `ResultPage`, trả `bool?` (true = muốn làm lại câu sai).
- `_runQuiz(pool, questionCount, {exam})` — **luồng quan trọng nhất**, vòng lặp `while(true)`:
  1. `createQuiz(pool, questionCount)`, `timed = exam`.
  2. Push `QuizPage` → nhận `QuizResult`.
  3. Tính `durationSeconds`, `resultTopics`; `topic = timed || resultTopics.length != 1
     ? 0 : resultTopics.single` (bài thi hoặc trộn khối → ghi topic 0 "tất cả").
  4. `QuizAttempt.fromResult(...)` rồi `saveAttempt` (try/catch → SnackBar nếu lỗi lưu).
  5. `_showResult(result)`; nếu người dùng bấm "làm lại" → lấy `wrongQuestions`,
     tạo đề mới `createQuiz(wrong, wrong.length)`, `timed = false`, lặp lại vòng while.
- `_openCards(questions)`: push `FlashcardPage` → refresh.
- `_start(pool, size, {exam})`: `_runQuiz` + refresh.

`build` của `_QuizHomeState`:

- `Scaffold` với `AppBar`: tiêu đề thay đổi theo tab (`[s.appTitle, s.tabPractice,
  s.tabCards][selectedTab]`); 3 action: lịch sử, camera, popup chọn ngôn ngữ.
- `bottomNavigationBar`: `NavigationBar` 3 tab (Hôm nay / Luyện tập / Thẻ ôn), khi đổi
  tab gọi `_refreshCards()`.
- `body`: `FutureBuilder(bank)`:
  - lỗi → `ErrorState(message: s.errorBankLoad, onRetry: _retryBank)`.
  - đang tải (data null) → `CircularProgressIndicator`.
  - **tab 0** → `TodayOverview(...)` truyền nhiều callback.
  - **tab 2** → `FlashcardPage(embedded: true, key: ValueKey(_deckRevision), ...)`.
    (`ValueKey` buộc Flutter tạo lại state khi `_deckRevision` đổi, để nạp lại thẻ.)
  - **tab 1** → giao diện luyện tập: lọc theo `topic`, tính `availableCounts`
    (các mức 3/5/10/15/20/30 ≤ số câu của pool), 2 `DropdownButtonFormField` (ngôn ngữ,
    khối), `ChoiceChip` chọn số câu, nút bắt đầu luyện tập, thi thử, luyện điểm yếu,
    nút xem kết quả mẫu.

**`QuizPage` (StatefulWidget)** — màn hình làm bài:

Tham số: `items`, `language`, `timed`, `onLanguageChanged`, `examDuration = 50 phút`,
`clock` (hàm trả thời gian, để test điều khiển).

`_QuizPageState`:

- `answers = <int, String>{}` (map câu trả lời, key = question.id).
- `_now()` = `widget.clock?.call() ?? DateTime.now()`.
- `deadline`, `timer`, `index = 0`, `submitted`, `seconds = examDuration.inSeconds`.
- `initState`: nếu `timed` → `deadline = _now().add(examDuration)` và
  `Timer.periodic(Duration(milliseconds: 250), (_) => _tick())` (tick mỗi 250ms).
- `_tick()`: nếu hết giờ (`remaining <= 0`) → `_submit(expired: true)`; ngược lại chỉ
  `setState` khi `seconds` thay đổi.
- `_submit({expired})`: chống nộp 2 lần (`submitted`, route inactive); `timer?.cancel()`;
  `navigator.popUntil((c) => c == route)` rồi `navigator.pop(QuizResult(items, answers,
  expired: expired))` — trả kết quả về `_runQuiz`.
- `_goTo(value)`: `if (_tick()) return;` (nếu hết giờ thì dừng) rồi `setState(index)`.
- `clock` getter: định dạng `mm:ss` (`(seconds ~/ 60).padLeft(2,'0')`).
- `dispose`: hủy timer.

`build` của `_QuizPageState`:

- `AppBar`: tiêu đề "Luyện tập"/"Thi thử", nếu `timed` hiện đồng hồ, popup ngôn ngữ.
- `body` là `ListView` với `key: ValueKey(index)` (khi đổi câu, ListView tạo lại, tránh
  giữ trạng thái cuộn cũ):
  - `Text(s.quizCounter(index+1, items.length, answers.length))`.
  - `LinearProgressIndicator(value: answers.length / items.length)`.
  - `Text('${topicLabel(...)} · ${question.level}')`.
  - `QuestionPrompt(...)`.
  - Vòng lặp `for (final (position, choice) in item.choices.indexed)` — tạo
    `ChoiceChip` với nhãn `'${String.fromCharCode(65 + position)}. ...'` (65 = 'A').
    `selected: answers[question.id] == choice.id`. Khi chọn → gán/xoá vào `answers`.
  - Nếu `!timed && answers[question.id] != null`: hiện `Card` verdict "Chính xác" /
    "Cần xem lại" + lời giải (chế độ luyện tập mới hiện đáp án tức thì; thi thử thì không).
- `bottomNavigationBar`: nút trước / "Nộp bài" / nút sau (nút trước/sau bị `null` ở đầu/cuối).

**`ResultPage` (StatelessWidget)** — màn hình kết quả:

- Tham số: `result`, `language`, `storage`.
- `build` dùng `ListView.builder` với `itemCount = items.length + 1` (phần tử 0 là header).
- **Header** (index 0):
  - `score.percent` hiện to, `scoreLine` (đúng/sai/bỏ trống), `expiredNotice` nếu hết giờ.
  - Nếu có câu sai: nút **"Làm lại N câu sai"** (`pop(true)`) và **"Lưu N câu sai vào thẻ"**
    (`storage.addCards(...)` → SnackBar báo số thẻ đã thêm).
  - Phần "Thống kê theo khối" (`byTopic`) dùng `ListTile`.
  - Tiêu đề "Xem lại bài".
- **Từng câu** (index ≥ 1): `ExpansionTile`:
  - `QuestionCard.resolve(...)` để lấy `resolvedQuestion` (đề phòng câu bị xóa khỏi ngân hàng).
  - `status` xác định bằng `switch`: `selected == null` → bỏ trống, `== correctId` →
    đúng, còn lại → sai.
  - Bên trong: `QuestionPrompt`, danh sách lựa chọn kèm đánh dấu "Đáp án đúng" /
    "Bạn đã chọn", lời giải, nút "Hỏi AI về câu này" (`showLearningTool`).

### 8.2 `lib/today_overview.dart` — Màn hình "Hôm nay" (tab 0)

`TodayOverview` là `StatelessWidget` nhận nhiều callback. Cấu trúc `ListView`:

1. Subtitle + heading "Hôm nay học gì?".
2. **Card flashcard**: `FutureBuilder(cardsFuture)` đếm `due` (`card.isDue()`), hiện
   "N thẻ đến hạn" / "N thẻ đã lưu · M thẻ cần ôn hôm nay", nút "Ôn thẻ ngay" / "Mở bộ thẻ".
   Nếu lỗi → nút "Thử lại" (`onRetryCards`).
3. **Card nhắc ôn**: `ReminderTile(service: reminder, strings: s)`.
4. **Phần luyện tập**: nút "Luyện 10 câu" (`onQuickPractice`) + "Thi thử" (`onExam`).
5. **Chọn chủ đề**: 3 khối gợi ý cố định `[1, 3, 12]`, mỗi `ListTile` hiện số câu trong
   khối, tap → `onTopic(topic)`.
6. **Điểm yếu** (chỉ khi `historyFuture != null && onAdaptivePractice != null`):
   `FutureBuilder` lồng nhau để lấy history + cards, gọi `WeaknessAnalyzer.analyze`,
   hiện top 3 khối yếu (màu đỏ nếu accuracy < 0.6, cam ngược lại) + nút "Luyện 10 câu
   điểm yếu".
7. **Công cụ học tập**: `ListTile` "Gia sư AI" gọi `onAiTutor` → mở sheet chọn tối đa
   10 câu đã làm sai từ lịch sử → `showLearningTool(assistant, question, language)`;
   chưa có câu sai nào thì hiện snackbar hướng dẫn làm một lượt luyện tập.
   "Camera học tập" mở `onCameraRequested` hoặc `showLearningTool`.

### 8.3 `lib/flashcard_page.dart` — Ôn thẻ SM-2 (tab 2)

`FlashcardPage` có cờ `embedded` (true khi nhúng trong tab, false khi push độc lập).

`_FlashcardPageState`:

- `language`, `allCards`, `loading`, `onlyDue = true` (mặc định chỉ hiện thẻ đến hạn),
  `currentIndex`, `showAnswer`.
- `didUpdateWidget`: nếu ngôn ngữ đổi thì cập nhật `language`.
- `_loadCards()`: nạp thẻ, đặt `loading = false`, reset index + showAnswer.
- `activeCards`: nếu `onlyDue` → lọc `card.isDue()`.
- `_rateCard(item, grade)`: `Sm2().review(...)` → `storage.updateCard` →
  `onCardsChanged?.call()` → cập nhật list local → chuyển thẻ kế tiếp (hoặc về đầu) →
  SnackBar "Hẹn ôn lại sau N ngày" (hoặc "Ôn lại ngày mai" nếu grade < 3).
- `_deleteCard(questionId)`: xóa khỏi storage + list, giảm index nếu cần.
- `build`: nếu `embedded` trả `body` trực tiếp; nếu không bọc `Scaffold` + AppBar có
  popup ngôn ngữ.
- 4 trạng thái body:
  - `loading` → spinner.
  - `allCards.isEmpty` → `_buildEmptyState()` (hướng dẫn lưu câu sai, nút quay lại luyện tập).
  - `currentList.isEmpty` (đã hết thẻ đến hạn) → `_buildCompletedDueState()` (nút "Ôn
    tiếp tất cả N thẻ" chuyển `onlyDue = false`).
  - còn thẻ → `_buildCardStudyView(currentList)`:
    - Header: "Thẻ x/N", `SegmentedButton<bool>` chọn "Đến hạn"/"Tất cả".
    - Card thông tin SM-2: "Lặp: n lần · Cách: n ngày", "Hạn: dd/mm (EF: x)", nút xóa.
    - Card mặt trước: khối · mức độ, `QuestionPrompt`, danh sách lựa chọn.
    - Nút "Xem đáp án & giải thích" → hiện Card đáp án đúng (viền xanh) + lời giải +
      nút "Hỏi AI" + 4 `ActionChip` đánh giá SM-2: **1 (Quên), 3 (Khó), 4 (Tốt), 5 (Dễ)**.

### 8.4 `lib/history_page.dart` — Lịch sử làm bài

`enum HistoryFilter { all, practice, exam }`.

`_HistoryPageState`:

- `_reload()`: setState gán lại `_historyFuture = historyStorage.loadHistory()`.
- `_confirmClear()`: dialog xác nhận → `clearHistory()` → reload.
- `_deleteAttempt(attempt)`: xóa 1 lượt + SnackBar + reload.
- `_reviewAttempt(attempt)`: **tái tạo** `QuizResult` từ `questionIds` + `answers`
  (dùng `Random(qId)` làm seed để tạo `QuizItem` ổn định) rồi push `ResultPage`.
- `_formatDate(dt)`: `dd/mm/yyyy hh:mm`.
- `build`: AppBar có nút xóa tất cả; bộ lọc `ChoiceChip` (All/Practice/Exam); body
  `FutureBuilder` → `ListView.separated` các `Card`:
  - Chip nhãn "Thi thử"/"Luyện tập" + tên khối + nút xóa.
  - Phần trăm (màu xanh ≥80, cam ≥50, đỏ <50) + `scoreLine`.
  - Ngày giờ + thời lượng.

### 8.5 `lib/learning_tools.dart` — Bảng chọn AI/Camera + Panel AI

**`enum LearningTool { assistant, camera }`**

**`showLearningTool(context, tool, {question, language, storage})`**:

- `camera` → push `CameraStudyPage` (truyền `onExplain` để mở AI khi bấm "Hỏi AI").
- `assistant` → `showModalBottomSheet` với `LearningToolPreview`.

**`LearningToolPreview` (StatefulWidget)** — panel AI:

- Tạo `TtsService _tts`, lắng nghe `onStateChanged` để cập nhật icon.
- `initState`: nếu là assistant và có `question` → `_fetchAi()` ngay (auto-fetch).
- `_fetchAi()`: `AiService.explain(...)` → `_result` (AiResult).
- `_toggleTts()`: nếu đang chơi → stop, ngược lại `speak(result.text)`.
- `_enterAccessCode()`: dialog nhập mã (TextField `obscureText: true`), lưu vào
  `AiService.accessCode`, fetch lại.
- `_buildAiPanel`: tiêu đề (chip "Lời giải gốc" nếu fallback), câu hỏi (giới hạn 3
  dòng), nội dung (`_loading` → spinner, có result → `_buildExplanationCard`), hành động
  (`_buildActionRow`), cảnh báo quyền audio (`_buildPermissionWarning`), nút đóng.
- `_buildExplanationCard`: Card màu khác nhau cho AI (primaryContainer) vs fallback
  (surfaceContainerHighest), có nhãn "AI giải thích".
- `_buildActionRow`: nút "Mã truy cập AI" (chỉ khi `AiService.isConfigured`), nút TTS
  (ẩn nếu `permissionDenied`), nút "Hỏi lại".

### 8.6 `lib/camera_study_page.dart` — Camera học tập (quét ảnh/QR/giọng nói)

File lớn (655 dòng), gồm `CameraStudyPage` + `_ScannedQuestionDetails`.

`_CameraStudyPageState`:

- `_service` (StudyImageService), `_speech` (SpeechInputService) — mặc định bản thật,
  test truyền bản giả.
- `_text` (TextEditingController), `_bank`, `_matches`, `_mode = text`, `_path`,
  `_error`, `_speechNotice`, các cờ `_loadingBank`, `_busy`, `_searched`, `_listening`.
- `_initialize()`: nạp ngân hàng (nếu `widget.questions` null thì tự đọc asset), rồi
  `recoverLostImage()` — nếu có ảnh bị mất thì đọc lại.
- `_message(error)`: ánh xạ lỗi → chuỗi (quyền, ảnh quá lớn, lỗi chung).
- `_pick(source)`: `_service.pick` rồi `_read(path)`.
- `_read(path)`: QR → `questionFromStudyQr` cho từng code, trả `_matches`; text →
  gán `_text.text` (OCR), báo lỗi nếu rỗng.
- `_search()`: `searchStudyQuestions(_bank, _text.text)`.
- `_toggleMic()`: bật/tắt micro, **giữ chữ đã có** (`base = _text.text.trim()`), ghép
  chữ nói thêm; khi `isFinal` hiện thông báo "Đã chép lời. Kiểm tra, sửa rồi bấm Tìm".
- `_openQuestion(q)`: `showModalBottomSheet` → `_ScannedQuestionDetails`.
- `build`: `SegmentedButton` chọn chế độ text/QR, nút chụp/chọn ảnh, ô `TextField`,
  nút mic, nút "Tìm trong 300 câu", hiện `_matches` (danh sách câu gợi ý), hiện ảnh
  đã chọn, thanh tiến trình khi bận.

**`_ScannedQuestionDetails`**: bottom sheet hiện chi tiết 1 câu (QuestionPrompt, các
lựa chọn với icon đúng, đáp án, lời giải), nút "Lưu thẻ ôn" (`storage.addCards`) và
"Hỏi AI".

### 8.7 Các widget nhỏ & theme

**`lib/question_prompt.dart`** — `QuestionPrompt`: `Column` gồm `Text` câu hỏi
(`language.display`) và (nếu `code` không rỗng) `Container` nền `inverseSurface` chứa
`SelectableText` (font monospace) có cuộn ngang (`SingleChildScrollView`).

**`lib/error_state.dart`** — `ErrorState`: `Center` + `Column` (icon error, message,
`FilledButton.icon` "Thử lại"). Dùng chung cho mọi `FutureBuilder` lỗi.

**`lib/app_theme.dart`** — `buildAppTheme()`: `ColorScheme.fromSeed(seedColor:
0xff246b52, primary: 0xff246b52, primaryContainer: 0xffe5f1df, ...)`,
`useMaterial3: true`, nền `0xfff6f7f9`, AppBar không tint, Card bo góc 18, input bo
góc 14, nút tối thiểu cao 48, NavigationBar nền trắng.

**`lib/app_strings.dart`** — `AppStrings`: 2 hằng `vietnamese`/`english`; `of(language)`
trả `english` nếu ngôn ngữ là English, ngược lại trả `vietnamese` (chế độ song ngữ vẫn
dùng nhãn Việt vì nội dung câu đã song ngữ). Chứa nhiều hàm định dạng (counter, score,
duration, cardsDue, accuracy, topicShort...).

---

## 9. Các luồng hoạt động chính

### 9.1 Khởi động app

```
main() → runApp(FlutterLab())
  → MaterialApp(theme: buildAppTheme(), home: QuizHome)
  → QuizHome._loadBank() đọc asset + decodeQuestions (kiểm tra 300 câu)
  → FutureBuilder(bank):
       lỗi → ErrorState("Không đọc được ngân hàng câu hỏi", retry)
       đang tải → spinner
       xong → tab 0 TodayOverview
```

### 9.2 Luyện tập (không tính giờ)

```
QuizHome tab 1 → chọn khối, số câu, ngôn ngữ → FilledButton "Bắt đầu luyện tập"
  → _runQuiz(pool, count) [exam=false]
     → createQuiz (xáo câu + xáo lựa chọn)
     → push QuizPage(timed: false)
     → người dùng chọn đáp án (ChoiceChip ghi vào answers, hiện verdict ngay)
     → bấm "Nộp bài" → pop(QuizResult)
  → saveAttempt (lưu lịch sử)
  → push ResultPage
```

### 9.3 Thi thử (tính giờ, 50 phút)

```
QuizHome → _runQuiz(questions, 50, exam: true)
  → QuizPage(timed: true) → initState đặt deadline + Timer.periodic(250ms)
  → _tick() mỗi 250ms:
       còn giờ → cập nhật seconds
       hết giờ → _submit(expired: true)
  → QuizResult(expired: true) → ResultPage hiện "Hết giờ, bài thi đã được nộp."
```

### 9.4 Làm lại câu sai

```
ResultPage → nút "Làm lại N câu sai" → Navigator.pop(true)
  → _runQuiz nhận retry == true
  → wrong = result.wrongQuestions (chỉ câu đã trả lời sai)
  → createQuiz(wrong, wrong.length), timed = false
  → push QuizPage lần nữa (vòng while)
```

### 9.5 Lưu thẻ & ôn tập SM-2

```
Kết quả → "Lưu N câu sai vào thẻ" / từng câu "Lưu câu này"
  → storage.addCards([...ids]) (chống trùng, trả số thẻ mới)
  → tab 2 FlashcardPage → activeCards (lọc isDue)
  → xem đáp án → chấm grade (1/3/4/5)
  → Sm2.review() tính EF/interval/repetitions/nextReviewDate
  → storage.updateCard() → chuyển thẻ kế tiếp
```

### 9.6 Phân tích điểm yếu & luyện thích ứng

```
TodayOverview / tab luyện tập → "Luyện 10 câu điểm yếu"
  → WeaknessAnalyzer.analyze(history, bank, flashcards)
  → selectAdaptiveQuestions(...) → 10 câu theo 3 khối yếu nhất
  → _runQuiz(adaptive, adaptive.length)
```

### 9.7 Lịch sử

```
QuizHome → nút lịch sử → HistoryPage
  → lọc All/Practice/Exam
  → tap 1 lượt → _reviewAttempt tạo lại QuizResult → ResultPage
  → nút xóa từng lượt / xóa tất cả
```

### 9.8 AI + TTS

```
ResultPage / FlashcardPage / CameraStudyPage → "Hỏi AI về câu này"
  → showLearningTool(assistant) → LearningToolPreview
  → _fetchAi → AiService.explain (POST, timeout 65s)
       thành công → AiResult(fromFallback: false)
       lỗi/timeout/không cấu hình → fallback lời giải gốc
  → nút "Nghe lời giải" → TtsService.speak
  → nút "Mã truy cập AI" (nhập code → fetch lại)
```

### 9.9 Camera / QR / giọng nói

```
TodayOverview → "Camera học tập" → CameraStudyPage
  → chọn chế độ text/QR
  → chụp/chọn ảnh → StudyImageService.read (OCR / quét QR)
     QR → questionFromStudyQr → tìm câu theo flutterlab://question/N hoặc K##-###
     text → điền vào TextField
  → (tùy chọn) mic → SpeechInputService.listen → chép lời vào ô
  → "Tìm trong 300 câu" → searchStudyQuestions → danh sách gợi ý
  → tap câu → _ScannedQuestionDetails (xem + lưu thẻ + hỏi AI)
```

---

## 10. Bộ câu hỏi vấn đáp mẫu kèm đáp án

### A. Tổng quan & cấu hình

**Q1. App này làm gì? Công nghệ gì?**
Ứng dụng Android "Flutter Lab" ôn thi Flutter & Dart bằng 300 câu song ngữ. Viết bằng
Dart + Flutter (Material 3). Điểm vào `lib/main.dart` → `runApp(FlutterLab())`.

**Q2. Kể tên các package chính và công dụng.**
`shared_preferences` (lưu dữ liệu), `flutter_local_notifications` + `timezone` +
`flutter_timezone` (nhắc ôn), `http` (AI), `flutter_tts` (đọc), `image_picker` (chọn
ảnh), `google_mlkit_text_recognition` (OCR), `google_mlkit_barcode_scanning` (QR),
`speech_to_text` (giọng nói).

**Q3. Quyền Android được khai báo ở đâu, gồm gì?**
Trong `android/app/src/main/AndroidManifest.xml`: `POST_NOTIFICATIONS`,
`RECEIVE_BOOT_COMPLETED`, `INTERNET`, `RECORD_AUDIO`, cùng 2 receiver của
flutter_local_notifications và các `<queries>` cho TTS/speech.

**Q4. Tại sao app không cần mạng để chạy phần luyện tập?**
Vì ngân hàng 300 câu nằm trong asset (`assets/flutter_quiz_300.json`), đọc bằng
`rootBundle.loadString`, không phải gọi mạng. Chỉ nút "Hỏi AI" mới dùng `INTERNET`.

### B. Model & dữ liệu

**Q5. Giải thích hàm `decodeQuestions` làm gì.**
Nạp JSON, parse thành `List<Question>`, rồi kiểm tra tính hợp lệ: đúng 300 câu, id
không trùng, topic 1..20, đúng 4 lựa chọn duy nhất, đáp án nằm trong lựa chọn, không
trường bắt buộc nào rỗng. Sai → `FormatException`.

**Q6. `QuestionLanguage` có mấy giá trị? Hàm `display` làm gì?**
3 giá trị: `vietnamese`, `english`, `bilingual`. `display(vi, en)` trả bản tương ứng;
song ngữ ghép `"$vi\n\n$en"`.

**Q7. `createQuiz` xáo trộn gì và vì sao?**
Xáo thứ tự câu (`pool.toList()..shuffle`) và xáo lựa chọn mỗi câu (`QuizItem` shuffle
choices). Vì đáp án đúng vẫn so theo `choice.id`, việc xáo chống học thuộc vị trí A/B/C/D.

**Q8. `Score.add` xử lý đúng/sai/bỏ trống thế nào?**
`answer == correctId` → correct+1; `answer != null && != correctId` → wrong+1;
`answer == null` → skipped+1.

**Q9. `QuizResult.wrongQuestions` và `byTopic` khác gì?**
`wrongQuestions` trả các câu **đã trả lời nhưng sai** (Iterable<Question>). `byTopic`
gộp Score theo khối (Map<int, Score>), sắp theo key tăng.

### C. Thuật toán SM-2 (trọng tâm)

**Q10. SM-2 là gì? Mỗi thẻ `Sm2Item` có những trường nào?**
Thuật toán lặp lại ngắt quãng SuperMemo-2. Thẻ có: `questionId`, `repetitions`,
`interval`, `easeFactor` (mặc định 2.5), `nextReviewDate`, `lastReviewedAt`.

**Q11. Viết công thức tính Ease Factor mới.**
`EF' = EF + (0.1 - (5 - grade) * (0.08 + (5 - grade) * 0.02))`, nếu `< 1.3` thì gán
1.3, làm tròn 2 chữ số.

**Q12. Với grade ≥ 3, interval tính thế nào?**
Lần đầu (repetitions 0) → 1 ngày; lần 2 (repetitions 1) → 6 ngày; từ lần 3 →
`round(interval_trước * EF)`. Repetitions tăng 1.

**Q13. Với grade < 3 thì sao?**
Reset chuỗi: `repetitions = 0`, `interval = 1 ngày` (mai ôn lại).

**Q14. `isDue` so sánh theo ngày hay giờ? Vì sao?**
Theo ngày (chuẩn hoá về đầu ngày). Vì lịch ôn tính theo ngày, không cần chính xác giờ.

### D. Điểm yếu & tìm kiếm

**Q15. Điều kiện một khối bị coi là "yếu"?**
`(totalAnswered >= 2 && accuracy < 0.7)` hoặc `(cardCount >= 2 && accuracy < 0.75)`.

**Q16. `weaknessScore` gồm những thành phần nào?**
`(1 - accuracy) * 0.6 + errorRate * 0.25 + (cardCount > 0 ? 0.15 : 0)`.

**Q17. `selectAdaptiveQuestions` ưu tiên chọn câu theo thứ tự nào?**
(1) câu từng sai thuộc khối yếu; (2) câu có thẻ thuộc khối yếu; (3) câu khác trong
khối yếu; (4) nếu thiếu thì bốc toàn ngân hàng (ưu tiên câu từng sai).

**Q18. `normalizeStudyText` làm gì?**
Chuyển thường, bỏ dấu tiếng Việt, xoá dấu tổ hợp, thay ký tự không phải `[a-z0-9_]`
thành khoảng trắng, gộp khoảng trắng. Mục đích: so khớp OCR không cần dấu chính xác.

**Q19. `questionFromStudyQr` chấp nhận định dạng QR nào?**
`flutterlab://question/<id>` (đúng scheme/host/path) hoặc mã `K##-###` khớp
`referenceCode`. Không mở website ngoài.

### E. Storage & Services

**Q20. Tại sao vừa có `CardStorage` (abstract) vừa có `SharedPrefsCardStorage`,
`MemoryCardStorage`?**
Tách interface khỏi hiện thực để test truyền bản giả (`MemoryCardStorage`) không cần
plugin; bản thật dùng SharedPreferences bền vững.

**Q21. `addCards` chống trùng thế nào? Trả về gì?**
Dùng `existingIds` (Set) bỏ qua ID đã có, chỉ thêm `Sm2Item.initial` cho ID mới; trả
về số thẻ mới thêm.

**Q22. `HistoryStorage.saveAttempt` giới hạn bao nhiêu lượt? Cơ chế?**
Mặc định `maxItems = 100`; thêm attempt lên đầu, bỏ trùng id, `take(100)`.

**Q23. `NotificationReminderService.enable` thực hiện các bước gì?**
Khởi tạo timezone/plugin → xin quyền thông báo → hủy lịch cũ → `zonedSchedule` với
`matchDateTimeComponents: DateTimeComponents.time` (lặp hằng ngày) → lưu cờ + giờ.

**Q24. TTS xử lý lỗi quyền thế nào?**
Handler lỗi kiểm tra chuỗi có "permission" thì đặt `permissionDenied = true`, chuyển
`TtsState.error`; `speak` chặn nếu đã bị từ chối.

**Q25. `AiService.explain` khi nào dùng fallback?**
Khi URL chưa cấu hình, lỗi mạng, timeout 65s, hoặc response không parse được → trả
`AiResult(text: lời giải gốc, fromFallback: true)`.

### F. UI & luồng

**Q26. `QuizHome` giữ những trạng thái gì?**
`language`, `selectedTab`, `topic`, `count`, `_deckRevision`, và 3 Future: `bank`,
`cardsFuture`, `historyFuture`.

**Q27. Vòng lặp `while(true)` trong `_runQuiz` để làm gì?**
Sau khi xem kết quả, nếu người dùng bấm "làm lại câu sai" thì tạo đề mới từ câu sai và
lặp lại; nếu không thì `return` thoát.

**Q28. Đồng hồ thi thử hoạt động thế nào?**
`initState` đặt `deadline` và `Timer.periodic(250ms)`; `_tick` tính thời gian còn lại,
khi ≤ 0 gọi `_submit(expired: true)`.

**Q29. `_submit` trả kết quả về `_runQuiz` bằng cách nào?**
`popUntil` về route của QuizPage rồi `pop(QuizResult(...))` — dùng giá trị pop làm kết
quả, `_runQuiz` nhận qua `await Navigator.push<QuizResult>`.

**Q30. Tại sao `ListView` trong QuizPage có `key: ValueKey(index)`?**
Để khi đổi câu, ListView tạo mới, tránh giữ trạng thái cuộn/cache của câu cũ.

**Q31. Chế độ luyện tập khác thi thử ở chỗ hiển thị gì?**
Luyện tập hiện verdict "Chính xác/Cần xem lại" + lời giải ngay khi chọn; thi thử không
hiện (để không lộ đáp án), chỉ hiện ở trang kết quả.

**Q32. `ValueKey(_deckRevision)` ở FlashcardPage trong tab có tác dụng gì?**
Khi `_deckRevision` tăng (sau khi lưu/xóa thẻ), key đổi → Flutter tạo lại state →
FlashcardPage nạp lại thẻ mới.

**Q33. `embedded` trong FlashcardPage nghĩa là gì?**
Khi `true` (nhúng trong tab 2) không bọc `Scaffold`/AppBar riêng, vì đã nằm trong
Scaffold của QuizHome.

**Q34. `_reviewAttempt` khôi phục kết quả cũ thế nào?**
Từ `attempt.questionIds` tìm lại `Question`, tạo `QuizItem` (dùng `Random(qId)` làm
seed ổn định), tạo `QuizResult` từ `attempt.answers` rồi push `ResultPage`.

---

## 11. Bảng cheat-sheet nhanh

| File | Vai trò | Điểm cần nhớ |
| --- | --- | --- |
| `main.dart` | Entry + 3 màn hình | `_runQuiz` vòng lặp; `_submit` pop kết quả |
| `question.dart` | Model + tạo đề | `decodeQuestions`, `createQuiz`, `Score` |
| `sm2.dart` | SM-2 | EF' công thức; 1→6→round(interval×EF) |
| `weakness_analyzer.dart` | Điểm yếu | `isWeak`, `weaknessScore`, 3 mức ưu tiên |
| `question_search.dart` | OCR/QR search | `normalizeStudyText`, `flutterlab://` |
| `card_storage.dart` | Lưu thẻ | abstract + 2 hiện thực |
| `history_storage.dart` | Lưu lịch sử | max 100, sort mới trước |
| `reminder_service.dart` | Nhắc ôn | `zonedSchedule` + `DateTimeComponents.time` |
| `tts_service.dart` | Đọc | `setSpeechRate(0.5)`, handler lỗi |
| `ai_service.dart` | AI | POST + timeout 65s + fallback |
| `study_image_service.dart` | OCR/QR ảnh | giới hạn 12MB, close trong finally |
| `speech_input_service.dart` | Giọng nói | `cancelOnError: true`, locale en/vi |
| `app_strings.dart` | Nhãn 2 ngôn ngữ | `of()` chọn bộ nhãn |
| `app_theme.dart` | Theme | Material 3, seed 0xff246b52 |
| `question_prompt.dart` | Widget câu + code | monospace, cuộn ngang |
| `error_state.dart` | Widget lỗi | luôn có nút "Thử lại" |

---

*Tài liệu này bám sát mã nguồn hiện tại của `lib/`. Khi trả lời vấn đáp, hãy mở đúng
file để đối chiếu số dòng nếu cần. Chúc bạn thi tốt!*
