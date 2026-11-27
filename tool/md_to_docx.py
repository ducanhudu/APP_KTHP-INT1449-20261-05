# -*- coding: utf-8 -*-
"""Chuyển đổi Markdown -> .docx với cỡ chữ dễ đọc (nhận SRC DST qua tham số)."""
import re
import sys
from docx import Document
from docx.shared import Pt, Cm, RGBColor, Inches
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

SRC = sys.argv[1] if len(sys.argv) > 1 else r"C:\Users\Admin\OneDrive\Documents\app\docs\tai-lieu-van-dap-chi-tiet.md"
DST = sys.argv[2] if len(sys.argv) > 2 else r"C:\Users\Admin\OneDrive\Documents\app\docs\tai-lieu-van-dap-chi-tiet.docx"

# ── Định dạng ──────────────────────────────────────────────────────────────
BODY_FONT = "Calibri"
CODE_FONT = "Consolas"
BODY_SIZE = 13.0          # cỡ chữ thân dễ đọc
CODE_SIZE = 10.5
INLINE_CODE_SIZE = 11.5

C_BODY = "1A1A1A"
C_H1 = "1E5A43"
C_H2 = "246B52"
C_H3 = "1F2937"
C_H4 = "374151"
C_INLINE_CODE = "0B5394"
C_QUOTE = "4B5563"

HEAD_SIZES = {1: 24.0, 2: 18.0, 3: 14.5, 4: 13.0, 5: 12.0, 6: 12.0}
HEAD_COLORS = {1: C_H1, 2: C_H2, 3: C_H3, 4: C_H4, 5: C_H4, 6: C_H4}


def _font(run, name, size, bold=False, italic=False, color=None):
    run.font.name = name
    run.font.size = Pt(size)
    run.font.bold = bold
    run.font.italic = italic
    if color is not None:
        run.font.color.rgb = RGBColor.from_string(color)
    rpr = run._element.get_or_add_rPr()
    rfonts = rpr.get_or_add_rFonts()
    rfonts.set(qn("w:ascii"), name)
    rfonts.set(qn("w:hAnsi"), name)
    rfonts.set(qn("w:eastAsia"), name)
    rfonts.set(qn("w:cs"), name)


INLINE_RE = re.compile(
    r"(\*\*.+?\*\*)|(`[^`]+`)|(\[[^\]]+\]\([^)]*\))|(\*[^*]+?\*)"
)


def add_inline(p, text, size=BODY_SIZE, bold=False, italic=False,
               color=C_BODY, font=BODY_FONT):
    """Thêm runs vào paragraph p, áp dụng bold/italic/inline-code/link."""
    pos = 0
    code_size = max(9.0, size - 1.5)
    for m in INLINE_RE.finditer(text):
        if m.start() > pos:
            r = p.add_run(text[pos:m.start()])
            _font(r, font, size, bold=bold, italic=italic, color=color)
        tok = m.group(0)
        if tok.startswith("**") and tok.endswith("**") and len(tok) >= 4:
            r = p.add_run(tok[2:-2])
            _font(r, font, size, bold=True, italic=italic, color=color)
        elif tok.startswith("`") and tok.endswith("`") and len(tok) >= 2:
            r = p.add_run(tok[1:-1])
            _font(r, CODE_FONT, code_size, bold=bold, italic=italic,
                  color=C_INLINE_CODE)
        elif tok.startswith("[") and tok.endswith(")"):
            lm = re.match(r"\[([^\]]+)\]\(([^)]*)\)", tok)
            label = lm.group(1)
            url = lm.group(2)
            if url.startswith(("http://", "https://")):
                r = p.add_run(label)
                _font(r, font, size, bold=bold, italic=italic, color=color)
                r.font.underline = True
            else:
                r = p.add_run(label)
                _font(r, font, size, bold=bold, italic=italic, color=color)
        elif tok.startswith("*") and tok.endswith("*") and len(tok) >= 2:
            r = p.add_run(tok[1:-1])
            _font(r, font, size, bold=bold, italic=True, color=color)
        pos = m.end()
    if pos < len(text):
        r = p.add_run(text[pos:])
        _font(r, font, size, bold=bold, italic=italic, color=color)


def shade_paragraph(p, fill):
    ppr = p._p.get_or_add_pPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:val"), "clear")
    shd.set(qn("w:color"), "auto")
    shd.set(qn("w:fill"), fill)
    ppr.append(shd)


def shade_cell(cell, fill):
    tcpr = cell._tc.get_or_add_tcPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:val"), "clear")
    shd.set(qn("w:color"), "auto")
    shd.set(qn("w:fill"), fill)
    tcpr.append(shd)


