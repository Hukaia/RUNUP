import XCTest
@testable import Haizo

/// Ce que « Ta semaine » AFFICHE : sept cartes, une par jour, et ce qu'elles disent d'un jour fait,
/// manqué, à venir, de repos, ou couru alors que le plan prévoyait du repos.
///
/// Le canvas dessine un mardi. L'app a la semaine que la coureuse a vraiment, et un texte faux sur
/// l'entraînement ne plante rien : il s'affiche.
final class PlanSemaineModeleTests: XCTestCase {

    private var calendrier: Calendar {
        var calendrier = Calendar(identifier: .gregorian)
        calendrier.timeZone = TimeZone(identifier: "Europe/Paris") ?? .current
        calendrier.firstWeekday = 1
        return calendrier
    }

    /// Lundi 16 novembre 2026, à minuit.
    private var lundi: Date {
        calendrier.date(from: DateComponents(year: 2026, month: 11, day: 16)) ?? .distantPast
    }

    private func seance(_ titre: String, minutes: Int = 40, allure: String = "5:30", zone: String = "Z2",
                        intervalles: IntervalStructure? = nil) -> WorkoutSession {
        WorkoutSession(title: titre, subtitle: "", durationMinutes: minutes, pace: allure,
                       zone: zone, intervals: intervalles)
    }

    private func semaine(_ seances: [WorkoutSession?], faites: Set<Int> = []) -> [PlannedDay] {
        var jours: [PlannedDay] = []
        for (indice, session) in seances.enumerated() {
            jours.append(PlannedDay(weekday: indice, session: session, completed: faites.contains(indice)))
        }
        return jours
    }

    private func cartes(_ jours: [PlannedDay], aujourdHui: Int) -> [PlanSemaineModele.Jour] {
        PlanSemaineModele.jours(jours, aujourdHui: aujourdHui, lundi: lundi,
                                titreDuRepos: "Jour de repos", calendrier: calendrier)
    }

    // MARK: - Les sept états

    func testUneSemaineDonneSeptCartesDuLundiAuDimanche() {
        let jours = semaine([seance("Footing"), nil, nil, nil, nil, nil, seance("Sortie longue", minutes: 80)])
        let cartes = cartes(jours, aujourdHui: 1)
        XCTAssertEqual(cartes.map(\.id), [0, 1, 2, 3, 4, 5, 6])
    }

    func testChaqueCarteEstDateeDeSonJour() {
        let jours = semaine([seance("Footing"), nil, nil, nil, nil, nil, nil])
        let cartes = cartes(jours, aujourdHui: 0)
        let dimanche = calendrier.date(from: DateComponents(year: 2026, month: 11, day: 22))
        XCTAssertEqual(cartes.first?.date, lundi)
        XCTAssertEqual(cartes.last?.date, dimanche)
    }

    func testLesCartesSontRangeesMemeSiLesJoursArriventDansLeDesordre() {
        var jours = semaine([seance("Footing"), nil, seance("Tempo")])
        jours.reverse()
        XCTAssertEqual(cartes(jours, aujourdHui: 0).map(\.id), [0, 1, 2])
    }

    func testUneSeanceFaiteUnJourPasseSAnnonceFaite() {
        let jours = semaine([seance("Footing"), seance("Footing")], faites: [0])
        XCTAssertEqual(cartes(jours, aujourdHui: 1)[0].etat, .fait)
    }

    func testAujourdHuiPrimeSurLeResteMemeSiLaSeanceEstFaite() {
        let jours = semaine([seance("Footing"), seance("Footing")], faites: [1])
        XCTAssertEqual(cartes(jours, aujourdHui: 1)[1].etat, .aujourdhui)
    }

    func testLaSeanceDuJourFaiteSeDitFaite() {
        let jours = semaine([seance("Footing"), seance("Footing")], faites: [1])
        let carte = cartes(jours, aujourdHui: 1)[1]
        XCTAssertTrue(carte.faite, "la pilule dira « Fait », pas « Aujourd'hui »")
        XCTAssertFalse(cartes(jours, aujourdHui: 1)[0].faite)
    }

