import Foundation

/// CE QUE L'ACCUEIL AFFICHE, calculé depuis les vraies données — et sans une vue.
///
/// # POURQUOI CE N'EST PAS DANS LA VUE
///
/// Le canvas montre UNE séance, un mardi : « 5 × 500 », « Fractionné léger », une pilule de
/// durée, d'allure et de zone. L'app en a des dizaines — un footing, une sortie de quatre-vingts
/// minutes, un jour de repos, une séance sans allure parce que c'est de la natation. Chaque cas
/// décide d'un texte, et un texte faux sur l'entraînement est la seule chose que cette app ne
/// peut pas se permettre. Ces décisions vivent donc ici, sans SwiftUI, et se testent seules
/// (`AccueilModeleTests`).
///
/// La vue, elle, ne décide de rien : elle pose ce que ce fichier lui rend.
///
/// Rien ici ne parle une langue, sauf les dates, qui suivent le réglage de l'appareil. Les mots
/// (« min », « Off », « Démarrer ») s'écrivent dans la vue, par le catalogue.
enum AccueilModele {

    // MARK: - Durées

    private static let minutesParHeure = 60

    /// 50 → « 50' », 80 → « 1h20 », 60 → « 1h00 ». Le format du canvas : l'apostrophe droite,
    /// et les minutes sur deux chiffres dès qu'il y a une heure.
    static func dureeCourte(minutes: Int) -> String {
        guard minutes >= minutesParHeure else { return "\(max(0, minutes))'" }
        let heures = minutes / minutesParHeure
        let reste = minutes % minutesParHeure
        return String(format: "%dh%02d", heures, reste)
    }

    // MARK: - Allure

    /// L'allure, si c'EN est une. `"4:22"` oui ; `"—"`, `""`, `"4:75"` non.
    ///
    /// Une séance de natation ou de vélo n'a pas d'allure au kilomètre, et `pace` y vaut « — » :
    /// écrire « — /km » serait écrire quelque chose de faux. Pas d'allure, pas de mesure.
    static func allureValide(_ texte: String) -> String? {
        let morceaux = texte.split(separator: ":", omittingEmptySubsequences: false)
        guard morceaux.count == 2,
              let minutes = Int(morceaux[0]), minutes >= 0,
              let secondes = Int(morceaux[1]), secondes >= 0, secondes < minutesParHeure
        else { return nil }
        return texte
    }

    // MARK: - La séance du jour

    /// Ce qui s'écrit dans la pilule sous le nom de la séance. L'unité est choisie par la vue.
    enum Mesure: Equatable {
        case minutes(Int)
        case allure(String)
        case zone(String)
    }

    /// Le grand nombre de l'écran.
    enum Nombre: Equatable {
        /// « 500 », « 50' », « 1h20 ».
        case valeur(String)
        /// Un jour de repos : « Off ».
        case repos
        /// Le plan ne prévoit rien, mais la personne court : « Libre ».
        case libre
    }

    struct Hero: Equatable {
        /// La séance du jour est déjà faite.
        var faite: Bool
        /// « 5 × » devant un fractionné ; rien devant un footing.
        var prefixe: String?
        var nombre: Nombre
        var titre: String
        var mesures: [Mesure]
    }

    /// - Parameters:
    ///   - titreDeLaCourseLibre: le titre quand le plan prévoyait du repos et qu'on court quand
    ///     même. Fourni par la vue : c'est un mot, et ce fichier n'en écrit pas.
    static func hero(session: WorkoutSession, estUnJourDeRepos: Bool, faiteAujourdhui: Bool,
                     titreDeLaCourseLibre: String) -> Hero {
        if estUnJourDeRepos {
            return Hero(faite: false, prefixe: nil, nombre: .repos,
                        titre: session.displayTitle, mesures: [])
        }
        // Le plan prévoyait du repos, la personne a couru : la séance affichée n'existe pas.
        if session.durationMinutes == 0 {
            return Hero(faite: faiteAujourdhui, prefixe: nil, nombre: .libre,
                        titre: titreDeLaCourseLibre, mesures: [])
        }

        var mesures: [Mesure] = [.minutes(session.durationMinutes)]
        if let allure = allureValide(session.pace) { mesures.append(.allure(allure)) }
        if !session.zone.isEmpty { mesures.append(.zone(session.zone)) }

        if let intervalles = session.intervals, !intervalles.estVide {
            return Hero(faite: faiteAujourdhui, prefixe: "\(intervalles.reps) ×",
                        nombre: .valeur(String(intervalles.repMeters)),
                        titre: session.displayTitle, mesures: mesures)
        }
        return Hero(faite: faiteAujourdhui, prefixe: nil,
                    nombre: .valeur(dureeCourte(minutes: session.durationMinutes)),
                    titre: session.displayTitle, mesures: mesures)
    }

