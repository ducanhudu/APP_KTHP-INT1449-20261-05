#!/usr/bin/env python3
"""Kiểm tra ngân hàng câu hỏi của app Flutter Lab (đề 32).

Chạy: python tool/audit_question_bank.py assets/flutter_quiz_300.json
Không cần thư viện ngoài. Mã thoát 0 nếu mọi kiểm tra đạt, 1 nếu có lỗi.
"""

import json
import re
import sys
import unicodedata
from collections import Counter

TOPICS = {
    1: "Dart căn bản",
    2: "Công cụ và môi trường",
    3: "Widget và vòng đời",
    4: "Bố cục giao diện",
    5: "Material và Cupertino",
    6: "Thiết kế thích ứng",
    7: "Tương tác và biểu mẫu",
    8: "Hình ảnh và tài nguyên",
    9: "Điều hướng",
    10: "Hoạt ảnh",
    11: "Trợ năng",
    12: "Quản lý trạng thái",
    13: "Dữ liệu và bất đồng bộ",
    14: "Kiến trúc ứng dụng",
    15: "Package và plugin",
    16: "Kiểm thử",
    17: "Hiệu năng",
    18: "Flutter đa nền tảng",
    19: "Cấu hình và bảo mật",
    20: "Flutter và AI",
}
LEVELS = {"Nhớ", "Hiểu", "Vận dụng"}
REQUIRED_KEYS = {
    "id",
    "code",
    "topic",
    "level",
    "question_vi",
    "question_en",
    "code_snippet",
    "options",
    "correct_answer",
    "explanation_vi",
    "explanation_en",
    "source_url",
}

problems = []
notes = []


def fail(msg):
    problems.append(msg)


