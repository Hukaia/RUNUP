import Foundation

/// CE QUE L'ÉCRAN « TA SEMAINE » AFFICHE, calculé depuis les vrais jours du plan — et sans une vue.
///
/// Le canvas dessine sept cartes : un footing fait, un fractionné aujourd'hui, un repos, une sortie
/// avec le club, deux repos, une sortie longue. L'app a la semaine que le moteur a générée, déplacée
/// par la coureuse, avec des séances faites, des séances manquées, des jours de repos qu'elle a
/// couru quand même. Chaque carte décide d'un texte ; un texte faux sur l'entraînement ne plante
/// rien, il s'affiche. Ces décisions vivent donc ici et se testent seules (`PlanSemaineModeleTests`).
///
/// Le grand nombre, le préfixe, le titre et les mesures sont CEUX de l'accueil : une séance se dit
/// de la même façon sur les deux écrans, par `AccueilModele.hero`.
enum PlanSemaineModele {

    /// Ce qu'une carte annonce dans sa pilule.
    enum Etat: Equatable {
        /// Une séance déjà faite.
        case fait
        /// Aujourd'hui, faite ou non : la carte du jour prend l'accent, c'est son rôle.
        case aujourdhui
        /// Une séance à venir.
        case aVenir
        /// Une séance passée et NON faite. Le canvas n'a pas ce cas ; l'écrire « À venir » serait
        /// faux, le taire serait faux aussi. La pilule le dit.
        case nonFait
        /// Rien de prévu.
        case repos
    }

    struct Jour: Identifiable, Equatable {
        /// 0 = lundi … 6 = dimanche.
        var id: Int
        var date: Date
        var etat: Etat
        /// La séance prévue ce jour-là est faite. Vrai aussi pour AUJOURD'HUI quand elle l'est :
        /// l'état dit « aujourd'hui », la pilule dit « Fait ».
        var faite: Bool
        var prefixe: String?
        var nombre: AccueilModele.Nombre
        var titre: String
        var mesures: [AccueilModele.Mesure]
        var famille: SessionFamily

        var estUnRepos: Bool { famille == .rest }
    }

    // MARK: - Les sept jours

    /// - Parameters:
    ///   - jours: `profile.weekSessions`, dans n'importe quel ordre.
    ///   - aujourdHui: 0 = lundi … 6 = dimanche.
    ///   - lundi: le début du lundi de la semaine affichée, pour dater chaque carte.
    ///   - titreDuRepos: « Jour de repos » — c'est un mot, et ce fichier n'en écrit pas.
    static func jours(_ jours: [PlannedDay], aujourdHui: Int, lundi: Date,
                      titreDuRepos: String, calendrier: Calendar = .current) -> [Jour] {
        jours.sorted { $0.weekday < $1.weekday }.map { jour in
            let date = calendrier.date(byAdding: .day, value: jour.weekday, to: lundi) ?? lundi
            let duree = jour.session?.durationMinutes ?? 0

            guard let session = jour.session, duree > 0 else {
                return Jour(id: jour.weekday, date: date,
                            etat: jour.weekday == aujourdHui ? .aujourdhui : .repos, faite: false,
                            prefixe: nil, nombre: .repos, titre: titreDuRepos, mesures: [], famille: .rest)
            }

            let hero = AccueilModele.hero(session: session, estUnJourDeRepos: false,
                                          faiteAujourdhui: jour.completed, titreDeLaCourseLibre: "")
            return Jour(id: jour.weekday, date: date,
                        etat: etat(du: jour, aujourdHui: aujourdHui), faite: jour.completed,
                        prefixe: hero.prefixe, nombre: hero.nombre, titre: hero.titre,
                        mesures: hero.mesures, famille: session.family)
        }
    }

    private static func etat(du jour: PlannedDay, aujourdHui: Int) -> Etat {
        if jour.weekday == aujourdHui { return .aujourdhui }
        if jour.completed { return .fait }
        return jour.weekday > aujourdHui ? .aVenir : .nonFait
    }

    /// Le nombre de séances prévues cette semaine : un repos n'en est pas une.
    static func nombreDeSeances(_ jours: [PlannedDay]) -> Int {
        jours.filter { ($0.session?.durationMinutes ?? 0) > 0 }.count
    }

    // MARK: - La semaine, en dates

    /// Le lundi (à minuit) de la semaine qui contient `date`. Les semaines du plan commencent le
    /// lundi, quel que soit le réglage de l'appareil : `weekday` vaut 0 pour lundi.
    static func lundi(de date: Date, calendrier: Calendar = .current) -> Date {
        let indice = indiceDuJour(date, calendrier: calendrier)
        let minuit = calendrier.startOfDay(for: date)
        return calendrier.date(byAdding: .day, value: -indice, to: minuit) ?? minuit
    }

    /// 0 = lundi … 6 = dimanche.
    static func indiceDuJour(_ date: Date, calendrier: Calendar = .current) -> Int {
        // `Calendar.component(.weekday)` : 1 = dimanche … 7 = samedi.
        (calendrier.component(.weekday, from: date) + decalageDuLundi) % joursParSemaine
    }

    /// L'initiale d'un jour (« L », « M »…), dans la langue de l'appareil. `indice` : 0 = lundi.
    static func initiale(duJour indice: Int, calendrier: Calendar = .current) -> String {
        let symboles = calendrier.veryShortStandaloneWeekdaySymbols
        // Les symboles commencent au dimanche : le lundi est le deuxième.
        let rang = (indice + 1) % joursParSemaine
        return symboles.indices.contains(rang) ? symboles[rang] : ""
    }

    /// « 16 au 22 novembre » en trois morceaux : les mots viennent du catalogue, pas d'ici.
    struct Periode: Equatable {
        var premierJour: Int
        var dernierJour: Int
        var moisDuPremier: String
        var moisDuDernier: String
        var surDeuxMois: Bool { moisDuPremier != moisDuDernier }
    }

    static func periode(lundi: Date, calendrier: Calendar = .current, locale: Locale = .current) -> Periode {
        let dimanche = calendrier.date(byAdding: .day, value: joursParSemaine - 1, to: lundi) ?? lundi
        var avecLangue = calendrier
        avecLangue.locale = locale
        return Periode(premierJour: calendrier.component(.day, from: lundi),
                       dernierJour: calendrier.component(.day, from: dimanche),
                       moisDuPremier: nomDuMois(de: lundi, calendrier: avecLangue),
                       moisDuDernier: nomDuMois(de: dimanche, calendrier: avecLangue))
    }

    /// « novembre ». Les noms de mois viennent du calendrier dans la langue demandée : pas de
    /// gabarit de date à écrire, donc pas de casse à garder.
    private static func nomDuMois(de date: Date, calendrier: Calendar) -> String {
        let noms = calendrier.standaloneMonthSymbols
        let rang = calendrier.component(.month, from: date) - 1
        return noms.indices.contains(rang) ? noms[rang] : ""
    }

    private static let joursParSemaine = 7
    /// `.weekday` compte à partir du dimanche (1) : + 5 le ramène à lundi = 0, modulo sept.
    private static let decalageDuLundi = 5
}
