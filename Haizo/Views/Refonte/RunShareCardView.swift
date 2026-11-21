import Foundation
import SwiftUI

/// Les trois styles de la carte de partage, choisis sur l'écran du résumé avant de partager. La
/// photo dessous décide lequel marche : blanc sur une soirée sombre, noir sur la neige ou le ciel,
/// et « Haizo » quand elle veut une carte qui se suffit — un fond noir franc, sans photo dessous.
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

    /// Ce qu'on met derrière l'aperçu, à l'écran. La carte blanche et la carte Haizo (texte blanc)
    /// se lisent sur le noir ; la carte noire disparaîtrait dessus, elle se pose sur le gris clair.
    var fondDeLApercu: Color {
        self == .noir ? HZCouleur.surfaceClaire : HZCouleur.noir
    }

    /// Ce qui s'écrit par-dessus l'aperçu : un chargement, un message d'échec.
    var encreSurApercu: Color {
        self == .noir ? HZCouleur.encre : HZCouleur.blanc
    }
}

/// La carte de partage : trois mesures empilées (le libellé en gris, la valeur dessous), centrées,
/// avec le tracé réel de la course au-dessus en un trait net d'accent, et la signature de Haizo en
/// dessous. Rendue hors écran (`ImageRenderer`, dans `RecapView`) en une `UIImage` qui garde son
/// alpha : sur les styles Blanc et Noir, le PNG se pose proprement sur n'importe quelle photo
/// (story Instagram, Snapchat, un éditeur). Le style Haizo porte son propre fond noir franc.
///
/// Des aplats, comme partout dans l'app : pas de dégradé, pas de lueur, pas de contour. La seule
/// ombre est celle du texte blanc (`HZJournee.ombreDuTexte`), parce que la carte est transparente et
/// que du blanc sur une photo claire ne se lit pas sans elle.
struct RunShareCardView: View {
    var run: RunRecord
    var textColor: ShareCardTextColor = .blanc
    /// True only when `RecapView` verified this run genuinely beat every prior real run (pace or
    /// distance) — never a guess made just for the card.
    var isPersonalRecord: Bool = false

    /// Les valeurs, le mot de la marque et le nom du record.
    private var valueColor: Color {
        textColor == .noir ? HZCouleur.encre : HZCouleur.blanc
    }

    /// Les libellés et la signature : un gris opaque, jamais une opacité.
    private var secondaryColor: Color {
        textColor == .noir ? HZCouleur.secondaireSurClair : HZCouleur.secondaireSurSombre
    }

    /// L'ombre du texte blanc, et seulement elle.
    private var ombre: Color {
        textColor == .blanc ? HZJournee.ombreDuTexte : .clear
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
        // One compact, centered block with generous transparent margins around it — spread across
        // the full canvas it would cover the whole photo once layered on a story. A tight
        // sticker-like block over an untouched photo is the instagramable shape.
        VStack(spacing: 0) {
            if isPersonalRecord {
                Text("Nouveau record")
                    .font(HZJournee.police(HZJournee.tailleDuLibelle, .gras))
                    .foregroundStyle(valueColor)
                    .padding(.bottom, HZJournee.sousLeRecord)
            }
            if normalizedRoutePoints.count > 1 {
                routeTrace
                    // Carré : le tracé ne peut occuper qu'un carré sans se déformer, donc réserver
                    // un bandeau large laissait de toute façon deux marges vides de part et d'autre.
                    .frame(width: HZJournee.coteDuTrace, height: HZJournee.coteDuTrace)
                    .padding(.bottom, HZJournee.sousLeTrace)
            }

            VStack(spacing: HZJournee.entreLesMesures) {
                // `statBlock` rend son libellé par un `Text(String)` nu.
                statBlock(String(localized: "Distance"), String(format: "%.2f km", locale: Locale.current, run.distanceKm), style: HZJournee.distanceDeLaCarte)
                statBlock(run.rythmeLibelle, run.rythmeEcrit, style: HZJournee.mesureDeLaCarte)
                statBlock(String(localized: "Temps"), PaceModel.formatDuration(Double(run.durationSeconds)), style: HZJournee.mesureDeLaCarte)
            }

            signature
        }
        .shadow(color: ombre, radius: HZJournee.flouDeLOmbre, x: 0, y: HZJournee.decalageDeLOmbre)
        .frame(width: HZJournee.largeurDeLImage, height: HZJournee.hauteurDeLImage)
        // Le style Haizo est la seule carte opaque : un noir franc, pour la poster telle quelle.
        .background(textColor == .haizo ? HZCouleur.noirFranc : Color.clear)
    }

    /// La marque, la date et l'adresse, en pied de carte.
    private var signature: some View {
        VStack(spacing: HZJournee.entreLesLignesDeLaSignature) {
            HStack(spacing: HZJournee.entreLaMarqueEtLeMot) {
                AppMarkView(size: HZJournee.coteDeLaMarque, radius: HZJournee.rayonDeLaMarque)
                MotDeMarque(tuile: HZJournee.coteDeLaMarque).foregroundStyle(valueColor)
            }
            Text(Self.dateFormatter.string(from: run.date))
                .font(HZJournee.police(HZJournee.tailleDeLaDate, .medium, tabulaire: true))
                .foregroundStyle(secondaryColor)
            // L'adresse, sans code. Plus petite que la date : sur une story, c'est une mention
            // qu'on lit si on a envie de savoir, pas une bannière. Une carte qui crie son adresse
            // ne se partage pas — et une carte qu'on ne partage pas ne recrute personne.
            Text(verbatim: Self.hoteDuLien)
                .font(HZJournee.police(HZJournee.tailleDeLAdresse, .medium, tabulaire: true))
                .foregroundStyle(secondaryColor)
        }
        .padding(.top, HZJournee.auDessusDeLaSignature)
    }

    /// Une mesure : le libellé en gris au-dessus, la valeur en Archivo large dessous, centrées.
    private func statBlock(_ label: String, _ value: String, style: HZAffichage) -> some View {
        VStack(spacing: HZJournee.entreLibelleEtValeur) {
            Text(label)
                .font(HZJournee.police(HZJournee.tailleDuLibelle, .semi))
                .foregroundStyle(secondaryColor)
            Text(value)
                .hzAffichage(style)
                .foregroundStyle(valueColor)
                // Un nombre ne se tronque pas : il rétrécit avant de se couper.
                .lineLimit(1)
                .minimumScaleFactor(HZJournee.reductionDeLaMesure)
        }
        .frame(maxWidth: .infinity)
    }

    /// Le tracé de la course : un seul trait net, en aplat d'accent, avec un disque au départ et à
    /// l'arrivée. Pas de dégradé, pas de flou, pas de second passage dessous.
    private var routeTrace: some View {
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

            context.stroke(path, with: .color(HZCouleur.accent),
                           style: StrokeStyle(lineWidth: HZJournee.traitDuTrace, lineCap: .round, lineJoin: .round))

            context.fill(Path(ellipseIn: HZJournee.pastille(en: first, rayon: HZJournee.rayonDuDepart)), with: .color(valueColor))
            context.fill(Path(ellipseIn: HZJournee.pastille(en: last, rayon: HZJournee.rayonDeLArrivee)), with: .color(valueColor))
        }
    }
}
