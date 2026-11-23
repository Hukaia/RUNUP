import SwiftUI

/// L'onglet Activité du Club : le mur et le fil des sorties, entrelacés.
///
/// # LE DERNIER MORCEAU DE LA DÉCOUPE, ET LE SEUL QUI A DEMANDÉ AUTRE CHOSE QU'UN DÉPLACEMENT
///
/// Les quatre cartes sorties avant celle-ci ne demandaient zéro ou un état. Le mur en touchait
/// ONZE sur les dix-huit de `ClubView`. Le sortir tel quel aurait transformé une vue longue en
/// une vue longue plus onze fils à ne pas confondre, dans un remaniement qui ne doit RIEN changer.
///
/// Huit de ces onze ont donc un propriétaire — `MurDuClub` — et son en-tête dit pourquoi. Restent
/// les deux qui ne sont PAS du mur : `reportTarget` et `pendingBlock` sont posés aussi par le
/// classement et par la page du club, et les feuilles qui les lisent sont accrochées au corps de
/// `ClubView`, qui reste à l'écran quel que soit l'onglet. Ils passent en liaison, comme ils le
/// faisaient déjà vers `ClubBoardSection`.
///
/// Voir « Chantier 42 » dans `PROGRESS.md`.
struct ClubWallView: View {
    @Environment(AppState.self) private var appState

    let magasin: ClubStore
    @Bindable var mur: MurDuClub

    @Binding var reportTarget: ReportTarget?
    @Binding var pendingBlock: (userId: String, name: String)?
    /// Supprimer un message emporte ses réponses : il se confirme, comme la suppression d'une
    /// activité juste à côté. Il partait au premier appui dans le menu.
    @State private var messageASupprimer: ClubPost?

    private var auth: AuthService { appState.auth }

