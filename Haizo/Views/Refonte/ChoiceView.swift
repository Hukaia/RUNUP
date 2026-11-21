import SwiftUI
import SwiftData

/// Post-recovery choice: new goal or free-run mode. Mirrors `ChoiceView` in screensD.jsx.
/// Une page à feuille : le haut noir, puis le bilan du programme et les deux suites possibles.
struct ChoiceView: View {
    @Environment(AppState.self) private var appState
    @Query private var runs: [RunRecord]
    @State private var showNewGoal = false

    private var profile: UserProfile { appState.profile }

    private var totalKm: Int {
        // Just the run records — `profile.runValue` is today's km, already inside `runs`, so
        // adding it double-counted today's distance in the end-of-program bilan.
        Int(runs.onFoot.reduce(0) { $0 + $1.distanceKm })
    }

    var body: some View {
        HZPage {
            hautDePage
        } contenu: {
            feuille
        }
        .fullScreenCover(isPresented: $showNewGoal) {
            NewGoalWizardView()
        }
    }

    // MARK: - Le haut, sur le noir

    /// L'avatar est la SEULE porte vers le Profil : `.profile` n'est pas un onglet, et cet écran
    /// remplace tout l'accueil pendant la phase `.choice`. Sans lui, tant qu'un programme terminé
    /// attendait ce choix, Profil — donc les Réglages, le compte, les chaussures — était
    /// inatteignable depuis toute l'app.
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
            Text("Récupération terminée")
                .hzTexte(.c15, .semi)
                .foregroundStyle(HZCouleur.secondaireSurSombre)
                .padding(.horizontal, HZEspace.margeDeTitre)
                .padding(.top, HZObjectif.sousLeTitre)
            Text("Et maintenant ?")
                .hzAffichage(.titreDEcran)
                .foregroundStyle(HZCouleur.blanc)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, HZEspace.margeDeTitre)
        }
    }

    // MARK: - La feuille

    private var feuille: some View {
        VStack(alignment: .leading, spacing: HZEspace.entreSections) {
            bilan
            VStack(spacing: HZEntree.ecartDesReponses) {
                HZReponse(titre: String(localized: "Se fixer un nouvel objectif"),
                          precision: String(localized: "Une nouvelle course, progresser encore, perdre du poids…")) {
                    showNewGoal = true
                }
                HZReponse(titre: String(localized: "Mode course libre"),
                          precision: String(localized: "Pas d'objectif précis : on te propose juste de quoi garder la forme.")) {
                    AdaptivePlanEngine.chooseFreeRun(profile)
                    appState.toast(String(localized: "Mode course libre activé"))
                    appState.go(.home)
                }
            }
        }
    }

    private var bilan: some View {
        VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
            HZTitreDeSection(titre: String(localized: "Bilan de ton programme"))
            VStack(spacing: 0) {
                ligneDeBilan(libelle: String(localized: "km parcourus"), valeur: "\(totalKm)")
                // Deux clés entières plutôt qu'un « s » recollé : le pluriel ne se fabrique
                // pas de la même façon dans les trois langues.
                ligneDeBilan(libelle: Pluriel.choisir(profile.weekNumber,
                                                      String(localized: "semaine"),
                                                      String(localized: "semaines")),
                             valeur: "\(profile.weekNumber)")
                ligneDeBilan(libelle: Pluriel.choisir(profile.streak,
                                                      String(localized: "jour de série"),
                                                      String(localized: "jours de série")),
                             valeur: "\(profile.streak)", filet: false)
            }
        }
    }

    private func ligneDeBilan(libelle: String, valeur: String, filet: Bool = true) -> some View {
        HZLigneDeListe(titre: libelle, filet: filet) {
            EmptyView()
        } queue: {
            Text(verbatim: valeur)
                .hzAffichage(.chiffreDeLigne)
                .foregroundStyle(HZCouleur.encre)
                .lineLimit(1)
        }
    }
}
