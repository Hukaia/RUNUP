import Foundation

/// LE PROGRAMME HYROX : une séance par station, et le travail qui n'est pas une station.
///
/// # CE QUE CHARLOTTE A DEMANDÉ, ET CE QUE ÇA CHANGE
///
/// Deux choses, le 22 novembre. D'abord, que chacune des huit stations ait SA séance : jusqu'ici
/// elles se travaillaient par paires (« Sleds », « Porter », « Sol-debout », « Ergomètres »), et
/// une paire ne dit pas ce que chaque geste exige. Ensuite, que le programme ne se limite pas aux
/// stations de l'épreuve : la force des jambes, la prise, le dos et le gainage, la pliométrie et
/// les appuis, la mobilité y ont leur place.
///
/// # CE QUI EST SOURCÉ, ET CE QUI EST UNE PRESCRIPTION DE PRÉPARATION
///
/// Deux sortes de contenu, et la séance les distingue à l'écran.
///
/// SOURCÉ : les standards de chaque station (HYROX Single Rulebook 26/27, section 8, voir
/// `ChargesHyrox`) — ce que le juge valide, ce qu'il refuse — et les distances et charges par division.
///
/// PRESCRIPTION DE PRÉPARATION : le nombre de séries, de répétitions, de mètres et le repos. HYROX ne
/// publie aucun plan pour adultes (seulement des programmes de partenaires), donc ces nombres ne
/// viennent d'aucun protocole officiel. Ce sont des valeurs de départ COURANTES en préparation
/// physique — volume modéré au bloc de base, charge et distance de course au bloc spécifique,
/// repos qui laisse le geste propre — écrites pour être ajustées au ressenti (effort sur dix). La
/// fiche le dit en toutes lettres : « valeurs de départ, pas un protocole officiel ». Elles n'ont
/// pas été relues par quelqu'un qui a couru un HYROX.
///
/// Les charges des stations sont relatives à la charge de course de la division (aux deux tiers, aux
/// trois quarts, à la charge de course) : la fiche connaît la division, donc les kilos.
/// La phase du programme d'où vient une séance HYROX : elle décide du volume et de la charge.
/// Portée par la séance (`WorkoutSession.phaseHyrox`) pour que la fiche sache de quelle semaine
/// elle parle sans recalculer le plan.
enum PhaseHyrox: String, Codable, Equatable, Sendable {
    case base, specifique
}

/// Ce qu'une séance prescrit : combien de séries de quoi, à quelle intensité, avec quel repos.
struct PrescriptionHyrox: Equatable, Sendable {
    enum Unite: Equatable, Sendable { case metres, repetitions, repetitionsParCote, secondes }
    /// L'intensité : relative à la charge de course de la division pour les stations, à l'effort
    /// ressenti (sur dix) pour le reste. Jamais un kilo : la fiche connaît la division, pas ta force.
    enum Intensite: Equatable, Sendable {
        case aucune, deuxTiers, troisQuarts, chargeDeCourse
        case effort(Int)
    }

    let series: Int
    let quantite: Int
    let unite: Unite
    let reposSecondes: Int
    let intensite: Intensite

    /// « 6 × 50 m · 90 s de repos · aux deux tiers de ta charge de course ».
    var texte: String {
        let volume: String
        switch unite {
        case .metres: volume = String(localized: "\(series) × \(quantite) m")
        case .repetitions: volume = String(localized: "\(series) × \(quantite) répétitions")
        case .repetitionsParCote: volume = String(localized: "\(series) × \(quantite) par côté")
        case .secondes: volume = String(localized: "\(series) × \(quantite) s")
        }
        var morceaux = [volume, String(localized: "\(reposSecondes) s de repos")]
        switch intensite {
        case .aucune: break
        case .deuxTiers: morceaux.append(String(localized: "aux deux tiers de ta charge de course"))
        case .troisQuarts: morceaux.append(String(localized: "aux trois quarts de ta charge de course"))
        case .chargeDeCourse: morceaux.append(String(localized: "à ta charge de course"))
        case .effort(let sur10): morceaux.append(String(localized: "effort \(sur10) sur 10"))
        }
        return morceaux.joined(separator: " · ")
    }
}

