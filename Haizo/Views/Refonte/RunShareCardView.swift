import Foundation
import SwiftUI

/// Text-color styles for the share card, picked on the recap screen before sharing — the photo
/// underneath decides which one works (white over a dark evening run, black over snow/sky, the
/// brand gradient when she wants the Haizo identity front and center).
enum ShareCardTextColor: String, CaseIterable, Identifiable {
    case blanc, noir, haizo
    var id: String { rawValue }
    var label: String {
        switch self {
        case .blanc: return String(localized: "Blanc")
        case .noir: return String(localized: "Noir")
        case .haizo: return "Haizo" // nom de marque
        }
    }
}

/// The share card — Strava-style stacked stats (label over big value, centered) floating on a
/// fully transparent background, with the real route trace as a glowing neon signature above and
/// Haizo branding below. Rendered off-screen (via `ImageRenderer` in `RecapView`) into a `UIImage`
/// with alpha preserved, so the exported PNG layers cleanly over any photo (Instagram Stories,
/// Snapchat, any editor). There used to be two variants (an opaque dark card + this transparent
/// one, two separate share buttons) — one transparent card covers both uses: it reads fine shared
/// as-is on a dark story background, and it's the only version that works over a photo. Every
/// element carries a strong drop shadow so legibility doesn't depend on what ends up underneath.
struct RunShareCardView: View {
    var run: RunRecord
    var textColor: ShareCardTextColor = .blanc
    /// True only when `RecapView` verified this run genuinely beat every prior real run (pace or
    /// distance) — never a guess made just for the card.
    var isPersonalRecord: Bool = false

    /// The big stat values — a flat color, or the brand rose→violet sweep for the `haizo` style
    /// (`HZAccent` fixed colors, same stops as the route trace, deliberately not the in-app theme
    /// token: the exported image shouldn't change with an unrelated app setting).
    private var valueStyle: AnyShapeStyle {
        switch textColor {
        case .blanc: return AnyShapeStyle(HZCouleur.blanc)
        case .noir: return AnyShapeStyle(HZCouleur.encre)
        case .haizo: return AnyShapeStyle(LinearGradient(colors: [HZJournee.rose, HZJournee.violet], startPoint: .leading, endPoint: .trailing))
        }
    }

    /// Labels, wordmark and date — a quieter companion to `valueStyle`.
    private var secondaryColor: Color {
        switch textColor {
        case .blanc: return HZCouleur.blanc.opacity(HZJournee.opaciteDuSecondaire)
        case .noir: return HZCouleur.encre.opacity(HZJournee.opaciteDuSecondaire)
        case .haizo: return HZJournee.rose
        }
    }

    /// Dark text needs a LIGHT halo to hold up over dark photos, and vice versa.
    private var outlineIsLight: Bool { textColor == .noir }

    private var roseGlowOpacity: Double {
        switch textColor {
        case .blanc: return HZJournee.lueurSurBlanc
        case .noir: return 0
        case .haizo: return HZJournee.lueurSurMarque
        }
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "d MMMM yyyy"
        return f
    }()

    /// L'adresse portée par la carte.
    ///
    /// Une course partagée est la seule publicité que Haizo ne paye pas : elle est publiée par
    /// quelqu'un qui vient de courir, devant des gens qui le connaissent. La carte portait la
    /// marque, mais aucun moyen d'agir — il fallait retenir un nom et aller le chercher dans
    /// l'App Store.
    ///
    /// Elle a porté un `/r/CODE` pendant la vie du parrainage. Le code est parti, l'adresse
    /// reste : c'est elle qui faisait le travail. Sans le `https://`, qui n'apprend rien à
    /// personne et coûte huit caractères sur une ligne qui doit rester discrète.
    private static let hoteDuLien = "runup-nu.vercel.app"

