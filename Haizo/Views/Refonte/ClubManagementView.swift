import SwiftUI
import UIKit
import PhotosUI

/// "Gestion du club" — reached by tapping the club name in `ClubView`'s header. Groups what
/// isn't part of the day-to-day leaderboard/feed: the invite code (used to sit as its own card on
/// the main page, which read as clutter), the full member list, a drill-down mini-profile per
/// member, et l'adhésion elle-même. Report/block stay owned by `ClubView` (its
/// confirmationDialog/alert are already wired there) — this only calls back into it.
///
/// « Signaler ce club » et « Quitter le club » vivaient en bas de l'onglet Vue d'ensemble, en
/// petit gris, sous les sorties de groupe : deux actions administratives — dont une
/// irréversible sans le code d'invitation — posées sous le contenu d'un onglet sur trois, là où
/// on fait défiler pour lire le club, pas pour le gérer. Leur place est ici, avec le code
/// d'invitation et la liste des membres.
///
/// C'est le CONTENU d'une feuille large (`ClubView` lui pose `.hzFeuille(detents: [.large])`) : le
/// nom du club en est le titre, et le profil d'un membre s'ouvre dans une seconde feuille plutôt
/// que dans une pile de navigation.
struct ClubManagementView: View {
    @Environment(AppState.self) private var appState
    var club: ClubInfo
    var members: [LeaderboardRow]
    var challenge: ClubChallenge?
    var onCreateChallenge: (String, Double, Date) async throws -> Void
    var onReport: (LeaderboardRow) -> Void
    var onBlock: (LeaderboardRow) -> Void
    var onUpdateBio: (String) async throws -> Void
    /// Ouvre ou ferme le club. Comme les autres actions de cet écran, c'est l'appelante qui la
    /// réalise et qui recharge : cette vue n'a pas de service à elle.
    var onSetOpen: (Bool) async throws -> Void
    /// Ce que le club est, et où il court. Réservé à qui l'a créé.
    var onSetClubProfile: (String, String) async throws -> Void
    /// Sa bannière — un data URI JPEG, ou nil pour l'effacer.
    var onSetClubCover: (String?) async throws -> Void
    /// Nommer un organisateur, ou lui retirer le rôle. Réservé à qui a créé le club.
    var onSetMemberRole: (String, Bool) async throws -> Void
    var onReportClub: () -> Void
    var onLeaveClub: () -> Void

    @State private var showCreateChallenge = false
    @State private var membreOuvert: LeaderboardRow?
    @State private var ouvertureEnCours = false
    @State private var descriptionDuClub = ""
    @State private var villeDuClub = ""
    @State private var identiteEnregistree = false
    @State private var identiteEnCours = false
    @State private var choixDeCouverture: PhotosPickerItem?
    @State private var couvertureEnCours = false

    var body: some View {
        HZFeuilleModale(titre: club.name) {
            ScrollView {
                VStack(alignment: .leading, spacing: HZEspace.entreSections) {
                    identiteDuClub
                    verrouDuClub
                    challengeSection
                    membres
                    membershipSection
                }
                .padding(.horizontal, HZEspace.marge)
            }
            .scrollIndicators(.hidden)
        }
        .sheet(isPresented: $showCreateChallenge) {
            CreateChallengeSheet(onCreate: onCreateChallenge)
                .hzFeuille(detents: [.large], gereSonBas: true)
        }
        .sheet(item: $membreOuvert) { member in
            ClubMemberProfileView(
                member: member,
                onReport: { onReport(member) },
                onBlock: { onBlock(member) },
                onUpdateBio: member.isMe ? onUpdateBio : nil
            )
            .hzFeuille(detents: [.large])
        }
    }

    // MARK: - Les membres