def main(path):
    with open(path, "rb") as fh:
        raw = fh.read()
    print(f"Tệp            : {path}")
    print(f"Kích thước     : {len(raw) / 1024:.1f} KB")

    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError as exc:
        fail(f"Tệp không phải UTF-8 hợp lệ: {exc}")
        return report()
    if text.startswith("\ufeff"):
        notes.append("Tệp có BOM UTF-8 (Flutter đọc được, nhưng nên bỏ).")
        text = text.lstrip("\ufeff")

    try:
        data = json.loads(text)
    except json.JSONDecodeError as exc:
        fail(f"JSON không hợp lệ: {exc}")
        return report()

    if not isinstance(data, list):
        fail(f"Cấp cao nhất phải là mảng, đang là {type(data).__name__}")
        return report()

    total = len(data)
    print(f"Số câu         : {total}")
    if total != 300:
        fail(f"Số câu là {total}, ứng dụng yêu cầu đúng 300 (decodeQuestions).")

    ids, codes = [], []
    topic_count = Counter()
    level_count = Counter()
    answer_count = Counter()
    host_count = Counter()
    with_code = 0
    max_snippet = 0
    exp_len = []
    question_texts = Counter()
    combining = 0
    control = 0

    for index, item in enumerate(data):
        where = f"phần tử #{index + 1} (id={item.get('id', '?')})"
        if not isinstance(item, dict):
            fail(f"{where}: không phải object")
            continue

        missing = REQUIRED_KEYS - item.keys()
        extra = item.keys() - REQUIRED_KEYS
        if missing:
            fail(f"{where}: thiếu trường {sorted(missing)}")
        if extra:
            notes.append(f"{where}: có trường ngoài mô hình {sorted(extra)}")

        qid = item.get("id")
        if not isinstance(qid, int):
            fail(f"{where}: id không phải số nguyên")
        else:
            ids.append(qid)

        code = item.get("code", "")
        if not isinstance(code, str) or not re.fullmatch(r"K\d{2}-\d{3}", code):
            fail(f"{where}: mã câu '{code}' không đúng dạng K##-###")
        else:
            codes.append(code)

        topic = item.get("topic")
        if not isinstance(topic, int) or topic not in TOPICS:
            fail(f"{where}: topic {topic!r} ngoài khoảng 1..20")
        else:
            topic_count[topic] += 1

        level = item.get("level")
        if level not in LEVELS:
            fail(f"{where}: level {level!r} không thuộc {sorted(LEVELS)}")
        else:
            level_count[level] += 1

        for key in ("question_vi", "question_en", "explanation_vi", "explanation_en"):
            value = item.get(key)
            if not isinstance(value, str) or not value.strip():
                fail(f"{where}: {key} rỗng hoặc không phải chuỗi")

        vi = item.get("question_vi") or ""
        en = item.get("question_en") or ""
        if vi and vi == en:
            notes.append(f"{where}: question_vi trùng question_en")
        question_texts[vi] += 1

        snippet = item.get("code_snippet") or ""
        if not isinstance(snippet, str):
            fail(f"{where}: code_snippet không phải chuỗi")
        elif snippet.strip():
            with_code += 1
            max_snippet = max(max_snippet, len(snippet))

        options = item.get("options")
        if not isinstance(options, list) or len(options) != 4:
            fail(f"{where}: phải có đúng 4 lựa chọn, đang có "
                 f"{len(options) if isinstance(options, list) else '?'}")
            options = options if isinstance(options, list) else []
        opt_ids = [o.get("id") for o in options if isinstance(o, dict)]
        if sorted(opt_ids) != ["A", "B", "C", "D"]:
            fail(f"{where}: mã lựa chọn phải là A,B,C,D — đang là {opt_ids}")
        opt_vi = [o.get("vi") for o in options if isinstance(o, dict)]
        if len(set(opt_vi)) != len(opt_vi):
            fail(f"{where}: có hai lựa chọn trùng nội dung tiếng Việt")
        for opt in options:
            if not isinstance(opt, dict):
                fail(f"{where}: lựa chọn không phải object")
                continue
            for key in ("id", "vi", "en"):
                if not isinstance(opt.get(key), str) or not opt.get(key).strip():
                    fail(f"{where}: lựa chọn thiếu '{key}'")

        correct = item.get("correct_answer")
        answer_count[correct] += 1
        if correct not in opt_ids:
            fail(f"{where}: correct_answer {correct!r} không nằm trong {opt_ids}")

        url = item.get("source_url")
        if not isinstance(url, str) or not url.startswith("https://"):
            fail(f"{where}: source_url không phải https")
        else:
            m = re.match(r"https://([^/]+)", url)
            if m:
                host_count[m.group(1)] += 1

        exp = item.get("explanation_vi") or ""
        if isinstance(exp, str) and exp:
            exp_len.append(len(exp))

        for field in ("question_vi", "question_en", "explanation_vi", "explanation_en"):
            value = item.get(field)
            if isinstance(value, str):
                if unicodedata.normalize("NFC", value) != value:
                    combining += 1
                if any(ord(ch) < 32 and ch not in "\n\t" for ch in value):
                    control += 1

    # id liên tục
    if ids:
        if len(set(ids)) != len(ids):
            fail("Có id trùng")
        if sorted(ids) != list(range(1, len(ids) + 1)):
            fail(f"id không liên tục 1..{len(ids)}")
        else:
            print("id             : liên tục 1..%d, không trùng" % len(ids))

    # mã câu
    if codes:
        if len(set(codes)) != len(codes):
            fail("Có mã câu trùng")
        else:
            print(f"mã câu         : {len(codes)} mã duy nhất, đúng dạng K##-###")
        for item in data:
            code, topic = item.get("code"), item.get("topic")
            if isinstance(code, str) and isinstance(topic, int):
                if not code.startswith(f"K{topic:02d}-"):
                    fail(f"id={item.get('id')}: mã {code} lệch khối {topic}")

    # phân bố
    if topic_count:
        print(f"Khối           : {len(topic_count)} khối (K01–K{max(topic_count):02d})")
        missing_topics = sorted(set(TOPICS) - set(topic_count))
        if missing_topics:
            fail(f"Thiếu khối {missing_topics}")
        low = [f"K{t:02d}={n}" for t, n in sorted(topic_count.items()) if n < 10]
        if low:
            notes.append("Khối dưới 10 câu: " + ", ".join(low))
        print("  " + " · ".join(
            f"K{t:02d}={topic_count[t]}" for t in sorted(topic_count)
        ))

    if level_count:
        print("Mức độ         : " + " · ".join(
            f"{k}={level_count[k]}" for k in ("Nhớ", "Hiểu", "Vận dụng")
        ))

    print("Đáp án đúng    : " + " · ".join(
        f"{k}={answer_count[k]}" for k in sorted(answer_count)
    ))
    if answer_count:
        spread = max(answer_count.values()) - min(answer_count.values())
        if spread > 12:
            notes.append(f"Đáp án đúng lệch {spread} giữa các mã — dễ đoán theo vị trí")

    print(f"Có code snippet: {with_code} câu (dài nhất {max_snippet} ký tự)")
    if exp_len:
        print(f"Lời giải tiếng Việt: ngắn nhất {min(exp_len)}, "
              f"trung bình {sum(exp_len) // len(exp_len)}, dài nhất {max(exp_len)} ký tự")

    if host_count:
        print("Nguồn          : " + " · ".join(
            f"{h}={n}" for h, n in host_count.most_common()
        ))

    dupes = {t: n for t, n in question_texts.items() if n > 1 and t}
    if dupes:
        notes.append(f"{len(dupes)} nội dung câu hỏi bị lặp lại (khác mã, khác đoạn mã)")

    if combining:
        notes.append(f"{combining} trường chứa dấu tổ hợp (NFD) — nên chuẩn hoá NFC")
    if control:
        notes.append(f"{control} trường chứa ký tự điều khiển")

    return report()


def report():
    print()
    if notes:
        print("GHI NHẬN:")
        for n in notes:
            print(f"  - {n}")
    if problems:
        print("LỖI:")
        for p in problems:
            print(f"  - {p}")
        print(f"\nKẾT LUẬN: KHÔNG ĐẠT ({len(problems)} lỗi)")
        return 1
    print("\nKẾT LUẬN: ĐẠT — ngân hàng câu hỏi hợp lệ với mô hình của ứng dụng.")
    return 0


if __name__ == "__main__":
    try:  # console Windows mặc định cp1252, cần UTF-8 để in tiếng Việt
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass
    target = sys.argv[1] if len(sys.argv) > 1 else "assets/flutter_quiz_300.json"
    sys.exit(main(target))
