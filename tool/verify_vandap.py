# -*- coding: utf-8 -*-
"""Kiểm tra nhanh docs/vandap-phan-phuc.docx."""
import sys
from docx import Document

f = (
    sys.argv[1]
    if len(sys.argv) > 1
    else r"C:\Users\Admin\OneDrive\Documents\app\docs\vandap-phan-phuc.docx"
)
d = Document(f)
print("paragraphs =", len(d.paragraphs))
print("tables =", len(d.tables))

heads = [p.text for p in d.paragraphs if p.style.name.startswith("Heading")]
print("headings =", len(heads))
for h in heads:
    print("  H:", h[:70])

full = "\n".join(p.text for p in d.paragraphs)
checks = [
    "Đoàn Vũ Phúc",
    "dòng 277",
    "dòng 415",
    "dòng 51–155",
    "dòng 251–355",
    "dòng 638–642",
    "chỉ done mới gọi",
    "_listenGeneration",
    "_armListenWatchdog",
    "Deploy AI server",
    "api/explain.js",
    "sin1",
    "flutterlab-ai-proxy.onrender.com",
    "Q32",
]
for c in checks:
    print(("OK  " if c in full else "MISS"), c)
print("DONE")