    private var membres: some View {
        VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
            HZTitreDeSection(titre: Pluriel.choisir(members.count,
                                                    String(localized: "\(members.count) membre"),
                                                    String(localized: "\(members.count) membres")))
            LazyVStack(spacing: 0) {
                ForEach(Array(members.enumerated()), id: \.element.id) { index, member in
                    ligneDeMembre(member, filet: index < members.count - 1)
                }
            }
        }
    }

    private func ligneDeMembre(_ member: LeaderboardRow, filet: Bool) -> some View {
        // QUI TIENT LE CLUB, écrit sous le nom. Un crew a trois ou quatre personnes qui
        // organisent, et savoir à qui s'adresser pour un créneau ou une annulation est
        // une information de tous les jours — pas un détail d'administration.
        HZLigneDePersonne(
            nom: member.isMe ? String(localized: "\(member.nomComplet) · toi") : member.nomComplet,
            sousTitre: libelleDuRole(member.role),
            photo: HZPhotoDePersonne(urlString: member.avatarUrl, base64DataURI: member.avatarBase64,
                                     initiales: HZInitiales.de(member.name, member.lastName)),
            filet: filet,
            nomDuBouton: String(localized: "Voir le profil de \(member.name)"),
            ouvrir: { membreOuvert = member }) {
            HStack(spacing: HZEspace.entrePilules) {
                Text("\(member.xp) XP")
                    .hzTexte(.c14, .semi, tabulaire: true)
                    .foregroundStyle(HZCouleur.secondaireSurClair)
                HZChevron()
            }
        }
        // SEULE LA CRÉATRICE NOMME. Un organisateur qui pourrait en nommer d'autres pourrait
        // aussi la destituer, et le club se prendrait en otage en deux gestes. Le serveur
        // applique la même règle — ce menu ne fait que ne pas proposer l'impossible.
        .contextMenu {
            if club.isOwner == true, !member.isMe, member.role != "owner" {
                if member.role == "organiser" {
                    Button("Retirer le rôle d'organisateur") {
                        Task { await changerLeRole(member, organisateur: false) }
                    }
                } else {
                    Button("Nommer organisateur") {
                        Task { await changerLeRole(member, organisateur: true) }
                    }
                }
            }
        }
    }

    /// DES TOURNURES SANS ACCORD, et ce n'est pas un détail de style : ces deux libellés
    /// décrivent QUELQU'UN D'AUTRE, dont l'app ne connaît pas le genre. `Accord` s'accorde avec
    /// la personne qui LIT — il n'a rien à dire ici. « Fondatrice » aurait donc été juste une
    /// fois sur deux, et « Organisateur·rice » n'est pas une phrase qu'on lit.
    private func libelleDuRole(_ role: String?) -> String? {
        switch role {
        case "owner": return String(localized: "A créé le club")
        case "organiser": return String(localized: "Organise les séances")
        default: return nil
        }
    }

    private func changerLeRole(_ member: LeaderboardRow, organisateur: Bool) async {
        do {
            try await onSetMemberRole(member.id, organisateur)
        } catch {
            appState.toast(PanneReseau.phrase(pour: error))
        }
    }

    // MARK: - L'adhésion

    /// L'adhésion, en bas de la page et séparée du reste par son intertitre : ce sont les deux
    /// seules actions de cet écran qui ne servent pas à faire vivre le club.
    private var membershipSection: some View {
        HZGroupeDeReglages(titre: String(localized: "Mon adhésion")) {
            Button(action: onReportClub) {
                ligneDAdhesion(String(localized: "Signaler ce club"))
            }
            .buttonStyle(.plain)
            // Pas de chevron : ces deux-là n'emmènent nulle part, elles ouvrent une demande de
            // confirmation. La forme doit dire ce que le geste fait. « Quitter le club » dit ce qu'il
            // coûte : il redemande le code d'invitation pour revenir.
            Button(action: onLeaveClub) {
                ligneDAdhesion(String(localized: "Quitter le club"), filet: false)
            }
            .buttonStyle(.plain)
        }
    }

    private func ligneDAdhesion(_ titre: String, filet: Bool = true) -> some View {
        HZLigneDeReglage(titre: titre, filet: filet) { EmptyView() }
            .contentShape(Rectangle())
    }

    // MARK: - Le défi

    private var challengeSection: some View {
        VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
            HZTitreDeSection(titre: String(localized: "Défi du club"),
                             lien: challenge == nil ? String(localized: "Créer") : String(localized: "Changer")) {
                showCreateChallenge = true
            }
            if let challenge {
                HZPlaque {
                    Text(challenge.title)
                        .hzAffichage(.section)
                        .foregroundStyle(HZCouleur.encre)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(Int(challenge.progressKm)) / \(Int(challenge.targetKm)) km parcourus ensemble")
                        .hzParagraphe(.c14, .semi, interligne: HZBandeauDuCoach.interligne)
                        .foregroundStyle(HZCouleur.secondaireSurClair)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                HZPhrase(texte: String(localized: "Aucun défi en cours pour l'instant."))
            }
        }
    }

    // MARK: - Ce que les autres voient

    /// LE VERROU DU CLUB — et il a remplacé le code d'invitation à cette place.
    ///
    /// On rejoignait ce club avec un code à six lettres, affiché ici. On le rejoint maintenant en
    /// cherchant son nom : le code supposait qu'on l'ait reçu de quelqu'un, donc qu'on sache déjà
    /// que le club existe — exactement ce qu'une recherche rend inutile.
    ///
    /// La contrepartie d'un club trouvable est de pouvoir le rendre introuvable. Fermé, il
    /// n'apparaît dans aucune recherche et ne se rejoint plus. Ses membres actuels ne sont pas
    /// touchés : fermer n'est pas vider, et c'est écrit sous l'interrupteur parce que c'est la
    /// première question que pose un interrupteur de ce genre.
    ///
    /// Montré à la seule personne qui a créé le club. Le serveur le revérifie de son côté.
    @ViewBuilder private var verrouDuClub: some View {
        if club.isOwner == true {
            HZPlaque {
                HZLigneDeReglage(
                    titre: String(localized: "Club ouvert"),
                    precision: club.isOpen ?? true
                        ? String(localized: "N'importe qui peut trouver ce club par son nom et le rejoindre.")
                        : String(localized: "Ce club n'apparaît dans aucune recherche et ne peut plus être rejoint. Ses membres actuels y restent."),
                    filet: false) {
                    Toggle("", isOn: Binding(
                        get: { club.isOpen ?? true },
                        set: { nouveau in Task { await changerLOuverture(nouveau) } }
                    ))
                    .labelsHidden()
                    .toggleStyle(HZStyleDInterrupteur())
                    .disabled(ouvertureEnCours)
                    .accessibilityLabel("Club ouvert")
                }
            }
        }
    }

    private func changerLOuverture(_ ouvert: Bool) async {
        ouvertureEnCours = true
        defer { ouvertureEnCours = false }
        do {
            try await onSetOpen(ouvert)
        } catch {
            appState.toast(PanneReseau.phrase(pour: error))
        }
    }

    /// CE QUE LE CLUB EST, ET OÙ IL COURT.
    ///
    /// Un club n'avait qu'un nom. « Les Foulées du Canal · 18 membres » ne dit ni où l'on court,
    /// ni à quelle heure, ni si on y est le bienvenu quand on débute — c'est-à-dire tout ce
    /// qu'on cherche à savoir avant d'en rejoindre un. Les deux champs s'affichent en tête de la
    /// page du club, et la ville suit jusque dans les résultats de recherche.
    ///
    /// Comme l'interrupteur ci-dessus : montré à la seule personne qui a créé le club, et
    /// revérifié par le serveur — cacher un bouton n'a jamais empêché personne d'appeler
    /// l'adresse qu'il ouvrait.
    @ViewBuilder private var identiteDuClub: some View {
        if club.isOwner == true {
            VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
                HZTitreDeSection(titre: String(localized: "Ce que les autres voient"))
                couverture
                HZChampDeTexte(titre: String(localized: "Où court-on ? (ville)"), invite: "",
                               texte: $villeDuClub)
                HZChampDeTexte(titre: String(localized: "En deux phrases : qui êtes-vous, quand courez-vous ?"),
                               invite: "", texte: $descriptionDuClub,
                               lignes: HZClubGestion.lignesDeLaDescription)
                HStack(spacing: HZEspace.entreCommandes) {
                    HZBoutonPilule(libelle: String(localized: "Enregistrer"), hauteur: .petite) {
                        Task { await enregistrerLIdentite() }
                    }
                    .opacity(identiteEnCours ? HZHub.opaciteEteinte : HZHub.opaciteNormale)
                    .disabled(identiteEnCours)
                    if identiteEnregistree {
                        Text("Enregistré")
                            .hzTexte(.c14, .semi)
                            .foregroundStyle(HZCouleur.secondaireSurClair)
                    }
                    Spacer(minLength: 0)
                }
            }
            .onAppear {
                descriptionDuClub = club.description ?? ""
                villeDuClub = club.city ?? ""
            }
        }
    }

    /// LA BANNIÈRE DU CLUB, déposée là où se décide tout le reste de son identité.
    ///
    /// L'aperçu montre l'image ACTUELLE quand il y en a une, et un cadre gris sinon : un
    /// bouton « Ajouter une photo » posé sur rien ne dit pas ce qu'il produira, là où un
    /// cadre à la bonne forme montre déjà la place qu'elle prendra en tête de la page.
    @ViewBuilder private var couverture: some View {
        VStack(alignment: .leading, spacing: HZEspace.entrePilules) {
            PhotosPicker(selection: $choixDeCouverture, matching: .images) {
                apercuDeLaCouverture
            }
            .disabled(couvertureEnCours)
            .accessibilityLabel("Changer la photo de couverture")
            .onChange(of: choixDeCouverture) { _, nouveau in
                Task { await envoyerLaCouverture(nouveau) }
            }
            if club.coverUrl != nil {
                HZBoutonPilule(libelle: String(localized: "Retirer la photo"), hauteur: .petite,
                               fond: HZCouleur.surfaceClaire, couleur: HZCouleur.encre) {
                    Task { await envoyerLaCouverture(nil) }
                }
                .opacity(couvertureEnCours ? HZHub.opaciteEteinte : HZHub.opaciteNormale)
                .disabled(couvertureEnCours)
            }
        }
    }

    private var apercuDeLaCouverture: some View {
        ZStack {
            if let brut = club.coverUrl, !brut.isEmpty, let url = URL(string: brut) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    HZCouleur.surfaceClaire
                }
            } else {
                HZCouleur.surfaceClaire
                VStack(spacing: HZEspace.entrePilules) {
                    Image(systemName: "photo").font(HZPolice.texte(.c20, .semi))
                    Text("Ajouter une photo de couverture").hzTexte(.c13, .semi)
                }
                .foregroundStyle(HZCouleur.secondaireSurClair)
            }
            if couvertureEnCours {
                HZCouleur.noir.opacity(HZFil.voileDePhoto)
                ProgressView().tint(HZCouleur.blanc)
            }
        }
        .aspectRatio(HZHub.rapportDeLaCouverture, contentMode: .fill)
        .frame(maxWidth: .infinity)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: HZRayon.bandeau, style: .circular))
        .contentShape(Rectangle())
    }

    /// 1080 points de large, et pas la photo d'origine : le sélecteur rend des images de pleine
    /// résolution d'appareil photo (plusieurs mégaoctets), et le serveur refuse au-delà de 500 ko.
    /// C'est le même redimensionnement que la photo de profil, à une autre taille — une bannière
    /// occupe toute la largeur de l'écran, une pastille 88 points.
    private func envoyerLaCouverture(_ item: PhotosPickerItem?) async {
        couvertureEnCours = true
        defer { couvertureEnCours = false }
        var dataURI: String?
        if let item {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data),
                  let jpeg = image.resized(maxDimension: HZClubGestion.coteMaxDeLaCouverture)
                    .jpegData(compressionQuality: HZClubGestion.qualiteDeLaCouverture)
            else {
                appState.toast(String(localized: "Cette image n'a pas pu être lue."))
                return
            }
            dataURI = "data:image/jpeg;base64,\(jpeg.base64EncodedString())"
        }
        do {
            try await onSetClubCover(dataURI)
            choixDeCouverture = nil
        } catch {
            appState.toast(PanneReseau.phrase(pour: error))
        }
    }

    private func enregistrerLIdentite() async {
        identiteEnCours = true
        defer { identiteEnCours = false }
        do {
            try await onSetClubProfile(descriptionDuClub, villeDuClub)
            identiteEnregistree = true
        } catch {
            appState.toast(PanneReseau.phrase(pour: error))
        }
    }
}

