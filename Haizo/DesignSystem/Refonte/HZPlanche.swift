#if DEBUG
import CoreGraphics

/// La mise en page de la planche elle-même — pas des jetons de l'app.
///
/// Elle est déclarée ici et non dans `PlancheView` pour la même raison que tout le reste : une
/// vue de la refonte ne contient pas un nombre, et la planche est la première vue de la refonte.
/// Une exception pour « l'outil » aurait été la première ligne d'une liste d'exceptions.
enum HZPlanche {
    /// Les six pages, dans l'ordre où `RefonteUITests` les photographie : `--planche=1` à `6`.
    enum Page: Int, CaseIterable {
        case jetons = 1, typographie, accueilHaut, accueilBas, plan, stats
    }

    static let ecart: CGFloat = 10
    static let fin: CGFloat = 6
    static let avantUneLegende: CGFloat = 18
    static let apresUneLegende: CGFloat = 8
    static let echantillon: CGFloat = 52
    static let nuance: CGFloat = 26
    static let forme: CGFloat = 50
    static let colonnesDIcones = 8
    static let iconesParLigne: CGFloat = 16
    static let rayonsParRangee = 5
    /// Ce qu'on laisse voir de l'accent au-dessus de la feuille, page 4.
    static let bandeDAccent: CGFloat = 14
}
#endif