    /// Le tracé réel, normalisé dans un carré 0…1 — la MÊME forme que celle parcourue.
    ///
    /// La projection vit dans `RouteGeometry`, partagée avec la vignette de l'historique : le
    /// même parcours doit avoir la même forme aux deux endroits, et une seule implémentation est
    /// la seule façon de le garantir.
    private var normalizedRoutePoints: [CGPoint] {
        RouteGeometry.normalized(run.route)
    }

    var body: some View {
        // One compact, centered block with generous transparent margins around it — the previous
        // pass spread the content across the full canvas, which covered the whole photo once
        // layered on a story. A tight sticker-like block over an untouched photo is the
        // instagramable shape.
        VStack(spacing: 0) {
            if isPersonalRecord {
                Text("NOUVEAU RECORD")
                    .font(HZJournee.police(HZJournee.tailleDuLibelle, .gras))
                    .tracking(HZJournee.interlettrageDuRecord)
                    .foregroundStyle(secondaryColor)
                    .modifier(OutlinedTextShadow(light: outlineIsLight))
                    .padding(.bottom, HZJournee.sousLeRecord)
            }
            if normalizedRoutePoints.count > 1 {
                neonRouteTrace
                    // Carré : le tracé ne peut occuper qu'un carré sans se déformer, donc réserver
                    // un bandeau large laissait de toute façon deux marges vides de part et d'autre.
                    .frame(width: HZJournee.coteDuTrace, height: HZJournee.coteDuTrace)
                    .padding(.bottom, HZJournee.sousLeTrace)
            }

            VStack(spacing: HZJournee.entreLesMesures) {
                // `statBlock` rend son libellé par un `Text(String)` nu.
                statBlock(String(localized: "DISTANCE"), String(format: "%.2f km", locale: Locale.current, run.distanceKm), style: HZJournee.distanceDeLaCarte)
                statBlock(String(localized: "ALLURE"), "\(run.avgPace) /km", style: HZJournee.mesureDeLaCarte)
                statBlock(String(localized: "TEMPS"), PaceModel.formatDuration(Double(run.durationSeconds)), style: HZJournee.mesureDeLaCarte)
            }

            signature
        }
        .frame(width: HZJournee.largeurDeLImage, height: HZJournee.hauteurDeLImage)
    }

    /// La marque, la date et l'adresse, en pied de carte.
    private var signature: some View {
        VStack(spacing: HZJournee.entreLesLignesDeLaSignature) {
            HStack(spacing: HZJournee.entreLaMarqueEtLeMot) {
                AppMarkView(size: HZJournee.coteDeLaMarque, radius: HZJournee.rayonDeLaMarque)
                MotDeMarque(tuile: HZJournee.coteDeLaMarque).foregroundStyle(valueStyle)
            }
            Text(Self.dateFormatter.string(from: run.date))
                .font(HZJournee.police(HZJournee.tailleDeLaDate, .medium, tabulaire: true))
                .tracking(HZJournee.interlettrageDeLaDate)
                .foregroundStyle(secondaryColor.opacity(HZJournee.opaciteDeLaDate))
            // L'adresse, sans code. Plus petite et plus discrète que la date : sur une
            // story, c'est une mention qu'on lit si on a envie de savoir, pas une bannière.
            // Une carte qui crie son adresse ne se partage pas — et une carte qu'on ne
            // partage pas ne recrute personne, quelle que soit la taille du lien.
            Text(verbatim: Self.hoteDuLien)
                .font(HZJournee.police(HZJournee.tailleDeLAdresse, .medium, tabulaire: true))
                .tracking(HZJournee.interlettrageDeLAdresse)
                .foregroundStyle(secondaryColor.opacity(HZJournee.opaciteDeLAdresse))
        }
        .modifier(OutlinedTextShadow(light: outlineIsLight))
        .padding(.top, HZJournee.auDessusDeLaSignature)
    }

