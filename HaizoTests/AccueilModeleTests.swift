import XCTest
@testable import Haizo

/// Ce que l'accueil de la refonte AFFICHE, et surtout ce qu'il se refuse à afficher.
///
/// Le canvas montre une séance de fractionné un mardi. L'app a des footings, des sorties longues,
/// des jours de repos, des séances de natation sans allure au kilomètre. Chacun de ces cas
/// décide d'un texte, et un texte faux sur l'entraînement ne plante rien : il s'affiche.
final class AccueilModeleTests: XCTestCase {

    private func seance(_ titre: String = "Footing", minutes: Int = 40, allure: String = "5:30",
                        zone: String = "Z2", intervalles: IntervalStructure? = nil) -> WorkoutSession {
        WorkoutSession(title: titre, subtitle: "", durationMinutes: minutes, pace: allure,
                       zone: zone, intervals: intervalles)
    }

    // MARK: - Durées

    func testUneDureeSousUneHeureSEcritEnMinutes() {
        XCTAssertEqual(AccueilModele.dureeCourte(minutes: 50), "50'")
        XCTAssertEqual(AccueilModele.dureeCourte(minutes: 5), "5'")
    }

    func testUneDureeAuDessusDUneHeureSEcritEnHeuresEtMinutes() {
        XCTAssertEqual(AccueilModele.dureeCourte(minutes: 80), "1h20")
        XCTAssertEqual(AccueilModele.dureeCourte(minutes: 125), "2h05", "les minutes sur deux chiffres")
    }

    func testUneHeurePileGardeSesDeuxZeros() {
        XCTAssertEqual(AccueilModele.dureeCourte(minutes: 60), "1h00")
    }

    // MARK: - Allure

    func testUneAllureSeReconnaitAuxDeuxPoints() {
        XCTAssertEqual(AccueilModele.allureValide("4:22"), "4:22")
        XCTAssertEqual(AccueilModele.allureValide("10:05"), "10:05")
    }

    func testCeQuiNEstPasUneAllureNEnEstPasUne() {
        XCTAssertNil(AccueilModele.allureValide("—"), "natation : pas d'allure au kilomètre")
        XCTAssertNil(AccueilModele.allureValide(""))
        XCTAssertNil(AccueilModele.allureValide("4"))
        XCTAssertNil(AccueilModele.allureValide("4:75"), "75 secondes n'existent pas")
        XCTAssertNil(AccueilModele.allureValide("a:bc"))
    }

    // MARK: - La séance du jour

    func testUnFractionneSAfficheEnRepetitionsFoisDistance() {
        let hero = AccueilModele.hero(
            session: seance("Fractionné léger", minutes: 45, allure: "4:22", zone: "Z3",
                            intervalles: IntervalStructure(reps: 5, repMeters: 500)),
            estUnJourDeRepos: false, faiteAujourdhui: false, titreDeLaCourseLibre: "Libre")
        XCTAssertEqual(hero.prefixe, "5 ×")
        XCTAssertEqual(hero.nombre, .valeur("500"))
        XCTAssertEqual(hero.titre, "Fractionné léger")
        XCTAssertEqual(hero.mesures, [.minutes(45), .allure("4:22"), .zone("Z3")])
        XCTAssertFalse(hero.faite)
    }

    func testUnFootingSAfficheEnDureeSansPrefixe() {
        let hero = AccueilModele.hero(session: seance(), estUnJourDeRepos: false,
                                      faiteAujourdhui: false, titreDeLaCourseLibre: "Libre")
        XCTAssertNil(hero.prefixe)
        XCTAssertEqual(hero.nombre, .valeur("40'"))
    }

    func testUneSortieLongueSAfficheEnHeures() {
        let hero = AccueilModele.hero(session: seance("Sortie longue", minutes: 80),
                                      estUnJourDeRepos: false, faiteAujourdhui: false,
                                      titreDeLaCourseLibre: "Libre")
        XCTAssertEqual(hero.nombre, .valeur("1h20"))
    }

