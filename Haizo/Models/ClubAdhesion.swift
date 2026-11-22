import Foundation

/// COMMENT ON ENTRE DANS UN CLUB : trois modes, au choix de son propriétaire.
///
/// Un club avait un seul réglage, ouvert ou fermé. L'adhésion n'est pas automatique pour tous :
///
///   · `open`    — n'importe qui rejoint d'un appui, depuis la fiche du club ;
///   · `request` — on demande à rejoindre, le propriétaire accepte ou refuse ;
///   · `code`    — on rejoint avec le code d'invitation, et on ne trouve pas le club autrement.
///
/// Ce fichier ne porte que ce qui se décide sans écran et sans réseau — le mode que dit le
/// serveur, le bouton que la fiche doit montrer, la teinte d'un club — pour que chaque décision
/// ait son test (`ClubAdhesionTests`).
enum ClubJoinMode: String, CaseIterable, Identifiable, Hashable {
    case open
    case request
    case code

    var id: Self { self }

    /// LE MODE QUE DIT LE SERVEUR, ET À DÉFAUT CELUI QUE DIT L'ANCIEN INTERRUPTEUR.
    ///
    /// Le serveur déployé avant cette version ne rend pas `joinMode`, et un serveur plus récent
    /// pourrait un jour en rendre un que cette version ne connaît pas. Dans les deux cas on retombe
    /// sur `isOpen`, le seul réglage que toute version du serveur rend : fermé est « sur code »
    /// (c'était un club qu'on ne trouvait pas et qu'on ne rejoignait pas d'un appui), tout le reste
    /// est ouvert. Une valeur absente n'est jamais une erreur de décodage.
    init(serveur: String?, isOpen: Bool?) {
        if let serveur, let mode = ClubJoinMode(rawValue: serveur) {
            self = mode
        } else {
            self = isOpen == false ? .code : .open
        }
    }

    /// Le mot de la pilule d'une carte ou d'une fiche : ce que le club demande, en un coup d'œil.
    var libelle: String {
        switch self {
        case .open: return String(localized: "Ouvert")
        case .request: return String(localized: "Sur demande")
        case .code: return String(localized: "Sur code")
        }
    }

    /// Ce que le mode veut dire, pour le propriétaire qui le choisit. Il dit aussi ce que le
    /// changement ne fait PAS : les membres actuels restent, quel que soit le mode.
    var precisionDuProprietaire: String {
        switch self {
        case .open:
            return String(localized: "N'importe qui peut trouver ce club par son nom et le rejoindre d'un toucher.")
        case .request:
            return String(localized: "On trouve ce club par son nom et on demande à le rejoindre. Tu acceptes ou tu refuses chaque demande.")
        case .code:
            return String(localized: "Ce club n'apparaît dans aucune recherche. On le rejoint seulement avec son code d'invitation.")
        }
    }

    /// Ce qu'une personne qui regarde la fiche comprend du mode, avant d'agir.
    var precisionDuVisiteur: String {
        switch self {
        case .open: return String(localized: "Tu peux rejoindre ce club tout de suite.")
        case .request: return String(localized: "Chaque nouvelle personne est acceptée par la personne qui a créé ce club.")
        case .code: return String(localized: "Ce club se rejoint avec son code d'invitation.")
        }
    }
}

/// LE BOUTON DE LA FICHE D'UN CLUB, selon le mode du club et l'état de la personne.
///
/// Une seule fonction décide, pour que la carte, la fiche et le test disent la même chose :
///
///   · elle est déjà dans un club : aucun bouton d'adhésion (un seul club à la fois) ;
///   · club ouvert : « Rejoindre » ;
///   · club sur demande : « Demander à rejoindre », puis « Demande envoyée » (qu'on peut annuler) ;
///   · club sur code : « Entrer le code » — ou « Rejoindre » quand la fiche a été ouverte AVEC le
///     code, qui a déjà été vérifié par le serveur.
enum ClubBoutonDAdhesion: Equatable {
    case rejoindre
    case demander
    case demandeEnvoyee
    case entrerLeCode
    case rejoindreAvecLeCode
    case dejaMembre

    static func pour(mode: ClubJoinMode, demandeEnvoyee: Bool, dejaDansUnClub: Bool,
                     codeConnu: Bool) -> ClubBoutonDAdhesion {
        if dejaDansUnClub { return .dejaMembre }
        switch mode {
        case .open:
            return .rejoindre
        case .request:
            return demandeEnvoyee ? .demandeEnvoyee : .demander
        case .code:
            return codeConnu ? .rejoindreAvecLeCode : .entrerLeCode
        }
    }

