import CoreText
import SwiftUI
import UIKit
import WidgetKit
import XCTest

/// Rend les vues du widget d'accueil en images, avec le vrai fichier Archivo, pour qu'on les REGARDE
/// avant de les livrer. Voir `HaizoWidgetTests` dans `project.yml` pour ce que ce rendu est, et
/// n'est pas : la mise en page, la fonte et les débordements y sont vrais ; les marges et les coins
/// du système ne le sont pas.
///
/// Les images vont dans `WIDGET_OUT` (posé par le workflow), sinon dans le dossier temporaire.
@MainActor
final class WidgetRenduTests: XCTestCase {

    private static var fonteEnregistree = false

    override func setUp() async throws {
        try await super.setUp()
        guard !Self.fonteEnregistree else { return }
        // Ce paquet n'a pas d'hôte, donc pas d'`UIAppFonts` : la fonte s'enregistre à la main.
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "Archivo-Variable",
                                                            withExtension: "ttf"),
                                "Archivo-Variable.ttf n'est pas dans le paquet de test")
        var erreur: Unmanaged<CFError>?
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, &erreur)
        Self.fonteEnregistree = true
    }

    // MARK: Les cas

    /// Un jeudi, parce que la pastille du jour se calcule depuis la date.
    private let jeudi = Date(timeIntervalSince1970: 1_763_553_600) // 2025-11-19 12:00 UTC

    private let semaine: [WidgetWeekDay] = [
        WidgetWeekDay(letter: "L", isDone: true, isToday: false),
        WidgetWeekDay(letter: "M", isDone: true, isToday: false),
        WidgetWeekDay(letter: "M", isDone: false, isToday: false),
        WidgetWeekDay(letter: "J", isDone: false, isToday: true),
        WidgetWeekDay(letter: "V", isDone: false, isToday: false),
        WidgetWeekDay(letter: "S", isDone: false, isToday: false),
        WidgetWeekDay(letter: "D", isDone: false, isToday: false),
    ]

    private func instantane(prefixe: String? = nil, nombre: String? = nil, titre: String? = nil,
                            mesures: String? = nil, faite: Bool = false, repos: Bool = false,
                            accent: String = "rose") -> DailyGoalsSnapshot {
        DailyGoalsSnapshot(progress: [1, 0.6, 0.3], streak: 4, accentThemeID: accent,
                           isLightMode: true, dailyGoalsDone: 2, dailyGoalsTotal: 3,
                           activeCaloriesRemaining: 110, stepsRemaining: 2400, weekStrip: semaine,
                           isRestDay: repos, heroPrefixe: prefixe, heroNombre: nombre,
                           heroTitre: titre, heroMesures: mesures, heroFaite: faite)
    }

    private var cas: [(nom: String, snapshot: DailyGoalsSnapshot)] {
        [
            ("seance", instantane(nombre: "45′", titre: "Footing endurance",
                                  mesures: "45 min · 5:30/km · Z2")),
            ("fractionne", instantane(prefixe: "5 ×", nombre: "400", titre: "Fractionné court")),
            ("quatre-chiffres", instantane(prefixe: "3 ×", nombre: "1000", titre: "Seuil long")),
            ("sortie-longue", instantane(nombre: "1h30", titre: "Sortie longue en endurance",
                                         mesures: "90 min · 5:50/km · Z2")),
            ("fait", instantane(nombre: "45′", titre: "Footing endurance",
                                mesures: "45 min", faite: true)),
            ("repos", instantane(nombre: "Off", titre: "Jour de repos", repos: true)),
            ("violet", instantane(nombre: "45′", titre: "Footing endurance",
                                  mesures: "45 min · 5:30/km · Z2", accent: "violet")),
            ("sans-seance", instantane()),
        ]
    }

    private let tailles: [(nom: String, famille: WidgetFamily, taille: CGSize)] = [
        ("petit-158", .systemSmall, CGSize(width: 158, height: 158)),
        ("petit-170", .systemSmall, CGSize(width: 170, height: 170)),
        ("moyen-338", .systemMedium, CGSize(width: 338, height: 158)),
    ]

    // MARK: Le rendu

    func testLeWidgetSeRendDansToutesSesTailles() throws {
        let dossier = URL(fileURLWithPath: ProcessInfo.processInfo.environment["WIDGET_OUT"]
                          ?? NSTemporaryDirectory() + "widget")
        try FileManager.default.createDirectory(at: dossier, withIntermediateDirectories: true)

        var ecrites = 0
        for t in tailles {
            for c in cas {
                let vue = DailyGoalsWidgetView(snapshot: c.snapshot, entryDate: jeudi,
                                               familleImposee: t.famille)
                try ecrire(vue, t, "\(c.nom)-\(t.nom)", dans: dossier, fond: WG.noir)
                ecrites += 1
            }
            // Et la course en cours, qui remplace la séance sur le même emplacement.
            let course = LiveRunWidgetSnapshot(startedAt: jeudi.addingTimeInterval(-1_425),
                                               elapsedSeconds: 1_425, isPaused: false,
                                               distanceKm: 4.62, rythmeValeur: "5:09",
                                               sessionTitle: "Footing endurance",
                                               disciplineRaw: nil, publishedAt: jeudi)
            let vue = DailyGoalsWidgetView(snapshot: instantane(), entryDate: jeudi, course: course,
                                           familleImposee: t.famille)
            try ecrire(vue, t, "course-\(t.nom)", dans: dossier, fond: WG.noirFranc)
            ecrites += 1
        }
        XCTAssertEqual(ecrites, tailles.count * (cas.count + 1))
    }

    private func ecrire(_ vue: DailyGoalsWidgetView, _ t: (nom: String, famille: WidgetFamily, taille: CGSize),
                        _ nom: String, dans dossier: URL, fond: Color) throws {
        // `containerBackground(for: .widget)` ne fait rien hors de WidgetKit : le fond se pose ici,
        // et la carte est coupée aux coins d'un widget (≈ 22 points).
        let carte = vue
            .frame(width: t.taille.width, height: t.taille.height)
            .background(fond)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .environment(\.colorScheme, .dark)
        let rendu = ImageRenderer(content: carte)
        rendu.scale = 3
        let image = try XCTUnwrap(rendu.uiImage, "\(nom) : rien n'a été rendu")
        let png = try XCTUnwrap(image.pngData(), "\(nom) : PNG impossible")
        try png.write(to: dossier.appendingPathComponent("\(nom).png"))
        let piece = XCTAttachment(image: image)
        piece.name = nom
        piece.lifetime = .keepAlways
        add(piece)
    }
}
