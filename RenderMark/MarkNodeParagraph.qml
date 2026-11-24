pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief Paragraph renderer.
 *
 * A paragraph is normally one inline text flow. When the paragraph contains
 * only an image (the common Markdown image-block form), use the native Image
 * component instead; QML rich text cannot load arbitrary file:// images. Mixed
 * text/image paragraphs keep the inline form and show the image as a link
 * placeholder.
 */
Item {
    id: root

    property var astNode: null
    property var renderMark: null

    readonly property var astStyle: renderMark ? renderMark.style : null
    readonly property var soleImageNode: findSoleImage(root.astNode)

    function init(node, rm) {
        astNode = node
        renderMark = rm
    }

    function findSoleImage(node) {
        if (!node || !node.children)
            return null
        var image = null
        for (var i = 0; i < node.children.length; ++i) {
            var child = node.children[i]
            if (!child)
                continue
            if (child.isImage && child.isImage()) {
                if (image)
                    return null
                image = child
            } else if (child.isText && child.isText()
                       && String(child.content).trim() === "") {
                continue
            } else if (child.isSoftbreak && child.isSoftbreak()) {
                continue
            } else {
                return null
            }
        }
        return image
    }

    width: parent ? parent.width : implicitWidth
    implicitHeight: root.soleImageNode ? imageLoader.height : inlineItem.height
    height: implicitHeight

    MarkInlineText {
        id: inlineItem
        visible: !root.soleImageNode
        width: root.width
        astNode: root.astNode
        renderMark: root.renderMark
    }

    Loader {
        id: imageLoader
        active: !!root.soleImageNode
        width: root.width
        sourceComponent: Component {
            MarkNodeImage {}
        }
        onLoaded: {
            item.astNode = Qt.binding(function() { return root.soleImageNode })
            item.renderMark = Qt.binding(function() { return root.renderMark })
        }
    }
}