/// UNE SÉANCE DE STATION : des tours de « course, puis la station », comme l'épreuve.
struct FormatDeStation: Equatable, Sendable {
    enum Unite: Equatable, Sendable { case metres, allers, repetitions }
    enum AllureDeCourse: Equatable, Sendable { case facile, epreuve }

    let tours: Int
    let courseM: Int
    let quantite: Int
    let unite: Unite
    let reposSecondes: Int
    let intensite: PrescriptionHyrox.Intensite
    let allure: AllureDeCourse
    /// Les secondes que prend une unité de la station (voir `Station.secondesParUnite`).
    let secondesParUnite: Double

    /// « 4 × (800 m de course + 500 m) · 60 s de repos après la station · course à allure facile ·
    /// effort 7 sur 10 ».
    var texte: String {
        let tour: String
        switch unite {
        case .metres: tour = String(localized: "\(tours) × (\(courseM) m de course + \(quantite) m)")
        case .allers: tour = String(localized: "\(tours) × (\(courseM) m de course + \(quantite) allers)")
        case .repetitions: tour = String(localized: "\(tours) × (\(courseM) m de course + \(quantite) répétitions)")
        }
        var morceaux = [tour, String(localized: "\(reposSecondes) s de repos après la station")]
        morceaux.append(allure == .facile
                        ? String(localized: "course à allure facile")
                        : String(localized: "course à allure d'épreuve"))
        switch intensite {
        case .aucune: break
        case .deuxTiers: morceaux.append(String(localized: "aux deux tiers de ta charge de course"))
        case .troisQuarts: morceaux.append(String(localized: "aux trois quarts de ta charge de course"))
        case .chargeDeCourse: morceaux.append(String(localized: "à ta charge de course"))
        case .effort(let sur10): morceaux.append(String(localized: "effort \(sur10) sur 10"))
        }
        return morceaux.joined(separator: " · ")
    }

    /// La durée de la séance, au multiple de cinq minutes le plus proche : dix minutes d'échauffement, les
    /// tours (course à 6 min le kilomètre au bloc de base, 5 min 30 à allure d'épreuve, station, repos) et
    /// cinq minutes de retour au calme. Écrite d'après le contenu : une séance annoncée « 40 minutes » qui
    /// n'en contient que douze était l'un des défauts relevés.
    var dureeMinutes: Int {
        let minutesParKm = allure == .facile ? 6.0 : 5.5
        let course = Double(courseM) / 1000 * minutesParKm
        let station = Double(quantite) * secondesParUnite / 60
        let tour = course + station + Double(reposSecondes) / 60
        let total = 10 + Double(tours) * tour + 5
        return Int((total / 5).rounded()) * 5
    }
}

enum ProgrammeHyrox {

    // MARK: Les huit stations

    /// Les huit stations, DANS L'ORDRE DE L'ÉPREUVE. La valeur brute est le rang dans la course.
    enum Station: Int, CaseIterable, Equatable, Sendable {
        case skiErg, sledPush, sledPull, burpeeBroadJumps, rameur, farmersCarry, fentesSandbag, wallBalls

        /// Le rang dans l'épreuve : 0 pour le SkiErg, 7 pour les wall balls.
        var rang: Int { rawValue }

        /// Le type de séance qui travaille cette station seule.
        var kind: SessionKind {
            switch self {
            case .skiErg: return .hyroxStationSkiErg
            case .sledPush: return .hyroxStationSledPush
            case .sledPull: return .hyroxStationSledPull
            case .burpeeBroadJumps: return .hyroxStationBurpee
            case .rameur: return .hyroxStationRameur
            case .farmersCarry: return .hyroxStationFarmers
            case .fentesSandbag: return .hyroxStationFentes
            case .wallBalls: return .hyroxStationWallBalls
            }
        }

        /// La station qu'un type de séance travaille, ou `nil` si ce n'en est pas une.
        static func pour(_ kind: SessionKind) -> Station? {
            allCases.first { $0.kind == kind }
        }

