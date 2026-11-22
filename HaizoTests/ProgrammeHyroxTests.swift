import XCTest
@testable import Haizo

/// Le programme HYROX : une séance par station, et le travail qui n'est pas une station.
///
/// Ces cas tiennent la COMPOSITION de la semaine (ce qui occupe quel jour de course) et le contenu
/// affiché, sans passer par le moteur. Ce que le moteur en fait — le plafond de deux séances dures,
/// les jours non consécutifs — est éprouvé dans `AdaptivePlanEngineSafetyTests`.
final class ProgrammeHyroxTests: XCTestCase {

    private func stations(_ places: [ProgrammeHyrox.Place]) -> [ProgrammeHyrox.Station] {
        places.compactMap { place in
            if case .station(let s) = place { return s }
            return nil
        }
    }

    private func complements(_ places: [ProgrammeHyrox.Place]) -> [ProgrammeHyrox.TravailComplementaire] {
        places.compactMap { place in
            if case .complement(let c) = place { return c }
            return nil
        }
    }

    // MARK: La rotation des stations

    /// LES HUIT STATIONS EN QUATRE SEMAINES, deux par semaine, chacune une fois.
    func testLesHuitStationsPassentEnQuatreSemaines() {
        var vues: [ProgrammeHyrox.Station] = []
        for semaine in 1...4 {
            let duo = ProgrammeHyrox.duo(semaine: semaine)
            XCTAssertNotEqual(duo.premiere, duo.seconde)
            vues += [duo.premiere, duo.seconde]
        }
        XCTAssertEqual(Set(vues).count, 8, "huit stations différentes sur quatre semaines")
        XCTAssertEqual(vues.count, 8)
    }

    /// L'ORDRE DE LA PAIRE S'INVERSE AU CYCLE SUIVANT : pour les semaines de trois jours, qui ne
    /// portent que la première, toutes les stations passent en huit semaines.
    func testLOrdreDeLaPaireSInverseAChaqueCycle() {
        let premiers = (1...8).map { ProgrammeHyrox.duo(semaine: $0).premiere }
        XCTAssertEqual(Set(premiers).count, 8, "la première station de huit semaines couvre les huit")
        for semaine in 1...4 {
            let avant = ProgrammeHyrox.duo(semaine: semaine)
            let apres = ProgrammeHyrox.duo(semaine: semaine + 4)
            XCTAssertEqual(avant.premiere, apres.seconde)
            XCTAssertEqual(avant.seconde, apres.premiere)
        }
        // Le troisième cycle recommence comme le premier.
        XCTAssertEqual(ProgrammeHyrox.duo(semaine: 9).premiere, ProgrammeHyrox.duo(semaine: 1).premiere)
    }

    func testUneSemaineAberranteNeFaitPasSortirDeLIndex() {
        XCTAssertEqual(ProgrammeHyrox.duo(semaine: 0).premiere, ProgrammeHyrox.duo(semaine: 1).premiere)
        XCTAssertEqual(ProgrammeHyrox.duo(semaine: -5).seconde, ProgrammeHyrox.duo(semaine: 1).seconde)
        XCTAssertEqual(ProgrammeHyrox.TravailComplementaire.pourLaSemaine(0),
                       ProgrammeHyrox.TravailComplementaire.pourLaSemaine(1))
        _ = ProgrammeHyrox.lesAutresSeances(semaine: -2, joursDeCourse: 0)
        _ = ProgrammeHyrox.lesAutresSeances(semaine: 0, joursDeCourse: 9)
    }

    // MARK: La composition de la semaine

    /// La liste fait toujours six éléments : le moteur boucle dessus, et une liste trop courte
    /// répéterait la station, c'est-à-dire une troisième séance dure.
    func testLaListeNeBoucleJamaisSurUneStation() {
        for jours in 1...7 {
            for semaine in 1...12 {
                let places = ProgrammeHyrox.lesAutresSeances(semaine: semaine, joursDeCourse: jours)
                XCTAssertGreaterThanOrEqual(places.count, 6)
                let nombreDeStations = stations(places).count
                XCTAssertLessThanOrEqual(nombreDeStations, 2, "\(jours) jours, S\(semaine)")
                // Une station jamais deux fois dans la semaine.
                XCTAssertEqual(Set(stations(places)).count, nombreDeStations)
            }
        }
    }

