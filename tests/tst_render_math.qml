import QtQuick
import QtTest
import RenderMark 1.0

// Run this suite against a build configured with JKQTMATH_TEXT_ROOT.
TestCase {
    name: "MathBlock"
    width: 500
    height: 600

    Component {
        id: renderComponent
        RenderMark {
            width: 420
            fitContent: true
            animate: false
        }
    }

    function findMath(item, out) {
        if (!item || !item.children)
            return
        for (var i = 0; i < item.children.length; ++i) {
            var child = item.children[i]
            if (child.latex !== undefined && child.error !== undefined)
                out.push(child)
            findMath(child, out)
        }
    }

    function render(markdown) {
        var item = renderComponent.createObject(this)
        item.markdown = markdown
        wait(120)
        return item
    }

    function test_display_math_dollar() {
        var item = render("$$\nx=\\frac{-b\\pm\\sqrt{b^2-4ac}}{2a}\n$$")
        var found = []
        findMath(item, found)
        verify(found.length > 0)
        verify(found[0].implicitWidth > 0)
        verify(found[0].implicitHeight > 0)
        verify(found[0].error === "")
        compare(found[0].latex.indexOf("\\frac") >= 0, true)
        item.destroy()
    }

    function test_display_math_bracket() {
        var item = render("\\[\na^2+b^2=c^2\n\\]")
        var found = []
        findMath(item, found)
        verify(found.length > 0)
        verify(found[0].implicitWidth > 0)
        verify(found[0].error === "")
        item.destroy()
    }

    function test_math_preserves_latex_escapes() {
        var item = render("$$\n\\int_0^1 x^2\\,dx\\n$$")
        var found = []
        findMath(item, found)
        verify(found.length > 0)
        verify(found[0].latex.indexOf("\\,") >= 0)
        item.destroy()
    }

    function test_fenced_code_is_not_math() {
        var item = render("```\n$$a**b**$$\n```")
        var found = []
        findMath(item, found)
        compare(found.length, 0)
        item.destroy()
    }

    function test_math_does_not_display_delimiters() {
        var item = render("$$\na+b\n$$")
        var found = []
        findMath(item, found)
        verify(found.length > 0)
        verify(found[0].latex.indexOf("$$") < 0)
        item.destroy()
    }
}
