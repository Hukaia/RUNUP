import Foundation

/// Pure geometry for one segment of the "3 daily goals" single ring — shared by the in-app
/// `DailyGoalsBarsView` and the widget extension's `WidgetRingView`, so a tweak to gap size or
/// segment count only ever needs to change in one place.
///
/// LE SEGMENT PORTAIT AUSSI SON ARC EN DEGRÉS, pour le `startAngle`/`endAngle` d'un
/// `AngularGradient`. Les deux anneaux sont passés en aplat le 16 novembre et plus personne ne
/// les lisait : deux champs calculés, un cas de test qui les comparait entre eux, et rien au
/// bout. Ils sont partis avec le dégradé qu'ils servaient.
enum RingSegmentGeometry {
    static let segmentCount = 3
    /// Degrees of empty space between adjacent segments. Round line caps eat into this visually,
    /// so the actual gap reads narrower than this number.
    static let gapDegrees: Double = 14

    struct Segment {
        /// `Circle().trim(from:to:)` fractions (0...1) for this segment's full track — always the
        /// whole segment regardless of progress.
        let trimStart: Double
        let trimEnd: Double
    }

    /// `count` plutôt que `segmentCount` en dur : un jour de repos ne compte que deux objectifs
    /// — aucune séance n'a été demandée — et l'anneau doit alors se partager en deux, pas dessiner
    /// un troisième arc qui ne pourra jamais se remplir sous un titre qui annonce « 0/2 ».
    static func segment(at index: Int, count: Int = segmentCount) -> Segment {
        let spanDegrees = 360.0 / Double(max(1, count))
        let startDeg = Double(index) * spanDegrees
        let endDeg = startDeg + (spanDegrees - gapDegrees)
        return Segment(trimStart: startDeg / 360, trimEnd: endDeg / 360)
    }
}
