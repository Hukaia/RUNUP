import SwiftUI

/// REPRENDRE CE QU'ON A ÉCRIT.
///
/// # POURQUOI UNE SEULE FEUILLE POUR DEUX MURS
///
/// Un message du mur d'un club et une annonce sur une page de course sont, du point de vue de
/// qui les corrige, exactement la même chose : un bloc de texte qu'on a publié et dans lequel il
/// y a une faute, un horaire qui a changé, une phrase qu'on regrette. Deux feuilles auraient été
/// la copie l'une de l'autre — donc l'endroit où une amélioration ne serait faite qu'une fois.
///
/// Ce qui diffère entre les deux appels — le titre, la borne de longueur, l'appel réseau — passe
/// en paramètres. Le reste est identique parce qu'il DOIT l'être.
///
/// # CE QU'ELLE NE FAIT PAS
///
/// Elle ne supprime pas. Effacer et réécrire sont deux gestes dont l'un est irréversible ; les
/// mettre dans la même feuille, c'est poser un bouton rouge sous les doigts de quelqu'un qui
/// voulait corriger une virgule. La suppression reste dans le menu, avec sa confirmation.
struct EditTextPostSheet: View {
    @Environment(\.dismiss) private var dismiss

    var titreDeLaFeuille: String
    var texteInitial: String
    /// 500 côté serveur pour les deux murs. Recopié ici pour que la limite se voie AVANT l'envoi
    /// plutôt que sous la forme d'un texte tronqué après coup.
    var longueurMax: Int = HZFeuillesDuFil.longueurDUnTexte
    var onSave: (String) async throws -> Void

    @State private var texte = ""
    @State private var prerempli = false
    @State private var enCours = false
    @State private var errorMessage: String?

    private var propre: String { texte.trimmingCharacters(in: .whitespacesAndNewlines) }
    /// Rien à enregistrer si le texte est vide — ou s'il n'a pas changé : un bouton actif qui
    /// déclenche un aller-retour réseau pour réécrire la même chose est un bouton qui ment.
    private var peutEnregistrer: Bool {
        !propre.isEmpty && propre != texteInitial.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var peutValider: Bool {
        peutEnregistrer && propre.count <= longueurMax && !enCours
    }

    var body: some View {
        HZFeuilleModale(titre: titreDeLaFeuille) {
            ScrollView {
                VStack(alignment: .leading, spacing: HZEspace.entreCommandes) {
                    // Une seule fois : `onAppear` repart à chaque retour de premier plan, et prendre un
                    // appel au milieu d'une correction effacerait ce qui vient d'être tapé.
                    HZChampDeTexte(titre: String(localized: "Message"), invite: "", texte: $texte,
                                   lignes: HZFeuillesDuFil.lignesDUneAnnonce)
                        .onAppear {
                            guard !prerempli else { return }
                            prerempli = true
                            texte = texteInitial
                        }

                    // Le compteur n'apparaît qu'à l'approche de la borne. Affiché en permanence,
                    // il transforme un champ libre en exercice de concision pour des messages
                    // qui font trois lignes.
                    if propre.count > longueurMax - HZFeuillesDuFil.margeDuCompteur {
                        Text(verbatim: "\(propre.count) / \(longueurMax)")
                            .hzTexte(.c13, .gras, tabulaire: true)
                            .foregroundStyle(propre.count > longueurMax ? HZCouleur.encre : HZCouleur.secondaireSurClair)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }

                    if let errorMessage {
                        HZAvisDeFeuille(texte: errorMessage)
                    }
                }
                .padding(.horizontal, HZEspace.marge)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                HZBasDeFeuille {
                    HZBoutonPilule(libelle: String(localized: "Enregistrer"), etendu: true) {
                        Task { await enregistrer() }
                    }
                    .opacity(peutValider ? HZHub.opaciteNormale : HZHub.opaciteEteinte)
                    .disabled(!peutValider)
                }
            }
        }
    }

    private func enregistrer() async {
        enCours = true
        errorMessage = nil
        do {
            try await onSave(propre)
            Haptics.success()
            dismiss()
        } catch ClubServiceError.badResponse(let code, _) where code == HZHub.refuse {
            errorMessage = String(localized: "Ce texte n'est pas autorisé — reformule.")
        } catch {
            errorMessage = String(localized: "Impossible d'enregistrer, réessaie.")
        }
        enCours = false
    }
}
