import SwiftUI

/// « Ce téléphone contient les données de quelqu'un d'autre. »
///
/// Elle s'affiche quand un compte se connecte sur un appareil dont le profil appartient à un autre
/// compte. Elle bloque tout : il n'y a pas de bonne façon de continuer sans avoir demandé.
///
/// Effacer d'office détruirait le programme de quelqu'un qui s'est simplement trompé de compte à
/// la connexion. Ne rien faire montrerait le nom, la photo et l'entraînement d'une personne à une
/// autre. Les deux valent moins que la question — d'où cette feuille, qu'on ne peut ni glisser ni
/// contourner, et dont les deux issues sont écrites en clair.
struct AccountSwitchSheet: View {
    @Environment(AppState.self) private var appState
    @State private var confirming = false

    var body: some View {
        // Fermer, ici, c'est répondre « ce n'est pas le bon compte » : la feuille ne se ferme
        // jamais en laissant le profil d'un autre à l'écran. C'est l'issue qui ne détruit rien.
        HZFeuilleModale(titre: String(localized: "Ces données ne sont pas les tiennes"),
                        fermer: { appState.cancelAccountSwitch() }) {
            ScrollView {
                VStack(alignment: .leading, spacing: HZEspace.groupe) {
                    corps
                    avertissement
                    reponses
                }
                .padding(.horizontal, HZEspace.marge)
            }
            .scrollIndicators(.hidden)
        }
        // LA SEULE ACTION DESTRUCTRICE DE L'APP QUI N'EN AVAIT PAS. Supprimer une course en a
        // une, une paire de chaussures en a une, effacer la conversation du coach en a une — et
        // celle-ci efface les trois à la fois.
        .confirmationDialog(
            Text("Effacer le programme et l'historique de \(appState.profile.nomComplet) ?"),
            isPresented: $confirming, titleVisibility: .visible
        ) {
            Button("Tout effacer", role: .destructive) { appState.startFreshForNewAccount() }
            Button("Annuler", role: .cancel) { }
        } message: {
            Text("Cette action est définitive.")
        }
        .interactiveDismissDisabled()
    }

    /// Le nom du profil local, pas celui du compte qui arrive : c'est lui qui est à l'écran en ce
    /// moment, et c'est de lui qu'on parle.
    private var corps: some View {
        Text("Ce téléphone contient le profil de \(appState.profile.nomComplet) — son programme, son historique et ses réglages. Tu viens de te connecter avec un autre compte.")
            .hzParagraphe(.c15, .medium, interligne: HZBandeauDuCoach.interligne)
            .foregroundStyle(HZCouleur.encre)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// AVANT LE GESTE, POUR DE BON : la phrase qui nomme ce qu'on détruit est au-dessus des
    /// boutons, pas dessous.
    private var avertissement: some View {
        Text("Repartir à neuf efface le programme, l'historique des courses et la conversation avec le coach enregistrés sur cet appareil. Ce qui appartient au Club — les sorties publiées, les kilomètres du club — reste sur le compte de chacune.")
            .hzParagraphe(.c14, .medium, interligne: HZBandeauDuCoach.interligne)
            .foregroundStyle(HZCouleur.secondaireSurClair)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var reponses: some View {
        VStack(spacing: HZEspace.entreCommandes) {
            HZBoutonPilule(libelle: String(localized: "Repartir à neuf"), etendu: true) {
                confirming = true
            }
            HZBoutonPilule(libelle: String(localized: "Ce n'est pas le bon compte"),
                           fond: HZCouleur.surfaceClaire, couleur: HZCouleur.encre, etendu: true) {
                appState.cancelAccountSwitch()
            }
        }
        .padding(.top, HZEspace.entrePilules)
    }
}
