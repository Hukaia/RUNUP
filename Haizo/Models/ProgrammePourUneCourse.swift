import Foundation

/// CALER LE PROGRAMME SUR UNE COURSE DU CALENDRIER.
///
/// # CE QUI MANQUAIT
///
/// À l'inscription, « Préparer une course » posait un objectif « progresser », sans date, puis ouvrait
/// la liste des courses. « Je prépare cette course » n'écrivait qu'un drapeau social (le club et la page
/// de la course) : le programme ne savait toujours pas quand la course avait lieu, donc il restait un
/// programme OUVERT, sans bloc spécifique ni affûtage, et la phrase qui promettait « le plan se calera
/// sur sa date » était fausse.
///
/// Ici, une course du calendrier devient un objectif de programme : la discipline et la distance
/// choisissent l'objectif, la date de la course ancre le plan (`AdaptivePlanEngine.startNewProgram`
/// sait déjà construire base, spécifique et affûtage vers une date).
///
/// # CE QUE LE CALENDRIER NE DIT PAS, ET QUI RESTE SANS PROGRAMME
///
/// Le calendrier porte une discipline, une distance et un dénivelé. Il ne porte ni le format d'un
/// triathlon ou d'un duathlon, ni la division d'un HYROX : sans eux le moteur construirait un plan
/// sans distances de natation ni de transitions. Pour ces disciplines, comme pour une course sans
/// distance ou déjà passée, il n'y a PAS de calage : on ne devine pas.
enum ProgrammePourUneCourse {

    /// Ce que le calage fera, prêt à être appliqué ou proposé.
    struct Calage {
        var resultat: AdaptivePlanEngine.NewGoalResult
        /// « 15 km », « 22 km » : la distance d'une course qui n'est pas un format nommé. Le moteur
        /// la relit par le suffixe « km » (`UserProfile.effectiveRaceDistanceKm`).
        var distanceLibre: String?
        var denivele: Int?
        var nomDeLaCourse: String
    }

    // Les fourchettes qui rangent une distance mesurée dans un format nommé : la distance d'une
    // course n'est presque jamais exacte (un 10 km mesure 10,05), et un marathon vaut 42,195.
    private static let tolerance: Double = 0.04
    private static let semi = 21.0975
    private static let marathon = 42.195
    private static let milleDeMiles = 160.934
    /// En dessous, un trail est une course ; à partir de là, c'est un ultra.
    private static let debutDeLUltra = 50.0

    private static func proche(_ km: Double, de cible: Double) -> Bool {
        abs(km - cible) <= cible * tolerance
    }

    /// Le format nommé d'une distance de route, ou nil.
    static func formatDeRoute(pourKm km: Double) -> RaceDistance? {
        if proche(km, de: 5) { return .k5 }
        if proche(km, de: 10) { return .k10 }
        if proche(km, de: semi) { return .semi }
        if proche(km, de: marathon) { return .marathon }
        return nil
    }

    /// Le format nommé d'un ultra, ou nil.
    static func formatDUltra(pourKm km: Double) -> RaceDistance? {
        if proche(km, de: 50) { return .ultra50 }
        if proche(km, de: 80) { return .ultra80 }
        if proche(km, de: 100) { return .ultra100 }
        if proche(km, de: milleDeMiles) { return .ultra100M }
        return nil
    }

    /// « 15 km » ou « 22,5 km » — la forme que `effectiveRaceDistanceKm` relit.
    static func distanceEcrite(_ km: Double) -> String {
        let entier = km.rounded()
        if abs(km - entier) < 0.05 { return "\(Int(entier)) km" }
        return String(format: "%.1f km", locale: Locale(identifier: "en_US_POSIX"), km)
    }

    /// Minuit UTC du jour de la course → midi, heure locale, du MÊME jour du calendrier. La date du
    /// calendrier est « AAAA-MM-JJ », sans fuseau : lue telle quelle à l'ouest de Greenwich, elle
    /// tomberait la veille.
    static func jourLocal(de course: RaceEvent, calendrier: Calendar = .current) -> Date? {
        guard let jour = course.jour else { return nil }
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        let c = utc.dateComponents([.year, .month, .day], from: jour)
        var local = DateComponents()
        local.year = c.year
        local.month = c.month
        local.day = c.day
        local.hour = 12
        return calendrier.date(from: local)
    }

    /// Le calage que cette course permet, ou nil quand elle ne dit pas de quoi caler un programme.
    static func calage(pour course: RaceEvent, chrono: String?, joursDeCourse: [Int],
                       maintenant: Date = .now, calendrier: Calendar = .current) -> Calage? {
        guard let km = course.distanceKm, km > 0,
              let date = jourLocal(de: course, calendrier: calendrier), date > maintenant
        else { return nil }

        let propre = chrono?.trimmingCharacters(in: .whitespaces)
        // Un chrono qui ne se lit pas comme un temps n'est pas un objectif : on ne le recopie pas.
        let chronoLu = (propre?.isEmpty == false && PaceModel.parseChronoSeconds(propre!, distance: nil) != nil)
            ? propre : nil

        let objectif: GoalType
        let distance: RaceDistance
        var libre: String?
        switch course.discipline {
        case "run":
            objectif = .race
            if let format = formatDeRoute(pourKm: km) {
                distance = format
            } else {
                distance = .other
                libre = distanceEcrite(km)
            }
        case "trail":
            if km >= debutDeLUltra {
                objectif = .ultraTrail
                if let format = formatDUltra(pourKm: km) {
                    distance = format
                } else {
                    distance = .other
                    libre = distanceEcrite(km)
                }
            } else {
                objectif = .race
                distance = .other
                libre = distanceEcrite(km)
            }
        default:
            return nil
        }

        let resultat = AdaptivePlanEngine.NewGoalResult(
            goal: objectif, distance: distance, chrono: chronoLu, raceDate: date,
            runningDays: joursDeCourse,
            raceElevationGainM: objectif == .ultraTrail ? course.elevationGainM : nil)
        return Calage(resultat: resultat, distanceLibre: libre, denivele: course.elevationGainM,
                      nomDeLaCourse: course.name)
    }

    /// Ce profil est-il déjà calé sur cette course ? Alors il n'y a rien à proposer.
    static func estDejaCale(_ profil: UserProfile, sur calage: Calage, calendrier: Calendar = .current) -> Bool {
        guard profil.goalId == calage.resultat.goal, let date = profil.raceDate,
              let visee = calage.resultat.raceDate else { return false }
        return calendrier.isDate(date, inSameDayAs: visee)
    }

    /// Reconstruit le programme vers la date de la course.
    static func appliquer(_ calage: Calage, a profil: UserProfile) {
        AdaptivePlanEngine.startNewProgram(calage.resultat, profile: profil)
        // `startNewProgram` efface la distance libre d'un programme précédent : les formats nommés
        // n'en ont pas. Celle d'une course hors format se rétablit ici, avec l'intitulé qui la dit.
        if let libre = calage.distanceLibre {
            profil.raceDistanceCustom = libre
            profil.goalDisplay = AdaptivePlanEngine.goalDisplay(
                goal: calage.resultat.goal, distance: calage.resultat.distance, custom: libre,
                chrono: calage.resultat.chrono, denivele: profil.raceElevationGainM)
        }
    }
}
