import SwiftUI

/// MOT DE PASSE OUBLIÉ : une adresse, un code reçu par courriel, un nouveau mot de passe.
///
/// Un compte créé avec une adresse et un mot de passe n'avait aucune issue quand le mot de passe
/// était perdu : l'écran de connexion répondait « Email ou mot de passe incorrect », et rien d'autre.
///
/// DEUX TEMPS, DANS LA MÊME FEUILLE :
///   1. l'adresse, et « Recevoir un code » ;
///   2. le code à six chiffres et le nouveau mot de passe. Le bon code connecte : on vient de
///      prouver qu'on tient la boîte de réception.
///
/// L'ÉCRAN NE DIT JAMAIS SI L'ADRESSE A UN COMPTE. Le serveur répond pareil dans les deux cas
/// (`api/auth/requestReset`), sans quoi cette feuille servirait d'annuaire. La phrase du second
/// temps est donc conditionnelle, et c'est voulu.
struct MotDePasseOublieSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    /// L'adresse déjà tapée sur l'écran de connexion, pour ne pas la redemander.
    let adresseInitiale: String
    /// Le mot de passe est changé et la session ouverte : l'écran de connexion reprend la main.
    let onConnecte: () -> Void

    @State private var adresse = ""
    @State private var code = ""
    @State private var motDePasse = ""
    @State private var codeDemande = false
    @State private var enCours = false
    @State private var avis: String?

    private var adresseValide: Bool {
        adresse.range(of: #"^\S+@\S+\.\S+$"#, options: .regularExpression) != nil
    }

    private var codeComplet: Bool {
        code.filter(\.isNumber).count == HZHub.chiffresDuCodeDeReinitialisation
    }

    private var peutChanger: Bool {
        codeComplet && motDePasse.count >= HZHub.longueurDuMotDePasse && !enCours
    }

    var body: some View {
        HZFeuilleModale(titre: String(localized: "Mot de passe oublié")) {
            ScrollView {
                VStack(alignment: .leading, spacing: HZEspace.groupe) {
                    if codeDemande { saisieDuCode } else { demandeDuCode }
                    if let avis { HZAvisDeFeuille(texte: avis) }
                }
                .padding(.horizontal, HZEspace.marge)
            }
            .scrollIndicators(.hidden)
            .disabled(enCours)
        }
        .onAppear { if adresse.isEmpty { adresse = adresseInitiale } }
    }

    // MARK: - Premier temps : l'adresse

    @ViewBuilder private var demandeDuCode: some View {
        HZPhrase(texte: String(localized: "Donne l'adresse de ton compte. On t'y envoie un code à six chiffres pour choisir un nouveau mot de passe."))
        HZChampDeTexte(titre: String(localized: "Email"), invite: String(localized: "prenom@exemple.com"),
                       texte: $adresse, clavier: .emailAddress, majuscules: .never, contenu: .emailAddress)
        HZBoutonPilule(libelle: enCours ? "…" : String(localized: "Recevoir un code"),
                       fond: adresseValide ? HZCouleur.encre : HZCouleur.filetGroupe,
                       couleur: adresseValide ? HZCouleur.blanc : HZCouleur.secondaireSurClair,
                       etendu: true) { Task { await demander() } }
            .disabled(!adresseValide || enCours)
    }

    // MARK: - Second temps : le code et le nouveau mot de passe

    @ViewBuilder private var saisieDuCode: some View {
        HZPhrase(texte: String(localized: "Si un compte avec mot de passe existe pour \(adresse), un code à six chiffres vient d'y être envoyé. Il est valable 15 minutes. Pense à regarder dans les indésirables."))
        HZChampDeTexte(titre: String(localized: "Code reçu"), invite: String(localized: "6 chiffres"),
                       texte: $code, clavier: .numberPad, majuscules: .never, contenu: .oneTimeCode)
        HZChampDeTexte(titre: String(localized: "Nouveau mot de passe"), invite: String(localized: "8 caractères minimum"),
                       texte: $motDePasse, securise: true, contenu: .newPassword)
        HZBoutonPilule(libelle: enCours ? "…" : String(localized: "Changer mon mot de passe"),
                       fond: peutChanger ? HZCouleur.encre : HZCouleur.filetGroupe,
                       couleur: peutChanger ? HZCouleur.blanc : HZCouleur.secondaireSurClair,
                       etendu: true) { Task { await changer() } }
            .disabled(!peutChanger)
        Button("Recevoir un nouveau code") {
            code = ""
            avis = nil
            Task { await demander() }
        }
        .hzTexte(.c14, .semi)
        .foregroundStyle(HZCouleur.secondaireSurClair)
        .frame(maxWidth: .infinity, minHeight: HZBoutonRond.zoneTactile)
        .contentShape(Rectangle())
        .buttonStyle(.plain)
    }

    // MARK: - Les deux appels

    private func demander() async {
        let cible = adresse.trimmingCharacters(in: .whitespaces)
        enCours = true
        avis = nil
        defer { enCours = false }
        do {
            try await appState.auth.requestPasswordReset(email: cible)
            codeDemande = true
        } catch AuthServiceError.badResponse(let statut, _) where statut == HZHub.serviceIndisponible {
            // Le serveur ne sait pas encore envoyer de courriel : on le dit, avec l'issue qui reste.
            avis = String(localized: "L'envoi du code n'est pas encore disponible. Écris-nous à \(Liens.adresseDeContact) et on règle ça avec toi.")
        } catch AuthServiceError.badResponse(let statut, _) where statut == HZHub.tropDeDemandes {
            avis = String(localized: "Trop de demandes aujourd'hui. Réessaie demain.")
        } catch {
            avis = PanneReseau.phrase(pour: error)
        }
    }

    private func changer() async {
        let cible = adresse.trimmingCharacters(in: .whitespaces)
        enCours = true
        avis = nil
        defer { enCours = false }
        do {
            try await appState.auth.resetPassword(email: cible, code: code, password: motDePasse)
            appState.toast(String(localized: "Mot de passe changé"))
            dismiss()
            onConnecte()
        } catch AuthServiceError.badResponse(_, let corps) where corps.contains("expired_code") {
            avis = String(localized: "Ce code a expiré. Demande-en un nouveau.")
        } catch AuthServiceError.badResponse(_, let corps) where corps.contains("code_locked") {
            avis = String(localized: "Trop d'essais sur ce code. Demande-en un nouveau.")
        } catch AuthServiceError.badResponse(_, let corps) where corps.contains("invalid_code") {
            avis = String(localized: "Ce code n'est pas le bon. Vérifie les six chiffres.")
        } catch AuthServiceError.badResponse(_, let corps) where corps.contains("weak_password") {
            avis = String(localized: "8 caractères minimum.")
        } catch AuthServiceError.badResponse(let statut, _) where statut == HZHub.tropDeDemandes {
            avis = String(localized: "Trop d'essais aujourd'hui. Réessaie demain.")
        } catch {
            avis = PanneReseau.phrase(pour: error)
        }
    }
}