        /// Le nom, dans la langue du téléphone. Les mêmes clés que `ChargesHyrox.stations`.
        var nom: String {
            switch self {
            case .skiErg: return String(localized: "SkiErg")
            case .sledPush: return String(localized: "Sled push")
            case .sledPull: return String(localized: "Sled pull")
            case .burpeeBroadJumps: return String(localized: "Burpee broad jumps")
            case .rameur: return String(localized: "Rameur")
            case .farmersCarry: return String(localized: "Farmers carry")
            case .fentesSandbag: return String(localized: "Fentes sandbag")
            case .wallBalls: return String(localized: "Wall balls")
            }
        }

        /// CE QU'ON FAIT DE LA STATION CETTE SEMAINE : des tours de « 1 km de course, puis la station »,
        /// comme l'épreuve, en plus court.
        ///
        /// UNE STATION SANS COURSE N'EST PAS UN ENTRAÎNEMENT HYROX : l'épreuve enchaîne huit fois un
        /// kilomètre et une station, et c'est la fatigue de l'un qui change l'autre. La première version
        /// de cette séance posait la station seule (« 6 × 50 m de sled »), et Charlotte l'a refusée.
        ///
        /// Bloc de base : quatre tours, 800 m de course facile, la moitié de la station aux deux tiers de
        /// la charge, pour apprendre le geste en gardant du souffle. Bloc spécifique : trois tours, 1 km
        /// à allure d'épreuve, les trois quarts de la station à la charge de course. La station entière
        /// n'est faite qu'à l'épreuve et à la simulation (voir `HyroxCompromisedRun6`).
        ///
        /// Voir l'en-tête de ce fichier : des valeurs de départ courantes, pas un protocole HYROX.
        func format(phase: PhaseHyrox) -> FormatDeStation {
            let base = phase == .base
            let course = base ? 800 : 1000
            let tours = base ? 4 : 3
            let repos = base ? 60 : 90
            let allure: FormatDeStation.AllureDeCourse = base ? .facile : .epreuve
            func f(_ quantite: Int, _ unite: FormatDeStation.Unite, _ intensite: PrescriptionHyrox.Intensite)
                -> FormatDeStation {
                FormatDeStation(tours: tours, courseM: course, quantite: quantite, unite: unite,
                                reposSecondes: repos, intensite: intensite, allure: allure,
                                secondesParUnite: secondesParUnite)
            }
            switch self {
            case .skiErg: return f(base ? 500 : 750, .metres, .effort(base ? 7 : 8))
            case .rameur: return f(base ? 500 : 750, .metres, .effort(base ? 7 : 8))
            case .sledPush, .sledPull: return f(base ? 2 : 3, .allers, base ? .deuxTiers : .chargeDeCourse)
            case .burpeeBroadJumps: return f(base ? 40 : 60, .metres, .aucune)
            case .farmersCarry: return f(base ? 100 : 150, .metres, base ? .deuxTiers : .chargeDeCourse)
            case .fentesSandbag: return f(base ? 50 : 75, .metres, base ? .deuxTiers : .chargeDeCourse)
            case .wallBalls: return f(base ? 50 : 75, .repetitions, .aucune)
            }
        }

        /// Le temps qu'une unité de la station prend à quelqu'un qui la fait sans se précipiter, en
        /// secondes : sert à écrire la DURÉE de la séance d'après son contenu. Une estimation de
        /// planification, pas une mesure.
        private var secondesParUnite: Double {
            switch self {
            case .skiErg, .rameur: return 0.24     // 4 min pour 1 000 m
            case .sledPush, .sledPull: return 12   // un aller de 12,5 m
            case .burpeeBroadJumps: return 3
            case .farmersCarry: return 0.7
            case .fentesSandbag: return 1.8
            case .wallBalls: return 3.5
            }
        }

