import SwiftUI

/// Lays out subviews left-to-right, wrapping whole subviews (never
/// breaking a single subview's own content) onto a new row once the
/// current row runs out of width — the standard "tag cloud" / chip-wrap
/// pattern. Each subview should protect its own internal text from
/// wrapping (`.lineLimit(1)` / `.fixedSize()`), so wrapping only ever
/// happens at the chip boundary, never mid-word.
struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var currentRowWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentRowWidth + size.width > maxWidth {
                totalHeight += rowHeight + spacing
                currentRowWidth = size.width + spacing
                rowHeight = size.height
            } else {
                currentRowWidth += size.width + spacing
                rowHeight = max(rowHeight, size.height)
            }
        }
        totalHeight += rowHeight
        return CGSize(width: maxWidth == .infinity ? currentRowWidth : maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
