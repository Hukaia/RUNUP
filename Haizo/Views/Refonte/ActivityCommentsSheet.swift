import SwiftUI

/// Real comments on one club-mate's activity (see `ClubService.fetchComments`/`postComment`) —
/// opened from the comment button next to kudos in `ClubView`'s feed. Report/block on a comment
/// author are owned by `ClubView` (its confirmationDialog/alert are already wired there), this
/// only calls back into it, same split as `ClubManagementView`.
struct ActivityCommentsSheet: View {
    @Environment(AppState.self) private var appState
    /// L'IDENTIFIANT, PAS LA CARTE. Cette feuille ne lisait que `activity.id` : exiger un
    /// `FeedItem` entier la rendait inatteignable depuis la page d'une sortie, qui en décode un
    /// autre type. Un identifiant est tout ce qu'il faut pour aller chercher des commentaires.
    var activityId: String
    var currentUserId: String?
    var clubService: ClubService
    /// Called once a comment is successfully posted, so `ClubView` can bump the feed's local
    /// `commentsCount` without a full refetch.
    var onCommentPosted: () -> Void
    /// SIGNALER ET BLOQUER SE FONT D'ICI, sauf si l'appelant veut s'en charger.
    ///
    /// Les deux gestes étaient délégués à l'écran du dessous, qui posait une alerte… sous cette
    /// feuille : elle n'apparaissait qu'une fois la feuille refermée. Deux appelants sur quatre
    /// passaient même des fermetures vides, donc « Signaler ce commentaire » et « Bloquer » ne
    /// faisaient rien du tout depuis la page d'une sortie. La feuille a le service et le
    /// commentaire sous la main : elle demande le motif, confirme le blocage, et répond.
    /// `ClubView` garde ses deux fermetures (il referme la feuille avant de demander).
    var onReport: ((CommentItem) -> Void)? = nil
    var onBlock: ((CommentItem) -> Void)? = nil
    /// Après un blocage fait d'ici : l'écran du dessous a peut-être des cartes de cette personne
    /// à retirer.
    var onBlocked: (() -> Void)? = nil

    @State private var comments: [CommentItem] = []
    @State private var isLoading = true
    @State private var newText = ""
    @State private var isSending = false
    @State private var errorMessage: String?
    @State private var commentaireSignale: CommentItem?
    @State private var motif = ""
    @State private var personneABloquer: CommentItem?

    private var peutEnvoyer: Bool {
        !newText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending
    }

    var body: some View {
        HZFeuilleModale(titre: String(localized: "Commentaires")) {
            corps
                .safeAreaInset(edge: .bottom, spacing: 0) { bas }
        }
        .task { await load() }
        .alert("Signaler", isPresented: Binding(get: { commentaireSignale != nil },
                                                set: { if !$0 { commentaireSignale = nil } })) {
            TextField("Pourquoi ?", text: $motif)
            // Le commentaire est lu AVANT la fermeture de l'alerte, qui remet l'état à `nil`.
            Button("Envoyer") { if let cible = commentaireSignale { signaler(cible) } }
            Button("Annuler", role: .cancel) { motif = "" }
        } message: {
            Text("Ce signalement sera examiné. Merci de préciser ce qui pose problème.")
        }
        .alert("Bloquer cette personne ?", isPresented: Binding(get: { personneABloquer != nil },
                                                                set: { if !$0 { personneABloquer = nil } })) {
            Button("Bloquer", role: .destructive) {
                if let cible = personneABloquer { Task { await bloquer(cible) } }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Vous ne verrez plus rien l'un de l'autre, nulle part dans l'app.")
        }
    }

    private func signaler(_ commentaire: CommentItem) {
        let raison = motif.trimmingCharacters(in: .whitespacesAndNewlines)
        motif = ""
        guard !raison.isEmpty else {
            errorMessage = String(localized: "Écris ce qui pose problème pour envoyer le signalement.")
            return
        }
        errorMessage = nil
        Task {
            do {
                try await clubService.report(targetType: "comment", targetId: commentaire.id, reason: raison)
                appState.toast(String(localized: "Signalement envoyé"))
            } catch {
                errorMessage = String(localized: "Signalement non envoyé. Réessaie.")
            }
        }
    }

    private func bloquer(_ commentaire: CommentItem) async {
        errorMessage = nil
        do {
            try await clubService.blockUser(userId: commentaire.userId)
            comments.removeAll { $0.userId == commentaire.userId }
            onBlocked?()
        } catch {
            errorMessage = String(localized: "Impossible de bloquer cette personne.")
        }
    }

    @ViewBuilder private var corps: some View {
        if isLoading {
            ProgressView().tint(HZCouleur.encre).frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                // `LazyVStack` : le fil des commentaires n'a pas de borne, et chaque
                // ligne porte un avatar à décoder. Un `VStack` les construirait TOUS à
                // l'ouverture de la feuille, y compris les quarante qu'on ne verra pas.
                LazyVStack(alignment: .leading, spacing: 0) {
                    if comments.isEmpty {
                        // La feuille s'intitule déjà « Commentaires » : la phrase seule suffit.
                        HZPhrase(texte: Accord.selon(
                            f: String(localized: "Aucun commentaire pour l'instant. Sois la première !"),
                            m: String(localized: "Aucun commentaire pour l'instant. Sois le premier !")))
                    }
                    ForEach(comments) { comment in
                        ligne(comment)
                    }
                }
                .padding(.horizontal, HZEspace.marge)
            }
        }
    }