        /// CE QUE LE JUGE VALIDE, tel que le règlement le dit (section 8) : le geste, pas un conseil.
        ///
        /// Chaque phrase reprend les points du règlement qui font refuser ou accepter une
        /// répétition, et rien d'autre. Les nombres du règlement qui changent par division
        /// (charges, hauteur de cible) ne sont pas ici : ils viennent de `ChargesHyrox`.
        var standard: String {
            switch self {
            case .skiErg:
                return String(localized: "les deux pieds reviennent sur la plateforme, même si tu sautes · les talons peuvent dépasser, sans toucher le sol")
            case .sledPush:
                return String(localized: "reste dans ton couloir, sled compris · le sled dépasse entièrement la ligne de fin de couloir avant de changer de sens")
            case .sledPull:
                return String(localized: "tu restes debout, jamais assis ni à genoux · tu restes dans ta zone de travail · le sled dépasse entièrement la ligne avant de changer de sens")
            case .burpeeBroadJumps:
                return String(localized: "poitrine au sol à chaque burpee · mains à 30 cm au plus devant les orteils · saut en longueur, décollage et réception des deux pieds ensemble, 5 cm d'écart au plus")
            case .rameur:
                return String(localized: "tu restes assis jusqu'au bout · tu peux t'arrêter, reposer la poignée et récupérer, sans quitter le siège")
            case .farmersCarry:
                return String(localized: "les deux kettlebells portées, bras tendus le long du corps · tu peux les poser pour te reposer, sans qu'elles avancent")
            case .fentesSandbag:
                return String(localized: "le genou arrière touche clairement le sol · chaque fente finit debout, genoux et hanches tendus · fentes alternées, sans pas intermédiaire, le sac sur les deux épaules")
            case .wallBalls:
                return String(localized: "départ debout, balle tenue à deux mains · squat complet, hanches sous les genoux · la balle touche la cible · une répétition hors standard ne compte pas")
            }
        }
    }

    // MARK: La rotation des stations

    /// LE RANG DE LA SEMAINE PARMI LES SEMAINES DE TRAVAIL, c'est-à-dire sans compter les décharges.
    ///
    /// Le moteur pose une décharge toutes les quatre semaines (voir `AdaptivePlanEngine.trainingBlock` :
    /// les semaines 4, 8, 12…). Une rotation de quatre semaines indexée sur le numéro brut de la semaine
    /// tombait donc, pour l'une des quatre familles, TOUJOURS sur une décharge — qui ne porte aucune
    /// station — et cette famille (les ergomètres) n'était jamais travaillée. Elle est maintenant indexée
    /// sur le nombre de semaines de travail : les semaines 1, 2, 3, 5, 6, 7, 9… valent 1, 2, 3, 4, 5, 6, 7…
    static func semaineDeTravail(_ semaine: Int) -> Int {
        let s = max(1, semaine)
        return s - s / 4
    }

    /// Les deux stations d'une semaine : la première, puis la seconde.
    ///
    /// Les paires viennent des quatre familles de `ChargesHyrox.FamilleDeStations`, qui tournent sur
    /// quatre semaines DE TRAVAIL (les décharges ne comptent pas, voir `semaineDeTravail`) : chaque
    /// station revient donc une fois par cycle de quatre semaines de travail quand la semaine compte au
    /// moins quatre jours de course.
    ///
    /// L'ORDRE DE LA PAIRE S'INVERSE À CHAQUE CYCLE, et c'est pour les semaines de trois jours : elles
    /// ne portent qu'UNE séance de station (la première), et sans cette alternance la seconde station
    /// de chaque paire — sled pull, fentes, wall balls, rameur — ne serait jamais travaillée. Avec
    /// elle, chacune revient tous les huit semaines. Voir `lesAutresSeances`.
    static func duo(semaine: Int) -> (premiere: Station, seconde: Station) {
        let travail = semaineDeTravail(semaine)
        let deux = ChargesHyrox.FamilleDeStations.pourLaSemaine(travail).stations
        let cycle = (travail - 1) / ChargesHyrox.FamilleDeStations.allCases.count
        return cycle % 2 == 0 ? (deux[0], deux[1]) : (deux[1], deux[0])
    }

    // MARK: Le travail complémentaire

    /// Ce que le programme ajoute aux stations de l'épreuve.
    enum TravailComplementaire: Int, CaseIterable, Equatable, Sendable {
        case forceDesJambes, gripDosGainage, pliometrie, mobilite

