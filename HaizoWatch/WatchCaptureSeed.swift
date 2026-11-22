#if DEBUG
import Foundation

/// LA GRAINE DES CAPTURES DE LA MONTRE : de quoi photographier l'écran de course et celui d'après.
///
/// L'écran de départ se photographie en lançant l'app. Les deux autres (la course, le résumé) ne
/// s'affichent que dans l'état d'une vraie séance HealthKit, qu'un simulateur ne sait pas produire :
/// ils n'avaient donc JAMAIS été vus. Cette graine pose l'état à la main, sans capteur, comme
/// `CaptureSeed` le fait pour l'iPhone.
///
/// `#if DEBUG` : une construction de livraison n'en contient rien, ni l'argument de lancement ni les
/// chiffres. Les chiffres sont ceux d'une sortie plausible (24:18, 4,32 km), jamais ceux de quelqu'un.
///
///     xcrun simctl launch <appareil> com.hicsuntco.runup.watchkitapp --ecran=course|pause|resume
enum WatchCaptureSeed {
    enum Ecran: String {
        case course, pause, resume
    }

    static var ecranDemande: Ecran? {
        ProcessInfo.processInfo.arguments
            .first { $0.hasPrefix("--ecran=") }
            .flatMap { Ecran(rawValue: String($0.dropFirst("--ecran=".count))) }
    }

    @MainActor
    static func appliquer(a workout: WatchWorkoutManager) {
        guard let ecran = ecranDemande else { return }
        WatchConnectivityManager.shared.installerPourCapture(titre: "Footing récap", allure: "5:30",
                                                             minutes: 40)
        switch ecran {
        case .course: workout.installerPourCapture(.running)
        case .pause: workout.installerPourCapture(.paused)
        case .resume: workout.installerPourCapture(.ended)
        }
    }
}
#endif