    private func ligne(_ comment: CommentItem) -> some View {
        // La photo et le nom mènent à la personne ; le TEXTE du commentaire, non — on doit
        // pouvoir le sélectionner et le relire sans changer d'écran.
        //
        // La page s'ouvre PAR-DESSUS cette feuille, qui reste en dessous : on revient dans la
        // conversation en refermant, à l'endroit où on l'avait laissée.
        let moi = comment.userId == currentUserId
        return HZLigneDeCommentaire(
            nom: comment.nomComplet,
            date: comment.createdAt.relativeDescription,
            texte: comment.text,
            photo: HZPhotoDePersonne(urlString: comment.avatarUrl, base64DataURI: comment.avatarBase64,
                                     initiales: String(comment.name.prefix(1))),
            nomDuProfil: moi ? comment.name : String(localized: "Voir le profil de \(comment.name)"),
            ouvrable: !moi,
            ouvrir: { if !moi { appState.ouvrirLeProfil(comment.userId) } })
        .contextMenu {
            if comment.userId != currentUserId {
                Button("Signaler ce commentaire") {
                    if let onReport { onReport(comment) } else { motif = ""; commentaireSignale = comment }
                }
                Button("Bloquer \(comment.name)", role: .destructive) {
                    if let onBlock { onBlock(comment) } else { personneABloquer = comment }
                }
            }
        }
    }

    /// Le champ d'écriture, collé en bas, et l'erreur au-dessus quand il y en a une.
    private var bas: some View {
        HZBasDeFeuille {
            if let errorMessage {
                HZAvisDeFeuille(texte: errorMessage)
            }
            HZSaisie(texte: $newText, invite: String(localized: "Écris un commentaire…"),
                     nomDuBouton: String(localized: "Envoyer le commentaire"),
                     peutEnvoyer: peutEnvoyer) {
                if peutEnvoyer { Task { await send() } }
            }
        }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            comments = try await clubService.fetchComments(activityId: activityId)
        } catch {
            errorMessage = String(localized: "Impossible de charger les commentaires.")
        }
        isLoading = false
    }

    private func send() async {
        let text = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        isSending = true
        errorMessage = nil
        do {
            let comment = try await clubService.postComment(activityId: activityId, text: text)
            comments.append(comment)
            newText = ""
            Haptics.impact(.light)
            onCommentPosted()
        } catch ClubServiceError.badResponse(let code, _) where code == HZHub.refuse {
            errorMessage = String(localized: "Ce message n'est pas autorisé. Reformule-le.")
        } catch {
            errorMessage = String(localized: "Impossible d'envoyer, réessaie.")
        }
        isSending = false
    }
}