        var kind: SessionKind {
            switch self {
            case .forceDesJambes: return .hyroxForceJambes
            case .gripDosGainage: return .hyroxGripDosGainage
            case .pliometrie: return .hyroxPliometrie
            case .mobilite: return .hyroxMobilite
            }
        }

        static func pour(_ kind: SessionKind) -> TravailComplementaire? {
            allCases.first { $0.kind == kind }
        }

        /// Le titre ENREGISTRÉ avec la séance, en français : un repli. L'écran lit le titre du type
        /// dans le catalogue (`SessionKind.titleKey`), qui suit la langue du téléphone.
        var titreEnregistre: String {
            switch self {
            case .forceDesJambes: return "Force des jambes"
            case .gripDosGainage: return "Prise, dos et gainage"
            case .pliometrie: return "Pliométrie et appuis"
            case .mobilite: return "Mobilité et récupération"
            }
        }

        /// Le travail de la semaine DE TRAVAIL `semaine` (voir `semaineDeTravail`), en rotation sur quatre.
        static func pourLaSemaine(_ semaine: Int) -> TravailComplementaire {
            allCases[(max(1, semaine) - 1) % allCases.count]
        }

        /// Le travail d'une semaine de travail PAIRE, pour les semaines de quatre jours : il n'y est
        /// qu'une semaine sur deux, en rotation sur huit. Voir `lesAutresSeances`.
        static func pourUneSemaineSurDeux(_ semaine: Int) -> TravailComplementaire {
            allCases[(max(2, semaine) / 2 - 1) % allCases.count]
        }

        /// Les gestes de la séance : leur nom, ce qui les relie à l'épreuve quand une source le dit, et
        /// la prescription de préparation du bloc. Voir l'en-tête de ce fichier : des valeurs de
        /// départ courantes (volume modéré, effort sur dix), pas un protocole HYROX.
        func gestes(phase: PhaseHyrox) -> [(nom: String, intention: String, prescription: PrescriptionHyrox)] {
            let base = phase == .base
            switch self {
            case .forceDesJambes:
                return [
                    (String(localized: "Squats"),
                     String(localized: "descends jusqu'à passer les hanches sous les genoux, comme à chaque wall ball"),
                     base ? PrescriptionHyrox(series: 4, quantite: 8, unite: .repetitions, reposSecondes: 120, intensite: .effort(7))
                          : PrescriptionHyrox(series: 4, quantite: 5, unite: .repetitions, reposSecondes: 150, intensite: .effort(8))),
                    (String(localized: "Fentes chargées"),
                     String(localized: "alterne les jambes, le genou arrière touche le sol, remonte debout : le geste des fentes sandbag"),
                     base ? PrescriptionHyrox(series: 3, quantite: 8, unite: .repetitionsParCote, reposSecondes: 90, intensite: .effort(7))
                          : PrescriptionHyrox(series: 3, quantite: 6, unite: .repetitionsParCote, reposSecondes: 120, intensite: .effort(8))),
                ]
            case .gripDosGainage:
                return [
                    (String(localized: "Suspensions"),
                     String(localized: "accroche-toi à une barre, bras tendus, le temps que ta prise le permet"),
                     PrescriptionHyrox(series: 4, quantite: base ? 30 : 45, unite: .secondes, reposSecondes: 60, intensite: .aucune)),
                    (String(localized: "Port de charges"),
                     String(localized: "une kettlebell ou un haltère dans chaque main, bras le long du corps : le geste du farmers carry"),
                     PrescriptionHyrox(series: 4, quantite: 40, unite: .metres, reposSecondes: 90, intensite: .effort(base ? 7 : 8))),
                    (String(localized: "Tirages"),
                     String(localized: "pour le haut du dos, que le farmers carry sollicite avec le gainage et la prise"),
                     PrescriptionHyrox(series: 3, quantite: base ? 10 : 8, unite: .repetitionsParCote, reposSecondes: 90, intensite: .effort(7))),
                    (String(localized: "Gainage"),
                     String(localized: "planche et variantes, le dos droit"),
                     PrescriptionHyrox(series: 3, quantite: 45, unite: .secondes, reposSecondes: 45, intensite: .aucune)),
                ]
            case .pliometrie:
                return [
                    (String(localized: "Sauts en longueur"),
                     String(localized: "décollage et réception des deux pieds ensemble, comme au burpee broad jump"),
                     PrescriptionHyrox(series: base ? 4 : 5, quantite: 5, unite: .repetitions, reposSecondes: 90, intensite: .aucune)),
                    (String(localized: "Burpees"),
                     String(localized: "poitrine au sol à chaque répétition, comme à l'épreuve"),
                     PrescriptionHyrox(series: 3, quantite: 8, unite: .repetitions, reposSecondes: 60, intensite: .aucune)),
                    (String(localized: "Appuis"),
                     String(localized: "rebonds courts et montées de genoux, pour le rythme et la coordination"),
                     PrescriptionHyrox(series: 3, quantite: 20, unite: .secondes, reposSecondes: 60, intensite: .aucune)),
                ]
            case .mobilite:
                return [
                    (String(localized: "Hanches et chevilles"),
                     String(localized: "amplitude complète, sans charge, lentement : de quoi tenir un squat sous le parallèle"),
                     PrescriptionHyrox(series: 2, quantite: 8, unite: .repetitionsParCote, reposSecondes: 30, intensite: .aucune)),
                    (String(localized: "Épaules et haut du dos"),
                     String(localized: "bras au-dessus de la tête, gestes lents : la zone que le farmers carry et les fentes chargées sollicitent"),
                     PrescriptionHyrox(series: 2, quantite: 10, unite: .repetitions, reposSecondes: 30, intensite: .aucune)),
                ]
            }
        }
    }

