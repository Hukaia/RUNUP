import Foundation

/// LE PROGRAMME HYROX : ce qu'on fait chaque semaine, et pourquoi.
///
/// # SUR QUOI IL EST CONSTRUIT
///
/// HYROX ne publie aucun plan pour adultes : il n'existe pas de « protocole officiel » à recopier. Le
/// programme est donc CONSTRUIT, à partir de ce qui est mesuré sur l'épreuve, et chaque choix ci-dessous
/// dit d'où il vient.
///
/// 1. LA COURSE EST LA COLONNE VERTÉBRALE. Sur 12 479 arrivées de la saison 8 (HyroxDataLab, chiffre lu
///    dans un résumé et non sur la page), la course fait 52 % du temps, les stations 40 %, les
///    transitions 8 % ; l'étude ci-dessous mesure la même chose (51 min de course sur 86,5). Et dans la seule étude de physiologie
///    de l'épreuve (Brandt, Ebel, Lebahn, Schmidt, Frontiers in Physiology, 2025, onze athlètes de
///    loisir), le temps final est lié à la VO2max (rho −0,71) et au volume d'endurance hebdomadaire
///    (rho −0,68) ; ni la force de préhension ni le volume de musculation ne le sont. Chaque semaine
///    porte donc une séance de course de qualité (des kilomètres au seuil, l'unité de l'épreuve), de la
///    course facile, et de la course dans la séance de station et dans la course compromise.
///
/// 2. L'ENCHAÎNEMENT SE RÉPÈTE CHAQUE SEMAINE. La même étude mesure 79,5 % du temps au-dessus de 90 %
///    de la fréquence cardiaque maximale : l'épreuve se court fatigué. La course compromise (un
///    kilomètre, une station, sans s'arrêter) revient chaque semaine, grandit de trois tours à six,
///    et passe par les huit stations à tour de rôle. La simulation complète n'est faite qu'une fois,
///    à la dernière semaine du bloc spécifique.
///
/// 3. CHAQUE STATION A SA SÉANCE, mesurée en parts de l'épreuve. Un tour demande un quart, la moitié ou
///    les trois quarts de la station ; une séance n'en demande jamais plus d'une fois et demie le
///    volume de l'épreuve (trois fois pour les sleds, dont la station ne dure que deux minutes). Au bloc de base, les stations lestées sont aux deux tiers de la charge de
///    course et la course est facile ; au bloc spécifique, tout est à la charge et à l'allure de
///    l'épreuve, avec moins de volume. Les wall balls passent en premier dans la rotation : c'est la
///    station la plus coûteuse de l'étude (fréquence cardiaque, lactate, effort perçu).
///
/// 4. LA CHARGE MONTE PAR PALIERS, une semaine de travail après l'autre, et redescend aux semaines de
///    décharge que le moteur pose toutes les quatre semaines. L'affûtage ne contient aucune
///    simulation : seulement un rappel court, à l'allure et à la charge de l'épreuve.
///
/// # CE QUI EST SOURCÉ, ET CE QUI EST UN CHOIX DE CONSTRUCTION
///
/// SOURCÉ : les standards de chaque station (HYROX Single Rulebook 26/27, section 8, voir
/// `ChargesHyrox`), les distances et les charges par division, la part de la course dans l'épreuve,
/// ce qui prédit le temps final, les temps de passage des sleds et du farmers carry (Brandt 2025).
///
/// CHOIX DE CONSTRUCTION : le nombre exact de tours et de répétitions de chaque palier. Ils suivent les
/// règles écrites ci-dessus (parts de l'épreuve, plafond d'une fois et demie, progression d'un palier
/// par semaine de travail) et se vérifient dans `ProgrammeHyroxTests`. L'étude est petite (onze
/// athlètes) : elle oriente le programme, elle ne fixe pas un nombre de séries. La fiche le dit à la
/// coureuse en une ligne, et lui laisse la main sur l'effort.

/// La phase du programme d'où vient une séance HYROX : elle décide de l'allure et de la charge. Portée
/// par la séance (`WorkoutSession.phaseHyrox`), avec son palier (`WorkoutSession.palierHyrox`), pour
/// que la fiche sache de quelle semaine elle parle sans recalculer le plan.
enum PhaseHyrox: String, Codable, Equatable, Sendable {
    case base, specifique, affutage, decharge