    func testUneSeanceAVenirSAnnonceAVenir() {
        let jours = semaine([seance("Footing"), seance("Footing"), seance("Footing")])
        XCTAssertEqual(cartes(jours, aujourdHui: 0)[2].etat, .aVenir)
    }

    func testUneSeancePasseeEtNonFaiteNEstNiAVenirNiFaite() {
        let jours = semaine([seance("Footing"), seance("Footing")])
        XCTAssertEqual(cartes(jours, aujourdHui: 1)[0].etat, .nonFait,
                       "écrire « À venir » sur un jour passé serait faux")
    }

    func testUnJourSansSeanceEstUnRepos() {
        let jours = semaine([seance("Footing"), nil])
        let carte = cartes(jours, aujourdHui: 0)[1]
        XCTAssertEqual(carte.etat, .repos)
        XCTAssertTrue(carte.estUnRepos)
        XCTAssertEqual(carte.nombre, .repos)
        XCTAssertEqual(carte.titre, "Jour de repos")
        XCTAssertTrue(carte.mesures.isEmpty, "pas de mesure inventée sur un repos")
    }

    func testUneSeanceDeDureeNulleEstUnRepos() {
        let jours = semaine([seance("Repos", minutes: 0), seance("Footing")])
        XCTAssertTrue(cartes(jours, aujourdHui: 1)[0].estUnRepos)
    }

    func testAujourdHuiEnReposRestePourtantAujourdHui() {
        let jours = semaine([nil, seance("Footing")])
        let carte = cartes(jours, aujourdHui: 0)[0]
        XCTAssertEqual(carte.etat, .aujourdhui)
        XCTAssertEqual(carte.nombre, .repos)
    }

    // MARK: - Ce qu'une carte dit de sa séance

    func testUnFractionneSAnnonceEnRepetitionsFoisDistance() {
        let fractionne = seance("Fractionné léger", minutes: 45, allure: "4:22", zone: "Z3",
                                intervalles: IntervalStructure(reps: 5, repMeters: 500))
        let carte = cartes(semaine([fractionne]), aujourdHui: 0)[0]
        XCTAssertEqual(carte.prefixe, "5 ×")
        XCTAssertEqual(carte.nombre, .valeur("500"))
        XCTAssertEqual(carte.mesures, [.minutes(45), .allure("4:22"), .zone("Z3")])
    }

    func testUnFootingSAnnonceEnDuree() {
        let carte = cartes(semaine([seance("Footing", minutes: 50)]), aujourdHui: 0)[0]
        XCTAssertNil(carte.prefixe)
        XCTAssertEqual(carte.nombre, .valeur("50'"))
    }

    func testUneSeanceSansAllureGardeSesAutresMesures() {
        let carte = cartes(semaine([seance("Natation", minutes: 40, allure: "—", zone: "Z2")]),
                           aujourdHui: 0)[0]
        XCTAssertEqual(carte.mesures, [.minutes(40), .zone("Z2")],
                       "« — par km » serait écrire quelque chose de faux")
    }

    // MARK: - Compter

    func testUnReposNEstPasUneSeance() {
        let jours = semaine([seance("Footing"), nil, seance("Repos", minutes: 0), seance("Tempo")])
        XCTAssertEqual(PlanSemaineModele.nombreDeSeances(jours), 2)
    }

    func testUneSemaineVideCompteZeroSeance() {
        XCTAssertEqual(PlanSemaineModele.nombreDeSeances([]), 0)
    }

    // MARK: - Les dates

    func testLeLundiDUnMercrediEstLeLundiPrecedent() {
        let mercredi = calendrier.date(from: DateComponents(year: 2026, month: 11, day: 18, hour: 15)) ?? .distantPast
        XCTAssertEqual(PlanSemaineModele.lundi(de: mercredi, calendrier: calendrier), lundi)
    }