    func testUnJourDeReposNAfficheNiMesureNiPrefixe() {
        let hero = AccueilModele.hero(session: seance("Repos", minutes: 0, allure: "—", zone: ""),
                                      estUnJourDeRepos: true, faiteAujourdhui: false,
                                      titreDeLaCourseLibre: "Libre")
        XCTAssertEqual(hero.nombre, .repos)
        XCTAssertEqual(hero.mesures, [])
        XCTAssertNil(hero.prefixe)
        XCTAssertEqual(hero.titre, "Repos")
    }

    func testUneSeanceSansAllureNEcritPasDAllure() {
        let hero = AccueilModele.hero(session: seance("Natation", minutes: 40, allure: "—", zone: "Z2"),
                                      estUnJourDeRepos: false, faiteAujourdhui: false,
                                      titreDeLaCourseLibre: "Libre")
        XCTAssertEqual(hero.mesures, [.minutes(40), .zone("Z2")],
                       "pas de « — /km » : une séance de nage n'a pas d'allure au kilomètre")
    }

    func testUneZoneVideNEstPasEcrite() {
        let hero = AccueilModele.hero(session: seance(zone: ""), estUnJourDeRepos: false,
                                      faiteAujourdhui: false, titreDeLaCourseLibre: "Libre")
        XCTAssertEqual(hero.mesures, [.minutes(40), .allure("5:30")])
    }

    func testLePlanPrevoyaitDuReposEtOnCourtQuandMeme() {
        let hero = AccueilModele.hero(session: seance("Repos", minutes: 0), estUnJourDeRepos: false,
                                      faiteAujourdhui: true, titreDeLaCourseLibre: "Course libre")
        XCTAssertEqual(hero.nombre, .libre)
        XCTAssertEqual(hero.titre, "Course libre")
        XCTAssertTrue(hero.faite)
    }

    func testUneSeanceFaiteLeDit() {
        let hero = AccueilModele.hero(session: seance(), estUnJourDeRepos: false,
                                      faiteAujourdhui: true, titreDeLaCourseLibre: "Libre")
        XCTAssertTrue(hero.faite)
    }

    // MARK: - La semaine

    private func semaine(faitLundi: Bool = true) -> [PlannedDay] {
        [PlannedDay(weekday: 0, session: seance(minutes: 40), completed: faitLundi),
         PlannedDay(weekday: 1, session: seance(minutes: 45)),
         PlannedDay(weekday: 2, session: nil),
         PlannedDay(weekday: 3, session: seance(minutes: 50)),
         PlannedDay(weekday: 4, session: seance(minutes: 0)),
         PlannedDay(weekday: 5, session: nil),
         PlannedDay(weekday: 6, session: seance(minutes: 80))]
    }

    func testLesSeptJoursPrennentLeursQuatreEtats() {
        XCTAssertEqual(AccueilModele.etatsDeLaSemaine(jours: semaine(), aujourdHui: 1),
                       [.fait, .aujourdhui, .repos, .aVenir, .repos, .repos, .aVenir])
    }

    func testUneSeancePasseeEtNonFaiteNEstPasUnAnneauAVenir() {
        XCTAssertEqual(AccueilModele.etatsDeLaSemaine(jours: semaine(faitLundi: false), aujourdHui: 1).first,
                       .repos, "un anneau dirait « à venir » d'une séance qui ne reviendra pas")
    }

    func testAujourdhuiGardeSonAnneauMemeQuandOnAFait() {
        var jours = semaine()
        jours[1].completed = true
        XCTAssertEqual(AccueilModele.etatsDeLaSemaine(jours: jours, aujourdHui: 1)[1], .aujourdhui)
    }

    func testLesJoursArriventDansLOrdreMemeMelanges() {
        let melange = semaine().reversed().map { $0 }
        XCTAssertEqual(AccueilModele.etatsDeLaSemaine(jours: melange, aujourdHui: 1),
                       AccueilModele.etatsDeLaSemaine(jours: semaine(), aujourdHui: 1))
    }

    // MARK: - La suite

    private let noms = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"]