    /// La phase se court-elle à allure facile, stations lestées aux deux tiers de la charge ? Le bloc
    /// de base et les semaines de décharge ; le spécifique et l'affûtage sont à l'allure et à la
    /// charge de l'épreuve.
    var estFacile: Bool { self == .base || self == .decharge }
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

/// La part de la station de l'épreuve qu'un tour demande, en quarts : toutes les quantités de
/// l'épreuve (1 000 m, 4 allers, 80 m, 200 m, 100 m, 100 répétitions) se divisent par quatre sans reste.
enum PartDeStation: Int, CaseIterable, Equatable, Sendable {
    case quart = 1, moitie, troisQuarts, entiere
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
        case .allers:
            // « 1 allers » ne se dit pas : le quart d'un sled est un seul aller.
            tour = Pluriel.choisir(quantite,
                                   String(localized: "\(tours) × (\(courseM) m de course + 1 aller)"),
                                   String(localized: "\(tours) × (\(courseM) m de course + \(quantite) allers)"))
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

        /// La quantité de la station À L'ÉPREUVE, et son unité (règlement, voir `ChargesHyrox.Format`).
        var deLEpreuve: (quantite: Int, unite: FormatDeStation.Unite) {
            switch self {
            case .skiErg: return (ChargesHyrox.Format.skiErgM, .metres)
            case .rameur: return (ChargesHyrox.Format.rameurM, .metres)
            case .sledPush, .sledPull: return (ChargesHyrox.Format.sledAllers, .allers)
            case .burpeeBroadJumps: return (ChargesHyrox.Format.burpeeBroadJumpM, .metres)
            case .farmersCarry: return (ChargesHyrox.Format.farmersCarryM, .metres)
            case .fentesSandbag: return (ChargesHyrox.Format.fentesM, .metres)
            case .wallBalls: return (ChargesHyrox.Format.wallBallsReps, .repetitions)
            }
        }

        /// Ce qu'une part de la station représente : la moitié du SkiErg, c'est 500 m ; les trois
        /// quarts d'un sled, trois allers.
        func quantite(_ part: PartDeStation) -> Int {
            deLEpreuve.quantite * part.rawValue / PartDeStation.entiere.rawValue
        }

        /// « 500 m », « 2 allers », « 50 répétitions » : ce qu'une part de la station demande, en clair.
        func texte(_ part: PartDeStation) -> String {
            let q = quantite(part)
            switch deLEpreuve.unite {
            case .metres: return String(localized: "\(q) m")
            case .allers: return Pluriel.choisir(q, String(localized: "1 aller"), String(localized: "\(q) allers"))
            case .repetitions: return String(localized: "\(q) répétitions")
            }
        }

        /// La station se fait-elle avec une charge qui change par division (sled, kettlebells, sac) ?
        /// Ce sont celles qu'on allège au bloc de base. La balle des wall balls est déjà légère.
        var estLestee: Bool {
            switch self {
            case .sledPush, .sledPull, .farmersCarry, .fentesSandbag: return true
            case .skiErg, .rameur, .burpeeBroadJumps, .wallBalls: return false
            }
        }

        /// LES PALIERS D'UNE SÉANCE DE STATION : combien de tours, et quelle part de la station par tour.
        ///
        /// Bloc de base : on apprend le geste sous une fatigue légère, avec du volume qui monte de
        /// 75 % à 150 % de celui de l'épreuve (3, 4, 5 tours d'un quart, puis 3 tours d'une moitié).
        /// Bloc spécifique : la charge et l'allure montent à celles de l'épreuve, donc le volume
        /// REDESCEND à 100 % avant de remonter (2 puis 3 tours d'une moitié, puis 2 tours de trois
        /// quarts). Le plafond d'une fois et demie l'épreuve n'est jamais dépassé.
        static func palierDeStation(phase: PhaseHyrox, palier: Int) -> (tours: Int, part: PartDeStation) {
            let p = max(0, palier)
            switch phase {
            case .base:
                switch p {
                case 0: return (3, .quart)
                case 1: return (4, .quart)
                case 2: return (5, .quart)
                default: return (3, .moitie)
                }
            case .specifique:
                switch p {
                case 0: return (2, .moitie)
                case 1: return (3, .moitie)
                default: return (2, .troisQuarts)
                }
            case .affutage, .decharge:
                return (2, .quart)
            }
        }

