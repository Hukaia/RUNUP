import SwiftUI

/// App-wide toast pill (bottom-center, ~2.2s auto-dismiss).
///
/// `@MainActor` parce que tout ce que fait cette classe est de l'interface : `withAnimation`,
/// une annonce VoiceOver, et une propriété que SwiftUI observe. Sans l'annotation, la tâche de
/// disparition ci-dessous capture une classe non-`Sendable` dans du code concurrent — un
/// avertissement aujourd'hui, une erreur en Swift 6, et une vraie course de données entre
/// l'écriture différée et la lecture par la vue.
@MainActor
@Observable
final class ToastCenter {
    private(set) var message: String?
    private var dismissTask: Task<Void, Never>?

    func show(_ message: String) {
        dismissTask?.cancel()
        withAnimation(.spring(response: HZToast.reponseDuRessort, dampingFraction: HZToast.amortissement)) {
            self.message = message
        }
        // Un texte non focalisable qui apparaît puis disparaît n'est JAMAIS lu par VoiceOver.
        // Les 39 messages de l'app passaient donc entièrement à la trappe, y compris ceux qui
        // n'ont aucun autre canal : « Kudos non envoyé », « Impossible de suivre cette
        // personne », « Connexion à Apple Santé impossible ». On tapait un bouton, rien ne se
        // passait, et rien ne disait pourquoi.
        AccessibilityNotification.Announcement(message).post()
        // Plus de `await MainActor.run` : une `Task` créée depuis un contexte `@MainActor` hérite
        // de son isolation, donc le corps s'exécute déjà sur le fil principal.
        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(HZToast.dureeAffichage))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: HZToast.dureeDeSortie)) { self?.message = nil }
        }
    }
}

/// Overlays the current toast message, positioned above the floating tab bar.
struct ToastHost: ViewModifier {
    var toastCenter: ToastCenter
    /// Dans une feuille ou une couverture il n'y a pas de barre flottante à dégager : le message se
    /// pose au bas de la modale.
    var dansUneModale = false

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let message = toastCenter.message {
                Text(message)
                    .hzTexte(.c14, .semi)
                    // Noir sur tous les fonds, blanc dessus : un message passager flotte au-dessus
                    // de n'importe quelle page, et la pilule noire est celle de la barre flottante.
                    .foregroundStyle(HZCouleur.blanc)
                    // Deux lignes : « Notifications refusées. Active-les dans Réglages. » finissait
                    // en points de suspension sur une seule.
                    .lineLimit(HZToast.lignes)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, HZToast.margeHorizontale)
                    .padding(.vertical, HZToast.margeVerticale)
                    .background(HZCouleur.noir, in: Capsule())
                    .shadow(color: HZCouleur.noirFranc.opacity(HZToast.opaciteDeLOmbre),
                            radius: HZToast.rayonDeLOmbre, x: 0, y: HZToast.decalageDeLOmbre)
                    .padding(.horizontal, HZEspace.marge)
                    .padding(.bottom, dansUneModale
                             ? HZHub.basDeFeuille
                             : HZEspace.sousLaBarre + HZMesuresDeLaCourse.hauteurDeLaBarre + HZToast.souffle)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .allowsHitTesting(false)
            }
        }
        .animation(.spring(response: HZToast.reponseDuRessort, dampingFraction: HZToast.amortissement), value: toastCenter.message)
    }
}

/// LE MÊME MESSAGE, DANS UNE FEUILLE OU UNE COUVERTURE.
///
/// L'hôte de la racine (`HaizoApp`) est une surcouche de la racine : toute feuille et toute
/// couverture plein écran se présentent PAR-DESSUS. « Achat restauré », « Compte supprimé »,
/// « Signalement envoyé », « Notifications refusées » partaient donc derrière la modale qui les
/// avait déclenchés : on touchait un bouton, et rien ne répondait. `hzFeuille` pose cet hôte dans
/// chaque feuille, et les couvertures le posent à leur présentation.
///
/// `AppState?` : une planche de composants ou un aperçu n'a pas d'`AppState` dans son
/// environnement, et n'a pas de message à montrer non plus.
struct ToastDeModale: ViewModifier {
    @Environment(AppState.self) private var appState: AppState?

    func body(content: Content) -> some View {
        if let appState {
            content.modifier(ToastHost(toastCenter: appState.toastCenter, dansUneModale: true))
        } else {
            content
        }
    }
}

extension View {
    func toastHost(_ toastCenter: ToastCenter) -> some View {
        modifier(ToastHost(toastCenter: toastCenter))
    }

    /// À poser sur le contenu d'une couverture plein écran. Les feuilles l'ont par `hzFeuille`.
    func toastDeModale() -> some View {
        modifier(ToastDeModale())
    }
}
