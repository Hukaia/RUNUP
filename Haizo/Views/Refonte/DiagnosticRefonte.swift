import Foundation

/// DES INTERRUPTEURS POUR TROUVER CE QUI CASSE, et rien d'autre.
///
/// Sur l'accueil et le plan refaits, le contenu d'un écran ne se remplace pas quand on en sort (la
/// barre change, le contenu reste), et la rangée des jours ne change pas de jour. Aucune ligne de
/// code ne l'explique à la lecture. Chaque interrupteur retire UNE des particularités de ces deux
/// écrans — ce qu'aucun autre écran de l'app n'a — pour que le test de capture dise laquelle est
/// en cause : `--sans-statusbar`, `--sans-fond`, `--sans-zonesure`, `--sans-recouvrement`,
/// `--sans-barre`, ou `--sans-tout`.
///
/// Hors DEBUG, tout est faux : la version publiée n'est jamais touchée. À supprimer dès que la
/// cause est trouvée.
enum DiagnosticRefonte {
    static func sans(_ nom: String) -> Bool {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        return arguments.contains("--sans-\(nom)") || arguments.contains("--sans-tout")
        #else
        return false
        #endif
    }
}
