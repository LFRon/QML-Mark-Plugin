# RenderMark regression tests

These are QML TestCase files for the native renderer. They cover the cases
that matter for a chat surface rather than the HTML output of a browser:

- long CJK paragraph wrapping;
- GFM table column alignment;
- GFM task-list rows;
- fenced-code width;
- raw HTML escaping;
- dangerous JavaScript links.

## Run

Build the project first, then point the QML engine at the build tree and the
RenderMark plugin:

```bash
qmltestrunner \
  -input tests/tst_render_mark.qml \
  -import "$PWD/build" \
  -import "$PWD/build/RenderMark"
```

If `RenderMark` and `cmark-gfm` are installed in a non-standard prefix, add the
corresponding `QML2_IMPORT_PATH` / `LD_LIBRARY_PATH` entries, for example:

```bash
QML2_IMPORT_PATH="$PWD/build" \
LD_LIBRARY_PATH="$PWD/build/RenderMark:/path/to/cmark-gfm/lib" \
qmltestrunner -input tests/tst_render_mark.qml
```

The tests use only the public `RenderMark` QML module and do not require a
display (`QT_QPA_PLATFORM=offscreen` works).