    func testLaSuiteNeContientQueLesSeancesAVenir() {
        let suite = AccueilModele.prochaines(jours: semaine(), aujourdHui: 1, nomsDesJours: noms)
        XCTAssertEqual(suite.map(\.id), [3, 6], "ni aujourd'hui, ni le repos, ni le passé")
        XCTAssertEqual(suite.map(\.jour), ["Jeudi", "Dimanche"])
        XCTAssertEqual(suite.map(\.duree), ["50'", "1h20"])
    }

    func testUneSeanceDejaFaiteNEstPasALaSuite() {
        var jours = semaine()
        jours[3].completed = true
        XCTAssertEqual(AccueilModele.prochaines(jours: jours, aujourdHui: 1, nomsDesJours: noms).map(\.id), [6])
    }

    func testIlNyAPlusRienALaSuiteLeDimanche() {
        XCTAssertTrue(AccueilModele.prochaines(jours: semaine(), aujourdHui: 6, nomsDesJours: noms).isEmpty)
    }

    func testLesTroisIntensitesDuCanvasEtLeReste() {
        XCTAssertEqual(AccueilModele.intensite(de: .endurance), .facile)
        XCTAssertEqual(AccueilModele.intensite(de: .recovery), .recuperation)
        XCTAssertEqual(AccueilModele.intensite(de: .longRun), .longue)
        for famille in [SessionFamily.tempo, .intervals, .functional, .rest] {
            XCTAssertNil(AccueilModele.intensite(de: famille), "le canvas n'a pas de couleur pour \(famille)")
        }
    }

    // MARK: - Dates et initiales

    func testLaDateDuJourPrendUneCapitaleEtGardeLeReste() {
        let date = DateComponents(calendar: Calendar(identifier: .gregorian), year: 2026, month: 11, day: 17)
            .date!
        XCTAssertEqual(AccueilModele.dateDuJour(date, locale: Locale(identifier: "fr_FR")),
                       "Mardi 17 novembre")
    }

    func testLesInitialesPrennentPrenomEtNom() {
        XCTAssertEqual(AccueilModele.initiales(prenom: "camille", nom: "garnier"), "CG")
        XCTAssertEqual(AccueilModele.initiales(prenom: "Camille", nom: ""), "C")
        XCTAssertEqual(AccueilModele.initiales(prenom: "", nom: ""), "")
    }

    // MARK: - La miniature d'une sortie

    func testUneSortieSansParcoursNAPasDeTrace() {
        XCTAssertNil(HZMiniatureDeSortie.normaliser([]))
        XCTAssertNil(HZMiniatureDeSortie.normaliser([(lat: 48.85, lng: 2.35)]))
        XCTAssertNil(HZMiniatureDeSortie.normaliser([(lat: 48.85, lng: 2.35), (lat: 48.85, lng: 2.35)]),
                     "deux fois le même point n'est pas une forme")
    }

    func testLeTraceTientDansLeCarreUnite() throws {
        let points = (0..<50).map { (lat: 48.85 + Double($0) * 0.0004, lng: 2.35 + sin(Double($0) / 5) * 0.003) }
        let trace = try XCTUnwrap(HZMiniatureDeSortie.normaliser(points))
        XCTAssertTrue(trace.allSatisfy { (0...1).contains($0.x) && (0...1).contains($0.y) })
        XCTAssertEqual(trace.map(\.y).min() ?? 1, 0, accuracy: 0.001, "le trace touche un bord : il est à l'échelle")
    }

    func testLeNordEstEnHaut() throws {
        let trace = try XCTUnwrap(HZMiniatureDeSortie.normaliser([(lat: 48.0, lng: 2.0), (lat: 49.0, lng: 2.0)]))
        XCTAssertLessThan(trace[1].y, trace[0].y, "le point le plus au nord a le plus petit y")
    }

    func testUnLongParcoursEstReduit() throws {
        let points = (0..<5000).map { (lat: 48.85 + Double($0) * 0.00001, lng: 2.35 + Double($0 % 7) * 0.00001) }
        let trace = try XCTUnwrap(HZMiniatureDeSortie.normaliser(points))
        XCTAssertLessThan(trace.count, 200, "une vignette n'a pas besoin de cinq mille points")
        XCTAssertGreaterThan(trace.count, 50)
    }
}
