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

    /// « TA SEMAINE » : le jour d'aujourd'hui, un glissement vers le jour suivant, puis le bas de la
    /// feuille.
    ///
    /// Le « maintenant » de la graine est un dimanche : la capture montre donc la carte du
    /// dimanche, et la référence celle du mardi. Le glissement ramène la carte voisine, pour
    /// comparer la même position. Par coordonnées, comme tout ce fichier.
    func test03Plan() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["Haizo_REFONTE"] != nil,
                          "réservé à refonte.yml")
        let app = lancer(arguments: ["--ecran=plan"])
        photographier("plan", app: app)

        let depart = app.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.5))
        let arrivee = app.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
        depart.press(forDuration: 0.1, thenDragTo: arrivee)
        Thread.sleep(forTimeInterval: 1.0)
        photographier("plan-glisse", app: app)

        defiler(app)
        photographier("plan-bas", app: app)
        app.terminate()
    }

    /// LES BOUTONS RÉPONDENT-ILS ? Un lancement par geste, et pour chacun : l'image change-t-elle ?
    ///
    /// C'est le test de non-régression d'un défaut qui a coûté une journée : sur l'Accueil et le
    /// Plan refaits, les boutons existaient, étaient touchables, leur action partait — et l'écran
    /// ne changeait pas. L'arbre d'accessibilité ne disait rien de juste (il ne reflétait pas
    /// l'image), le journal de l'app non plus : seule la comparaison des octets de la capture
    /// avant et après le geste dit si l'écran a vraiment bougé. La cause était la lecture de la
    /// zone sûre de la fenêtre dans `HZEspace.haut` ; voir son commentaire.
    ///
    /// Un témoin d'abord : deux captures sans rien toucher doivent être identiques, sinon la
    /// comparaison ne prouve rien.
    func test04Touches() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["Haizo_REFONTE"] != nil,
                          "réservé à refonte.yml")

        // 1. La recherche de l'accueil mène au Club : l'écran change de contenu.
        let accueil = lancer(arguments: ["--ecran=prog"])
        verifierQuEcranFixe(accueil, "accueil")
        toucherEtComparer(accueil, "accueil-recherche", dx: 0.5, dy: 0.095,
                          attendu: "la recherche de l'accueil doit ouvrir le Club")
        accueil.terminate()

        // 2. Le retour du plan mène à l'accueil.
        let retour = lancer(arguments: ["--ecran=plan"])
        toucherEtComparer(retour, "plan-retour", dx: 0.1, dy: 0.095,
                          attendu: "le retour du plan doit ramener à l'accueil")
        retour.terminate()

        // 3. La carte du jour ouvre la feuille de la séance.
        let carte = lancer(arguments: ["--ecran=plan"])
        toucherEtComparer(carte, "plan-carte", dx: 0.5, dy: 0.5,
                          attendu: "la carte du jour doit ouvrir le détail de la séance")
        carte.terminate()

        // 4. Le jeudi de la rangée change le jour affiché.
        let jeudi = lancer(arguments: ["--ecran=plan"])
        verifierQuEcranFixe(jeudi, "plan")
        let avant = jeudi.screenshot().pngRepresentation
        let bouton = jeudi.buttons["rangee-des-jours-3"]
        XCTAssertTrue(bouton.waitForExistence(timeout: 5), "la rangée des jours doit exister")
        bouton.tap()
        Thread.sleep(forTimeInterval: 1.5)
        photographier("plan-jeudi", app: jeudi)
        XCTAssertNotEqual(avant, jeudi.screenshot().pngRepresentation,
                          "le jeudi de la rangée doit changer la carte et la pastille")
        jeudi.terminate()
    }

    /// Deux captures à une seconde d'écart, sans rien toucher : identiques, ou la comparaison
    /// avant/après d'un geste ne prouve rien.
    private func verifierQuEcranFixe(_ app: XCUIApplication, _ nom: String) {
        let premiere = app.screenshot().pngRepresentation
        Thread.sleep(forTimeInterval: 1.0)
        XCTAssertEqual(premiere, app.screenshot().pngRepresentation,
                       "l'écran « \(nom) » n'est pas stable : la comparaison ne prouve rien")
    }

    private func toucherEtComparer(_ app: XCUIApplication, _ nom: String, dx: CGFloat, dy: CGFloat,
                                   attendu: String) {
        let avant = app.screenshot().pngRepresentation
        app.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: dy)).tap()
        Thread.sleep(forTimeInterval: 1.5)
        photographier("touche-\(nom)", app: app)
        XCTAssertNotEqual(avant, app.screenshot().pngRepresentation, attendu)
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
