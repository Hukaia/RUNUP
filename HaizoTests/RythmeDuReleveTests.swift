import XCTest
@testable import Haizo

/// Le rythme d'une sortie s'écrit comme sa discipline l'écrit.
///
/// Le défaut qu'ils gardent : la carte de partage, le tracé agrandi et le résumé écrivaient « /km » à
/// la main sous `avgPace`, quelle que soit la sortie. Une sortie à vélo montrait donc des
/// kilomètres-heure comme des minutes au kilomètre. `avgPace` reste stocké en minutes-secondes au
/// kilomètre ; `RunRecord.rythmeEcrit` en fait ce qu'on lit.
final class RythmeDuReleveTests: XCTestCase {

    private func sortie(_ discipline: Discipline, allure: String = "5:18") -> RunRecord {
        RunRecord(title: "Test", distanceKm: 8, durationSeconds: 2550, avgPace: allure,
                  avgHeartRate: 140, kcal: 400, discipline: discipline)
    }

    func testALaPiedLAllureSEcritAuKilometre() {
        let texte = sortie(.run).rythmeEcrit
        XCTAssertTrue(texte.hasSuffix("/km"), texte)
        XCTAssertTrue(texte.hasPrefix("5:18"), texte)
    }

    func testAVeloLeRythmeEstUneVitesse() {
        let texte = sortie(.bike).rythmeEcrit
        XCTAssertTrue(texte.hasSuffix("km/h"), texte)
        XCTAssertFalse(texte.contains("/km"), "des km/h ne s'écrivent pas « /km » : \(texte)")
        XCTAssertFalse(texte.hasPrefix("5:18"), "la vitesse n'est pas l'allure recopiée : \(texte)")
    }

    func testEnBassinLAllureEstAuxCentMetres() {
        let texte = sortie(.swim).rythmeEcrit
        XCTAssertTrue(texte.hasSuffix("/100 m"), texte)
    }

    func testUneValeurIllisibleSeLitTelleQuelleSansUnite() {
        XCTAssertEqual(sortie(.bike, allure: "—").rythmeEcrit, "—")
        XCTAssertEqual(sortie(.swim, allure: "—").rythmeEcrit, "—")
    }

    func testLeLibelleSuitLaDiscipline() {
        XCTAssertEqual(sortie(.run).rythmeLibelle, Discipline.run.rythmeLabel)
        XCTAssertEqual(sortie(.bike).rythmeLibelle, Discipline.bike.rythmeLabel)
        XCTAssertNotEqual(sortie(.run).rythmeLibelle, sortie(.bike).rythmeLibelle)
    }
}