def add_heading(doc, text, level):
    h = doc.add_heading("", level=level)
    pf = h.paragraph_format
    pf.space_before = Pt(18 if level <= 2 else 12)
    pf.space_after = Pt(6 if level <= 2 else 4)
    pf.line_spacing = 1.05
    add_inline(h, text, size=HEAD_SIZES.get(level, 12.0), bold=True,
               color=HEAD_COLORS.get(level, C_H4))


def add_paragraph(doc, text):
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(6)
    p.paragraph_format.line_spacing = 1.15
    add_inline(p, text)


def add_hrule(doc):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(4)
    p.paragraph_format.space_after = Pt(12)
    ppr = p._p.get_or_add_pPr()
    pbdr = OxmlElement("w:pBdr")
    bottom = OxmlElement("w:bottom")
    bottom.set(qn("w:val"), "single")
    bottom.set(qn("w:sz"), "6")
    bottom.set(qn("w:space"), "1")
    bottom.set(qn("w:color"), "C9CFC7")
    pbdr.append(bottom)
    ppr.append(pbdr)


def add_code_block(doc, lines):
    p = doc.add_paragraph()
    shade_paragraph(p, "F4F5F7")
    pf = p.paragraph_format
    pf.space_before = Pt(6)
    pf.space_after = Pt(10)
    pf.line_spacing = 1.0
    pf.left_indent = Pt(10)
    pf.right_indent = Pt(10)
    for i, line in enumerate(lines):
        r = p.add_run(line)
        _font(r, CODE_FONT, CODE_SIZE)
        if i < len(lines) - 1:
            r.add_break()


def add_blockquote(doc, lines):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(4)
    p.paragraph_format.space_after = Pt(8)
    p.paragraph_format.left_indent = Pt(14)
    p.paragraph_format.line_spacing = 1.15
    ppr = p._p.get_or_add_pPr()
    pbdr = OxmlElement("w:pBdr")
    left = OxmlElement("w:left")
    left.set(qn("w:val"), "single")
    left.set(qn("w:sz"), "18")
    left.set(qn("w:space"), "8")
    left.set(qn("w:color"), "246B52")
    pbdr.append(left)
    ppr.append(pbdr)
    add_inline(p, " ".join(lines), color=C_QUOTE, italic=True)


def add_bullet(doc, text, level=0):
    p = doc.add_paragraph()
    pf = p.paragraph_format
    pf.left_indent = Inches(0.25 + 0.35 * level)
    pf.first_line_indent = Inches(-0.18)
    pf.space_after = Pt(2)
    pf.line_spacing = 1.1
    r = p.add_run("•  ")
    _font(r, BODY_FONT, BODY_SIZE, color=C_BODY)
    add_inline(p, text)


def add_ordered(doc, text, level=0):
    p = doc.add_paragraph()
    pf = p.paragraph_format
    pf.left_indent = Inches(0.30 + 0.35 * level)
    pf.first_line_indent = Inches(-0.22)
    pf.space_after = Pt(2)
    pf.line_spacing = 1.1
    add_inline(p, text)


def set_cell(cell, text, bold=False, size=11.0, fill=None):
    cell.text = ""
    p = cell.paragraphs[0]
    pf = p.paragraph_format
    pf.space_before = Pt(2)
    pf.space_after = Pt(2)
    pf.line_spacing = 1.05
    add_inline(p, text, size=size, bold=bold, color=C_BODY)
    if fill:
        shade_cell(cell, fill)


def is_table_separator(line):
    s = line.strip()
    if "|" not in s or "-" not in s:
        return False
    stripped = s.replace("|", "").replace(" ", "").replace(":", "")
    return stripped != "" and set(stripped) == {"-"}


def add_table(doc, lines):
    rows = []
    for line in lines:
        if is_table_separator(line):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        rows.append(cells)
    if not rows:
        return
    ncols = max(len(r) for r in rows)
    table = doc.add_table(rows=0, cols=ncols)
    table.style = "Table Grid"
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = True
    for ri, row in enumerate(rows):
        cells = table.add_row().cells
        for ci in range(ncols):
            txt = row[ci] if ci < len(row) else ""
            if ri == 0:
                set_cell(cells[ci], txt, bold=True, size=11.0, fill="E4EEE5")
            else:
                set_cell(cells[ci], txt, size=11.0)
    # một khoảng trống sau bảng
    spacer = doc.add_paragraph()
    spacer.paragraph_format.space_after = Pt(6)


def classify(line):
    s = line.strip()
    if s == "":
        return "blank"
    if s.startswith("```"):
        return "fence"
    if re.match(r"^#{1,6}\s", line):
        return "heading"
    if re.match(r"^(\s*)[-*]\s+", line):
        return "bullet"
    if re.match(r"^(\s*)\d+\.\s+", line):
        return "ordered"
    if s.startswith(">"):
        return "quote"
    if re.match(r"^\s*(---|\*\*\*|___)\s*$", line):
        return "hr"
    return "text"


