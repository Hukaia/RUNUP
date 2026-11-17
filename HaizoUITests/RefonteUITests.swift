import XCTest

/// LES CAPTURES DE LA REFONTE — vite, et sur un écran de la taille du canvas.
///
/// # POURQUOI PAS `CapturesUITests`
///
/// Cette chaîne-là photographie trente écrans dans trois langues et deux thèmes, compose la fiche
/// App Store et filme l'aperçu : soixante-dix minutes. La refonte, elle, demande de comparer UN
/// écran à sa référence, de corriger, et de recommencer — « tu ne passes au suivant que sans écart
/// visible ». À soixante-dix minutes le tour, la méthode ne tient pas.
///
/// Ce fichier ne fait que ça : ouvrir l'app sur ce qu'on lui demande, photographier, écrire le
/// PNG. `refonte.yml` le lance seul, sur un simulateur de 390 points de large — la largeur des
/// artboards du canvas — pour que la capture et la référence se superposent sans mise à l'échelle.
///
/// Comme sa grande sœur, il touche par coordonnées et n'interroge jamais l'arbre d'accessibilité.
final class RefonteUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    /// La planche de l'étape 1 : jetons et composants de base, six pages. Voir `PlancheView`.
    ///
    /// `Haizo_REFONTE` : la grande campagne lance toute la cible sans filtre, donc aussi cette
    /// classe. Sans ce drapeau, que seul `refonte.yml` pose, le test se saute — sinon chaque
    /// passe de la campagne paierait six lancements pour des images qu'elle ne publie pas.
    func test01Planche() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["Haizo_REFONTE"] != nil,
                          "réservé à refonte.yml")
        for page in 1...6 {
            prendre("planche-\(page)", arguments: ["--planche=\(page)"])
        }
    }

    private func prendre(_ nom: String, arguments: [String], attente: TimeInterval = 2.0) {
        let app = XCUIApplication()
        // `--captures` même pour la planche, qui ne lit aucune donnée : c'est ce drapeau qui coupe
        // Santé, et la construction non signée d'un simulateur plante au premier appel HealthKit.
        app.launchArguments = ["--captures", "--clair"] + arguments
        if let langue = ProcessInfo.processInfo.environment["Haizo_LANG"] {
            app.launchArguments += ["-AppleLanguages", "(\(langue))", "-AppleLocale", langue]
        }
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 30)
        Thread.sleep(forTimeInterval: attente)

        let capture = XCUIScreen.main.screenshot()
        let piece = XCTAttachment(screenshot: capture)
        piece.name = nom
        piece.lifetime = .keepAlways
        add(piece)

        if let dossier = ProcessInfo.processInfo.environment["Haizo_CAPTURES_DIR"] {
            let url = URL(fileURLWithPath: dossier).appendingPathComponent("\(nom).png")
            do {
                try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                        withIntermediateDirectories: true)
                try capture.pngRepresentation.write(to: url)
            } catch {
                XCTFail("capture non écrite sur l'hôte : \(error)")
            }
        }
        app.terminate()
    }
}