    /// Le libellé du bouton ; `nil` quand il n'y a pas de bouton d'adhésion à montrer.
    var libelle: String? {
        switch self {
        case .rejoindre, .rejoindreAvecLeCode: return String(localized: "Rejoindre")
        case .demander: return String(localized: "Demander à rejoindre")
        case .demandeEnvoyee: return String(localized: "Demande envoyée")
        case .entrerLeCode: return String(localized: "Entrer le code")
        case .dejaMembre: return nil
        }
    }

    /// Une demande envoyée n'est pas une action de plus : c'est un état, dit en gris, et le geste
    /// qui reste est de la retirer.
    var estUnEtat: Bool { self == .demandeEnvoyee }
}

/// LA LIGNE SOUS LE NOM D'UN CLUB : sa ville, puis son nombre de membres.
///
/// Écrite une fois pour la carte de découverte, la fiche et les lignes de recherche. Une ville
/// absente ou vide n'est pas un blanc ni un séparateur seul : « Lyon · 18 membres » ou
/// « 18 membres », jamais « · 18 membres ».
enum ClubLigne {
    static func detail(ville: String?, membres: Int) -> String {
        let nombre = Pluriel.choisir(membres,
                                     String(localized: "\(membres) membre"),
                                     String(localized: "\(membres) membres"))
        let propre = ville?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return propre.isEmpty ? nombre : "\(propre) · \(nombre)"
    }
}

/// LA TEINTE D'UN CLUB.
///
/// Un club n'a pas de couleur à lui dans la donnée : il en reçoit une de la palette d'intensité
/// du système, la même chaque fois qu'on le voit (carte de découverte, fiche). Le choix ne dépend
/// que de son identifiant, par une somme qui ne change pas d'un lancement à l'autre — `hashValue`
/// de Swift est tiré au sort à chaque lancement et ferait changer un club de couleur d'une
/// ouverture de l'app à la suivante.
enum ClubTeinte {
    /// Un entier de `0` à `nombre - 1`, le même pour le même identifiant. `0` quand `nombre` n'est
    /// pas positif : il n'y a alors rien à choisir.
    static func indice(pour identifiant: String, parmi nombre: Int) -> Int {
        guard nombre > 0 else { return 0 }
        // djb2 : une suite d'octets, un entier non signé qui boucle sans lever.
        var somme: UInt32 = 5381
        for octet in identifiant.utf8 {
            somme = (somme &* 33) &+ UInt32(octet)
        }
        return Int(somme % UInt32(nombre))
    }
}

/// CE QU'ON DIT QUAND UNE ADHÉSION NE PASSE PAS.
///
/// Le statut HTTP ne suffit pas : 409 veut dire « tu es déjà dans un club » comme « ce club se
/// demande, il ne se rejoint pas d'un appui », et la personne n'a pas à faire la même chose. Le
/// serveur écrit donc un code dans sa réponse (`ClubServiceError.codeServeur`), et c'est lui qui
/// choisit la phrase. Tout ce qui n'est pas une réponse du serveur sur l'adhésion — pas de réseau,
/// session expirée, panne — passe par `PanneReseau`, qui sait distinguer les trois.
enum ClubAdhesionErreur {

    /// La phrase pour qui essaie d'entrer ou de demander.
    static func phrase(pour erreur: Error) -> String {
        guard let club = erreur as? ClubServiceError else { return PanneReseau.phrase(pour: erreur) }
        let code = club.codeServeur
        if code == "bad_code" { return String(localized: "Ce code n'est pas le bon.") }
        if code == "already_in_club" {
            return String(localized: "Tu fais déjà partie d'un club. Quitte-le pour en rejoindre un autre.")
        }
        if code == "request_required" {
            return String(localized: "Ce club accepte maintenant sur demande. Demande à le rejoindre.")
        }
        if code == "use_join" {
            return String(localized: "Ce club est maintenant ouvert. Tu peux le rejoindre tout de suite.")
        }
        if code == "too_many_pending_requests" {
            return String(localized: "Tu as déjà plusieurs demandes en attente. Retire-en une pour en faire une autre.")
        }
        if club.statut == 429 { return String(localized: "Trop d'essais pour aujourd'hui. Réessaie demain.") }
        if club.statut == 404 {
            return String(localized: "Ce club n'est plus disponible, ou il a changé sa façon d'accueillir.")
        }
        return PanneReseau.phrase(pour: erreur)
    }