    /// One Strava-style stacked stat — small tracked label over a big display-face value, centered.
    private func statBlock(_ label: String, _ value: String, style: HZAffichage) -> some View {
        VStack(spacing: HZJournee.entreLibelleEtValeur) {
            Text(label)
                .font(HZJournee.police(HZJournee.tailleDuLibelle, .gras))
                .tracking(HZJournee.interlettrageDuLibelle)
                .foregroundStyle(secondaryColor)
                .modifier(OutlinedTextShadow(light: outlineIsLight))
            Text(value)
                .hzAffichage(style)
                .foregroundStyle(valueStyle)
                .modifier(OutlinedTextShadow(light: outlineIsLight))
                // A whisper of rose around white, a restrained one on the gradient style, none on
                // black — tuned down twice from the original, which read as too much.
                .shadow(color: HZJournee.rose.opacity(roseGlowOpacity), radius: HZJournee.rayonDeLaLueur)
        }
        .frame(maxWidth: .infinity)
    }

    /// Legibility over ANY photo without a background veil: a tight, near-opaque shadow hugging
    /// the glyphs (reads as an outline, the trick text-over-video apps use) plus a wider soft
    /// halo. `light` flips the halo to white for the black-text style — a dark outline under dark
    /// text would vanish over a dark photo.
    private struct OutlinedTextShadow: ViewModifier {
        var light: Bool = false

        func body(content: Content) -> some View {
            // Enough presence for legibility over a photo, without the grey-black smudge the
            // heavier version drew around every glyph.
            content
                .shadow(color: light ? HZJournee.halo : HZJournee.ombreDuContour,
                        radius: HZJournee.rayonDuContour, x: 0, y: light ? 0 : HZJournee.decalageDuContour)
                .shadow(color: light ? HZJournee.haloLarge : HZJournee.ombreLarge,
                        radius: HZJournee.rayonDuHalo, x: 0, y: light ? 0 : HZJournee.decalageDuHalo)
        }
    }

    /// A wide, blurred pass underneath a crisp pass — the same brand gradient (rose → violet) as
    /// the app mark, drawn thick enough to read as the card's real hero visual, not a thin line
    /// tucked in a box. `drawLayer` isolates the blur filter to just that pass, so it doesn't also
    /// smear the crisp stroke drawn after it.
    private var neonRouteTrace: some View {
        Canvas { context, size in
            // `normalizedRoutePoints` rend un CARRÉ unité : le parcours y est déjà centré et à
            // son vrai rapport de forme. On dessine dans le plus grand carré centré disponible :
            // c'est la seule mise à l'échelle qui conserve la forme.
            let side = max(min(size.width, size.height) - HZJournee.margeDuTrace * HZJournee.deuxCotes, 1)
            let originX = (size.width - side) / HZHub.moitie
            let originY = (size.height - side) / HZHub.moitie
            let points = normalizedRoutePoints.map {
                CGPoint(x: originX + $0.x * side, y: originY + $0.y * side)
            }
            guard let first = points.first, let last = points.last else { return }
            var path = Path()
            path.move(to: first)
            for p in points.dropFirst() { path.addLine(to: p) }

            let gradient = GraphicsContext.Shading.linearGradient(
                Gradient(colors: [HZJournee.rose, HZJournee.violet]),
                startPoint: first,
                endPoint: last
            )
            let style = StrokeStyle(lineWidth: HZJournee.traitDuTrace, lineCap: .round, lineJoin: .round)

            context.drawLayer { glow in
                glow.addFilter(.blur(radius: HZJournee.flouDuTrace))
                glow.opacity = HZJournee.opaciteDuFlou
                glow.stroke(path, with: gradient, style: StrokeStyle(lineWidth: HZJournee.traitDuFlou, lineCap: .round, lineJoin: .round))
            }
            context.stroke(path, with: gradient, style: style)

            context.fill(Path(ellipseIn: HZJournee.pastille(en: first, rayon: HZJournee.rayonDuDepart)), with: .color(HZCouleur.blanc))
            context.fill(Path(ellipseIn: HZJournee.pastille(en: last, rayon: HZJournee.rayonDeLArrivee)), with: .color(HZCouleur.blanc))
        }
    }
}