    func testLeLundiDUnDimancheEstSixJoursAvant() {
        let dimanche = calendrier.date(from: DateComponents(year: 2026, month: 11, day: 22, hour: 23)) ?? .distantPast
        XCTAssertEqual(PlanSemaineModele.lundi(de: dimanche, calendrier: calendrier), lundi,
                       "le dimanche ferme la semaine, il n'ouvre pas la suivante")
    }

    func testLeLundiEstSonPropreLundi() {
        XCTAssertEqual(PlanSemaineModele.lundi(de: lundi, calendrier: calendrier), lundi)
    }

    func testLIndiceDuJourCommenceAuLundi() {
        XCTAssertEqual(PlanSemaineModele.indiceDuJour(lundi, calendrier: calendrier), 0)
        let dimanche = calendrier.date(from: DateComponents(year: 2026, month: 11, day: 22)) ?? .distantPast
        XCTAssertEqual(PlanSemaineModele.indiceDuJour(dimanche, calendrier: calendrier), 6)
    }

    func testLInitialeDuLundiEstCelleDuLundi() {
        var fr = calendrier
        fr.locale = Locale(identifier: "fr_FR")
        XCTAssertEqual(PlanSemaineModele.initiale(duJour: 0, calendrier: fr), "L")
        XCTAssertEqual(PlanSemaineModele.initiale(duJour: 6, calendrier: fr), "D")
    }

    func testUnIndiceHorsSemaineNeDonneRien() {
        XCTAssertNotNil(PlanSemaineModele.initiale(duJour: 40, calendrier: calendrier))
    }

    func testUneSemaineDansLeMemeMoisNaQuUnMois() {
        let periode = PlanSemaineModele.periode(lundi: lundi, calendrier: calendrier,
                                                locale: Locale(identifier: "fr_FR"))
        XCTAssertEqual(periode.premierJour, 16)
        XCTAssertEqual(periode.dernierJour, 22)
        XCTAssertEqual(periode.moisDuPremier, "novembre")
        XCTAssertFalse(periode.surDeuxMois)
    }

    func testUneSemaineACheval() {
        let lundiDe30 = calendrier.date(from: DateComponents(year: 2026, month: 11, day: 30)) ?? .distantPast
        let periode = PlanSemaineModele.periode(lundi: lundiDe30, calendrier: calendrier,
                                                locale: Locale(identifier: "fr_FR"))
        XCTAssertEqual(periode.premierJour, 30)
        XCTAssertEqual(periode.dernierJour, 6)
        XCTAssertEqual(periode.moisDuPremier, "novembre")
        XCTAssertEqual(periode.moisDuDernier, "décembre")
        XCTAssertTrue(periode.surDeuxMois)
    }

    // MARK: - La course libre

    /// En course libre la semaine du plan n'existe pas : une seule carte, la séance proposée
    /// aujourd'hui, jamais un repos issu de l'ancien programme.
    func testEnCourseLibreUneSeuleCarteAvecLaSeanceDuJour() {
        let cartes = PlanSemaineModele.joursEnCourseLibre(
            seance: seance("Footing récap", minutes: 30, zone: "Z1-2"), faite: false, aujourdHui: 5,
            lundi: lundi, titreDuRepos: "Jour de repos", calendrier: calendrier)
        XCTAssertEqual(cartes.count, 1)
        XCTAssertEqual(cartes.first?.id, 5)
        XCTAssertEqual(cartes.first?.etat, .aujourdhui)
        XCTAssertFalse(cartes.first?.estUnRepos ?? true)
        XCTAssertEqual(cartes.first?.nombre, .valeur("30'"))
    }

    func testEnCourseLibreLaSeanceFaiteSeDitFaite() {
        let cartes = PlanSemaineModele.joursEnCourseLibre(
            seance: seance("Footing récap", minutes: 30), faite: true, aujourdHui: 2,
            lundi: lundi, titreDuRepos: "Jour de repos", calendrier: calendrier)
        XCTAssertEqual(cartes.first?.faite, true)
    }
}