    /// Trois jours de course ou moins : une station, puis du footing. Quatre et plus : les deux, avec
    /// une séance entre elles — jamais deux stations adjacentes dans l'ordre de distribution.
    func testLesDeuxStationsNeSontJamaisAdjacentes() {
        for jours in 1...3 {
            let places = ProgrammeHyrox.lesAutresSeances(semaine: 1, joursDeCourse: jours)
            XCTAssertEqual(stations(places).count, 1, "\(jours) jours : une seule station")
        }
        for jours in 4...7 {
            for semaine in 1...8 {
                let places = ProgrammeHyrox.lesAutresSeances(semaine: semaine, joursDeCourse: jours)
                XCTAssertEqual(stations(places).count, 2, "\(jours) jours, S\(semaine)")
                let rangs = places.indices.filter { if case .station = places[$0] { return true } else { return false } }
                XCTAssertEqual(rangs.count, 2)
                XCTAssertGreaterThan(rangs[1] - rangs[0], 1, "\(jours) jours, S\(semaine) : stations adjacentes")
            }
        }
    }

    /// À CINQ JOURS ET PLUS, UN TRAVAIL COMPLÉMENTAIRE CHAQUE SEMAINE, les quatre en quatre semaines.
    func testLeTravailComplementaireTourneChaqueSemaineAuDessusDeQuatreJours() {
        for jours in 5...7 {
            var vus = Set<ProgrammeHyrox.TravailComplementaire>()
            for semaine in 1...4 {
                let c = complements(ProgrammeHyrox.lesAutresSeances(semaine: semaine, joursDeCourse: jours))
                XCTAssertEqual(c.count, 1, "\(jours) jours, S\(semaine)")
                vus.formUnion(c)
            }
            XCTAssertEqual(vus.count, 4, "les quatre travaux en quatre semaines")
        }
    }

    /// À QUATRE JOURS, une semaine sur deux, et un footing l'autre. Les quatre travaux en huit semaines.
    func testAQuatreJoursLeTravailComplementaireUneSemaineSurDeux() {
        var vus = Set<ProgrammeHyrox.TravailComplementaire>()
        for semaine in 1...8 {
            let places = ProgrammeHyrox.lesAutresSeances(semaine: semaine, joursDeCourse: 4)
            let c = complements(places)
            if semaine % 2 == 0 {
                XCTAssertEqual(c.count, 1, "S\(semaine) paire : un travail complémentaire")
                XCTAssertEqual(places[1], .complement(c[0]), "il prend la place entre les deux stations")
            } else {
                XCTAssertTrue(c.isEmpty, "S\(semaine) impaire : un footing")
                XCTAssertEqual(places[1], .footing)
            }
            vus.formUnion(c)
        }
        XCTAssertEqual(vus.count, 4, "les quatre travaux en huit semaines")
    }

    /// Trois jours de course : aucun travail complémentaire, et c'est dit ici plutôt que découvert.
    func testAvecTroisJoursIlNYAPasDeTravailComplementaire() {
        for semaine in 1...8 {
            XCTAssertTrue(complements(ProgrammeHyrox.lesAutresSeances(semaine: semaine, joursDeCourse: 3)).isEmpty)
        }
    }

    // MARK: Le contenu

    /// Chaque station dit ce que le juge valide, et chaque phrase est écrite.
    func testChaqueStationADitCeQueLeJugeValide() {
        for station in ProgrammeHyrox.Station.allCases {
            XCTAssertFalse(station.standard.isEmpty, "\(station)")
            XCTAssertFalse(station.nom.isEmpty, "\(station)")
        }
        let phrases = ProgrammeHyrox.Station.allCases.map(\.standard)
        XCTAssertEqual(Set(phrases).count, 8, "huit standards distincts")
    }

    /// LES CHIFFRES VIVENT DANS LA PRESCRIPTION, PAS DANS LE TEXTE DES GESTES.
    ///
    /// Le nom d'un geste et son intention ne portent aucun nombre : séries, répétitions, distances et
    /// repos sont dans `PrescriptionHyrox`, où le test suivant les borne. Un nombre glissé dans une
    /// phrase échapperait à ces bornes.
    func testLeTexteDesGestesNePorteAucunNombre() {
        for phase in [PhaseHyrox.base, .specifique] {
            for travail in ProgrammeHyrox.TravailComplementaire.allCases {
                XCTAssertFalse(travail.gestes(phase: phase).isEmpty, "\(travail)")
                for geste in travail.gestes(phase: phase) {
                    for texte in [geste.nom, geste.intention] {
                        XCTAssertNil(texte.rangeOfCharacter(from: .decimalDigits),
                                     "« \(texte) » porte un nombre hors de la prescription")
                    }
                }
            }
        }
    }

