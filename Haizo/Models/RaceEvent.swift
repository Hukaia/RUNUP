import Foundation

/// Une course officielle, et ce que l'app en sait.
///
/// POURQUOI `raceDate` EST UNE CHAÎNE ET PAS UNE `Date`.
///
/// Côté serveur c'est une colonne `DATE` : un jour, sans heure. Une colonne DATE traverse le
/// pilote Postgres en objet `Date` JavaScript, donc en ISO complet — et le 4 avril devient le
/// 3 avril à 22 h pour qui la relit dans un autre fuseau. La route rend donc « 2027-04-04 » en
/// clair (`to_char`), et c'est cette chaîne qu'on garde : une date de course n'a pas d'heure, elle
/// n'a pas à en gagner une au passage, et le jour affiché ne doit pas dépendre d'où l'on est.
///
/// AUCUN INSTANT N'EST LE MÊME JOUR PARTOUT, et c'est pour ça que l'affichage est en UTC et non
/// dans le fuseau du téléphone. Les fuseaux habités vont de UTC−12 à UTC+14 : vingt-six heures
/// d'écart, donc à n'importe quelle heure du globe il y a deux dates au calendrier en même temps.
/// Choisir midi UTC au lieu de minuit déplace le problème sans le résoudre — à Kiritimati (+14),
/// midi UTC est déjà le lendemain à deux heures du matin. `dateLisible` formate donc le jour
/// explicitement en UTC : la LANGUE suit le téléphone, le JOUR ne suit personne. Le 4 avril est le
/// 4 avril, de Los Angeles à Tokyo.
///
/// `joursRestants`, lui, compare deux JOURS et non deux instants : le jour imprimé sur le dossard,
/// et le jour qu'il est chez la personne qui regarde. C'est le seul endroit où son fuseau compte,
/// parce que « J-42 » répond à « combien de jours me reste-t-il », pas « où est la course ».
struct RaceEvent: Decodable, Identifiable, Hashable {
    var id: String
    var name: String
    var city: String?
    /// « AAAA-MM-JJ ». Voir le commentaire ci-dessus.
    var raceDate: String
    var distanceKm: Double?
    var elevationGainM: Int?
    /// « run » | « trail » | « hyrox » | « triathlon » | « duathlon ».
    var discipline: String
    /// Affichée en lien tapable. Le serveur ne laisse passer que http(s) — voir lib/courses.js.
    var website: String?
    /// Combien de personnes préparent cette course. Optionnel par prudence de version : la
    /// fenêtre entre un déploiement du serveur et celui de l'app n'est jamais nulle.
    var followerCount: Int?

    // MARK: Les caractéristiques
    //
    // TOUT CE QUI SUIT EST OPTIONNEL, ET `nil` VEUT DIRE « PERSONNE NE L'A PUBLIÉ ». Jamais une
    // estimation : une page n'affiche pas une ligne dont elle n'a pas la valeur. Ajoutés après
    // coup, donc placés après `followerCount` — l'initialiseur d'avant continue de compiler — et
    // optionnels pour la même raison que lui : un serveur plus ancien ne les envoie pas, une app
    // plus ancienne ignore ceux qu'elle ne connaît pas.

    /// Le pays, en code ISO 3166-1 alpha-2 (« FR »). Se met en mots avec `paysLisible`.
    var country: String?
    /// Les formats d'un même événement, du plus court au plus long, quand l'organisateur en publie
    /// plusieurs. `distanceKm` reste la distance d'une épreuve à format unique.
    var distancesKm: [Double]?
    /// « route » | « trail » | « piste » | « mixte ».
    var surface: String?
    /// « plat » | « vallonne » | « montagneux ».
    var profile: String?
    /// L'heure de départ LOCALE, « HH:MM » : celle du dossard, pas un instant.
    var startTime: String?
    /// « ouverte » | « tirage_au_sort » | « bientot » | « complete » | « fermee ». Une PHOTO,
    /// datée par `verifiedOn` : elle a pu changer depuis.
    var registrationStatus: String?
    /// L'adresse d'inscription quand elle diffère du site. Même règle que `website` : http(s) seulement.
    var registrationUrl: String?
    /// « AAAA-MM-JJ » : le jour d'ouverture annoncé d'une inscription qui n'est pas encore ouverte.
    var registrationOpens: String?
    /// « AAAA-MM-JJ » : le jour où les caractéristiques de cette course ont été relues à la source.
    var verifiedOn: String?
    /// Vrai pour une course dont la date a été relevée chez l'organisateur ; `nil` pour une course
    /// créée par un coureur, dont la date est celle qu'il a tapée. Jamais `false` : l'absence d'un
    /// relevé n'est pas la preuve d'une date fausse.
    var officialDate: Bool?