    /// Faut-il relire la fiche ? Vrai quand l'erreur dit que le club n'est plus ce que la fiche
    /// montrait : il a changé de mode, ou n'existe plus. Le bouton affiché mentirait sinon.
    static func faitRelireLaFiche(_ erreur: Error) -> Bool {
        guard let club = erreur as? ClubServiceError else { return false }
        let code = club.codeServeur
        return code == "request_required" || code == "use_join" || club.statut == 404
    }

    /// La phrase quand le code tapé ne mène à aucun club : 404, ou un code qui n'a pas la bonne
    /// forme. Le serveur ne dit pas « ce club existe mais ce n'est pas le bon code » : il n'y a
    /// qu'une seule réponse pour un code qui ne désigne rien.
    static func phraseDuCode(pour erreur: Error) -> String {
        guard let club = erreur as? ClubServiceError else { return PanneReseau.phrase(pour: erreur) }
        if club.statut == 404 || club.statut == 400 {
            return String(localized: "Aucun club ne correspond à ce code.")
        }
        return phrase(pour: erreur)
    }

    /// La phrase pour le propriétaire qui répond à une demande ou change le mode de son club.
    static func phraseDuProprietaire(pour erreur: Error) -> String {
        guard let club = erreur as? ClubServiceError else { return PanneReseau.phrase(pour: erreur) }
        let code = club.codeServeur
        if code == "already_in_club" { return String(localized: "Cette personne a déjà rejoint un autre club.") }
        if code == "forbidden" { return String(localized: "Seule la personne qui a créé le club peut faire cela.") }
        if club.statut == 404 {
            return String(localized: "Cette demande n'existe plus : la personne l'a peut-être retirée.")
        }
        return PanneReseau.phrase(pour: erreur)
    }
}

/// CE QU'ON SAIT D'UN CLUB AVANT D'OUVRIR SA FICHE, et donc de quoi la dessiner sans attendre.
///
/// Venu d'une ligne de recherche ou d'une carte (`init(_:)` sur un `ClubSearchResult`), la fiche
/// montre tout de suite le nom, la ville, le nombre de membres et le mode, puis complète avec la
/// présentation et la prochaine séance quand le serveur répond. Venu d'un code (`init(_:code:)`),
/// elle a déjà tout : le serveur ne rend la fiche d'un club sur code qu'à qui en a donné le code.
struct ClubFicheOuverte: Identifiable, Hashable {
    var id: String
    var name: String
    var city: String?
    var memberCount: Int
    var mode: ClubJoinMode
    var requestPending: Bool
    /// Le code que la personne a tapé et que le serveur a reconnu. Nil quand la fiche est ouverte
    /// depuis une recherche : un club sur code n'y figure pas, mais un club peut avoir changé de
    /// mode entre-temps.
    var code: String?
    /// La fiche déjà chargée, quand elle l'a été pour trouver le club (le chemin du code).
    var apercu: ClubPreview?

    init(_ resultat: ClubSearchResult) {
        id = resultat.id
        name = resultat.name
        city = resultat.city
        memberCount = resultat.memberCount
        mode = resultat.mode
        requestPending = resultat.requestPending == true
        code = nil
        apercu = nil
    }

    init(_ fiche: ClubPreview, code: String?) {
        id = fiche.id
        name = fiche.name
        city = fiche.city
        memberCount = fiche.memberCount
        mode = fiche.mode
        requestPending = fiche.requestPending == true
        self.code = code
        apercu = fiche
    }
}

/// UN CODE D'INVITATION, TEL QU'ON LE TAPE ET TEL QUE LE SERVEUR L'ATTEND.
///
/// Six signes (le serveur n'en emploie ni 0, ni O, ni 1, ni I, pour qu'on puisse les dicter).
/// Les espaces et les tirets n'y changent rien : on les retire avant d'envoyer. La casse non plus,
/// mais ce n'est pas l'app qui la fixe — le serveur met le code en capitales avant de le comparer,
/// et le champ de saisie demande déjà des capitales au clavier.
enum ClubCode {
    static let longueur = 6

    static func normaliser(_ brut: String) -> String {
        brut.filter { !$0.isWhitespace && $0 != "-" }
    }

    /// Le code a-t-il la longueur qu'on attend ? Ne dit pas qu'il est juste : seul le serveur le sait.
    static func estComplet(_ brut: String) -> Bool {
        normaliser(brut).count == longueur
    }
}
