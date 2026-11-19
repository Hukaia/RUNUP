import SwiftUI
import UIKit

/// L'aiguilleur de l'app : l'écran courant, et la barre flottante posée par-dessus.
///
/// La barre est celle de la refonte, sur tous les écrans sauf deux : la course en direct et son
/// résumé, qui prennent tout l'écran.
struct RootTabView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var showBar: Bool {
        appState.screen != .live && appState.screen != .recap
    }

    /// Les écrans qui reçoivent du texte À MÊME LA PAGE.
    ///
    /// PARTOUT AILLEURS, UN ENCART DE CLAVIER N'A AUCUN SENS. Il n'y a rien à y taper : s'il en
    /// arrive un, c'est un reste, et il se voit comme une page cassée.
    ///
    /// Ces deux-là gardent le comportement d'origine : tout remonte avec le clavier, barre
    /// comprise, et le champ reste au-dessus. Une feuille est une hiérarchie séparée, que ce
    /// modificateur n'atteint pas : ses champs remontent tout seuls.
    private var typesText: Bool { appState.screen == .coach || appState.screen == .club }

    /// Quelle entrée la barre allume. Les pages ouvertes depuis un onglet gardent celui qui les
    /// porte allumé : c'est par lui qu'on y REVIENT.
    private var ongletRefait: Binding<HZOnglet> {
        Binding(
            get: {
                switch appState.screen {
                case .coach: return .coach
                case .stats, .history, .weeklyRecap, .heatmap: return .stats
                case .club, .fil: return .club
                case .explorer: return .explorer
                default: return .aujourdhui
                }
            },
            set: { onglet in
                Haptics.selection()
                switch onglet {
                case .aujourdhui: appState.go(.home)
                case .explorer: appState.go(.explorer)
                case .club: appState.go(.fil)
                case .stats: appState.go(.stats)
                case .coach: appState.go(.coach)
                }
            })
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            HZCouleur.blanc.ignoresSafeArea()

            currentScreen
                // Chaque écran emporte sa transition : voir `AppScreen.transitionDecran`.
                .transition(appState.screen.transitionDecran)
                .id(appState.screen)

            if showBar && appState.isRunActive {
                HZCourseEnCours(ecoule: appState.liveRun.map { PaceModel.formatDuration($0.elapsedSeconds) } ?? "0:00") {
                    appState.go(.live)
                }
                .padding(.bottom, HZEspace.sousLaBarre + HZCourseEnCours.hauteurDeLaBarre + HZCourseEnCours.souffle)
            }

            if showBar {
                // À vingt-huit points DU BORD DE L'ÉCRAN, comme dans le canvas. `ignoresSafeArea`
                // posé sur la barre elle-même ne ferait rien : c'est une surface qui OCCUPE
                // l'écran qui l'ignore, et la barre y est posée en bas.
                Color.clear
                    // Sans ceci la surface recevrait les touches destinées à la page dessous ;
                    // posé AVANT l'`overlay`, le réglage ne touche que la surface.
                    .allowsHitTesting(false)
                    .overlay(alignment: .bottom) {
                        HZBarreFlottante(selection: ongletRefait,
                                         aucuneActive: [AppScreen.profile, .club, .shoes].contains(appState.screen))
                            .padding(.bottom, HZEspace.sousLaBarre)
                    }
                    .ignoresSafeArea(edges: .bottom)
            }
        }
        // Un jeu de bords VIDE plutôt qu'un `if` autour du modificateur : la valeur change, pas
        // la structure de la vue. Un `if` en donnerait deux différentes, et SwiftUI recréerait
        // tout l'arbre — donc l'écran courant — à chaque passage sur le Coach.
        .ignoresSafeArea(.keyboard, edges: typesText ? [] : .bottom)
        // `HZMouvement.ressort` : « ce qui arrive à l'écran » se pose au lieu de freiner. Et il
        // respecte « Réduire les animations » : la valeur saute, elle ne s'anime pas plus vite.
        .animation(HZMouvement.respecter(reduceMotion, HZMouvement.ressort), value: appState.screen)
        // Un seul point d'émission pour toute l'app : chaque écran passe par ce `switch`, donc
        // rien ne peut être oublié ni compté deux fois. `onChange` plutôt qu'un `onAppear` par
        // écran, qui se serait redéclenché à chaque retour de feuille modale.
        .onAppear { Analytics.shared.track(.screenViewed, ["screen": .string(appState.screen.rawValue)]) }
        .onChange(of: appState.screen) { _, screen in
            // LE CLAVIER NE SUIT PAS L'ÉCRAN QUI L'A OUVERT. En quittant le Coach pendant qu'on
            // écrit, la vue est détruite avec son champ encore actif — `currentScreen` porte un
            // `.id(appState.screen)`. iOS referme bien le clavier, mais l'encart de sécurité qui
            // l'accompagnait reste parfois posé sur la hiérarchie. Le refermer AVANT de changer
            // d'écran supprime le cas à la source ; le `ignoresSafeArea` ci-dessus n'est là que
            // pour qu'il ne puisse plus rien casser s'il revenait par un autre chemin.
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                            to: nil, from: nil, for: nil)
            Analytics.shared.track(.screenViewed, ["screen": .string(screen.rawValue)])
        }
        .sheet(isPresented: Binding(get: { appState.sessionDetailPresented }, set: { appState.sessionDetailPresented = $0 })) {
            SessionDetailSheet()
                .haizoSheetStyle(gereSonBas: true)
        }
        .sheet(isPresented: Binding(get: { appState.moveSessionPresented }, set: { appState.moveSessionPresented = $0 })) {
            MoveSessionSheet()
                .haizoSheetStyle()
        }
        .sheet(isPresented: Binding(get: { appState.logSessionPresented }, set: { appState.logSessionPresented = $0 })) {
            LogSessionSheet()
                .haizoSheetStyle(detents: [.medium], gereSonBas: true)
        }
        .sheet(isPresented: Binding(get: { appState.programSettingsPresented }, set: { appState.programSettingsPresented = $0 })) {
            ProgramSettingsSheet()
                .haizoSheetStyle(gereSonBas: true)
        }
        .sheet(isPresented: Binding(get: { appState.notificationsPresented }, set: { appState.notificationsPresented = $0 })) {
            NotificationsSheet()
                .haizoSheetStyle()
        }
        // Presented from the ROOT, same reasoning as the debrief sheet above — "Refaire un
        // programme" is reachable from Profil's "Plus de réglages" sheet, so this must be able to
        // open on top of it, not nested one level inside where dismissing would fight it.
        .fullScreenCover(isPresented: Binding(get: { appState.newGoalWizardPresented }, set: { appState.newGoalWizardPresented = $0 })) {
            NewGoalWizardView()
        }
        // Presented from the ROOT, not HomeView's session card — a debrief can be triggered while
        // she's on any tab (a run arriving from the Apple Watch, "Marquer comme faite" flows),
        // and a sheet anchored inside a view that isn't currently mounted simply never appears
        // (the RPE, streak and plan adaptation were then silently lost).
        // `.sheet(item:)`, not `.sheet(isPresented:)` — keyed on the run itself so a second run
        // arriving while this one is still showing (see `AppState.pendingDebriefs`) tears down and
        // recreates `DebriefSheet`'s state instead of silently swapping its content underneath an
        // already-picked RPE. Dismissing (swipe-down or VALIDER, both call `dismiss()`, which
        // clears the binding) pops the front of the queue, presenting the next one if any.
        .sheet(item: Binding(
            get: { appState.pendingDebriefs.first },
            set: { newValue in if newValue == nil, !appState.pendingDebriefs.isEmpty { appState.pendingDebriefs.removeFirst() } }
        )) { run in
            DebriefSheet(run: run).haizoSheetStyle(gereSonBas: true)
        }
        // Tapping the weekly-recap local notification lands here rather than wherever the app
        // happened to be left open — `NotificationService` can't reach `AppState` directly (it's a
        // plain singleton with no app-state reference), so it posts this instead.
        .onReceive(NotificationCenter.default.publisher(for: .haizoOpenWeeklyRecap)) { _ in
            appState.go(.weeklyRecap)
        }
    }

    @ViewBuilder
    private var currentScreen: some View {
        switch appState.screen {
        case .home:
            AccueilView()
        case .plan:
            PlanSemaineView()
        case .rings: RingsView()
        case .live: LiveRunView()
        case .recap: RecapView()
        case .coach: CoachView()
        case .stats: StatsView()
        case .club: SocialView()
        case .explorer: ExplorerView()
        case .fil: WallView()
        case .race: RaceGoalView()
        case .profile: ProfileView()
        case .history: HistoryView()
        case .weeklyRecap: WeeklyRecapView()
        case .shoes: ShoesView()
        case .heatmap: HeatmapView()
        }
    }
}