    private static let jourISO: DateFormatter = {
        let f = DateFormatter()
        // `posix` et non `current` : « 2027-04-04 » est un format de machine. Avec un calendrier
        // non grégorien ou des chiffres non arabes, un formateur local ne le relirait pas.
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let utc = TimeZone(identifier: "UTC") ?? .gmt

    private static var calendrierUTC: Calendar {
        var calendrier = Calendar(identifier: .gregorian)
        calendrier.timeZone = utc
        return calendrier
    }

    /// Minuit UTC le jour de la course. Un repère, pas une heure : rien n'affiche cet instant
    /// tel quel — voir `dateLisible`, qui le remet en mots dans le même fuseau qu'il a été lu.
    var jour: Date? { Self.jourISO.date(from: raceDate) }

    /// Le style d'affichage : la langue et l'ordre des mots viennent du téléphone, le fuseau non.
    private static let styleDuJour = Date.FormatStyle(date: .long, time: .omitted, timeZone: utc)

    var dateLisible: String {
        guard let jour else { return raceDate }
        return jour.formatted(Self.styleDuJour)
    }

    /// Combien de jours il reste, du jour qu'il est CHEZ MOI au jour de la course. Négatif
    /// n'arrive quasiment pas : le serveur ne rend aucune course passée, mais la veille est
    /// acceptée à la création (voir lib/courses.js), donc l'appel reste honnête s'il arrive.
    var joursRestants: Int? {
        guard let jour else { return nil }
        // `Calendar.current` pour lire le jour local — il suit les voyages, là où un
        // `DateFormatter` statique figerait le fuseau du lancement de l'app. Puis les deux jours
        // se comparent dans le MÊME calendrier, sinon on compterait un décalage de fuseau comme
        // un jour de préparation.
        let local = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        let calendrier = Self.calendrierUTC
        guard let aujourdhui = calendrier.date(from: DateComponents(
            year: local.year, month: local.month, day: local.day)) else { return nil }
        return calendrier.dateComponents([.day], from: aujourdhui, to: jour).day
    }

    /// « Paris · 42,2 km · 1 200 m D+ » — ce qui distingue deux courses du même nom, dans cet
    /// ordre, et rien d'autre. La distance passe par `Distances` : « 42.2 » est faux en français.
    /// Plusieurs formats : le NOMBRE de formats, jamais un seul d'entre eux à la place des autres.
    var sousTitre: String {
        var morceaux: [String] = []
        if let city, !city.isEmpty {
            morceaux.append(city)
        } else if let paysLisible {
            morceaux.append(paysLisible)
        }
        if let distanceKm {
            morceaux.append(Distances.km(distanceKm))
        } else if formats.count > 1 {
            let nombre = formats.count
            morceaux.append(String(localized: "\(nombre) formats"))
        }
        if let elevationGainM, elevationGainM > 0 { morceaux.append("\(elevationGainM) m D+") }
        return morceaux.joined(separator: " · ")
    }

    var disciplineSymbole: String {
        switch discipline {
        case "trail": return "mountain.2.fill"
        case "hyrox": return "dumbbell.fill"
        case "triathlon", "duathlon": return "bicycle"
        default: return "figure.run"
        }
    }

    // MARK: - Ce que la page en dit
    //
    // Tout est calculé ici, une fois, pour que les écrans n'aient qu'à poser ce qui vient. Chaque
    // propriété rend `nil` quand la valeur manque : l'écran ne montre alors PAS la ligne. Pas de
    // tiret, pas de « inconnu » — une ligne vide est une ligne qu'on a oubliée de retirer.

    /// Le nom du pays dans la langue du téléphone, jamais écrit à la main : « Japon », « Japan ».
    var paysLisible: String? {
        guard let country, !country.isEmpty else { return nil }
        return Locale.current.localizedString(forRegionCode: country)
    }

    /// « Rome, Italie » : la ville, puis le pays, celui des deux qu'on a seul sinon.
    var lieuLisible: String? {
        let morceaux = [city, paysLisible].compactMap { $0 }.filter { !$0.isEmpty }
        return morceaux.isEmpty ? nil : morceaux.joined(separator: ", ")
    }

    /// Les distances à montrer, du plus court au plus long : la liste de l'organisateur quand il y
    /// en a une, sinon l'unique distance de l'épreuve. Vide quand on n'en sait rien.
    var formats: [Double] {
        if let distancesKm, !distancesKm.isEmpty { return distancesKm.sorted() }
        if let distanceKm { return [distanceKm] }
        return []
    }

    /// « 10 · 21,1 · 42,2 km » : les nombres, puis l'unité une seule fois.
    var formatsLisibles: String? {
        guard !formats.isEmpty else { return nil }
        let nombres = formats.map { Distances.valeur($0) }.joined(separator: " · ")
        return String(localized: "\(nombres) km")
    }

    var deniveleLisible: String? {
        guard let elevationGainM, elevationGainM > 0 else { return nil }
        let valeur = elevationGainM.formatted()
        return String(localized: "\(valeur) m D+")
    }

    var surfaceLisible: String? {
        switch surface ?? "" {
        case "route": return String(localized: "Route")
        case "trail": return String(localized: "Trail")
        case "piste": return String(localized: "Piste")
        case "mixte": return String(localized: "Mixte")
        default: return nil
        }
    }

    var profilLisible: String? {
        switch profile ?? "" {
        case "plat": return String(localized: "Plat")
        case "vallonne": return String(localized: "Vallonné")
        case "montagneux": return String(localized: "Montagneux")
        default: return nil
        }
    }

    /// L'heure du dossard, écrite comme le téléphone écrit l'heure (« 08:30 » ou « 8:30 AM »). Elle
    /// est lue et rendue dans le MÊME fuseau (UTC) : c'est une heure locale à la course, pas un
    /// instant, et le fuseau du téléphone ne doit pas la déplacer.
    var departLisible: String? {
        guard let startTime else { return nil }
        let morceaux = startTime.split(separator: ":")
        guard morceaux.count == 2, let heures = Int(morceaux[0]), let minutes = Int(morceaux[1]),
              (0..<24).contains(heures), (0..<60).contains(minutes) else { return nil }
        let composantes = DateComponents(year: 2000, month: 1, day: 1, hour: heures, minute: minutes)
        guard let instant = Self.calendrierUTC.date(from: composantes) else { return nil }
        return instant.formatted(Date.FormatStyle(date: .omitted, time: .shortened, timeZone: Self.utc))
    }

    /// « Ouverte », « Tirage au sort », « Ouvre le 11 janvier 2027 »… `nil` si le statut est absent
    /// ou si on ne le reconnaît pas : une version plus récente du serveur peut en ajouter un.
    var inscriptionLisible: String? {
        switch registrationStatus ?? "" {
        case "ouverte": return String(localized: "Ouverte")
        case "tirage_au_sort": return String(localized: "Tirage au sort")
        case "bientot":
            if let ouverture = registrationOpens.flatMap({ Self.jourLisible($0) }) {
                return String(localized: "Ouvre le \(ouverture)")
            }
            return String(localized: "Pas encore ouverte")
        case "complete": return String(localized: "Complète")
        case "fermee": return String(localized: "Fermée")
        default: return nil
        }
    }

    /// « 22 novembre 2026 » : le jour où le statut d'inscription a été relevé. Absent pour une course
    /// créée par un coureur, qui n'a pas de relevé.
    var verifieLe: String? { verifiedOn.flatMap { Self.jourLisible($0) } }

    /// Une date relevée chez l'organisateur : la page le dit, plutôt que d'en laisser douter. Faux
    /// pour une saisie, dont on ne dit rien.
    var dateEstAnnoncee: Bool { officialDate == true }

    /// L'inscription mène quelque part : sa propre adresse, ou à défaut le site, tant que les
    /// places ne sont pas parties. Sur une course complète, fermée ou pas encore ouverte, un bouton
    /// « s'inscrire » serait une promesse que le site ne tient pas.
    var adresseDInscription: String? {
        if let registrationUrl, !registrationUrl.isEmpty { return registrationUrl }
        guard let website, !website.isEmpty else { return nil }
        switch registrationStatus ?? "" {
        case "ouverte", "tirage_au_sort": return website
        default: return nil
        }
    }

    /// Le mot du type d'épreuve : ce qui tient lieu de grand nombre quand on n'a aucune distance.
    var libelleDeDiscipline: String {
        switch discipline {
        case "trail": return String(localized: "Trail")
        case "hyrox": return String(localized: "Hyrox")
        case "triathlon": return String(localized: "Triathlon")
        case "duathlon": return String(localized: "Duathlon")
        default: return String(localized: "Route")
        }
    }

    /// Le grand chiffre d'une affiche : la distance la plus longue, que l'organisateur publie.
    /// Faute de distance, le type d'épreuve — pas un tiret : « — » dit « inconnu », et on sait au
    /// moins ce que c'est.
    var grandeEtiquette: String {
        if let plusLongue = formats.last { return Distances.valeur(plusLongue) }
        return libelleDeDiscipline
    }

    private static func jourLisible(_ iso: String) -> String? {
        guard let jour = jourISO.date(from: iso) else { return nil }
        return jour.formatted(styleDuJour)
    }

    /// Un pays qu'on peut choisir à la création d'une course.
    struct PaysPropose: Identifiable {
        let code: String
        let nom: String
        var id: String { code }
    }

    /// Les pays qu'on peut choisir : les régions ISO 3166-1, nommées dans la langue du téléphone (jamais
    /// écrites à la main) et triées par ce nom. Les codes à trois chiffres (« 150 », l'Europe) sont des
    /// zones et non des pays : seuls les codes à deux lettres restent. Le serveur recontrôle chaque
    /// code contre la liste ISO, et efface ce qu'il ne reconnaît pas plutôt que de refuser la course.
    static let paysProposes: [PaysPropose] = {
        Locale.Region.isoRegions
            .map(\.identifier)
            .filter { $0.count == 2 }
            .compactMap { code in
                Locale.current.localizedString(forRegionCode: code).map { PaysPropose(code: code, nom: $0) }
            }
            .sorted { $0.nom.localizedCompare($1.nom) == .orderedAscending }
    }()

    /// Les lignes de la page d'une course, dans l'ordre où on les lit. Une énumération PLUTÔT
    /// qu'un tableau de paires : sept rubriques, bornées par leur déclaration, et chacune dit
    /// d'elle-même si elle a quelque chose à montrer.
    enum Rubrique: CaseIterable, Identifiable {
        case lieu, distances, denivele, surface, profil, depart, inscription

        var id: Self { self }

        func titre(pour course: RaceEvent) -> String {
            switch self {
            case .lieu: return String(localized: "Lieu")
            case .distances:
                return Pluriel.choisir(course.formats.count, String(localized: "Distance"), String(localized: "Distances"))
            case .denivele: return String(localized: "Dénivelé")
            case .surface: return String(localized: "Surface")
            case .profil: return String(localized: "Profil")
            case .depart: return String(localized: "Heure de départ")
            case .inscription: return String(localized: "Inscription")
            }
        }

        /// `nil` : la rubrique n'est pas montrée.
        func valeur(de course: RaceEvent) -> String? {
            switch self {
            case .lieu: return course.lieuLisible
            case .distances: return course.formatsLisibles
            case .denivele: return course.deniveleLisible
            case .surface: return course.surfaceLisible
            case .profil: return course.profilLisible
            case .depart: return course.departLisible
            case .inscription: return course.inscriptionLisible
            }
        }
    }

    /// Les rubriques qui ont une valeur, dans l'ordre de la page.
    var rubriques: [Rubrique] {
        Rubrique.allCases.filter { $0.valeur(de: self) != nil }
    }
}

/// Ce que MOI j'ai déclaré sur cette course. `nil` quand je ne la suis pas encore.
struct RaceFollow: Decodable, Hashable {
    /// Le chrono visé, tel qu'il a été écrit — « 3h30 », « sub-4 ». Volontairement libre : un
    /// objectif se dit comme on le dit, et le serveur n'en fait rien d'autre que l'afficher.
    var targetChrono: String?
    var targetPaceSecPerKm: Int?
    /// Opt-in EXPLICITE. Faux par défaut, et quand il est faux le volume d'entraînement n'est
    /// même pas calculé par la requête — voir api/races/[action].js.
    var sharesTraining: Bool
    var lookingForPartner: Bool
}

/// Quelqu'un qui prépare la même course.
struct RaceRunner: Decodable, Identifiable, Hashable, Nomme {
    var id: String
    var name: String
    var lastName: String?
    var username: String?
    var avatarUrl: String?
    var avatarBase64: String?
    var isPrivate: Bool
    /// Ma relation à cette personne : nil, « pending » ou « accepted ».
    var followStatus: String?
    var targetChrono: String?
    var targetPaceSecPerKm: Int?
    var lookingForPartner: Bool
    /// `nil` veut dire « n'a pas autorisé le partage ». Différent de `0`, qui veut dire « n'a rien
    /// couru ». Les deux s'affichent autrement, et les confondre serait accuser quelqu'un de ne
    /// pas s'entraîner parce qu'il tient à sa vie privée.
    var km4Weeks: Double?
    var runs4Weeks: Int?