// MARK: - Les pièces communes des feuilles du club

/// Un choix de date : son titre en gris au-dessus, la date dans le sélecteur compact du système.
///
/// Le sélecteur est posé en clair : la feuille est blanche quel que soit le réglage de l'appareil,
/// et son texte, sinon, s'écrirait en blanc dessus.
struct ClubChampDeDate: View {
    let titre: String
    @Binding var date: Date
    /// La première date qu'on peut choisir.
    let depuis: Date
    var composants: DatePickerComponents = .date

    var body: some View {
        VStack(alignment: .leading, spacing: HZEspace.entrePilules) {
            Text(titre)
                .hzTexte(.c13, .semi)
                .foregroundStyle(HZCouleur.secondaireSurClair)
            DatePicker(titre, selection: $date, in: depuis..., displayedComponents: composants)
                .datePickerStyle(.compact)
                .labelsHidden()
                .tint(HZCouleur.encre)
                .environment(\.colorScheme, .light)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Une erreur d'enregistrement : une phrase sur la surface claire, comme celles de la connexion.
struct ClubMessageDErreur: View {
    let texte: String

    var body: some View {
        Text(texte)
            .hzParagraphe(.c14, .semi, interligne: HZBandeauDuCoach.interligne)
            .foregroundStyle(HZCouleur.encre)
            .fixedSize(horizontal: false, vertical: true)
            .padding(HZEspace.groupe)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(HZCouleur.surfaceClaire,
                        in: RoundedRectangle(cornerRadius: HZRayon.bandeau, style: .circular))
    }
}

/// L'action principale d'une feuille, épinglée au bas : une pilule pleine largeur sur le blanc. La
/// feuille qui l'emploie gère son bas (`gereSonBas: true`).
struct ClubActionEpinglee: View {
    let libelle: String
    let disponible: Bool
    let action: () -> Void

    var body: some View {
        HZBoutonPilule(libelle: libelle, etendu: true, action: action)
            .opacity(disponible ? HZHub.opaciteNormale : HZHub.opaciteEteinte)
            .disabled(!disponible)
            .padding(.horizontal, HZEspace.marge)
            .padding(.vertical, HZEspace.entreCommandes)
            .background(HZCouleur.blanc)
    }
}

// MARK: - Le profil d'un membre

/// A member's mini-profile — real membership date, real per-club activity count, real permanent
/// badges (synced server-side, see `ClubBadgeCatalog`), and an editable status for your own
/// profile. Used to only ever show id/name/xp/rank (`LeaderboardRow`'s original shape).
///
/// UNE FEUILLE LARGE : l'appelant (`ClubManagementView`) lui pose `.hzFeuille(detents: [.large])`.
struct ClubMemberProfileView: View {
    var member: LeaderboardRow
    var onReport: () -> Void
    var onBlock: () -> Void
    /// Only non-nil for your own profile — `ClubManagementView` passes `nil` for anyone else.
    var onUpdateBio: ((String) async throws -> Void)?

    @State private var savedBio: String?
    @State private var bioText = ""
    @State private var isEditingBio = false
    @State private var isSavingBio = false
    @State private var bioError: String?
    @State private var selectedBadge: ClubBadge?

    // `String(localized:)` et non des littéraux nus : ces titres sont composés dans `Text("Niveau
    // \(level) · \(levelTitle)")` en tant qu'argument, ils n'atteignent donc jamais un
    // `LocalizedStringKey` par eux-mêmes.
    private static let levelTitles = [
        String(localized: "Premiers pas"),
        String(localized: "Foulée légère"),
        String(localized: "Rythme trouvé"),
        String(localized: "Foulée d'or"),
        String(localized: "Vitesse de croisière"),
        String(localized: "Endurance de fer"),
        String(localized: "Élite locale")
    ]
    private var level: Int { member.xp / HZClubGestion.xpParNiveau + 1 }
    // Clamped like ClubView.levelInfo — the old `%` wrapped a level-8 member back to "Premiers pas".
    private var levelTitle: String { Self.levelTitles[min(max(level - 1, 0), Self.levelTitles.count - 1)] }

    private static let joinedFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    /// Real earned/locked state from the server's `badgeKeys` — never a live progress number
    /// here, unlike `ClubView.badges`: this device has no access to another member's run history.
    private var badges: [ClubBadge] {
        ClubBadgeCatalog.all.map { def in
            ClubBadge(key: def.key, symbole: def.symbole, name: def.name, detail: def.detail, progressText: nil, earned: member.badgeKeys.contains(def.key))
        }
    }

    var body: some View {
        HZFeuilleModale(titre: member.nomComplet) {
            ScrollView {
                VStack(alignment: .leading, spacing: HZEspace.entreSections) {
                    identite
                    bioSection
                    chiffres
                    badgesSection
                    if !member.isMe { actions }
                }
                .padding(.horizontal, HZEspace.marge)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear {
            savedBio = member.bio
            bioText = member.bio ?? ""
        }
        .sheet(item: $selectedBadge) { badge in
            BadgeDetailView(badge: badge)
                .hzFeuille(detents: [.height(HZClubGestion.hauteurDuDetailDeBadge)])
        }
    }

    private var identite: some View {
        HStack(spacing: HZProfil.entreAvatarEtNom) {
            HZPhotoDePersonne(urlString: member.avatarUrl, base64DataURI: member.avatarBase64,
                              initiales: HZInitiales.de(member.name, member.lastName),
                              cote: HZClubGestion.avatarDeMembre)
            VStack(alignment: .leading, spacing: 0) {
                Text("Niveau \(level) · \(levelTitle)")
                    .hzTexte(.c15, .semi)
                    .foregroundStyle(HZCouleur.encre)
                Text("Membre depuis \(Self.joinedFormatter.string(from: member.joinedAt))")
                    .hzTexte(.c13, .medium)
                    .foregroundStyle(HZCouleur.secondaireSurClair)
            }
            .lineLimit(1)
            .minimumScaleFactor(HZAction.retraitDuLibelle)
            Spacer(minLength: 0)
        }
    }

    /// Trois chiffres en rang, comme les totaux du Profil : XP, rang dans le club, activités.
    private var chiffres: some View {
        HStack(alignment: .top, spacing: 0) {
            chiffre("\(member.xp)", String(localized: "XP"))
            chiffre("#\(member.rank)", String(localized: "Rang club"))
            chiffre("\(member.activitiesCount)", String(localized: "Activités"))
        }
    }

    private func chiffre(_ valeur: String, _ libelle: String) -> some View {
        VStack(alignment: .leading, spacing: HZProfil.sousUnTotal) {
            Text(verbatim: valeur)
                .hzAffichage(.chiffreDeProfil)
                .foregroundStyle(HZCouleur.encre)
                .lineLimit(1)
                .minimumScaleFactor(HZProfil.reductionDuNom)
            Text(libelle)
                .hzTexte(.c13, .semi)
                .foregroundStyle(HZCouleur.secondaireSurClair)
                .lineLimit(1)
                .minimumScaleFactor(HZAction.retraitDuLibelle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var bioSection: some View {
        if let onUpdateBio {
            VStack(alignment: .leading, spacing: HZEspace.entreCommandes) {
                if isEditingBio {
                    HZChampDeTexte(titre: String(localized: "Un petit statut…"), invite: "",
                                   texte: $bioText, lignes: HZClubGestion.lignesDuStatut)
                    if let bioError {
                        ClubMessageDErreur(texte: bioError)
                    }
                    HStack(spacing: HZEspace.entreCommandes) {
                        HZBoutonPilule(libelle: String(localized: "Annuler"), hauteur: .petite,
                                       fond: HZCouleur.surfaceClaire, couleur: HZCouleur.encre) {
                            isEditingBio = false
                            bioText = savedBio ?? ""
                            bioError = nil
                        }
                        HZBoutonPilule(libelle: isSavingBio ? String(localized: "…") : String(localized: "Enregistrer"),
                                       hauteur: .petite) { Task { await saveBio(onUpdateBio) } }
                            .opacity(isSavingBio ? HZHub.opaciteEteinte : HZHub.opaciteNormale)
                            .disabled(isSavingBio)
                        Spacer(minLength: 0)
                    }
                } else {
                    Button(action: { isEditingBio = true }) {
                        Text(savedBio?.isEmpty == false ? savedBio! : String(localized: "Ajouter un statut"))
                            .hzParagraphe(.c15, .medium, interligne: HZBandeauDuCoach.interligne)
                            .foregroundStyle(savedBio?.isEmpty == false ? HZCouleur.encre : HZCouleur.secondaireSurClair)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, minHeight: HZBoutonRond.zoneTactile, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        } else if let bio = member.bio, !bio.isEmpty {
            Text(bio)
                .hzParagraphe(.c15, .medium, interligne: HZBandeauDuCoach.interligne)
                .foregroundStyle(HZCouleur.secondaireSurClair)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// La grille du Profil : les seize badges, les gagnés en noir, les autres en gris.
    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: HZProfil.sousLeTitreDeBadges) {
            Text("Badges")
                .hzAffichage(.section)
                .foregroundStyle(HZCouleur.encre)
            ClubBadgeGrille(badges: badges) { selectedBadge = $0 }
        }
    }

    private var actions: some View {
        HStack(spacing: HZEspace.entreCommandes) {
            HZBoutonPilule(libelle: String(localized: "Signaler"), hauteur: .moyenne,
                           fond: HZCouleur.surfaceClaire, couleur: HZCouleur.encre, etendu: true,
                           action: onReport)
            HZBoutonPilule(libelle: String(localized: "Bloquer"), hauteur: .moyenne,
                           fond: HZCouleur.surfaceClaire, couleur: HZCouleur.encre, etendu: true,
                           action: onBlock)
        }
    }

    private func saveBio(_ onUpdateBio: (String) async throws -> Void) async {
        isSavingBio = true
        bioError = nil
        do {
            try await onUpdateBio(bioText)
            savedBio = bioText.trimmingCharacters(in: .whitespacesAndNewlines)
            isEditingBio = false
            Haptics.success()
        } catch ClubServiceError.badResponse(let code, _) where code == HZHub.refuse {
            bioError = String(localized: "Ce texte n'est pas autorisé. Reformule-le.")
        } catch {
            bioError = String(localized: "Impossible d'enregistrer, réessaie.")
        }
        isSavingBio = false
    }
}

// MARK: - Le défi

/// Any member can set the club's challenge (a distance target by a deadline) — replaces whichever
/// one was active before it, since a club has at most one at a time.
///
/// UNE FEUILLE : `.hzFeuille(detents: [.large], gereSonBas: true)` — l'action « Créer » est
/// épinglée au bas.
struct CreateChallengeSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onCreate: (String, Double, Date) async throws -> Void

    @State private var title = ""
    @State private var targetKmText = ""
    @State private var endDate = Calendar.current.date(byAdding: .day, value: HZClubGestion.joursDUnDefiParDefaut,
                                                       to: .now) ?? .now
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var targetKm: Double? { Double(targetKmText.replacingOccurrences(of: ",", with: ".")) }
    private var isValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty && (targetKm ?? 0) > 0 }

    /// Le lendemain : un défi qui finit aujourd'hui n'a pas de sens.
    private var premierJourPossible: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
    }

    var body: some View {
        HZFeuilleModale(titre: String(localized: "Nouveau défi")) {
            ScrollView {
                VStack(alignment: .leading, spacing: HZEspace.entreSections) {
                    HZChampDeTexte(titre: String(localized: "Nom du défi"),
                                   invite: String(localized: "Ex. 200 km avant l'été"), texte: $title)
                    HStack(alignment: .bottom, spacing: HZEspace.entreCommandes) {
                        HZChampDeTexte(titre: String(localized: "Distance cible"),
                                       invite: HZClubGestion.exempleDeDistance,
                                       texte: $targetKmText, clavier: .decimalPad)
                        Text("km")
                            .hzTexte(.c16, .semi)
                            .foregroundStyle(HZCouleur.secondaireSurClair)
                            .frame(minHeight: HZHub.hauteurDuChamp)
                    }
                    ClubChampDeDate(titre: String(localized: "Jusqu'au"), date: $endDate,
                                    depuis: premierJourPossible)
                    if let errorMessage {
                        ClubMessageDErreur(texte: errorMessage)
                    }
                }
                .padding(.horizontal, HZEspace.marge)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                ClubActionEpinglee(libelle: String(localized: "Créer"), disponible: isValid && !isSaving) {
                    Task { await save() }
                }
            }
        }
    }

    private func save() async {
        guard let targetKm else { return }
        isSaving = true
        errorMessage = nil
        do {
            try await onCreate(title.trimmingCharacters(in: .whitespaces), targetKm, endDate)
            Haptics.success()
            dismiss()
        } catch ClubServiceError.badResponse(let code, _) where code == HZHub.refuse {
            errorMessage = String(localized: "Ce nom n'est pas autorisé. Choisis-en un autre.")
        } catch {
            errorMessage = String(localized: "Impossible de créer le défi, réessaie.")
        }
        isSaving = false
    }
}

// MARK: - La sortie de groupe

/// Bottom sheet to propose a sortie de groupe — mirrors `CreateChallengeSheet`'s structure
/// (same visual language, same error handling), for a title + optional meeting point + date/time.
///
/// UNE FEUILLE : détents voulus `[.large]`, et elle gère son bas (`gereSonBas: true`) parce que
/// « Proposer » / « Enregistrer » est épinglé au bas par un `safeAreaInset`.
struct CreateEventSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onCreate: (String, String?, Date, Bool, [String]) async throws -> Void
    /// LA SORTIE QU'ON MODIFIE, ou nil pour en proposer une nouvelle.
    ///
    /// Une seule feuille pour les deux gestes, et pas par économie de fichiers : proposer et
    /// corriger demandent EXACTEMENT les mêmes champs, et une seconde feuille serait la copie
    /// de celle-ci — donc l'endroit où un champ ajouté demain ne serait ajouté qu'une fois.
    ///
    /// Ce qui change est le remplissage, le titre du bouton, et rien d'autre : c'est l'appelant
    /// qui décide si `onCreate` crée ou met à jour.
    var existant: ClubEvent? = nil

    /// Les champs ne sont remplis qu'UNE fois. `onAppear` repart à chaque retour de premier plan
    /// — passer prendre un appel pendant la saisie effacerait sinon tout ce qui a été tapé.
    @State private var prerempli = false

    @State private var title = ""
    @State private var location = ""
    @State private var startsAt = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
    @State private var chaqueSemaine = false
    /// Les groupes, saisis d'une traite et séparés par des virgules. Un champ par groupe avec
    /// un bouton « ajouter » demanderait quatre gestes pour écrire « 4:30, 5:15, 6:00 » ; une
    /// ligne en demande un.
    @State private var groupes = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    /// « 4:30, 5:15, 6:00 » → trois groupes. Les espaces et les entrées vides tombent : une
    /// virgule en trop à la fin ne doit pas créer un quatrième groupe sans nom.
    private var groupesSaisis: [String] {
        groupes.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private var isValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    /// Maintenant, ou la date de la séance qu'on modifie si elle est déjà derrière.
    private var borneBasse: Date { min(.now, existant?.startsAt ?? .now) }

    var body: some View {
        HZFeuilleModale(titre: String(localized: "Sortie de groupe")) {
            ScrollView {
                champs
                    .padding(.horizontal, HZEspace.marge)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                ClubActionEpinglee(
                    libelle: existant == nil ? String(localized: "Proposer") : String(localized: "Enregistrer"),
                    disponible: isValid && !isSaving
                ) { Task { await save() } }
            }
        }
        .onAppear {
            guard !prerempli, let e = existant else { return }
            prerempli = true
            title = e.title
            location = e.location ?? ""
            startsAt = e.startsAt
            chaqueSemaine = e.repeatsWeekly ?? false
            groupes = (e.paceGroups ?? []).joined(separator: ", ")
        }
    }

    private var champs: some View {
        VStack(alignment: .leading, spacing: HZEspace.entreSections) {
            HZChampDeTexte(titre: String(localized: "Quelle sortie ?"),
                           invite: String(localized: "Ex. Sortie longue tranquille 10 km"), texte: $title)
            HZChampDeTexte(titre: String(localized: "Point de rendez-vous (facultatif)"),
                           invite: String(localized: "Ex. Entrée du parc de la Tête d'Or"), texte: $location)
            // LA BORNE BASSE DESCEND JUSQU'À LA SÉANCE QU'ON MODIFIE.
            //
            // `in: .now...` seul est juste à la création, et faux à la modification :
            // une séance qui commence dans vingt minutes a une date ANTÉRIEURE au
            // moment où l'on ouvre cette feuille pour corriger son lieu. SwiftUI
            // ramène alors silencieusement la sélection dans la plage — on vient
            // changer un mot, et on repart avec la date déplacée sans l'avoir vu.
            ClubChampDeDate(titre: String(localized: "Quand ?"), date: $startsAt, depuis: borneBasse,
                            composants: [.date, .hourAndMinute])
            // LA SÉANCE QUI REVIENT : ce qui sépare un club d'une suite de sorties.
            //
            // Un crew a un rendez-vous — « le mardi 19h30 » — et c'est lui qui fait le
            // club. Sans cet interrupteur, quelqu'un devait reposter la même sortie
            // chaque semaine, et le jour où il oublie, le club n'a plus de séance.
            HZPlaque {
                HZLigneDeReglage(
                    titre: String(localized: "Chaque semaine"),
                    precision: String(localized: "La séance se reporte d'elle-même à la semaine suivante, et les présences repartent de zéro."),
                    filet: false) {
                    Toggle("", isOn: $chaqueSemaine)
                        .labelsHidden()
                        .toggleStyle(HZStyleDInterrupteur())
                        .accessibilityLabel("Chaque semaine")
                }
            }
            VStack(alignment: .leading, spacing: HZEspace.entrePilules) {
                HZChampDeTexte(titre: String(localized: "Groupes d'allure (facultatif)"),
                               invite: String(localized: "Ex. 4:30, 5:15, 6:00"), texte: $groupes)
                Text("Séparés par des virgules. Chacun choisit le sien en disant « J'y serai ». C'est ce qui dit combien de meneurs prévoir.")
                    .hzParagraphe(.c13, .medium, interligne: HZBandeauDuCoach.interligne)
                    .foregroundStyle(HZCouleur.secondaireSurClair)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let errorMessage {
                ClubMessageDErreur(texte: errorMessage)
            }
        }
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        do {
            let trimmedLocation = location.trimmingCharacters(in: .whitespaces)
            try await onCreate(title.trimmingCharacters(in: .whitespaces),
                               trimmedLocation.isEmpty ? nil : trimmedLocation,
                               startsAt, chaqueSemaine, groupesSaisis)
            Haptics.success()
            dismiss()
        } catch ClubServiceError.badResponse(let code, _) where code == HZHub.refuse {
            errorMessage = String(localized: "Ce texte n'est pas autorisé. Reformule.")
        } catch {
            errorMessage = existant == nil
                ? String(localized: "Impossible de proposer la sortie, réessaie.")
                : String(localized: "Impossible d'enregistrer la sortie, réessaie.")
        }
        isSaving = false
    }
}
