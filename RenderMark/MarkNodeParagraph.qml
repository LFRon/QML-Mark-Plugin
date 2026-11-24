pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief Paragraph renderer.
 *
 * A paragraph is one inline text flow. Rendering all inline nodes as one
 * rich-text control is what makes long CJK/English paragraphs wrap correctly.
 */
MarkInlineText {
    id: root
}
