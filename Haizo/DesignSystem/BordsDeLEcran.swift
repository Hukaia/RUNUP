import SwiftUI
import UIKit

/// Les encarts de sécurité de l'écran, LUS SUR LA FENÊTRE et non sur la mise en page.
///
/// # Pourquoi ce détour existe
///
/// À l'intérieur d'un `ignoresSafeArea()`, les encarts rapportés par la mise en page valent
/// zéro — c'est précisément ce qu'on a demandé. Une vue qui déborde volontairement sous la barre
/// d'état ou sous l'indicateur d'accueil doit pourtant savoir de combien, pour reposer son
/// contenu au bon endroit. La fenêtre, elle, connaît toujours la vraie valeur.
///
/// # Pourquoi il est partagé
///
/// Il existait en trois exemplaires : un `ScreenEdges` privé dans `LiveRunView`, le même geste
/// dans `StravaService`, et il en aurait fallu un troisième pour l'en-tête de l'accueil. Le
/// commentaire de `LiveRunView` le disait déjà — « le même détour existe déjà dans
/// `StravaService` pour la même raison » — ce qui est la définition d'une valeur du système
/// restée dans une vue.
enum BordsDeLEcran {
    /// Le repli du HAUT : 59 points, la valeur des modèles à îlot dynamique, c'est-à-dire tous
    /// ceux qui sortent aujourd'hui. Sur un modèle à encoche le vrai encart est plus petit, donc
    /// l'erreur de repli est une marge un peu large — jamais un contenu sous l'îlot.
    static var haut: CGFloat { encart(\.top) ?? 59 }

    /// Le repli du BAS : 34 points, la valeur des modèles sans bouton d'accueil, c'est-à-dire la
    /// grande majorité, et la seule erreur sans conséquence des deux (une marge un peu large sur
    /// un SE plutôt qu'un bouton inatteignable sur un 15).
    static var bas: CGFloat { encart(\.bottom) ?? 34 }

    private static func encart(_ bord: KeyPath<UIEdgeInsets, CGFloat>) -> CGFloat? {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow?.safeAreaInsets[keyPath: bord] }
            .first
    }
}
