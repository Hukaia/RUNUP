import XCTest
@testable import Haizo

/// Le programme HYROX : le fractionné, la séance de station, la course compromise, et le travail qui
/// n'est pas une station.
///
/// Ces cas tiennent la COMPOSITION de la semaine (ce qui occupe quel jour de course) et le contenu
/// affiché, sans passer par le moteur. Ce que le moteur en fait — le plafond de deux séances dures,
/// les jours non consécutifs — est éprouvé dans `AdaptivePlanEngineSafetyTests`.
final class ProgrammeHyroxTests: XCTestCase {

    /// Les semaines de TRAVAIL d'un plan : sans les décharges (4, 8, 12…), qui ne portent aucune station.
    private static let travail: [Int] = (1...40).filter { $0 % 4 != 0 }

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

    /// LES DÉCHARGES NE COMPTENT PAS DANS LA ROTATION.
    ///
    /// Le moteur pose une décharge toutes les quatre semaines. Indexée sur le numéro brut de la
    /// semaine, la rotation faisait tomber une famille sur chaque décharge — les ergomètres n'étaient
    /// jamais travaillés. Ce cas tient que les semaines de travail se suivent sans trou.
    func testLaRotationIgnoreLesDecharges() {
        XCTAssertEqual(Self.travail.prefix(8).map(ProgrammeHyrox.semaineDeTravail), Array(1...8))
        XCTAssertEqual(ProgrammeHyrox.semaineDeTravail(4), ProgrammeHyrox.semaineDeTravail(3),
                       "une décharge ne consomme pas de rang")
    }

    /// CHAQUE STATION A SA SÉANCE, une par semaine de travail : les huit en huit semaines, puis on recommence.
    func testChaqueStationASaSeanceEnHuitSemainesDeTravail() {
        XCTAssertEqual(Set(ProgrammeHyrox.ordreDesStations), Set(ProgrammeHyrox.Station.allCases))
        XCTAssertEqual(ProgrammeHyrox.ordreDesStations.count, 8, "aucune station deux fois dans l'ordre")
        let huit = Self.travail.prefix(8).map(ProgrammeHyrox.stationDeLaSemaine)
        XCTAssertEqual(Set(huit).count, 8, "huit stations différentes sur huit semaines de travail")
        XCTAssertEqual(ProgrammeHyrox.stationDeLaSemaine(Self.travail[8]), huit[0], "le cycle recommence")
        // Les wall balls d'abord : la station la plus coûteuse de l'épreuve (Brandt 2025).
        XCTAssertEqual(huit[0], .wallBalls)
        // Une décharge ne consomme pas de station : la semaine d'après reprend la suivante.
        XCTAssertEqual(ProgrammeHyrox.stationDeLaSemaine(5), ProgrammeHyrox.ordreDesStations[3])
    }

    func testUneSemaineAberranteNeFaitPasSortirDeLIndex() {
        XCTAssertEqual(ProgrammeHyrox.stationDeLaSemaine(0), ProgrammeHyrox.stationDeLaSemaine(1))
        XCTAssertEqual(ProgrammeHyrox.stationDeLaSemaine(-5), ProgrammeHyrox.stationDeLaSemaine(1))
        XCTAssertEqual(ProgrammeHyrox.TravailComplementaire.pourLaSemaine(0),
                       ProgrammeHyrox.TravailComplementaire.pourLaSemaine(1))
        _ = ProgrammeHyrox.lesAutresSeances(semaine: -2, joursDeCourse: 0)
        _ = ProgrammeHyrox.lesAutresSeances(semaine: 0, joursDeCourse: 9)
        _ = ProgrammeHyrox.courseCompromise(phase: .base, palier: -3)
        _ = ProgrammeHyrox.courseCompromise(phase: .specifique, palier: 400)
        _ = ProgrammeHyrox.Station.wallBalls.format(phase: .base, palier: -1)
    }

    // MARK: La composition de la semaine