        /// LES SLEDS ONT LEURS PROPRES PALIERS, parce que la station est courte : quatre allers, deux
        /// minutes à l'épreuve (128 s pour le push, 155 s pour le pull, Brandt 2025). Les parts de
        /// l'épreuve donnaient « 3 × (800 m + 1 aller) » : trois allers de 12,5 m dans toute une séance,
        /// vus sur la capture, de quoi ne rien apprendre. Un tour fait donc deux allers au moins, puis
        /// la station entière ; le plafond est de trois fois l'épreuve (douze allers) au lieu d'une
        /// fois et demie. Bloc de base : 6, 8, 10 puis 12 allers aux deux tiers de la charge. Bloc
        /// spécifique : 8 puis 12 allers à la charge de course.
        static func palierDeSled(phase: PhaseHyrox, palier: Int) -> (tours: Int, allers: Int) {
            let p = max(0, palier)
            switch phase {
            case .base:
                switch p {
                case 0: return (3, 2)
                case 1: return (4, 2)
                case 2: return (5, 2)
                default: return (3, 4)
                }
            case .specifique:
                return p == 0 ? (2, 4) : (3, 4)
            case .affutage, .decharge:
                return (2, 2)
            }
        }

        /// CE QU'ON FAIT DE LA STATION CETTE SEMAINE : des tours de « course, puis la station », comme
        /// l'épreuve, en plus court.
        ///
        /// UNE STATION SANS COURSE N'EST PAS UN ENTRAÎNEMENT HYROX : l'épreuve enchaîne huit fois un
        /// kilomètre et une station, et c'est la fatigue de l'un qui change l'autre. La première version
        /// de cette séance posait la station seule (« 6 × 50 m de sled »), et Charlotte l'a refusée.
        ///
        /// Bloc de base : 800 m de course facile, stations lestées aux deux tiers de la charge. Bloc
        /// spécifique et affûtage : 1 km à allure d'épreuve, charge de course. Le nombre de tours et la
        /// part de la station viennent du palier (voir `palierDeStation`).
        func format(phase: PhaseHyrox, palier: Int = 0) -> FormatDeStation {
            let base = phase.estFacile
            let commun = Station.palierDeStation(phase: phase, palier: palier)
            var tours = commun.tours
            var parTour = quantite(commun.part)
            if self == .sledPush || self == .sledPull {
                (tours, parTour) = Station.palierDeSled(phase: phase, palier: palier)
            }
            let intensite: PrescriptionHyrox.Intensite
            switch self {
            case .skiErg, .rameur: intensite = .effort(base ? 7 : 8)
            case .burpeeBroadJumps, .wallBalls: intensite = .aucune
            case .sledPush, .sledPull, .farmersCarry, .fentesSandbag:
                intensite = base ? .deuxTiers : .chargeDeCourse
            }
            return FormatDeStation(tours: tours, courseM: base ? 800 : 1000,
                                   quantite: parTour, unite: deLEpreuve.unite,
                                   reposSecondes: base ? 60 : 90, intensite: intensite,
                                   allure: base ? .facile : .epreuve,
                                   secondesParUnite: secondesParUnite)
        }

