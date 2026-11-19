import SwiftUI

/// Simple wrapping flow layout for chip groups (iOS 16+ `Layout` protocol).
struct ChipFlowLayout: Layout {
    var spacing: CGFloat = HZEspace.entrePilules
    /// `.leading` partout dans l'inscription : une grille de réponses se lit en colonne, le long
    /// de son bord gauche. `.center` existe pour l'écran « TON PLAN », qui n'est pas une grille
    /// de réponses mais une rangée de pastilles posée sous un titre centré — alignée à gauche,
    /// la dernière rangée y pendait sous le titre au lieu d'en être l'assise.
    var alignment: HorizontalAlignment = .leading

    // `sizeThatFits` and `placeSubviews` must wrap chips onto IDENTICAL rows, or the parent stack
    // reserves the wrong height for whatever this reports and the next sibling overlaps the last
    // row (exactly what happened before this fix: a card's caption text drawn on top of a wrapped
    // "Autre" chip in Profil → Santé & blessures). The old code defaulted an unspecified
    // `proposal.width` to `.infinity` — a correct "ideal size" answer in isolation (everything
    // fits on one row given infinite space), but SwiftUI's own stacks ask this exact question, with
    // this exact nil-width fallback, to size a non-flexible child *before* they've settled on its
    // real width — then reuse that (single-row, too-short) height once the child is actually placed
    // at its real, narrower width. `replacingUnspecifiedDimensions()` leaves a real proposal's width
    // untouched and only swaps in a small, finite placeholder for a genuinely unspecified one, so an
    // ideal-size probe now over-wraps (extra whitespace, never overlap) instead of under-wrapping.
    private func chipFlowLayout(subviews: Subviews, containerWidth: CGFloat) -> (positions: [CGPoint], size: CGSize) {
        var positions: [CGPoint] = []
        var debutDeRangee = 0
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        // Recentrer ne peut se faire qu'une fois la rangée CLOSE : sa largeur n'est connue qu'au
        // moment où la pastille suivante déborde. D'où ce post-traitement par rangée plutôt
        // qu'un calcul au placement — et d'où, en `.leading`, un décalage de zéro : la boucle
        // ci-dessous est exactement celle d'avant, aux deux lignes de `clore` près.
        func clore(_ fin: Int, largeur: CGFloat) {
            guard alignment == .center, largeur < containerWidth else { return }
            let decalage = (containerWidth - largeur) / HZLigne.moitie
            for i in debutDeRangee..<fin { positions[i].x += decalage }
        }
        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > containerWidth, x > 0 {
                // `x` porte l'espacement de la pastille qu'on vient de poser ; la largeur de la
                // rangée s'arrête à son bord droit.
                clore(index, largeur: x - spacing)
                debutDeRangee = index
                x = 0; y += rowHeight + spacing; rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        clore(subviews.count, largeur: max(0, x - spacing))
        return (positions, CGSize(width: containerWidth, height: y + rowHeight))
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        chipFlowLayout(subviews: subviews, containerWidth: proposal.replacingUnspecifiedDimensions().width).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = chipFlowLayout(subviews: subviews, containerWidth: proposal.replacingUnspecifiedDimensions().width)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
}
