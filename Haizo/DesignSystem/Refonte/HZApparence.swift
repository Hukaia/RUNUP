import SwiftUI

/// LE RÉGLAGE D'APPARENCE : l'accent choisi et le thème clair ou sombre, lus avant la première image.
///
/// Le profil porte la préférence ; ce magasin en garde un MIROIR en mémoire, que les couleurs lisent
/// (`HZAccent.courant`) et que SwiftUI observe. Basculer ici redessine l'app entière sans toucher à
/// un seul appelant.
///
/// # POURQUOI UN MIROIR, ET UN CACHE DISQUE
///
/// Au lancement, l'accent et le thème doivent être connus AVANT que le profil soit lu : sans quoi
/// la première image est dessinée avec les valeurs par défaut, puis redessinée. Les trois valeurs sont
/// donc écrites aussi dans `UserDefaults`, et `AppState` les écrase avec celles du profil dès qu'il
/// est lu. Une personne qui a déjà un profil ne voit jamais ce cache décider de quoi que ce soit.
@Observable
final class ThemeStore {
    static let shared = ThemeStore()

    /// L'accent par défaut : le rose, la couleur de la marque.
    static let accentParDefaut = "rose"

    private(set) var themeID: String
    /// Le miroir de `UserProfile.isLightMode`.
    private(set) var isLightMode: Bool

    private static let cleTheme = "apparence.accent.v1"
    private static let cleClair = "apparence.clair.v1"

    private init() {
        let d = UserDefaults.standard
        themeID = d.string(forKey: Self.cleTheme) ?? Self.accentParDefaut
        // `d.bool(forKey:)` REND `false` QUAND LA CLÉ EST ABSENTE : c'est de là que venait le thème
        // sombre par défaut, que personne n'avait choisi. Au tout premier lancement, avant qu'un
        // profil existe, on démarre donc en clair.
        isLightMode = d.object(forKey: Self.cleClair) as? Bool ?? true
    }

    /// Le seul chemin d'écriture : une affectation directe depuis un écran de réglages aurait changé
    /// l'app sans rien écrire, et le réglage serait revenu en arrière au lancement suivant. Chaque
    /// paramètre absent laisse sa valeur inchangée.
    func appliquer(themeID: String? = nil, isLightMode: Bool? = nil) {
        if let themeID { self.themeID = themeID }
        if let isLightMode { self.isLightMode = isLightMode }
        let d = UserDefaults.standard
        d.set(self.themeID, forKey: Self.cleTheme)
        d.set(self.isLightMode, forKey: Self.cleClair)
    }
}
