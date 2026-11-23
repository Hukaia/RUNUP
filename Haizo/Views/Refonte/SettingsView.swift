import SwiftUI
import SwiftData
import UIKit

/// LES RÉGLAGES, refaits d'après le canvas « Réglages » : une page blanche, la carte d'offre en noir,
/// puis des groupes sur la surface claire (apparence, sources, préférences, objectifs, compte).
///
/// Ils s'ouvrent en feuille depuis le profil, comme avant, et ne perdent aucun réglage : les mêmes
/// valeurs, écrites aux mêmes endroits. Ce qui change est ce qu'on voit.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    private var profile: UserProfile { appState.profile }

    @State private var showMoreSettings = false
    @State private var showPaywall = false
    @Environment(SubscriptionService.self) private var subscriptions

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HZReglages.sousLeTitre) {
                entete
                HZCarteDOffre(
                    etat: subscriptions.isSubscribed == true
                        ? String(localized: "Abonnement actif") : String(localized: "Abonnement inactif"),
                    titre: String(localized: "Haizo Plus"),
                    bouton: String(localized: "Voir l'offre")) { showPaywall = true }
                    .padding(.top, HZReglages.sousLeTitreDePage - HZReglages.sousLeTitre)

                apparence
                sources
                preferences
                objectifs
                compte
            }
            .padding(.horizontal, HZEspace.marge)
            .padding(.top, HZReglages.hautDeFeuille)
            .padding(.bottom, HZReglages.basDePage)
        }
        .scrollIndicators(.hidden)
        .background(HZCouleur.blanc)
        .sheet(isPresented: $showMoreSettings) {
            MoreSettingsView()
                .hzFeuille(detents: [.large])
        }
        // Le bloc du cycle n'est pas dans CETTE feuille : il est derrière « Plus de réglages ».
        #if DEBUG
        .onAppear {
            if CaptureSeed.plusDeReglagesDemandes { showMoreSettings = true }
        }
        #endif
        .sheet(isPresented: $showPaywall) {
            PaywallView(subscriptions: subscriptions, onClose: { showPaywall = false })
                .hzFeuille(detents: [.large], gereSonBas: true)
        }
    }

    private var entete: some View {
        HStack {
            Text("Réglages")
                .hzAffichage(.titreDeReglages)
                .foregroundStyle(HZCouleur.encre)
            Spacer(minLength: 0)
            HZBoutonRond(dessin: .fermer, nom: String(localized: "Fermer"), diametre: .outil,
                         fond: HZCouleur.surfaceClaire, couleur: HZCouleur.encre) { dismiss() }
        }
    }

    // MARK: - Apparence

    private var apparence: some View {
        HZGroupeDeReglages(titre: String(localized: "Apparence")) {
            HZLigneDeReglage(titre: String(localized: "Mode")) {
                HZChoixADeux(premier: String(localized: "Clair"), second: String(localized: "Sombre"),
                             premierChoisi: profile.isLightMode) { selectMode(isLight: $0) }
            }
            HZLigneDeReglage(titre: String(localized: "Couleur"), filet: false) {
                HStack(spacing: HZReglages.ecartDePastilles) {
                    ForEach(HZAccent.allCases) { accent in
                        HZPastilleDeCouleur(couleur: accent.couleur,
                                            nom: accent.nom,
                                            choisie: HZAccent.courant == accent) {
                            selectAccent(accent)
                        }
                    }
                }
            }
        }
    }

    private func selectMode(isLight: Bool) {
        profile.isLightMode = isLight
        ThemeStore.shared.appliquer(isLightMode: isLight)
        appState.publishWidgetSnapshot()
    }

    /// Le choix s'écrit sous l'identifiant de l'ancien thème de même nom : `HZAccent` lit
    /// `ThemeStore`, et la sauvegarde comme le widget lisent l'identifiant.
    private func selectAccent(_ accent: HZAccent) {
        profile.accentThemeID = accent.rawValue
        ThemeStore.shared.appliquer(themeID: accent.rawValue)
        Haptics.selection()
        appState.publishWidgetSnapshot()
    }

    // MARK: - Sources de données

    /// Apple Santé seulement : les lignes Strava et Garmin sont retirées tant que ces intégrations
    /// ne fonctionnent pas (aucune mention visible d'un service qui ne l'est pas).
    private var sources: some View {
        HZGroupeDeReglages(titre: String(localized: "Sources de données")) {
            HZLigneDeReglage(titre: ConnectedSource.apple.title, filet: false) {
                Toggle("", isOn: santeConnectee)
                    .labelsHidden()
                    .toggleStyle(HZStyleDInterrupteur())
                    .accessibilityLabel("Synchroniser avec Apple Santé")
            }
        }
    }

    private var santeConnectee: Binding<Bool> {
        Binding(
            get: { profile.connectedSources.contains(.apple) },
            set: { on in
                if on {
                    profile.connectedSources.append(.apple)
                    // Une vraie panne (HealthKit indisponible) ne doit pas laisser « Apple Santé »
                    // marquée connectée en silence.
                    Task {
                        do {
                            try await appState.healthKit.requestAuthorization()
                        } catch {
                            await MainActor.run {
                                profile.connectedSources.removeAll { $0 == .apple }
                                appState.toast(String(localized: "Connexion à Apple Santé impossible, réessaie plus tard."))
                            }
                        }
                    }
                } else {
                    profile.connectedSources.removeAll { $0 == .apple }
                }
            })
    }

    // MARK: - Préférences

    private var preferences: some View {
        HZGroupeDeReglages(titre: String(localized: "Préférences")) {
            HZLigneDeReglage(titre: String(localized: "Notifications du coach")) {
                Toggle("", isOn: notificationsDuCoach)
                    .labelsHidden()
                    .toggleStyle(HZStyleDInterrupteur())
                    .accessibilityLabel("Notifications du coach")
            }
            HZLigneDeReglage(
                titre: String(localized: "Prévenir s'il va pleuvoir"),
                precision: String(localized: "Quand ton créneau habituel tombe sous l'averse et qu'un autre moment de la journée est au sec."),
                filet: false) {
                Toggle("", isOn: alertesDePluie)
                    .labelsHidden()
                    .toggleStyle(HZStyleDInterrupteur())
                    .accessibilityLabel("Prévenir s'il va pleuvoir")
            }
            // ATTRIBUTION EXIGÉE PAR APPLE, pas une politesse : les conditions de WeatherKit imposent
            // la marque « Apple Weather » et un lien vers la page des sources partout où la donnée
            // météo est utilisée. L'omettre est un motif de retour de revue.
            Link(destination: URL(string: "https://weatherkit.apple.com/legal-attribution.html")!) {
                Text("Météo  Apple Weather")
                    .hzTexte(.c12, .medium)
                    .foregroundStyle(HZCouleur.secondaireSurClair)
                    .frame(minHeight: HZBoutonRond.zoneTactile, alignment: .leading)
            }
        }
    }

    /// Même règle que « Notifications du coach » juste en dessous : sans l'autorisation du système
    /// l'alerte de pluie ne peut pas partir (`WeatherAdviceService` s'arrête en silence), donc
    /// l'interrupteur ne reste pas allumé sur une promesse qu'il ne tiendra pas.
    private var alertesDePluie: Binding<Bool> {
        Binding(
            get: { profile.weatherAlertsEnabled },
            set: { on in
                profile.weatherAlertsEnabled = on
                guard on else { return }
                Task {
                    let accordees = await NotificationService.shared.requestAuthorization()
                    if !accordees {
                        await MainActor.run {
                            profile.weatherAlertsEnabled = false
                            appState.toast(String(localized: "Notifications refusées côté iPhone : active-les dans Réglages > Haizo."))
                        }
                    }
                }
            })
    }

    private var notificationsDuCoach: Binding<Bool> {
        Binding(
            get: { profile.coachNotificationsEnabled },
            set: { on in
                profile.coachNotificationsEnabled = on
                if on {
                    Task {
                        // L'autorisation du système était ignorée : refusée, l'interrupteur restait
                        // allumé pendant que chaque programmation ne faisait rien. On reflète la
                        // réalité : il revient en arrière, et on renvoie aux Réglages de l'iPhone.
                        let granted = await NotificationService.shared.requestAuthorization()
                        if granted {
                            NotificationService.shared.rescheduleDailyReminder(for: profile)
                            NotificationService.shared.rescheduleInactivityReminder(for: profile)
                            NotificationService.shared.scheduleWeeklyRecapReminder(for: profile)
                        } else {
                            await MainActor.run {
                                profile.coachNotificationsEnabled = false
                                appState.toast(String(localized: "Notifications refusées côté iPhone : active-les dans Réglages > Haizo."))
                            }
                        }
                    }
                } else {
                    NotificationService.shared.cancelDailyReminder()
                    NotificationService.shared.cancelInactivityReminder()
                    NotificationService.shared.cancelWeeklyRecapReminder()
                }
            })
    }

    // MARK: - Objectifs quotidiens

    /// Les deux objectifs pilotent les barres de l'accueil : les modifier change aussitôt ce qui
    /// compte comme « fait » aujourd'hui.
    private var objectifs: some View {
        HZGroupeDeReglages(titre: String(localized: "Objectifs quotidiens")) {
            HZLigneDeReglage(titre: String(localized: "Pas")) {
                HZCompteur(valeur: Int(profile.stepsGoal).formatted(),
                           nomDuMoins: String(localized: "Moins de pas"), nomDuPlus: String(localized: "Plus de pas"),
                           moins: { profile.stepsGoal = max(HZReglages.pasMin, profile.stepsGoal - HZReglages.pasDuCompteurDePas) },
                           plus: { profile.stepsGoal = min(HZReglages.pasMax, profile.stepsGoal + HZReglages.pasDuCompteurDePas) })
            }
            HZLigneDeReglage(titre: String(localized: "Calories actives"), filet: false) {
                HZCompteur(valeur: Int(profile.activeCaloriesGoal).formatted(),
                           nomDuMoins: String(localized: "Moins de calories"), nomDuPlus: String(localized: "Plus de calories"),
                           moins: { profile.activeCaloriesGoal = max(HZReglages.caloriesMin, profile.activeCaloriesGoal - HZReglages.pasDuCompteurDeCalories) },
                           plus: { profile.activeCaloriesGoal = min(HZReglages.caloriesMax, profile.activeCaloriesGoal + HZReglages.pasDuCompteurDeCalories) })
            }
        }
    }

    // MARK: - Compte et équipement

    private var compte: some View {
        HZGroupeDeReglages(titre: String(localized: "Compte et équipement")) {
            destination(String(localized: "Mes chaussures")) { dismiss(); appState.go(.shoes) }
            // Ici et pas seulement sur l'offre : qui vient de recevoir un code le cherche dans ses
            // réglages, pas derrière un verrou de fonctionnalité.
            OfferCodeButton(subscriptions: subscriptions, onOutcome: announce) {
                ligne(String(localized: "Utiliser un code promo"))
            }
            .buttonStyle(.plain)
            // Gérer, donc résilier : les cacher derrière les Réglages iOS est autorisé, les omettre
            // de l'app ne l'est pas. Le canvas n'a pas cette ligne ; elle reste pour la validation.
            Link(destination: Liens.abonnements) {
                ligne(String(localized: "Gérer mon abonnement"))
            }
            // Le résultat est toujours annoncé, comme sur l'écran d'abonnement : la ligne lançait
            // la restauration et jetait la réponse, donc rien ne disait si elle avait marché.
            destination(String(localized: "Restaurer mes achats")) {
                Task { appState.toast(await subscriptions.restore().message) }
            }
            destination(String(localized: "Plus de réglages"), filet: false) { showMoreSettings = true }
        }
    }

    private func announce(_ outcome: OfferCodeOutcome) {
        if let message = outcome.message { appState.toast(message) }
    }

    private func destination(_ titre: String, filet: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) { ligne(titre, filet: filet) }
            .buttonStyle(.plain)
    }

    private func ligne(_ titre: String, filet: Bool = true) -> some View {
        HZLigneDeReglage(titre: titre, hauteur: HZReglages.hauteurDeDestination, filet: filet) {
            HZChevron()
        }
        .contentShape(Rectangle())
    }
}