    var partageSonEntrainement: Bool { km4Weeks != nil }

    var nomDeFamille: String? { lastName }
}

/// Un message du fil de la course : une question, une recherche de partenaire, une annonce de
/// dossard. Le genre décide de l'apparence, pas du traitement.
struct RacePost: Decodable, Identifiable, Hashable {
    var id: String
    /// Non nil pour une réponse. Il n'y a que deux niveaux : une réponse de réponse n'existe pas.
    var parentId: String?
    /// « message » | « partner » | « bib_offer » | « bib_wanted ».
    var kind: String
    var text: String
    /// Retiré par son auteur : le dossard est parti, le partenaire est trouvé. On marque au lieu
    /// de supprimer, sinon les réponses en dessous deviennent des messages sans contexte.
    var closed: Bool
    /// Dit par le serveur : « marquer comme réglé » n'est proposé qu'à l'auteur, et l'app n'a
    /// aucune raison de porter son propre identifiant pour le savoir.
    var isMine: Bool
    /// Les applaudissements. Un mur où l'on ne peut pas réagir est froid : quelqu'un qui demande
    /// « 3h30, quelqu'un sur ce rythme ? » et ne reçoit rien ne saura jamais si personne ne l'a lu
    /// ou si personne n'est au même rythme.
    var kudos: Int
    var kudoedByMe: Bool
    var createdAt: Date
    var author: PublicUser
}

/// Tout ce qu'une page de course affiche, en un seul aller-retour. Cinq requêtes pour un écran
/// qu'on ouvre en marchant vers le métro, ce sont cinq occasions de ne rien voir.
struct RacePage: Decodable {
    var race: RaceEvent
    var me: RaceFollow?
    var runners: [RaceRunner]
    var posts: [RacePost]
}
