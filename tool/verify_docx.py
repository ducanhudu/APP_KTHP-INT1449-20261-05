# -*- coding: utf-8 -*-
from docx import Document
from docx.shared import Pt

f = r"C:\Users\Admin\OneDrive\Documents\app\docs\tai-lieu-van-dap-chi-tiet.docx"
d = Document(f)
print("paragraphs =", len(d.paragraphs))
print("tables =", len(d.tables))

# in các heading + cỡ chữ
heads = [p.text for p in d.paragraphs if p.style.name.startswith("Heading")]
print("headings =", len(heads))
for h in heads[:8]:
    print("  H:", h[:60])

# kiểm tra cỡ chữ một đoạn thân và một đoạn code
def show(prefix, p):
    if not p.runs:
        return
    r = p.runs[0]
    sz = r.font.size.pt if r.font.size else None
    name = r.font.name
    print(f"{prefix} font={name} size={sz} text={p.text[:50]!r}")

body_paras = [p for p in d.paragraphs if p.style.name == "Normal" and p.text.strip()]
print("normal paras =", len(body_paras))
show("body[0]  ", body_paras[0])
# tìm đoạn code (font Consolas)
code = [p for p in d.paragraphs if p.runs and p.runs[0].font.name == "Consolas"]
print("code paras =", len(code))
if code:
    show("code[0]  ", code[0])
print("OK")
