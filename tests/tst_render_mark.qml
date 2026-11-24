import QtQuick
import QtTest
import RenderMark 1.0

TestCase {
    name: "RenderMarkRegression"
    width: 400
    height: 400

    Component {
        id: renderComponent
        RenderMark {
            width: 240
            fitContent: true
        }
    }

    function create(markdown) {
        var item = renderComponent.createObject(this)
        item.markdown = markdown
        wait(80)
        return item
    }

    function collectText(item, out) {
        if (!item || !item.children)
            return
        for (var i = 0; i < item.children.length; ++i) {
            var child = item.children[i]
            if (child.text !== undefined && child.textFormat !== undefined)
                out.push(child.text)
            collectText(child, out)
        }
    }

    function collectAlignment(item, out) {
        if (!item || !item.children)
            return
        for (var i = 0; i < item.children.length; ++i) {
            var child = item.children[i]
            if (child.horizontalAlignment !== undefined)
                out.push(child.horizontalAlignment)
            collectAlignment(child, out)
        }
    }

    function collectFonts(item, out) {
        if (!item || !item.children)
            return
        for (var i = 0; i < item.children.length; ++i) {
            var child = item.children[i]
            if (child.font !== undefined && child.horizontalAlignment !== undefined)
                out.push({ bold: child.font.bold, alignment: child.horizontalAlignment })
            collectFonts(child, out)
        }
    }

    function test_source_file_loads() {
        var item = renderComponent.createObject(this)
        item.source = Qt.resolvedUrl("fixtures/source.md")
        wait(40)
        verify(item.contentHeight > 0)
        verify(item.source !== "")
        item.destroy()
    }

    function test_clearing_markdown_clears_document() {
        var item = create("# visible")
        verify(item.contentHeight > 0)
        item.markdown = ""
        wait(30)
        compare(item.contentHeight, 0)
        verify(item.tree === null)
        item.destroy()
    }

    function test_disabling_parse_delay_flushes_pending_parse() {
        var item = renderComponent.createObject(this)
        item.parseDelay = 100
        item.markdown = "# pending"
        wait(10)
        item.parseDelay = 0
        wait(20)
        verify(item.tree !== null)
        verify(item.contentHeight > 0)
        item.destroy()
    }

    function test_long_paragraph_wraps() {
        var item = create("这是一个很长的中文段落，用来验证自动换行是否正常工作。"
                          + "这是一个很长的中文段落，用来验证自动换行是否正常工作。"
                          + "这是一个很长的中文段落，用来验证自动换行是否正常工作。")
        compare(item.contentWidth, 240)
        verify(item.contentHeight > 30)
        item.destroy()
    }

    function test_table_alignment() {
        var item = create("| left | center | right |\n"
                          + "|:--|:--:|--:|\n"
                          + "| a | b | c |")
        var out = []
        collectAlignment(item, out)
        verify(out.indexOf(Text.AlignHCenter) >= 0)
        verify(out.indexOf(Text.AlignRight) >= 0)
        item.destroy()
    }

    function test_table_header_is_bold() {
        var item = create("| left | right |\n"
                          + "|:--|--:|\n"
                          + "| a | b |")
        var out = []
        collectFonts(item, out)
        verify(out.filter(function(entry) { return entry.bold }).length >= 2)
        item.destroy()
    }

    function test_task_list_rows() {
        var item = create("- [x] done\n- [ ] todo\n- normal")
        verify(item.contentHeight > 30)
        item.destroy()
    }

    function test_ordered_task_list_rows() {
        var item = create("5. [x] done\n6. [ ] todo\n7. normal")
        verify(item.contentHeight > 30)
        item.destroy()
    }

    function test_nested_list_rows() {
        var item = create("- one\n  - nested one\n  - nested two\n- two")
        verify(item.contentHeight > 30)
        item.destroy()
    }

    function test_code_block_width() {
        var item = create("```cpp\nint main() { return 0; }\n```")
        compare(item.contentWidth, 240)
        verify(item.contentHeight > 20)
        item.destroy()
    }

    function test_code_wrap_toggle() {
        var item = create("```cpp\n"
                          + "int main() { return 0; } // a long line that should not need wrapping\n"
                          + "```")
        item.codeWrap = false
        wait(30)
        compare(item.contentWidth, 240)
        item.destroy()
    }

    function test_raw_html_escaped() {
        var item = create("<b>raw</b>")
        var out = []
        collectText(item, out)
        verify(out.join("").indexOf("&lt;b&gt;raw&lt;/b&gt;") >= 0)
        item.destroy()
    }

    function test_javascript_link_is_text() {
        var item = create("[bad](javascript:alert(1))")
        var out = []
        collectText(item, out)
        verify(out.join("").indexOf("javascript:") < 0)
        item.destroy()
    }
}