        /// Le temps qu'une unité de la station prend à une athlète de loisir, en secondes : sert à
        /// écrire la DURÉE de la séance d'après son contenu.
        ///
        /// Les sleds et le farmers carry viennent des médianes de Brandt 2025 (sled push 128 s et sled
        /// pull 155 s pour quatre allers, farmers carry 2,7 min pour 200 m). Les autres sont des
        /// estimations de planification (4 min 30 à 4 min 50 pour 1 000 m d'ergomètre, 6 min pour cent
        /// wall balls) : elles règlent une durée affichée, pas une cible.
        var secondesParUnite: Double {
            switch self {
            case .skiErg: return 0.27
            case .rameur: return 0.29
            case .sledPush: return 32
            case .sledPull: return 39
            case .burpeeBroadJumps: return 3.5
            case .farmersCarry: return 0.8
            case .fentesSandbag: return 2.8
            case .wallBalls: return 3.6
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
    /// les semaines 4, 8, 12…). Une rotation indexée sur le numéro brut de la semaine tombait donc,
    /// pour une station sur quatre, TOUJOURS sur une décharge — qui ne porte aucune station — et cette
    /// station n'était jamais travaillée. Elle est indexée sur le nombre de semaines de travail : les
    /// semaines 1, 2, 3, 5, 6, 7, 9… valent 1, 2, 3, 4, 5, 6, 7…
    static func semaineDeTravail(_ semaine: Int) -> Int {
        let s = max(1, semaine)
        return s - s / 4
    }

    /// L'ORDRE DANS LEQUEL LES STATIONS REÇOIVENT LEUR SÉANCE, une par semaine de travail.
    ///
    /// Les wall balls d'abord : c'est la station la plus coûteuse de l'épreuve (Brandt 2025), et
    /// celle qui revient donc la première quand le programme dépasse huit semaines de travail. La
    /// suite alterne ce qui pousse, ce qui tire et ce qui porte, pour que deux semaines de suite ne
    /// chargent pas les mêmes muscles.
    static let ordreDesStations: [Station] = [
        .wallBalls, .sledPush, .rameur, .fentesSandbag,
        .sledPull, .skiErg, .burpeeBroadJumps, .farmersCarry,
    ]

    /// La station qui a sa séance la semaine `semaine` du programme.
    static func stationDeLaSemaine(_ semaine: Int) -> Station {
        ordreDesStations[(semaineDeTravail(semaine) - 1) % ordreDesStations.count]
    }

    // MARK: Le fractionné

    /// LA SÉANCE DE COURSE DE QUALITÉ : des kilomètres au seuil, l'unité de course de l'épreuve.
    ///
    /// Quatre répétitions au premier palier du bloc de base, huit au dernier du bloc spécifique :
    /// les huit kilomètres de l'épreuve, sans les stations. L'allure est le seuil du profil
    /// (`PaceModel`), soutenue mais tenable. La récupération est en mètres, comme tous les
    /// fractionnés de l'app : c'est ce que l'écran de course sait guider.
    static let recuperationDesIntervallesM = 200

    static func repetitionsDesIntervalles(phase: PhaseHyrox, palier: Int) -> Int {
        let p = min(max(0, palier), 2)
        switch phase {
        case .base: return 4 + p
        case .specifique: return 6 + p
        case .affutage, .decharge: return 3
        }
    }

    /// La durée d'un fractionné : dix minutes d'échauffement, les répétitions (cinq minutes par
    /// kilomètre au seuil et une minute et demie de récupération, des estimations de planification),
    /// cinq minutes de retour au calme. Au multiple de cinq le plus proche.
    static func dureeDesIntervalles(phase: PhaseHyrox, palier: Int) -> Int {
        let reps = repetitionsDesIntervalles(phase: phase, palier: palier)
        let total = 10 + Double(reps) * 6.5 + 5
        return Int((total / 5).rounded()) * 5
    }

    // MARK: La course compromise

    /// UNE COURSE COMPROMISE : des tours d'un kilomètre suivis d'une station, sans s'arrêter.
    struct CourseCompromise: Equatable, Sendable {
        /// Les stations de la séance, DANS L'ORDRE DE L'ÉPREUVE : une par tour.
        let stations: [Station]
        /// La part de chaque station qu'un tour demande.
        let part: PartDeStation
        /// La charge des stations lestées.
        let intensite: PrescriptionHyrox.Intensite
        let allure: FormatDeStation.AllureDeCourse
        /// Les huit tours entiers de l'épreuve ?
        let estLaSimulation: Bool

        var tours: Int { stations.count }

        /// La durée, d'après le contenu : dix minutes d'échauffement, un kilomètre par tour (6 min à
        /// allure facile, 5 min 30 à allure d'épreuve), la part de chaque station, une minute de
        /// transition par tour, cinq minutes de retour au calme. Au multiple de cinq le plus proche.
        var dureeMinutes: Int {
            let minutesParKm = allure == .facile ? 6.0 : 5.5
            let stationsMin = stations.reduce(0.0) {
                $0 + Double($1.quantite(part)) * $1.secondesParUnite / 60
            }
            let total = 10 + Double(tours) * (minutesParKm + 1) + stationsMin + 5
            return Int((total / 5).rounded()) * 5
        }
    }

    /// Le nombre de tours de la course compromise d'un palier (hors simulation).
    static func toursDeCourseCompromise(phase: PhaseHyrox, palier: Int) -> Int {
        let p = max(0, palier)
        switch phase {
        case .base: return [3, 4, 5][min(p, 2)]
        case .specifique: return [5, 6][min(p, 1)]
        case .affutage: return p == 0 ? 3 : 2
        case .decharge: return 2
        }
    }

    /// LA COURSE COMPROMISE D'UNE SEMAINE.
    ///
    /// LES STATIONS TOURNENT : la séance reprend là où la précédente du même bloc s'est arrêtée (trois
    /// tours au premier palier : SkiErg, sled push, sled pull ; quatre au suivant : burpees, rameur,
    /// farmers carry, fentes…). Les huit stations passent donc toutes, en deux ou trois semaines, au
    /// lieu que la séance répète toujours les trois premières. Dans la séance, elles restent dans
    /// l'ordre de l'épreuve.
    ///
    /// Bloc de base : la moitié de chaque station, aux deux tiers de la charge, course facile — on
    /// apprend à repartir. Bloc spécifique : les trois quarts, à la charge et à l'allure de l'épreuve.
    /// Affûtage : un quart, pour le rythme, sans fatigue. Décharge : deux tours d'un quart, faciles.
    /// `simulation` : les huit tours entiers.
    static func courseCompromise(phase: PhaseHyrox, palier: Int, simulation: Bool = false) -> CourseCompromise {
        if simulation {
            return CourseCompromise(stations: Station.allCases, part: .entiere,
                                    intensite: .chargeDeCourse, allure: .epreuve, estLaSimulation: true)
        }
        let p = max(0, palier)
        let tours = toursDeCourseCompromise(phase: phase, palier: p)
        let debut = (0..<p).reduce(0) { $0 + toursDeCourseCompromise(phase: phase, palier: $1) }
        let nombre = Station.allCases.count
        let stations = (0..<tours)
            .compactMap { Station(rawValue: (debut + $0) % nombre) }
            .sorted { $0.rang < $1.rang }
        let part: PartDeStation
        switch phase {
        case .base: part = .moitie
        case .specifique: part = .troisQuarts
        case .affutage, .decharge: part = .quart
        }
        return CourseCompromise(stations: stations, part: part,
                                intensite: phase.estFacile ? .deuxTiers : .chargeDeCourse,
                                allure: phase.estFacile ? .facile : .epreuve, estLaSimulation: false)
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

    /// Ce qui occupe un jour de course d'une semaine HYROX, hors course compromise.
    enum Place: Equatable, Sendable {
        case station(Station)
        case intervalles
        case footing
        case complement(TravailComplementaire)
    }

    /// Les séances d'une semaine HYROX hors course compromise (qui prend le jour de la sortie longue),
    /// DANS L'ORDRE où les distribue le moteur : le premier jour de course reçoit le premier élément.
    ///
    /// DEUX SÉANCES DE QUALITÉ, PAS PLUS : le fractionné et la séance de station. C'est le plafond du
    /// moteur (deux séances dures par semaine, la course compromise à part), et c'est ce que l'épreuve
    /// demande : de la course rapide, et une station apprise sous fatigue. Dès que la semaine compte
    /// quatre jours, un footing les sépare, pour qu'elles ne tombent jamais sur deux jours de course
    /// consécutifs.
    ///
    /// LEUR ORDRE S'INVERSE UNE SEMAINE SUR DEUX. Quand quelqu'un pratique deux autres sports qui
    /// pèsent sur les jambes, le moteur ne garde qu'UNE séance de qualité, la première de la liste :
    /// sans cette alternance, ce serait toujours le fractionné, et jamais une station.
    ///
    /// LE NOMBRE DE JOURS DE COURSE DÉCIDE DU RESTE :
    /// - trois jours : fractionné, station, course compromise ;
    /// - quatre jours : un footing en plus, parce que le volume d'endurance est ce qui prédit le
    ///   mieux le temps final (voir l'en-tête) ;
    /// - cinq jours : un travail complémentaire en plus (force, prise, pliométrie, mobilité, à tour
    ///   de rôle) ;
    /// - six jours et plus : un second footing.
    ///
    /// La liste fait toujours six éléments : le moteur boucle dessus, et une liste trop courte
    /// répéterait une séance de qualité.
    static func lesAutresSeances(semaine: Int, joursDeCourse: Int) -> [Place] {
        let travail = semaineDeTravail(semaine)
        let station = Place.station(stationDeLaSemaine(semaine))
        let (premiere, seconde): (Place, Place) = travail % 2 == 1
            ? (.intervalles, station) : (station, .intervalles)

        if joursDeCourse <= 3 {
            return [premiere, seconde, .footing, .footing, .footing, .footing]
        }
        if joursDeCourse == 4 {
            return [premiere, .footing, seconde, .footing, .footing, .footing]
        }
        let complement = Place.complement(TravailComplementaire.pourLaSemaine(travail))
        return [premiere, .footing, seconde, complement, .footing, .footing]
    }
}
