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
/// # CE QUI EST SOURCÉ, ET CE QUI NE L'EST PAS
///
/// Les standards de chaque station viennent du règlement (HYROX Single Rulebook 26/27, section 8,
/// voir `ChargesHyrox`) : ce que le juge valide, ce qu'il refuse. C'est le seul « contenu
/// d'entraînement » que cette app affirme.
///
/// Pour le travail complémentaire, aucun plan officiel pour adultes n'est publié par HYROX — seulement
/// des programmes de partenaires. L'app ne prescrit donc NI séries NI répétitions NI charges pour
/// lui : elle nomme les gestes et ce qui les relie à l'épreuve, quand une source le dit (le règlement
/// pour le squat des wall balls et la fente du sandbag, hyrox.com pour ce que le farmers carry
/// sollicite). Rien de plus précis que ce qui est sourcé, et le dit à l'écran.
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
                return String(localized: "le sled et toi restez dans votre couloir · le sled dépasse entièrement la ligne de fin de couloir avant de changer de sens")
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

    /// Les deux stations d'une semaine : la première, puis la seconde.
    ///
    /// Les paires viennent des quatre familles de `ChargesHyrox.FamilleDeStations`, qui tournent sur
    /// quatre semaines : chaque station revient donc une fois par cycle de quatre semaines quand la
    /// semaine compte au moins quatre jours de course.
    ///
    /// L'ORDRE DE LA PAIRE S'INVERSE À CHAQUE CYCLE, et c'est pour les semaines de trois jours : elles
    /// ne portent qu'UNE séance de station (la première), et sans cette alternance la seconde station
    /// de chaque paire — sled pull, fentes, wall balls, rameur — ne serait jamais travaillée. Avec
    /// elle, chacune revient tous les huit semaines. Voir `lesAutresSeances`.
    static func duo(semaine: Int) -> (premiere: Station, seconde: Station) {
        let deux = ChargesHyrox.FamilleDeStations.pourLaSemaine(semaine).stations
        let cycle = (max(1, semaine) - 1) / ChargesHyrox.FamilleDeStations.allCases.count
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

        /// Le travail de la semaine, en rotation sur quatre semaines.
        static func pourLaSemaine(_ semaine: Int) -> TravailComplementaire {
            allCases[(max(1, semaine) - 1) % allCases.count]
        }

        /// Le travail d'une semaine PAIRE, pour les semaines de quatre jours : il n'y est qu'une
        /// semaine sur deux, en rotation sur huit semaines. Voir `lesAutresSeances`.
        static func pourUneSemaineSurDeux(_ semaine: Int) -> TravailComplementaire {
            allCases[(max(2, semaine) / 2 - 1) % allCases.count]
        }

        /// Les gestes de la séance : leur nom, et ce qui les relie à l'épreuve quand une source le dit.
        /// Jamais de séries, de répétitions ni de charge : aucune source ne les publie pour un
        /// programme d'adulte, et un nombre sans source est ce que cette app s'interdit.
        var gestes: [(nom: String, intention: String)] {
            switch self {
            case .forceDesJambes:
                return [
                    (String(localized: "Squats"),
                     String(localized: "descends jusqu'à passer les hanches sous les genoux, comme à chaque wall ball")),
                    (String(localized: "Fentes chargées"),
                     String(localized: "alterne les jambes, le genou arrière touche le sol, remonte debout : le geste des fentes sandbag")),
                ]
            case .gripDosGainage:
                return [
                    (String(localized: "Suspensions"),
                     String(localized: "accroche-toi à une barre, bras tendus, le temps que ta prise le permet")),
                    (String(localized: "Port de charges"),
                     String(localized: "une kettlebell ou un haltère dans chaque main, bras le long du corps : le geste du farmers carry")),
                    (String(localized: "Tirages"),
                     String(localized: "pour le haut du dos, que le farmers carry sollicite avec le gainage et la prise")),
                    (String(localized: "Gainage"),
                     String(localized: "planche et variantes, le dos droit")),
                ]
            case .pliometrie:
                return [
                    (String(localized: "Sauts en longueur"),
                     String(localized: "décollage et réception des deux pieds ensemble, comme au burpee broad jump")),
                    (String(localized: "Burpees"),
                     String(localized: "poitrine au sol à chaque répétition, comme à l'épreuve")),
                    (String(localized: "Appuis"),
                     String(localized: "rebonds courts et montées de genoux, pour le rythme et la coordination")),
                ]
            case .mobilite:
                return [
                    (String(localized: "Hanches et chevilles"),
                     String(localized: "amplitude complète, sans charge, lentement : de quoi tenir un squat sous le parallèle")),
                    (String(localized: "Épaules et haut du dos"),
                     String(localized: "bras au-dessus de la tête, gestes lents : la zone que le farmers carry et les fentes chargées sollicitent")),
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
        let semainePaire = max(1, semaine) % 2 == 0

        if joursDeCourse <= 3 {
            return [.station(premiere), .footing, .footing, .footing, .footing, .footing]
        }
        if joursDeCourse == 4 {
            let milieu: Place = semainePaire
                ? .complement(TravailComplementaire.pourUneSemaineSurDeux(semaine))
                : .footing
            return [.station(premiere), milieu, .station(seconde), .footing, .footing, .footing]
        }
        let complement = Place.complement(TravailComplementaire.pourLaSemaine(semaine))
        return [.station(premiere), .footing, .station(seconde), complement, .footing, .footing]
    }
}