    private func rangsDeQualite(_ places: [ProgrammeHyrox.Place]) -> [Int] {
        places.indices.filter {
            switch places[$0] {
            case .station, .intervalles: return true
            case .footing, .complement: return false
            }
        }
    }

    /// DEUX SÉANCES DE QUALITÉ, NI PLUS NI MOINS : un fractionné et une station. La liste fait toujours
    /// six éléments : le moteur boucle dessus, et une liste trop courte répéterait une séance dure.
    func testUnFractionneEtUneStationChaqueSemaine() {
        for jours in 1...7 {
            for semaine in 1...12 {
                let places = ProgrammeHyrox.lesAutresSeances(semaine: semaine, joursDeCourse: jours)
                XCTAssertGreaterThanOrEqual(places.count, 6)
                XCTAssertEqual(stations(places).count, 1, "\(jours) jours, S\(semaine)")
                XCTAssertEqual(places.filter { $0 == .intervalles }.count, 1, "\(jours) jours, S\(semaine)")
                XCTAssertEqual(stations(places), [ProgrammeHyrox.stationDeLaSemaine(semaine)])
            }
        }
    }

    /// DÈS QUATRE JOURS, UN FOOTING SÉPARE LES DEUX SÉANCES DE QUALITÉ : jamais deux jours durs de suite.
    func testLesDeuxSeancesDeQualiteNeSontJamaisAdjacentesDesQuatreJours() {
        for jours in 4...7 {
            for semaine in Self.travail.prefix(8) {
                let places = ProgrammeHyrox.lesAutresSeances(semaine: semaine, joursDeCourse: jours)
                let rangs = rangsDeQualite(places)
                XCTAssertEqual(rangs.count, 2)
                XCTAssertGreaterThan(rangs[1] - rangs[0], 1, "\(jours) jours, S\(semaine)")
                XCTAssertEqual(places[1], .footing, "le volume d'endurance d'abord")
            }
        }
    }

    /// L'ORDRE S'INVERSE UNE SEMAINE DE TRAVAIL SUR DEUX : quand le moteur ne garde qu'une séance de
    /// qualité (deux autres sports qui pèsent sur les jambes), ce n'est pas toujours la même.
    func testLOrdreDesDeuxSeancesDeQualiteSInverseUneSemaineSurDeux() {
        for jours in [3, 4, 5] {
            let premieres = Self.travail.prefix(6).map {
                ProgrammeHyrox.lesAutresSeances(semaine: $0, joursDeCourse: jours)[0]
            }
            for i in premieres.indices {
                XCTAssertEqual(premieres[i] == .intervalles, i % 2 == 0, "\(jours) jours, rang \(i)")
            }
        }
    }

    /// À CINQ JOURS ET PLUS, UN TRAVAIL COMPLÉMENTAIRE CHAQUE SEMAINE, les quatre en quatre semaines.
    func testLeTravailComplementaireTourneChaqueSemaineAuDessusDeQuatreJours() {
        for jours in 5...7 {
            var vus = Set<ProgrammeHyrox.TravailComplementaire>()
            for semaine in Self.travail.prefix(4) {
                let c = complements(ProgrammeHyrox.lesAutresSeances(semaine: semaine, joursDeCourse: jours))
                XCTAssertEqual(c.count, 1, "\(jours) jours, S\(semaine)")
                vus.formUnion(c)
            }
            XCTAssertEqual(vus.count, 4, "les quatre travaux en quatre semaines")
        }
    }