    // MARK: - La semaine, en sept points

    /// L'état de chaque jour, du lundi au dimanche.
    ///
    /// Le canvas en connaît quatre : fait, aujourd'hui, à venir, repos. Une séance PASSÉE et NON
    /// FAITE n'en est aucun : elle s'affiche comme un repos (un point éteint), et c'est le moins
    /// faux des quatre — un anneau dirait « à venir ». L'étiquette lue par VoiceOver, elle, dit
    /// la vérité (`etiquetteDuJour`). La question du quatrième état est posée à la direction
    /// artistique.
    static func etatsDeLaSemaine(jours: [PlannedDay], aujourdHui: Int) -> [HZEtatDeJour] {
        jours.sorted { $0.weekday < $1.weekday }.map { jour in
            if jour.weekday == aujourdHui { return .aujourdhui }
            if jour.completed { return .fait }
            guard (jour.session?.durationMinutes ?? 0) > 0 else { return .repos }
            return jour.weekday > aujourdHui ? .aVenir : .repos
        }
    }

    // MARK: - La suite

    struct Prochaine: Identifiable, Equatable {
        var id: Int
        var jour: String
        var duree: String
        var titre: String
        var famille: SessionFamily
        var zone: String
    }

    /// Les séances à venir cette semaine, après aujourd'hui. Un jour de repos ou une séance déjà
    /// faite n'y figure pas.
    static func prochaines(jours: [PlannedDay], aujourdHui: Int, nomsDesJours: [String]) -> [Prochaine] {
        jours.sorted { $0.weekday < $1.weekday }.compactMap { jour in
            guard jour.weekday > aujourdHui, !jour.completed,
                  let session = jour.session, session.durationMinutes > 0
            else { return nil }
            let nom = nomsDesJours.indices.contains(jour.weekday) ? nomsDesJours[jour.weekday] : ""
            return Prochaine(id: jour.weekday, jour: nom,
                             duree: dureeCourte(minutes: session.durationMinutes),
                             titre: session.displayTitle, famille: session.family, zone: session.zone)
        }
    }

    /// La couleur d'intensité d'une famille de séance, quand le canvas en a une.
    ///
    /// Il en dessine TROIS — vert, bleu, violet — pour le footing, la récupération et la sortie
    /// longue. Le seuil, le fractionné et le renforcement n'ont pas de couleur dans le canvas :
    /// `nil`, et la vue les peint à l'accent. C'est une hypothèse, posée à la direction
    /// artistique ; elle est écrite ici pour qu'on la retrouve.
    static func intensite(de famille: SessionFamily) -> HZIntensite? {
        switch famille {
        case .endurance: return .facile
        case .recovery: return .recuperation
        case .longRun: return .longue
        case .rest, .tempo, .intervals, .functional: return nil
        }
    }

    // MARK: - Dates

    /// « Mardi 17 novembre ». Le gabarit du système écrit le jour en minuscule en français ;
    /// la première lettre passe en capitale, le reste ne bouge pas.
    static func dateDuJour(_ date: Date, locale: Locale = .current) -> String {
        let formateur = DateFormatter()
        formateur.locale = locale
        formateur.setLocalizedDateFormatFromTemplate("EEEEdMMMM")
        return avecInitialeEnCapitale(formateur.string(from: date))
    }

    /// « Dim. 15 nov. ».
    static func dateCourte(_ date: Date, locale: Locale = .current) -> String {
        let formateur = DateFormatter()
        formateur.locale = locale
        formateur.setLocalizedDateFormatFromTemplate("EEEdMMM")
        return avecInitialeEnCapitale(formateur.string(from: date))
    }

    /// La capitale d'une initiale, et rien d'autre : « mardi 17 novembre » → « Mardi 17 novembre ».
    /// C'est UNE lettre, pas un libellé en capitales — voir `PERMIS_A_LA_VOLEE`.
    private static func avecInitialeEnCapitale(_ texte: String) -> String {
        texte.prefix(1).uppercased() + texte.dropFirst()
    }

    // MARK: - Initiales

    /// Les initiales d'une personne : celle du prénom, celle du nom s'il y en a un.
    static func initiales(prenom: String, nom: String) -> String {
        HZAvatar.initiales(prenom: prenom, nom: nom.isEmpty ? nil : nom)
    }
}
