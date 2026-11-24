# MarkText alignment and known limits

Reference repository: `marktext/marktext`, branch `develop`, revision
`95a14e5` (2026-11-23). The Markdown semantics used by MarkText live in
`packages/muya` and its export path:

- `marked` 18.2.0 for static HTML export;
- CommonMark 0.31.2 and GFM 0.29 spec suites;
- `marked-highlight` + Prism for code highlighting;
- KaTeX for math, Mermaid/PlantUML/Vega for diagrams;
- Muya's own inline/block parser for the live editor.

`RenderMark` uses `cmark-gfm`, so the common block/inline grammar is the same
family. This document records where the two intentionally differ.

## Aligned core behaviour

The following are supported by both and covered by the local QML regression
suite or by the Markdown parser:

- paragraphs, headings, blockquotes, thematic breaks;
- strong, emphasis, strikethrough;
- inline code and fenced code with an info string;
- ordered, unordered and nested lists;
- GFM task lists, including ordered task-list syntax (the list marker is
  hidden for task items, as in MarkText);
- GFM tables with left/center/right column alignment;
- links, reference links, autolinks, images;
- soft breaks (browser-equivalent space) and hard breaks;
- escaping of text content and raw HTML.

## Deliberate differences

| Area | MarkText develop | RenderMark | Reason |
| --- | --- | --- | --- |
| Raw HTML | preserved then sanitized on export | displayed as escaped text | chat surface is not an HTML host |
| Link schemes | sanitized HTML links | only `http`, `https`, `mailto` may be opened | avoid handing dangerous schemes to the desktop |
| Code highlighting | Prism via `marked-highlight` | plain monospace + language tag | no browser/JS dependency; can be added as a native highlighter later |
| Inline math | KaTeX, enabled by default in export | not rendered | deferred by product scope |
| Super/subscript | `^sup^`, `~sub~` extension enabled by default | plain text | deferred; avoids risky text-node rewriting |
| Footnotes | optional extension | basic reference text only | deferred |
| Emoji | `:name:` extension | plain text | deferred |
| Front matter | optional front-matter block | plain Markdown text | deferred |
| GitHub alerts, fancy lists, multiline blockquotes | optional extensions | not parsed specially | deferred |
| Mark/highlight and inline diff | optional extensions | plain text | deferred |
| Images | inline HTML image support | image-only paragraphs use native `Image`; mixed paragraphs use a link placeholder | QML rich text cannot resolve arbitrary file/network image sources |
| Mixed text + image | one inline flow | text flow plus a placeholder link | preserves wrapping and avoids broken rich-text images |

## cmark-gfm limitation: CJK emphasis edges

MarkText added explicit CJK emphasis handling (`#4307`) so cases such as:

```markdown
例子例子**"加粗"**例子例子
日本語**(強調)**日本語
한국어**[강조]**한국어
**来源：**2013年
```

render as emphasis. `cmark-gfm` follows the strict CommonMark flanking rules
and leaves these as literal text because punctuation inside the delimiters is
not flanking-compatible when the outside characters are CJK letters.

Per the project decision, cmark-gfm is **not patched**. This is a known
limitation, not a QML renderer bug. The common CJK forms that do not put
punctuation at the delimiter boundary (for example `中文**加粗**中文`) work
normally.

## Performance options

- `RenderMark.parseDelay` coalesces streaming re-parses (0 = immediate).
- `RenderMark.fitContent: true` plus `interactive: false` lets a chat
  `ListView` own scrolling.
- `RenderMark.animate: false` disables the staggered block fade during
  token streaming.
- `MarkNode.children()` and `plainText()` cache their results; mutation
  invalidates them.
- Images load asynchronously and are bounded to the content column.
- New QML files participate in `qmlcachegen` through `qt_add_qml_module`.

## Out of scope

The following MarkText editor capabilities are not part of this renderer:
WYSIWYG editing, source/state round-trip, Mermaid/PlantUML/Vega diagrams,
KaTeX math, Prism tokenization, footnote collection UIs, and export to
HTML/PDF/DOCX. Those belong to the future UOS-AI-Libre application layer, not
to `RenderMark`.
