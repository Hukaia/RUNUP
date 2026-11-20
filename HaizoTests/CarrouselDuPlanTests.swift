import XCTest
@testable import Haizo

/// Le balayage des cartes de l'écran « Ta semaine ».
///
/// Le défaut qu'ils gardent : la carte ne bougeait qu'à la fin du geste, d'un seul cran, quelle que
/// soit la vitesse, et un geste de quarante points à peine suffisait ou ne suffisait pas sans que
/// rien ne le montre. La décision du cran est une fonction pure — elle se teste ici ; le suivi du
/// doigt, lui, ne se voit que sur l'appareil.
final class CarrouselDuPlanTests: XCTestCase {

    private let pas = HZPlan.pasDuCarrousel

    func testUnGesteLentAuDessusDuSeuilChangeD_UneCarte() {
        // Le doigt va à gauche de 100 points et s'arrête : la course prévue est à peu près la même.
        XCTAssertEqual(HZCarrousel.pas(deplacement: -100, prevu: -110, pasDeCarte: pas), 1)
        XCTAssertEqual(HZCarrousel.pas(deplacement: 100, prevu: 110, pasDeCarte: pas), -1)
    }

    func testUnGesteTropCourtEtTropLentRamèneLaCarte() {
        XCTAssertEqual(HZCarrousel.pas(deplacement: -30, prevu: -35, pasDeCarte: pas), 0)
        XCTAssertEqual(HZCarrousel.pas(deplacement: 0, prevu: 0, pasDeCarte: pas), 0)
    }

    func testUnGesteRapideSauteDeuxCartes() {
        // Un coup de doigt de 120 points dont la course prévue dépasse un pas et demi.
        XCTAssertEqual(HZCarrousel.pas(deplacement: -120, prevu: -pas * 1.7, pasDeCarte: pas), 2)
        XCTAssertEqual(HZCarrousel.pas(deplacement: 120, prevu: pas * 1.7, pasDeCarte: pas), -2)
    }

    func testOnNeSauteJamaisToutLaSemaine() {
        XCTAssertEqual(HZCarrousel.pas(deplacement: -200, prevu: -pas * 6, pasDeCarte: pas),
                       HZCarrousel.sautMaximal)
        XCTAssertEqual(HZCarrousel.pas(deplacement: 200, prevu: pas * 6, pasDeCarte: pas),
                       -HZCarrousel.sautMaximal)
    }

    func testUnGesteRapideMaisCourtChangeUneCarte() {
        // Prévu : un peu plus d'un demi-pas. Arrondi à une carte, pas à zéro.
        XCTAssertEqual(HZCarrousel.pas(deplacement: -60, prevu: -pas * 0.6, pasDeCarte: pas), 1)
    }

    func testUnPasNulOuNegatifNeFaitRien() {
        XCTAssertEqual(HZCarrousel.pas(deplacement: -200, prevu: -400, pasDeCarte: 0), 0)
    }

    func testAuBoutDeLaRangeeLaCarteResiste() {
        XCTAssertEqual(HZCarrousel.decalage(100, auBout: false), 100)
        XCTAssertEqual(HZCarrousel.decalage(100, auBout: true), 100 * HZCarrousel.resistanceAuBout, accuracy: 0.001)
        XCTAssertLessThan(HZCarrousel.resistanceAuBout, 1)
    }

    func testLeDebutDuSuiviEstPlusBasQueLeSeuilDuChangement() {
        // Sans cela, la carte sauterait de quarante points d'un coup à l'instant où le geste commence.
        XCTAssertLessThan(HZCarrousel.seuilDeDebut, HZCarrousel.seuilDeGlissement)
    }
}
