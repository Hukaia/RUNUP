import XCTest
import UIKit
@testable import Haizo

/// CHAQUE SYMBOLE NOMMÉ PAR L'APP EXISTE-T-IL VRAIMENT ?
///
/// `Image(systemName: "mountain.2.fill")` sur un nom qui n'existe pas ne lève rien, ne journalise
/// rien, et ne dessine RIEN. Un `Image` vide de la bonne taille : la mise en page ne bouge pas, la
/// construction est verte, les tests passent. Le défaut ne se voit qu'en regardant l'écran
/// concerné — autant dire jamais pour un écran qu'on ne photographie pas.
///
/// `UIImage(systemName:)` rend `nil` sur un nom inconnu, et c'est la seule façon de poser la
/// question : le catalogue des symboles appartient au système, pas au dépôt. Un script ne peut
/// donc pas y répondre, et `ci_scripts/check_symboles.py` ne fait que garantir que la liste
/// ci-dessous est EXACTEMENT celle que le code emploie — sans quoi cette barrière resterait verte
/// en ignorant le symbole ajouté la veille.
///
/// # CE QUE CE TEST NE COUVRE PAS
///
/// Un symbole introduit dans une version d'iOS plus récente que la cible de déploiement passe ici
/// — le simulateur est à jour — et reste vide sur un téléphone plus ancien. La parade n'est pas
/// mécanique : elle est de préférer des noms anciens.
final class SymbolesTests: XCTestCase {

    /// Tenue à jour par `ci_scripts/check_symboles.py`, qui refuse la construction si elle
    /// s'écarte des `systemName:` du code — dans un sens comme dans l'autre.
    static let tous: [String] = [
        "applewatch",
        "arrow.clockwise",
        "arrow.down.doc",
        "arrow.right.to.line",
        "arrow.triangle.2.circlepath",
        "arrow.triangle.swap",
        "arrow.up.left.and.arrow.down.right",
        "bell.slash",
        "bicycle",
        "bolt.fill",
        "bubble.right",
        "calendar",
        "calendar.badge.clock",
        "chart.line.uptrend.xyaxis",
        "chevron.left",
        "chevron.right",
        "chevron.up.chevron.down",
        "drop.fill",
        "dumbbell.fill",
        "ellipsis",
        "envelope",
        "exclamationmark.triangle",
        "exclamationmark.triangle.fill",
        "figure.pool.swim",
        "figure.run",
        "film",
        "flag.checkered",
        "flame.fill",
        "hands.clap",
        "hands.clap.fill",
        "heart.fill",
        "key.horizontal",
        "leaf.fill",
        "link",
        "list.bullet",
        "list.bullet.clipboard",
        "location.magnifyingglass",
        "location.slash.fill",
        "lock.fill",
        "lock.rectangle",
        "lock.slash",
        "map",
        "moon.zzz.fill",
        "mountain.2.fill",
        "pause.circle",
        "pause.fill",
        "pencil",
        "person.2.fill",
        "person.2.slash",
        "person.crop.circle",
        "photo",
        "play.fill",
        "play.rectangle.fill",
        "scalemass",
        "shoeprints.fill",
        "sparkles",
        "speaker.wave.2",
        "speaker.wave.2.fill",
        "speedometer",
        "square.and.arrow.up",
        "square.grid.3x1.below.line.grid.1x2",
        "stop.fill",
        "trash",
        "waveform",
        "xmark",
        "xmark.circle.fill",
    ]

    func testTousLesSymbolesNommesExistent() {
        var inconnus: [String] = []
        for nom in Self.tous where UIImage(systemName: nom) == nil {
            inconnus.append(nom)
        }
        XCTAssertTrue(inconnus.isEmpty,
                      "symbole(s) inexistant(s), donc icône(s) invisible(s) : \(inconnus.joined(separator: ", "))")
    }

    /// Une liste vide passerait le test ci-dessus sans rien vérifier.
    func testLaListeNEstPasVide() {
        XCTAssertGreaterThan(Self.tous.count, 50, "la liste des symboles s'est vidée")
    }
}
