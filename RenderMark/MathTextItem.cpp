#include "MathTextItem.h"

#include <QFont>
#include <QFontMetricsF>
#include <QPainter>
#include <QQuickWindow>
#include <QtMath>

#ifdef RENDERMARK_ENABLE_MATH_TEXT
#include "jkqtmathtext/jkqtmathtext.h"
#endif

MathTextItem::MathTextItem(QQuickItem *parent)
    : QQuickPaintedItem(parent)
{
    setAntialiasing(true);
    setFlag(ItemHasContents, true);
}

QString MathTextItem::latex() const
{
    return m_latex;
}

void MathTextItem::setLatex(const QString &latex)
{
    if (m_latex == latex)
        return;
    m_latex = latex;
    emit latexChanged();
    rebuild();
}

int MathTextItem::fontSize() const
{
    return m_fontSize;
}

void MathTextItem::setFontSize(int fontSize)
{
    const int clamped = qBound(6, fontSize, 160);
    if (m_fontSize == clamped)
        return;
    m_fontSize = clamped;
    emit fontSizeChanged();
    rebuild();
}

QColor MathTextItem::color() const
{
    return m_color;
}

void MathTextItem::setColor(const QColor &color)
{
    if (m_color == color)
        return;
    m_color = color;
    emit colorChanged();
    rebuild();
}

int MathTextItem::padding() const
{
    return m_padding;
}

void MathTextItem::setPadding(int padding)
{
    const int clamped = qMax(0, padding);
    if (m_padding == clamped)
        return;
    m_padding = clamped;
    emit paddingChanged();
    rebuild();
}

QString MathTextItem::error() const
{
    return m_error;
}

void MathTextItem::paint(QPainter *painter)
{
    if (m_image.isNull())
        rebuild();

    if (m_image.isNull())
        return;

    painter->save();
    painter->setRenderHint(QPainter::Antialiasing, true);
    painter->setRenderHint(QPainter::TextAntialiasing, true);
    painter->drawImage(QRectF(0, 0, width(), height()), m_image);
    painter->restore();
}

void MathTextItem::itemChange(ItemChange change, const ItemChangeData &data)
{
    QQuickPaintedItem::itemChange(change, data);
    if (change == ItemSceneChange) {
        const qreal dpr = window() ? window()->devicePixelRatio() : 1.0;
        if (!qFuzzyCompare(dpr, m_lastDpr))
            rebuild();
    }
}

void MathTextItem::rebuild()
{
    const qreal dpr = window() ? window()->devicePixelRatio() : 1.0;
    m_lastDpr = dpr;
    m_error.clear();
    m_image = QImage();

    const QString formula = m_latex.trimmed();
    if (formula.isEmpty()) {
        setImplicitSize(0, 0);
        update();
        emit errorChanged();
        return;
    }

#ifdef RENDERMARK_ENABLE_MATH_TEXT
    {
        JKQTMathText math;
        math.setFontSize(m_fontSize);
        math.setFontColor(m_color);

        if (math.parse(formula)) {
            m_image = math.drawIntoImage(false, QColor(Qt::transparent),
                                         m_padding, dpr, 96);
            if (!m_image.isNull()) {
                setImplicitSize(m_image.width() / dpr, m_image.height() / dpr);
                update();
                emit errorChanged();
                return;
            }
            m_error = QStringLiteral("JKQTMathText returned an empty image");
        } else {
            m_error = math.getErrorList().join(QStringLiteral("; "));
            if (m_error.isEmpty())
                m_error = QStringLiteral("JKQTMathText parse failed");
        }
    }
#endif

    rebuildFallback();
    emit errorChanged();
}

void MathTextItem::rebuildFallback()
{
    QFont font;
    font.setPixelSize(m_fontSize);
    font.setStyleHint(QFont::Serif);

    const QFontMetricsF metrics(font);
    const qreal textWidth = metrics.horizontalAdvance(m_latex);
    const qreal textHeight = metrics.height();
    const int padding = m_padding;

    QImage image(qCeil(textWidth) + padding * 2,
                 qCeil(textHeight) + padding * 2,
                 QImage::Format_ARGB32_Premultiplied);
    image.fill(Qt::transparent);

    QPainter painter(&image);
    painter.setRenderHint(QPainter::TextAntialiasing, true);
    painter.setFont(font);
    painter.setPen(m_color);
    painter.drawText(QPointF(padding, padding + metrics.ascent()), m_latex);
    painter.end();

    m_image = image;
    setImplicitSize(image.width(), image.height());
    update();
}