def list_marker_indent(line):
    return len(line) - len(line.lstrip(" "))


def build():
    with open(SRC, encoding="utf-8") as f:
        lines = f.read().split("\n")

    doc = Document()
    # Trang A4, lề 2 cm
    sec = doc.sections[0]
    sec.page_width = Cm(21.0)
    sec.page_height = Cm(29.7)
    sec.top_margin = Cm(2.0)
    sec.bottom_margin = Cm(2.0)
    sec.left_margin = Cm(2.0)
    sec.right_margin = Cm(2.0)

    normal = doc.styles["Normal"]
    normal.font.name = BODY_FONT
    normal.font.size = Pt(BODY_SIZE)
    normal.paragraph_format.line_spacing = 1.15
    normal.paragraph_format.space_after = Pt(6)
    rpr = normal.element.get_or_add_rPr()
    rfonts = rpr.get_or_add_rFonts()
    rfonts.set(qn("w:ascii"), BODY_FONT)
    rfonts.set(qn("w:hAnsi"), BODY_FONT)
    rfonts.set(qn("w:eastAsia"), BODY_FONT)
    rfonts.set(qn("w:cs"), BODY_FONT)

    i = 0
    n = len(lines)
    while i < n:
        line = lines[i]
        kind = classify(line)
        s = line.strip()

        if kind == "blank":
            i += 1
            continue

        if kind == "fence":
            buf = []
            i += 1
            while i < n and not lines[i].strip().startswith("```"):
                buf.append(lines[i])
                i += 1
            if i < n:  # bỏ dòng đóng fence
                i += 1
            add_code_block(doc, buf)
            continue

        if kind == "heading":
            m = re.match(r"^(#{1,6})\s+(.*)$", line)
            add_heading(doc, m.group(2).strip(), len(m.group(1)))
            i += 1
            continue

        if kind == "hr":
            add_hrule(doc)
            i += 1
            continue

        if kind == "quote":
            buf = []
            while i < n and lines[i].strip().startswith(">"):
                buf.append(lines[i].strip()[1:].strip())
                i += 1
            add_blockquote(doc, buf)
            continue

        # bảng: dòng bắt đầu '|' và dòng kế tiếp là separator
        if s.startswith("|") and i + 1 < n and is_table_separator(lines[i + 1]):
            tbl = []
            while i < n and lines[i].strip().startswith("|"):
                tbl.append(lines[i].strip())
                i += 1
            add_table(doc, tbl)
            continue

        if kind == "bullet":
            m = re.match(r"^(\s*)[-*]\s+(.*)$", line)
            level = len(m.group(1)) // 2
            text = m.group(2).strip()
            i += 1
            # gom các dòng tiếp nối (thụt vào, không phải block mới)
            while i < n:
                nk = classify(lines[i])
                if nk == "blank":
                    break
                if nk in ("heading", "fence", "hr", "quote"):
                    break
                if nk in ("bullet", "ordered"):
                    if list_marker_indent(lines[i]) <= len(m.group(1)):
                        break
                if nk == "text" and not lines[i].startswith((" ", "\t")):
                    break
                if nk == "text":
                    text += " " + lines[i].strip()
                    i += 1
                    continue
                break
            add_bullet(doc, text, level)
            continue

        if kind == "ordered":
            m = re.match(r"^(\s*)(\d+)\.\s+(.*)$", line)
            level = len(m.group(1)) // 2
            text = m.group(2) + ". " + m.group(3).strip()
            i += 1
            while i < n:
                nk = classify(lines[i])
                if nk == "blank":
                    break
                if nk in ("heading", "fence", "hr", "quote"):
                    break
                if nk in ("bullet", "ordered"):
                    if list_marker_indent(lines[i]) <= len(m.group(1)):
                        break
                if nk == "text" and not lines[i].startswith((" ", "\t")):
                    break
                if nk == "text":
                    text += " " + lines[i].strip()
                    i += 1
                    continue
                break
            add_ordered(doc, text, level)
            continue

        # đoạn văn thường: gom các dòng 'text' liên tiếp
        buf = [s]
        i += 1
        while i < n and classify(lines[i]) == "text":
            buf.append(lines[i].strip())
            i += 1
        add_paragraph(doc, " ".join(buf))

    doc.save(DST)
    print("Đã lưu:", DST)
    print("Số đoạn:", len(doc.paragraphs))
    print("Số bảng:", len(doc.tables))


if __name__ == "__main__":
    build()
