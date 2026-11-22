import XCTest
@testable import Haizo

/// Le lissage du tracé GPS du fil du club : un tracé dentelé devient une courbe, sans bouger ses extrémités
/// et sans sortir de son carré.
final class TraceDuFilTests: XCTestCase {

    private typealias Fil = HZSortieDuFil<EmptyView, EmptyView>

    private let dentele = [CGPoint(x: 0, y: 0), CGPoint(x: 0.2, y: 0.9), CGPoint(x: 0.4, y: 0.1),
                           CGPoint(x: 0.6, y: 0.9), CGPoint(x: 1, y: 1)]

    func testLesExtremitesNeBougentPas() {
        let lisse = Fil.lisser(dentele)
        XCTAssertEqual(lisse.first, dentele.first)
        XCTAssertEqual(lisse.last, dentele.last)
    }

    func testLeTraceGagneDesPointsEtResteDansSonCarre() {
        let lisse = Fil.lisser(dentele)
        XCTAssertGreaterThan(lisse.count, dentele.count)
        XCTAssertTrue(lisse.allSatisfy { (0...1).contains($0.x) && (0...1).contains($0.y) })
    }

    /// Les pointes sont coupées : le point le plus haut du tracé lissé est moins haut que la pointe d'origine.
    func testUnePointeEstAdoucie() {
        let pointe = [CGPoint(x: 0, y: 0), CGPoint(x: 0.5, y: 1), CGPoint(x: 1, y: 0)]
        let hauteur = Fil.lisser(pointe).map(\.y).max() ?? 1
        XCTAssertLessThan(hauteur, 1)
    }

    func testUnTraceTropCourtEstRenduTelQuel() {
        let un = [CGPoint(x: 0.5, y: 0.5)]
        XCTAssertEqual(Fil.lisser(un), un)
        XCTAssertEqual(Fil.lisser([]), [])
    }
}