    /// Quatre jours ou moins : aucun travail complémentaire. La place va à la course, parce que c'est
    /// le volume d'endurance qui prédit le temps final, et c'est dit ici plutôt que découvert.
    func testJusquAQuatreJoursIlNYAPasDeTravailComplementaire() {
        for jours in 1...4 {
            for semaine in 1...8 {
                XCTAssertTrue(complements(ProgrammeHyrox.lesAutresSeances(semaine: semaine, joursDeCourse: jours)).isEmpty)
            }
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
    func testLesPrescriptionsDesComplementsRestentDansDesBornes() {
        var toutes: [PrescriptionHyrox] = []
        for phase in [PhaseHyrox.base, .specifique] {
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

    private static let phases: [PhaseHyrox] = [.base, .specifique, .affutage, .decharge]

    /// UNE SÉANCE DE STATION EST DES TOURS DE « COURSE, PUIS LA STATION » — JAMAIS LA STATION SEULE.
    ///
    /// La première version posait « 6 × 50 m de sled » sans une foulée, et Charlotte l'a refusée : l'épreuve
    /// enchaîne huit fois un kilomètre et une station. Chaque séance de station, à chaque phase et à chaque
    /// palier, a donc de la course, des tours, un repos, et une DURÉE écrite d'après son contenu.
    func testChaqueSeanceDeStationCourtEtDureCeQuElleContient() {
        for phase in Self.phases {
            for palier in 0...6 {
                for station in ProgrammeHyrox.Station.allCases {
                    let f = station.format(phase: phase, palier: palier)
                    let ou = "\(station) \(phase) palier \(palier)"
                    XCTAssertTrue((2...6).contains(f.tours), "\(ou) : \(f.tours) tours")
                    XCTAssertTrue((400...1000).contains(f.courseM), "\(ou) : \(f.courseM) m de course")
                    XCTAssertGreaterThan(f.quantite, 0, ou)
                    XCTAssertTrue((30...120).contains(f.reposSecondes), "\(ou) : repos")
                    XCTAssertTrue((25...60).contains(f.dureeMinutes), "\(ou) : \(f.dureeMinutes) min")
                    XCTAssertEqual(f.dureeMinutes % 5, 0, "la durée est un multiple de cinq minutes")
                    XCTAssertNil(f.texte.range(of: "%"), "une chaîne non résolue : \(f.texte)")
                    XCTAssertNotNil(f.texte.rangeOfCharacter(from: .decimalDigits), f.texte)
                    XCTAssertNil(f.texte.range(of: "1 allers"), "un seul aller s'écrit au singulier")
                }
            }
        }
    }

    /// LES PARTS DE L'ÉPREUVE TOMBENT JUSTE : un quart, la moitié, les trois quarts de chaque station
    /// sont des nombres entiers, sans arrondi caché.
    func testLesPartsDeChaqueStationTombentJuste() {
        for station in ProgrammeHyrox.Station.allCases {
            for part in PartDeStation.allCases {
                XCTAssertEqual(station.quantite(part) * 4, station.deLEpreuve.quantite * part.rawValue,
                               "\(station) \(part)")
                XCTAssertNil(station.texte(part).range(of: "%"))
            }
            XCTAssertEqual(station.quantite(.entiere), station.deLEpreuve.quantite)
        }
        XCTAssertEqual(ProgrammeHyrox.Station.sledPush.quantite(.quart), 1)
        XCTAssertEqual(ProgrammeHyrox.Station.wallBalls.quantite(.troisQuarts), 75)
        XCTAssertEqual(ProgrammeHyrox.Station.skiErg.quantite(.moitie), 500)
    }

    /// LE PLAFOND : une séance de station ne demande jamais plus d'une fois et demie le volume de
    /// l'épreuve, ni moins de la moitié. Deux cent vingt-cinq wall balls en une séance, c'était le
    /// défaut de la version précédente.
    func testUneSeanceDeStationNeDepasseJamaisUneFoisEtDemieLEpreuve() {
        for phase in Self.phases {
            for palier in 0...8 {
                for station in ProgrammeHyrox.Station.allCases {
                    let f = station.format(phase: phase, palier: palier)
                    let volume = f.tours * f.quantite
                    let epreuve = station.deLEpreuve.quantite
                    // Les sleds vont jusqu'à trois fois l'épreuve : la station ne dure que deux minutes.
                    let estUnSled = station == .sledPush || station == .sledPull
                    XCTAssertLessThanOrEqual(volume * 2, epreuve * (estUnSled ? 6 : 3),
                                             "\(station) \(phase) palier \(palier) : \(volume)")
                    XCTAssertGreaterThanOrEqual(volume * 2, epreuve, "\(station) \(phase) palier \(palier) : \(volume)")
                }
            }
        }
    }

    /// UNE SÉANCE DE SLED N'EST JAMAIS UN SEUL ALLER PAR TOUR. Les parts de l'épreuve donnaient trois
    /// allers dans toute la séance du premier palier ; les sleds ont leurs propres paliers.
    func testUneSeanceDeSledFaitAssezDeSled() {
        for station in [ProgrammeHyrox.Station.sledPush, .sledPull] {
            let base = (0...4).map { palier -> Int in
                let f = station.format(phase: .base, palier: palier)
                return f.tours * f.quantite
            }
            XCTAssertEqual(base, [6, 8, 10, 12, 12], "\(station)")
            let specifique = (0...3).map { palier -> Int in
                let f = station.format(phase: .specifique, palier: palier)
                return f.tours * f.quantite
            }
            XCTAssertEqual(specifique, [8, 12, 12, 12], "\(station)")
            for phase in Self.phases {
                for palier in 0...6 {
                    let f = station.format(phase: phase, palier: palier)
                    XCTAssertGreaterThanOrEqual(f.quantite, 2, "\(station) \(phase) palier \(palier)")
                    XCTAssertLessThanOrEqual(f.quantite, station.deLEpreuve.quantite)
                }
            }
        }
    }

    /// LE VOLUME MONTE D'UN PALIER À L'AUTRE, sans jamais redescendre à l'intérieur d'un bloc.
    func testLeVolumeDUneStationMonteAuFilDuBloc() {
        for phase in [PhaseHyrox.base, .specifique] {
            for station in ProgrammeHyrox.Station.allCases {
                let volumes = (0...5).map { palier -> Int in
                    let f = station.format(phase: phase, palier: palier)
                    return f.tours * f.quantite
                }
                XCTAssertEqual(volumes, volumes.sorted(), "\(station) \(phase) : \(volumes)")
                XCTAssertGreaterThan(volumes[5], volumes[0], "\(station) \(phase) : le bloc progresse")
            }
        }
    }

    /// LE BLOC DE BASE EST FACILE ET ALLÉGÉ ; LE SPÉCIFIQUE EST À L'ALLURE ET À LA CHARGE DE L'ÉPREUVE.
    func testLeBlocDeBaseEstPlusLegerQueLeBlocSpecifique() {
        for station in ProgrammeHyrox.Station.allCases {
            let base = station.format(phase: .base)
            let spe = station.format(phase: .specifique)
            XCTAssertEqual(base.allure, .facile)
            XCTAssertEqual(spe.allure, .epreuve)
            XCTAssertLessThan(base.courseM, spe.courseM)
            XCTAssertLessThan(base.quantite, spe.quantite, "\(station) : une plus grande part par tour au spécifique")
        }
        for station in ProgrammeHyrox.Station.allCases where station.estLestee {
            XCTAssertEqual(station.format(phase: .specifique).intensite, .chargeDeCourse, "\(station)")
            XCTAssertEqual(station.format(phase: .affutage).intensite, .chargeDeCourse, "\(station)")
            XCTAssertEqual(station.format(phase: .base).intensite, .deuxTiers, "\(station)")
            XCTAssertEqual(station.format(phase: .decharge).intensite, .deuxTiers, "\(station)")
        }
        XCTAssertEqual(ProgrammeHyrox.Station.allCases.filter(\.estLestee).count, 4)
        // Les ergomètres se règlent à l'effort : plus haut au bloc spécifique.
        for station in [ProgrammeHyrox.Station.skiErg, .rameur] {
            guard case .effort(let base) = station.format(phase: .base).intensite,
                  case .effort(let spe) = station.format(phase: .specifique).intensite else {
                return XCTFail("\(station) : un effort sur dix attendu")
            }
            XCTAssertLessThan(base, spe)
        }
    }

    // MARK: La course compromise

    /// ELLE GRANDIT : trois, quatre puis cinq tours au bloc de base, cinq puis six au spécifique, et les
    /// huit de l'épreuve à la simulation seulement.
    func testLaCourseCompromiseGrandit() {
        XCTAssertEqual((0...4).map { ProgrammeHyrox.courseCompromise(phase: .base, palier: $0).tours }, [3, 4, 5, 5, 5])
        XCTAssertEqual((0...3).map { ProgrammeHyrox.courseCompromise(phase: .specifique, palier: $0).tours }, [5, 6, 6, 6])
        XCTAssertEqual((0...2).map { ProgrammeHyrox.courseCompromise(phase: .affutage, palier: $0).tours }, [3, 2, 2])
        XCTAssertEqual(ProgrammeHyrox.courseCompromise(phase: .decharge, palier: 0).tours, 2)
        let simulation = ProgrammeHyrox.courseCompromise(phase: .specifique, palier: 2, simulation: true)
        XCTAssertEqual(simulation.stations, ProgrammeHyrox.Station.allCases)
        XCTAssertEqual(simulation.part, .entiere)
        XCTAssertTrue(simulation.estLaSimulation)
        for phase in Self.phases {
            for palier in 0...10 {
                XCTAssertFalse(ProgrammeHyrox.courseCompromise(phase: phase, palier: palier).estLaSimulation)
            }
        }
    }

    /// LES HUIT STATIONS PASSENT, au lieu que la séance répète toujours les trois premières : en trois
    /// semaines de travail au bloc de base, en deux au spécifique.
    func testLesHuitStationsPassentDansLaCourseCompromise() {
        let base = (0...2).flatMap { ProgrammeHyrox.courseCompromise(phase: .base, palier: $0).stations }
        XCTAssertEqual(Set(base), Set(ProgrammeHyrox.Station.allCases))
        let specifique = (0...1).flatMap { ProgrammeHyrox.courseCompromise(phase: .specifique, palier: $0).stations }
        XCTAssertEqual(Set(specifique), Set(ProgrammeHyrox.Station.allCases))
        // La première séance commence comme l'épreuve.
        XCTAssertEqual(ProgrammeHyrox.courseCompromise(phase: .base, palier: 0).stations,
                       [.skiErg, .sledPush, .sledPull])
        // La suivante reprend où la première s'est arrêtée.
        XCTAssertEqual(ProgrammeHyrox.courseCompromise(phase: .base, palier: 1).stations,
                       [.burpeeBroadJumps, .rameur, .farmersCarry, .fentesSandbag])
    }

    /// Dans une séance, les stations sont toutes différentes et DANS L'ORDRE DE L'ÉPREUVE.
    func testLesStationsDUneCourseCompromiseSontDansLOrdreDeLEpreuve() {
        for phase in Self.phases {
            for palier in 0...12 {
                let rangs = ProgrammeHyrox.courseCompromise(phase: phase, palier: palier).stations.map(\.rang)
                XCTAssertEqual(rangs, rangs.sorted(), "\(phase) palier \(palier)")
                XCTAssertEqual(Set(rangs).count, rangs.count, "\(phase) palier \(palier)")
            }
        }
    }

    /// LA PART ET LA CHARGE SUIVENT LA PHASE : la moitié aux deux tiers de la charge au bloc de base, les
    /// trois quarts à la charge de course au spécifique, un quart à l'affûtage et à la décharge.
    func testLaCourseCompromiseSAlourditAvecLaPhase() {
        let base = ProgrammeHyrox.courseCompromise(phase: .base, palier: 0)
        XCTAssertEqual(base.part, .moitie)
        XCTAssertEqual(base.intensite, .deuxTiers)
        XCTAssertEqual(base.allure, .facile)
        let spe = ProgrammeHyrox.courseCompromise(phase: .specifique, palier: 0)
        XCTAssertEqual(spe.part, .troisQuarts)
        XCTAssertEqual(spe.intensite, .chargeDeCourse)
        XCTAssertEqual(spe.allure, .epreuve)
        let affutage = ProgrammeHyrox.courseCompromise(phase: .affutage, palier: 0)
        XCTAssertEqual(affutage.part, .quart)
        XCTAssertEqual(affutage.allure, .epreuve)
        let decharge = ProgrammeHyrox.courseCompromise(phase: .decharge, palier: 0)
        XCTAssertEqual(decharge.part, .quart)
        XCTAssertEqual(decharge.allure, .facile)
    }

    /// LA DURÉE EST CELLE DU CONTENU : quarante minutes pour trois tours faciles, une heure quarante pour
    /// la simulation, et rien de démesuré à l'affûtage.
    func testLaDureeDeLaCourseCompromiseSuitSonContenu() {
        XCTAssertEqual(ProgrammeHyrox.courseCompromise(phase: .base, palier: 0).dureeMinutes, 40)
        let simulation = ProgrammeHyrox.courseCompromise(phase: .specifique, palier: 0, simulation: true)
        XCTAssertTrue((90...110).contains(simulation.dureeMinutes), "\(simulation.dureeMinutes) min")
        XCTAssertLessThanOrEqual(ProgrammeHyrox.courseCompromise(phase: .affutage, palier: 0).dureeMinutes, 40)
        XCTAssertLessThanOrEqual(ProgrammeHyrox.courseCompromise(phase: .decharge, palier: 0).dureeMinutes, 35)
        for phase in Self.phases {
            for palier in 0...6 {
                let c = ProgrammeHyrox.courseCompromise(phase: phase, palier: palier)
                XCTAssertEqual(c.dureeMinutes % 5, 0)
                XCTAssertTrue((25...85).contains(c.dureeMinutes), "\(phase) palier \(palier) : \(c.dureeMinutes) min")
            }
        }
    }

    // MARK: Le fractionné

    /// DES KILOMÈTRES AU SEUIL, de quatre à huit : les huit kilomètres de l'épreuve au bout du plan.
    func testLeFractionneMonteDeQuatreAHuitKilometres() {
        XCTAssertEqual((0...3).map { ProgrammeHyrox.repetitionsDesIntervalles(phase: .base, palier: $0) }, [4, 5, 6, 6])
        XCTAssertEqual((0...3).map { ProgrammeHyrox.repetitionsDesIntervalles(phase: .specifique, palier: $0) }, [6, 7, 8, 8])
        XCTAssertEqual(ProgrammeHyrox.repetitionsDesIntervalles(phase: .specifique, palier: 99),
                       ChargesHyrox.Format.segmentsDeCourse, "jamais plus que l'épreuve")
        XCTAssertEqual(ProgrammeHyrox.dureeDesIntervalles(phase: .base, palier: 0), 40)
        XCTAssertEqual(ProgrammeHyrox.dureeDesIntervalles(phase: .specifique, palier: 2), 65)
        XCTAssertGreaterThan(ProgrammeHyrox.recuperationDesIntervallesM, 0)
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

    /// LE PALIER VOYAGE AVEC LA SÉANCE, et une valeur illisible vaut « pas de palier », pas un plantage.
    func testLePalierSeDecodeEtUneValeurIllisibleVautNil() throws {
        let avec = #"{"title":"X","subtitle":"","durationMinutes":40,"pace":"—","zone":"Z3","kind":"hyrox_course_compromise","phaseHyrox":"affutage","palierHyrox":2}"#
        let s1 = try JSONDecoder().decode(WorkoutSession.self, from: Data(avec.utf8))
        XCTAssertEqual(s1.palierHyrox, 2)
        XCTAssertEqual(s1.phaseHyrox, .affutage)
        XCTAssertEqual(s1.kind, .hyroxCourseCompromise)
        let relue = try JSONDecoder().decode(WorkoutSession.self, from: JSONEncoder().encode(s1))
        XCTAssertEqual(relue.palierHyrox, 2)
        let illisible = #"{"title":"X","subtitle":"","durationMinutes":40,"pace":"—","zone":"Z3","palierHyrox":"deux"}"#
        XCTAssertNil(try JSONDecoder().decode(WorkoutSession.self, from: Data(illisible.utf8)).palierHyrox)
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
