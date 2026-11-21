import SwiftUI

/// Post-program recovery tracker — mirrors `RecoveryView` in screensD.jsx.
/// Une page à feuille : le haut noir dit « Bravo », la feuille dit où en est la récupération.
struct RecoveryView: View {
    @Environment(AppState.self) private var appState
    private var profile: UserProfile { appState.profile }

    private var total: Int { profile.goalId.recoveryDays }
    private var done: Int { total - profile.recoveryDaysLeft }

    var body: some View {
        HZPage {
            hautDePage
        } contenu: {
            feuille
        }
        .onAppear { Haptics.success() }
    }

    // MARK: - Le haut, sur le noir

    private var hautDePage: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer(minLength: 0)
                HZAvatar(initiales: HZAvatar.initiales(prenom: profile.name, nom: profile.lastName),
                         nom: String(localized: "Profil")) {
                    appState.go(.profile)
                }
            }
            .padding(.horizontal, HZEspace.marge)
            Text("Programme terminé")
                .hzTexte(.c15, .semi)
                .foregroundStyle(HZCouleur.secondaireSurSombre)
                .padding(.horizontal, HZEspace.margeDeTitre)
                .padding(.top, HZObjectif.sousLeTitre)
            Text(String(localized: "Bravo \(profile.name)"))
                .hzAffichage(.titreDEcran)
                .foregroundStyle(HZCouleur.blanc)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, HZEspace.margeDeTitre)
        }
    }

    // MARK: - La feuille

    private var feuille: some View {
        VStack(alignment: .leading, spacing: HZEspace.entreSections) {
            HZPhrase(texte: String(localized: "Ton corps a fait le plus dur. On souffle \(total) jours avant de repartir : c'est ce qui fait tenir les progrès dans la durée."),
                     titre: String(localized: "Place à la récupération"))
            jours
            aujourdhui
            suite
        }
    }

    /// Un carré par jour de récupération : noir une fois passé, gris tant qu'il reste. Le décompte
    /// est dit en toutes lettres juste dessous, donc la rangée elle-même est muette pour VoiceOver.
    private var jours: some View {
        HStack(spacing: HZEspace.entrePilules) {
            ForEach(0..<total, id: \.self) { i in
                pastille(i)
            }
        }
        .accessibilityHidden(true)
    }

    private func pastille(_ i: Int) -> some View {
        ZStack {
            if i < done {
                HZIcone(dessin: .coche, cote: HZHub.coteDeLIcone, trait: HZHub.traitDeLIcone,
                        couleur: HZCouleur.blanc)
            } else {
                Text(verbatim: "\(i + 1)")
                    .hzTexte(.c14, .gras, tabulaire: true)
                    .foregroundStyle(HZCouleur.secondaireSurClair)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: HZDiametre.pas.rawValue)
        .background(i < done ? HZCouleur.encre : HZCouleur.surfaceClaire,
                    in: RoundedRectangle(cornerRadius: HZRayon.vignette, style: .circular))
    }

    private var aujourdhui: some View {
        HZPlaque {
            Text("Aujourd'hui")
                .hzTexte(.c13, .semi)
                .foregroundStyle(HZCouleur.secondaireSurClair)
            Text("Marche, étirements ou repos complet")
                .hzParagraphe(.c16, .gras, interligne: HZBandeauDuCoach.interligne)
                .foregroundStyle(HZCouleur.encre)
                .fixedSize(horizontal: false, vertical: true)
            Text("Pas de course prévue. Hydrate-toi bien et dors un peu plus si tu peux.")
                .hzParagraphe(.c14, .medium, interligne: HZBandeauDuCoach.interligne)
                .foregroundStyle(HZCouleur.secondaireSurClair)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Days now tick with the real calendar (see `refreshProgramForCurrentDate`) — no
    /// more tap-to-advance. What remains is an honest, explicit early exit.
    @ViewBuilder private var suite: some View {
        if profile.recoveryDaysLeft > 0 {
            VStack(spacing: HZEspace.groupe) {
                Text("Jour \(done + 1) sur \(total). La suite se débloque demain.")
                    .hzParagraphe(.c14, .medium, interligne: HZBandeauDuCoach.interligne)
                    .foregroundStyle(HZCouleur.secondaireSurClair)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                HZBoutonPilule(libelle: String(localized: "Passer la récupération"),
                               fond: HZCouleur.surfaceClaire, couleur: HZCouleur.encre, etendu: true) {
                    AdaptivePlanEngine.skipRecovery(profile)
                }
            }
        } else {
            HZBoutonPilule(libelle: Accord.selon(f: String(localized: "Je suis prête"),
                                                 m: String(localized: "Je suis prêt")),
                           etendu: true) {
                AdaptivePlanEngine.skipRecovery(profile)
            }
        }
    }
}
