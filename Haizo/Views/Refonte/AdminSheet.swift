import SwiftUI

/// La fiche de la maison.
///
/// # À QUOI ELLE SERT, ET À QUOI ELLE NE SERT PAS
///
/// Elle ne commande RIEN. Pas un interrupteur, pas un bouton qui accorde un droit : tout ce
/// qu'on pourrait y actionner serait, par construction, une chose que l'app s'accorde à
/// elle-même. Le droit est décidé par le serveur, à partir d'une liste qui vit dans son
/// environnement — voir `lib/admin.js`.
///
/// Elle RÉPOND. À une question précise, et c'est celle qu'on se pose quand ça ne marche pas :
/// « sous quelle adresse suis-je connectée ? » Parce que « Se connecter avec Apple » peut créer
/// un compte sous un `…@privaterelay.appleid.com` que personne ne devine, et qu'on peut avoir
/// deux comptes sans le savoir — un par mot de passe sur un appareil, un par Apple sur l'autre.
/// Hukaia a passé une mise à jour entière à chercher ça : le péage s'y était refermé sur la
/// personne qui avait écrit l'app, parce que son iPhone s'était connecté sous une autre adresse.
///
/// Et elle distingue les deux pannes qui se ressemblent : « tu n'es pas dans la liste » et « il
/// n'y a pas de liste ». La première se corrige en ajoutant une adresse, la seconde en créant la
/// variable. Sans cette distinction on essaie la première pendant une heure.
struct AdminSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(SubscriptionService.self) private var subscriptions

    private var compte: AuthenticatedUser? { appState.auth.currentUser }

    var body: some View {
        HZFeuilleModale(titre: String(localized: "Fiche admin")) {
            ScrollView {
                VStack(alignment: .leading, spacing: HZEspace.entreSections) {
                    etat

                    HZGroupeDeReglages(titre: String(localized: "Le compte connecté")) {
                        ligneDeFiche(String(localized: "Adresse"),
                                     compte?.email ?? String(localized: "inconnue du serveur"))
                        ligneDeFiche(String(localized: "Nom"), compte?.name ?? "—")
                        ligneDeFiche(String(localized: "Identifiant"), compte?.id ?? "—", filet: false)
                    }

                    HZGroupeDeReglages(titre: String(localized: "Les droits")) {
                        ligneDeFiche(String(localized: "Compte de la maison"), oui(compte?.isAdmin == true))
                        ligneDeFiche(String(localized: "Liste configurée côté serveur"),
                                     oui(compte?.adminListConfigured == true))
                        ligneDeFiche(String(localized: "Abonnement App Store"), abonnement)
                        ligneDeFiche(String(localized: "Plan complet ouvert"),
                                     oui(subscriptions.unlocks(.raceGoal)), filet: false)
                    }

                    HZGroupeDeReglages(titre: String(localized: "Cette installation")) {
                        ligneDeFiche(String(localized: "Version"), "\(version) (\(build))")
                        ligneDeFiche(String(localized: "Serveur"), AuthService.hoteDuServeur, filet: false)
                    }

                    Text("Cette fiche ne commande rien : elle montre ce que le serveur répond. Un droit qu'on pourrait s'accorder depuis l'app ne serait pas un droit, ce serait un interrupteur.")
                        .hzParagraphe(.c13, .medium, interligne: HZReglages.interligne)
                        .foregroundStyle(HZCouleur.secondaireSurClair)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, HZEspace.marge)
            }
            .scrollIndicators(.hidden)
        }
    }

    /// La phrase d'en-tête, qui dit QUOI FAIRE plutôt que ce qui ne va pas.
    ///
    /// Trois états, et trois conduites différentes. C'est tout l'intérêt de distinguer « pas de
    /// liste » de « pas dedans » : la première se répare dans les réglages de Vercel, la seconde
    /// en ajoutant une ligne à une liste qui existe déjà.
    @ViewBuilder private var etat: some View {
        if compte == nil {
            encart(String(localized: "Pas de compte connecté sur cet appareil. Les droits de la maison suivent le compte, pas le téléphone."))
        } else if compte?.isAdmin == true {
            encart(String(localized: "Compte de la maison reconnu. Le plan complet est ouvert, sans abonnement."))
        } else if compte?.adminListConfigured == false {
            encart(String(localized: "Aucune liste de comptes de la maison côté serveur. Crée la variable d'environnement RUNUP_ADMIN_EMAILS sur Vercel, avec l'adresse affichée ci-dessous, puis redéploie."))
        } else {
            encart(String(localized: "Cette adresse n'est pas dans la liste des comptes de la maison. Ajoute celle affichée ci-dessous à RUNUP_ADMIN_EMAILS sur Vercel. C'est la seule que le serveur reconnaîtra."))
        }
    }

    private func encart(_ texte: String) -> some View {
        HZPlaque {
            Text(texte)
                .hzParagraphe(.c14, .semi, interligne: HZBandeauDuCoach.interligne)
                .foregroundStyle(HZCouleur.encre)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Une ligne de la fiche : son nom en gris, sa valeur dessous, sur autant de lignes qu'il faut.
    /// Une adresse ou un identifiant ne tiennent pas en bout de ligne, et une valeur coupée ne
    /// servirait à rien : on vient ici pour la recopier.
    ///
    /// `Text(verbatim:)` : ces valeurs viennent du serveur ou du bundle, elles sont déjà ce
    /// qu'elles sont. Les repasser au catalogue chercherait une clé qui n'existe pas.
    private func ligneDeFiche(_ titre: String, _ valeur: String, filet: Bool = true) -> some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: HZReglages.entreTitreEtPrecision) {
                Text(titre)
                    .hzTexte(.c13, .semi)
                    .foregroundStyle(HZCouleur.secondaireSurClair)
                Text(verbatim: valeur)
                    .hzParagraphe(.c15, .semi, interligne: HZReglages.interligne)
                    .foregroundStyle(HZCouleur.encre)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, HZReglages.margeDUneLigneALaPrecision)
            .frame(maxWidth: .infinity, alignment: .leading)
            if filet {
                Rectangle()
                    .fill(HZCouleur.filetGroupe)
                    .frame(height: HZMesuresDeLigne.filet)
            }
        }
    }

    private func oui(_ valeur: Bool) -> String {
        valeur ? String(localized: "oui") : String(localized: "non")
    }

    private var abonnement: String {
        switch subscriptions.isSubscribed {
        case true: return String(localized: "actif")
        case false: return String(localized: "aucun")
        default: return String(localized: "pas encore vérifié")
        }
    }

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    }

    private var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
    }
}