    // MARK: La composition de la semaine

    /// Ce qui occupe un jour de course d'une semaine HYROX, hors sortie longue.
    enum Place: Equatable, Sendable {
        case station(Station)
        case footing
        case complement(TravailComplementaire)
    }

    /// Les séances d'une semaine HYROX hors sortie longue (la course compromise), DANS L'ORDRE où
    /// les distribue le moteur : le premier jour de course reçoit le premier élément, et ainsi de suite.
    ///
    /// L'ORDRE EST UNE RÈGLE DE SÉCURITÉ. Les deux stations ne sont jamais sur deux jours de course
    /// consécutifs : il y a toujours une séance entre elles. Le moteur plafonne par ailleurs les
    /// séances de qualité à deux par semaine, et les deux stations les prennent.
    ///
    /// LE NOMBRE DE JOURS DE COURSE DÉCIDE :
    /// - trois jours ou moins : une station et un footing. Une seule station, parce que deux séances
    ///   dures sur deux jours de course sur trois laisseraient la semaine sans souffle. La paire
    ///   s'inverse à chaque cycle (voir `duo`), pour que toutes les stations passent.
    /// - quatre jours : les deux stations, et entre elles un footing une semaine sur deux, un travail
    ///   complémentaire l'autre. C'est un ARBITRAGE : la semaine n'a pas la place de tout porter, et
    ///   c'est le footing qui cède, pas une station. À relire si le volume de course paraît juste.
    /// - cinq jours : les deux stations, un footing, un travail complémentaire chaque semaine.
    /// - six jours et plus : en plus, un second footing.
    ///
    /// La liste fait toujours six éléments au moins : le moteur boucle dessus, et une liste trop
    /// courte répéterait la station — une troisième séance dure, que le plafond remplacerait en
    /// silence par un footing.
    static func lesAutresSeances(semaine: Int, joursDeCourse: Int) -> [Place] {
        let (premiere, seconde) = duo(semaine: semaine)
        let travail = semaineDeTravail(semaine)
        let semainePaire = travail % 2 == 0

        if joursDeCourse <= 3 {
            return [.station(premiere), .footing, .footing, .footing, .footing, .footing]
        }
        if joursDeCourse == 4 {
            let milieu: Place = semainePaire
                ? .complement(TravailComplementaire.pourUneSemaineSurDeux(travail))
                : .footing
            return [.station(premiere), milieu, .station(seconde), .footing, .footing, .footing]
        }
        let complement = Place.complement(TravailComplementaire.pourLaSemaine(travail))
        return [.station(premiere), .footing, .station(seconde), complement, .footing, .footing]
    }
}
