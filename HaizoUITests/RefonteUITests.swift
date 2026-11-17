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

    /// L'ACCUEIL, avec la graine des captures : le haut, puis le bas.
    ///
    /// Le canvas fait 1 400 points de haut ; l'écran en fait 844. Le haut (la séance du jour, les
    /// quatre actions) se compare au haut de la référence ; le bas (le coach, la suite, Explorer,
    /// les dernières sorties) après un glissement. `--ecran=prog` : l'accueil, dont la valeur
    /// brute reste celle de l'ancien onglet « Prog ».
    func test02Accueil() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["Haizo_REFONTE"] != nil,
                          "réservé à refonte.yml")
        let app = lancer(arguments: ["--ecran=prog"])
        photographier("accueil", app: app)
        defiler(app)
        photographier("accueil-bas", app: app)
        app.terminate()
    }

    /// « TA SEMAINE » : le jour d'aujourd'hui, puis le mardi (la carte que le canvas met au premier
    /// plan), puis le bas de la feuille.
    ///
    /// Le « maintenant » de la graine est un dimanche : la capture montre donc la carte du
    /// dimanche, et la référence celle du mardi. On touche le deuxième jour de la rangée pour
    /// comparer la même position de carte. Par coordonnées, comme tout ce fichier.
    func test03Plan() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["Haizo_REFONTE"] != nil,
                          "réservé à refonte.yml")
        let app = lancer(arguments: ["--ecran=plan"])
        photographier("plan", app: app)

        // TROIS CHEMINS POUR CHANGER DE JOUR, un par image : un seul ne dirait pas LEQUEL manque.
        // (1) La rangée des jours, touchée par coordonnées : le deuxième des sept jours,
        //     (20 + 50 × 1,5) / 390 de la largeur, au milieu de la rangée.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.244, dy: 0.26)).tap()
        Thread.sleep(forTimeInterval: 1.0)
        photographier("plan-tap-coordonnees", app: app)

        // (2) Le même jour, par son identifiant d'accessibilité : si celui-ci marche et pas le
        //     précédent, c'est la position qui est fausse ; si aucun ne marche, c'est que quelque
        //     chose recouvre la rangée et prend les touches.
        let jour = app.buttons["rangee-des-jours-3"]
        let existe = jour.waitForExistence(timeout: 5)
        XCTContext.runActivity(named: "rangee-des-jours-3 existe : \(existe)") { _ in }
        if existe { jour.tap() }
        Thread.sleep(forTimeInterval: 1.0)
        photographier("plan-tap-identifiant", app: app)

        // (3) Un glissement horizontal sur la carte, vers la gauche : le jour suivant.
        let depart = app.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
        let arrivee = app.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.5))
        depart.press(forDuration: 0.1, thenDragTo: arrivee)
        Thread.sleep(forTimeInterval: 1.0)
        photographier("plan-mardi", app: app)

        defiler(app)
        photographier("plan-bas", app: app)
        app.terminate()
    }

    private func prendre(_ nom: String, arguments: [String], attente: TimeInterval = 2.0) {
        let app = lancer(arguments: arguments, attente: attente)
        photographier(nom, app: app)
        app.terminate()
    }

    private func lancer(arguments: [String], attente: TimeInterval = 2.0) -> XCUIApplication {
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
        return app
    }

    /// Un glissement vers le haut, par coordonnées — la page défile jusqu'au bout.
    private func defiler(_ app: XCUIApplication) {
        let depart = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85))
        let arrivee = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.05))
        depart.press(forDuration: 0.1, thenDragTo: arrivee)
        depart.press(forDuration: 0.1, thenDragTo: arrivee)
        Thread.sleep(forTimeInterval: 1.0)
    }

    private func photographier(_ nom: String, app: XCUIApplication) {
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
    }
}
