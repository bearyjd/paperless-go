# PDF Annotate & Redact — Future Plan

> **Status:** Planning only. This is a complex UI feature requiring a dedicated session.

**Goal:** Let users draw annotations (highlights, freehand, text) and place redaction rectangles on PDF pages, then save the result as a new PDF.

**Architecture approach:**
1. **Page rendering** — Use the `PdfRendererChannel` platform channel (already built) to render pages as images
2. **Canvas overlay** — `CustomPainter` on top of each page image for drawing
3. **Annotation types:** Freehand draw, highlight (semi-transparent rectangle), text note, redaction (opaque black rectangle)
4. **Tool palette** — Bottom toolbar: pen, highlighter, text, redact, eraser, undo/redo
5. **Save** — Composite annotations onto page images → rebuild as PDF via `pdf` package → share or re-upload
6. **Undo/redo stack** — List of annotation operations with push/pop

**Key decisions needed:**
- Annotation persistence (save to Paperless-ngx notes? Local-only?)
- Layer management (annotations as separate layer vs baked into image)
- Touch precision (finger vs stylus detection)
- Performance on large documents (render only visible pages)

**Estimated scope:** 6-10 tasks. Requires brainstorming session and likely a dedicated drawing library evaluation (e.g., `perfect_freehand` for stroke rendering).

**Dependencies:** `PdfRendererChannel` (built), `pdf` package (exists), `image` package (exists). Need to evaluate: `perfect_freehand`, `flutter_painter`, or custom `CustomPainter`.