    /// TOUTE PRESCRIPTION RESTE DANS DES BORNES RAISONNABLES, station et complément, base et spécifique.
    ///
    /// Un volume de départ n'a pas de bonne valeur unique, mais il a des valeurs absurdes : zéro série,
    /// dix minutes de repos, un effort de onze sur dix. Ce cas les écarte, et il échoue si quelqu'un
    /// dérape en éditant le tableau.
    func testLesPrescriptionsRestentDansDesBornes() {
        var toutes: [PrescriptionHyrox] = []
        for phase in [PhaseHyrox.base, .specifique] {
            toutes += ProgrammeHyrox.Station.allCases.map { $0.prescription(phase: phase) }
            toutes += ProgrammeHyrox.TravailComplementaire.allCases.flatMap {
                $0.gestes(phase: phase).map(\.prescription)
            }
        }
        for p in toutes {
            XCTAssertTrue((1...8).contains(p.series), "séries : \(p)")
            XCTAssertTrue((1...1000).contains(p.quantite), "quantité : \(p)")
            XCTAssertTrue((20...240).contains(p.reposSecondes), "repos : \(p)")
            if case .effort(let sur10) = p.intensite {
                XCTAssertTrue((5...9).contains(sur10), "effort : \(p)")
            }
            XCTAssertNil(p.texte.range(of: "%"), "une chaîne non résolue : \(p.texte)")
            XCTAssertNotNil(p.texte.rangeOfCharacter(from: .decimalDigits), p.texte)
        }
    }

    /// LE BLOC SPÉCIFIQUE PRESCRIT LA CHARGE DE COURSE, LE BLOC DE BASE MOINS, pour les stations chargées.
    func testLeBlocDeBaseChargeMoinsQueLeBlocSpecifique() {
        for station in [ProgrammeHyrox.Station.sledPush, .sledPull, .farmersCarry, .fentesSandbag] {
            XCTAssertEqual(station.prescription(phase: .specifique).intensite, .chargeDeCourse, "\(station)")
            XCTAssertNotEqual(station.prescription(phase: .base).intensite, .chargeDeCourse, "\(station)")
            XCTAssertNotEqual(station.prescription(phase: .base).intensite, .aucune, "\(station)")
        }
        // Les stations d'ergomètre se règlent à l'effort : plus haut au bloc spécifique.
        for station in [ProgrammeHyrox.Station.skiErg, .rameur] {
            guard case .effort(let base) = station.prescription(phase: .base).intensite,
                  case .effort(let spe) = station.prescription(phase: .specifique).intensite else {
                return XCTFail("\(station) : un effort sur dix attendu")
            }
            XCTAssertLessThan(base, spe)
        }
    }

    /// La phase voyage avec la séance, et une séance enregistrée avant ce champ se décode encore.
    func testLaPhaseSeDecodeEtUneAncienneSeanceAussi() throws {
        let avec = #"{"title":"Sled push","subtitle":"","durationMinutes":40,"pace":"—","zone":"Z3-4","kind":"hyrox_station_sled_push","phaseHyrox":"specifique"}"#
        let s1 = try JSONDecoder().decode(WorkoutSession.self, from: Data(avec.utf8))
        XCTAssertEqual(s1.phaseHyrox, .specifique)
        XCTAssertEqual(s1.kind, .hyroxStationSledPush)

        let sans = #"{"title":"Sled push","subtitle":"","durationMinutes":40,"pace":"—","zone":"Z3-4"}"#
        XCTAssertNil(try JSONDecoder().decode(WorkoutSession.self, from: Data(sans.utf8)).phaseHyrox)

        // Une phase inconnue (une version future) ne fait pas perdre la séance.
        let future = #"{"title":"X","subtitle":"","durationMinutes":40,"pace":"—","zone":"Z2","phaseHyrox":"autre"}"#
        XCTAssertNil(try JSONDecoder().decode(WorkoutSession.self, from: Data(future.utf8)).phaseHyrox)
    }

    /// Chaque travail complémentaire a son type, retrouvable depuis lui.
    func testChaqueTravailComplementaireAUnTypeDistinct() {
        let types = ProgrammeHyrox.TravailComplementaire.allCases.map(\.kind)
        XCTAssertEqual(Set(types).count, 4)
        for travail in ProgrammeHyrox.TravailComplementaire.allCases {
            XCTAssertEqual(ProgrammeHyrox.TravailComplementaire.pour(travail.kind), travail)
            XCTAssertEqual(travail.kind.family, .functional)
        }
        XCTAssertNil(ProgrammeHyrox.TravailComplementaire.pour(.hyroxBaseFooting))
        XCTAssertNil(ProgrammeHyrox.TravailComplementaire.pour(.hyroxStationSledPush))
    }
}
