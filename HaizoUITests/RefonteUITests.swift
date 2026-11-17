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

        // L'ÉTAT DES TOUCHES, ÉCRIT : pour chaque jour de la rangée, existe-t-il, est-il touchable,
        // où est-il. Trois captures sans changement ne disent pas POURQUOI ; ce fichier le dit.
        var rapport = "Rangée des jours, avant tout geste\n"
        for jour in 0..<7 {
            let bouton = app.buttons["rangee-des-jours-\(jour)"]
            rapport += "  jour \(jour) : existe=\(bouton.exists) touchable=\(bouton.exists && bouton.isHittable) cadre=\(bouton.exists ? "\(bouton.frame)" : "-")\n"
        }
        rapport += "Fenêtre de l'app : \(app.frame)\n"

        // (1) La rangée des jours, touchée par coordonnées : le deuxième des sept jours,
        //     (20 + 50 × 1,5) / 390 de la largeur, au milieu de la rangée.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.244, dy: 0.26)).tap()
        Thread.sleep(forTimeInterval: 1.0)
        photographier("plan-tap-coordonnees", app: app)
        let apresLeTap = app.staticTexts["plan-diagnostic"]
        rapport += "Après le tap par coordonnées : \(apresLeTap.exists ? "\(apresLeTap.value ?? "?")" : "absent")\n"

        // (2) Le même geste par l'identifiant d'accessibilité.
        let jeudi = app.buttons["rangee-des-jours-3"]
        if jeudi.exists { jeudi.tap() }
        Thread.sleep(forTimeInterval: 1.0)
        photographier("plan-tap-identifiant", app: app)

        // (3) Un glissement horizontal sur la carte, vers la gauche : le jour suivant.
        let depart = app.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
        let arrivee = app.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.5))
        depart.press(forDuration: 0.1, thenDragTo: arrivee)
        Thread.sleep(forTimeInterval: 1.0)
        photographier("plan-mardi", app: app)

        // L'état de la sélection lu dans l'app après chacun des trois gestes.
        let diagnostic = app.staticTexts["plan-diagnostic"]
        rapport += "Après les trois gestes : \(diagnostic.exists ? "\(diagnostic.value ?? "?")" : "absent")\n"

        defiler(app)
        photographier("plan-bas", app: app)
        ecrire("arbre-plan.txt", rapport + "\n" + app.debugDescription)
        app.terminate()

        // (4) UN AUTRE BOUTON DE LA MÊME PAGE : « Déplacer » ouvre une feuille, visible sur l'image.
        // S'il répond et pas la rangée des jours, le défaut est propre à la rangée ; s'il ne répond
        // pas non plus, c'est la page entière qui ne reçoit aucune touche.
        let seconde = lancer(arguments: ["--ecran=plan"])
        seconde.coordinate(withNormalizedOffset: CGVector(dx: 0.80, dy: 0.865)).tap()
        Thread.sleep(forTimeInterval: 1.5)
        photographier("plan-deplacer", app: seconde)
        seconde.terminate()
    }

    /// QUELS BOUTONS DE LA REFONTE RÉPONDENT ? Quatre lancements, un geste chacun, un effet visible :
    /// la recherche de l'accueil (mène au Club), le retour du plan (mène à l'accueil), la carte du
    /// jour (ouvre la feuille de la séance), le jeudi de la rangée (change le jour). « Déplacer »
    /// répondait et la rangée non ; ceci dit si c'est la rangée, le haut de la page, ou le plan.
    func test04Touches() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["Haizo_REFONTE"] != nil,
                          "réservé à refonte.yml")
        var rapport = ""

        let accueil = lancer(arguments: ["--ecran=prog"])
        accueil.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.095)).tap()
        Thread.sleep(forTimeInterval: 1.5)
        photographier("touche-accueil-recherche", app: accueil)
        accueil.terminate()

        let retour = lancer(arguments: ["--ecran=plan"])
        retour.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.095)).tap()
        Thread.sleep(forTimeInterval: 1.5)
        photographier("touche-plan-retour", app: retour)
        retour.terminate()

        let carte = lancer(arguments: ["--ecran=plan"])
        carte.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        Thread.sleep(forTimeInterval: 1.5)
        photographier("touche-plan-carte", app: carte)
        carte.terminate()

        let jeudi = lancer(arguments: ["--ecran=plan"], attente: 5.0)
        jeudi.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.255)).tap()
        Thread.sleep(forTimeInterval: 1.5)
        photographier("touche-plan-jeudi", app: jeudi)
        let diagnostic = jeudi.staticTexts["plan-diagnostic"]
        rapport += "Jeudi, après 5 s d'attente : \(diagnostic.exists ? "\(diagnostic.value ?? "?")" : "absent")\n"
        jeudi.terminate()

        ecrire("touches.txt", rapport)
    }

    /// OÙ LA RANGÉE DES JOURS RÉPOND-ELLE ? Une touche à plusieurs hauteurs au milieu de l'écran,
    /// puis une sur chacune des sept colonnes, et le compteur de l'app lu après chaque touche. La
    /// rangée est à 191-235 pt ; si elle ne répond qu'à une autre hauteur, la zone touchable n'est
    /// pas là où elle est dessinée.
    func test05Balayage() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["Haizo_REFONTE"] != nil,
                          "réservé à refonte.yml")
        let app = lancer(arguments: ["--ecran=plan"], attente: 4.0)
        let hauteur: CGFloat = 844
        let largeur: CGFloat = 390
        func demandes() -> String {
            let diagnostic = app.staticTexts["plan-diagnostic"]
            guard diagnostic.exists, let valeur = diagnostic.value as? String else { return "absent" }
            return valeur.components(separatedBy: " ").last(where: { $0.hasPrefix("demandes=") }) ?? "?"
        }
        var rapport = "Avant tout geste : \(demandes())\n\nBalayage vertical, x = 195 (jeudi)\n"
        for y in stride(from: 150 as CGFloat, through: 270, by: 10) {
            app.coordinate(withNormalizedOffset: CGVector(dx: 195 / largeur, dy: y / hauteur)).tap()
            Thread.sleep(forTimeInterval: 0.6)
            rapport += "  y = \(Int(y)) pt : \(demandes())\n"
        }
        rapport += "\nBalayage horizontal, y = 213\n"
        for colonne in 0..<7 {
            let x = 20 + 50 * CGFloat(colonne) + 25
            app.coordinate(withNormalizedOffset: CGVector(dx: x / largeur, dy: 213 / hauteur)).tap()
            Thread.sleep(forTimeInterval: 0.6)
            rapport += "  colonne \(colonne) (x = \(Int(x)) pt) : \(demandes())\n"
        }
        ecrire("balayage.txt", rapport)
        photographier("balayage", app: app)
        app.terminate()
    }

    private func ecrire(_ nom: String, _ texte: String) {
        guard let dossier = ProcessInfo.processInfo.environment["Haizo_CAPTURES_DIR"] else { return }
        let url = URL(fileURLWithPath: dossier).appendingPathComponent(nom)
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
            try texte.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            XCTFail("fichier non écrit sur l'hôte : \(error)")
        }
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