    var body: some View {
        LazyVStack(alignment: .leading, spacing: HZFil.ecartEntreSorties) {
            composeurDuMur
            if magasin.feed.isEmpty && magasin.posts.isEmpty && !magasin.isLoading {
                if magasin.seuleDansSonClub {
                    ClubAloneCard(magasin: magasin)
                } else {
                    HZPhrase(texte: Accord.selon(
                        f: String(localized: "Personne n'a encore rien posté. Sois la première !"),
                        m: String(localized: "Personne n'a encore rien posté. Sois le premier !")))
                }
            }
            ForEach(MurDuClub.entrees(sorties: magasin.feed, messages: magasin.posts), id: \.id) { entree in
                switch entree {
                case .sortie(let item):
                    FeedSortieView(
                        item: item,
                        estLaMienne: item.userId == auth.currentUser?.id,
                        applaudir: { Task { await magasin.toggleKudos(item) } },
                        commenter: { mur.commentsActivity = item },
                        modifier: { mur.editingActivity = item },
                        supprimer: { mur.pendingDeleteActivity = item },
                        signaler: {
                            reportTarget = ReportTarget(targetType: "activity", targetId: item.id, displayName: String(localized: "l'activité de \(item.nomComplet)"))
                        },
                        bloquer: { pendingBlock = (item.userId, item.name) })
                case .message(let post):
                    blocDeMessage(post)
                }
            }
        }
        .alert("Supprimer ce message ?",
               isPresented: Binding(get: { messageASupprimer != nil },
                                    set: { if !$0 { messageASupprimer = nil } })) {
            // Lu AVANT la fermeture de l'alerte, qui remet l'état à `nil`.
            Button("Supprimer", role: .destructive) {
                if let message = messageASupprimer { Task { await magasin.supprimerLeMessage(message) } }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Ses réponses partent avec lui.")
        }
    }

    private var composeurDuMur: some View {
        VStack(alignment: .leading, spacing: HZEspace.entrePilules) {
            if let reponseA = mur.reponseA {
                HStack(spacing: HZEspace.entrePilules) {
                    Text("Réponse à \(reponseA.author.nomComplet)")
                        .hzTexte(.c13, .semi)
                        .foregroundStyle(HZCouleur.secondaireSurClair)
                    Button(action: { mur.reponseA = nil }) {
                        HZIcone(dessin: .fermer, cote: HZHub.coteDeLaCroix, trait: HZHub.traitDeLaCroix,
                                couleur: HZCouleur.secondaireSurClair)
                            .frame(width: HZBoutonRond.zoneTactile, height: HZBoutonRond.zoneTactile)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Annuler la réponse")
                    Spacer(minLength: 0)
                }
            }
            HStack(spacing: HZEspace.entreCommandes) {
                TextField(text: $mur.brouillon,
                          prompt: Text(mur.reponseA == nil ? String(localized: "Dis quelque chose au club…")
                                                           : String(localized: "Ta réponse…"))
                              .foregroundStyle(HZCouleur.secondaireSurClair),
                          axis: .vertical) { EmptyView() }
                    .accessibilityLabel(String(localized: "Dis quelque chose au club…"))
                    .lineLimit(HZHub.lignesDuChamp)
                    .font(HZPolice.texte(.c15, .semi))
                    .foregroundStyle(HZCouleur.encre)
                    .padding(.horizontal, HZEspace.groupe)
                    .padding(.vertical, HZEspace.tuile)
                    .background(HZCouleur.surfaceClaire,
                                in: RoundedRectangle(cornerRadius: HZRayon.bandeau, style: .circular))
                Button(action: publier) {
                    HZIcone(dessin: .envoyer, cote: HZHub.coteDeLIcone, trait: HZHub.traitDeLIcone,
                            couleur: mur.peutPublier ? HZCouleur.encreSurAccent : HZCouleur.secondaireSurClair)
                        .frame(width: HZDiametre.outil.rawValue, height: HZDiametre.outil.rawValue)
                        .background(mur.peutPublier ? HZCouleur.accent : HZCouleur.surfaceClaire, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(!mur.peutPublier)
                .accessibilityLabel("Publier sur le mur du club")
            }
        }
    }

    private func publier() {
        guard mur.peutPublier else { return }
        mur.envoiEnCours = true
        Task {
            let parti = await magasin.publier(texte: mur.brouillon, enReponseA: mur.reponseA)
            mur.envoiEnCours = false
            if parti {
                mur.brouillon = ""
                mur.reponseA = nil
            }
        }
    }

    private func blocDeMessage(_ message: ClubPost) -> some View {
        HZPlaque {
            enTeteDeMessage(message)
            ForEach(MurDuClub.reponses(a: message, dans: magasin.posts)) { reponse in
                HStack(alignment: .top, spacing: HZEspace.entreCommandes) {
                    Rectangle().fill(HZCouleur.filetGroupe).frame(width: HZHub.traitDeLaCouronne)
                    enTeteDeMessage(reponse)
                }
                .padding(.leading, HZEspace.entreCommandes)
            }
            HStack(spacing: HZEspace.entreCommandes) {
                Button(action: { Task { await magasin.applaudirLeMessage(message) } }) {
                    HStack(spacing: HZBoutonPilule.ecart) {
                        HZIcone(dessin: .coeur, cote: HZFil.coteDuBravo,
                                couleur: message.kudoedByMe ? HZCouleur.accent : HZCouleur.encre)
                        if message.kudos > 0 {
                            Text("\(message.kudos)").hzTexte(.c14, .gras).foregroundStyle(HZCouleur.encre)
                        }
                    }
                    .padding(.horizontal, HZHauteurDeBouton.moyenne.marge)
                    .frame(height: HZHauteurDeBouton.moyenne.rawValue)
                    .background(HZCouleur.blanc, in: Capsule())
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(message.kudoedByMe ? "Retirer ton applaudissement" : "Applaudir ce message")

                Button(action: {
                    mur.reponseA = message
                    mur.brouillon = ""
                }) {
                    HStack(spacing: HZBoutonPilule.ecart) {
                        HZIcone(dessin: .bulle, cote: HZFil.coteDuBravo, couleur: HZCouleur.encre)
                        let compte = MurDuClub.reponses(a: message, dans: magasin.posts).count
                        if compte > 0 {
                            Text("\(compte)").hzTexte(.c14, .gras).foregroundStyle(HZCouleur.encre)
                        }
                    }
                    .padding(.horizontal, HZHauteurDeBouton.moyenne.marge)
                    .frame(height: HZHauteurDeBouton.moyenne.rawValue)
                    .background(HZCouleur.blanc, in: Capsule())
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "Répondre à \(message.author.name)"))
                Spacer(minLength: 0)
            }
        }
    }

    private func enTeteDeMessage(_ message: ClubPost) -> some View {
        VStack(alignment: .leading, spacing: HZEspace.entrePilules) {
            HStack(spacing: HZEspace.entrePilules) {
                Button(action: { if !message.isMine { appState.ouvrirLeProfil(message.author.id) } }) {
                    HStack(spacing: HZEspace.entreCommandes) {
                        HZPhotoDePersonne(urlString: message.author.avatarUrl,
                                          base64DataURI: message.author.avatarBase64,
                                          initiales: HZInitiales.de(message.author.name, message.author.lastName),
                                          cote: HZHub.avatarCompact)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(message.author.nomComplet)
                                .hzTexte(.c15, .gras)
                                .foregroundStyle(HZCouleur.encre)
                            Text(message.createdAt.relativeDescription)
                                .hzTexte(.c13, .medium)
                                .foregroundStyle(HZCouleur.secondaireSurClair)
                        }
                        .lineLimit(1)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Spacer(minLength: 0)
                Menu {
                    if message.isMine {
                        Button("Modifier ce message") { mur.messageEnModification = message }
                        Button("Supprimer ce message", role: .destructive) { messageASupprimer = message }
                    } else {
                        Button("Signaler ce message") {
                            reportTarget = ReportTarget(targetType: "club_post", targetId: message.id,
                                                        displayName: message.author.nomComplet)
                        }
                        Button("Bloquer \(message.author.name)", role: .destructive) {
                            pendingBlock = (message.author.id, message.author.name)
                        }
                    }
                } label: {
                    HZIcone(dessin: .options, cote: HZFil.coteDuBravo, couleur: HZCouleur.secondaireSurClair)
                        .frame(width: HZBoutonRond.zoneTactile, height: HZBoutonRond.zoneTactile)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Plus d'options")
            }
            Text(message.text)
                .hzParagraphe(.c15, .medium, interligne: HZBandeauDuCoach.interligne)
                .foregroundStyle(HZCouleur.encre)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
