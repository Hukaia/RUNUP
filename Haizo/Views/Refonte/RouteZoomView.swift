import SwiftUI
import MapKit

/// LE TRACÉ EN GRAND : la carte plein écran, qu'on déplace et qu'on agrandit au doigt, avec les trois
/// chiffres de la course dans une plaque blanche et un bouton rond pour refermer.
///
/// C'est un écran entier, pas une feuille : une feuille se referme en la tirant vers le bas, et c'est
/// le geste qu'on fait pour déplacer la carte.
struct RouteZoomView: View {
    var run: RunRecord
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .top) {
            RunRouteMapView(route: run.route, lineWidth: HZTraceEnGrand.traitDuTrace, interactive: true)
                .ignoresSafeArea()

            HStack(alignment: .top) {
                resume
                Spacer(minLength: HZEspace.entreCommandes)
                fermer
            }
            .padding(.horizontal, HZEspace.marge)
            .padding(.top, HZTraceEnGrand.sousLeHaut)
        }
    }

    private var resume: some View {
        VStack(alignment: .leading, spacing: HZTraceEnGrand.entreTitreEtChiffres) {
            Text(run.titreAffiche)
                .hzTexte(.c14, .semi)
                .foregroundStyle(HZCouleur.encre)
                .lineLimit(1)
            // Les trois mêmes valeurs, formatées comme l'écran de fin les formate : deux décimales et
            // la locale courante, pour qu'agrandir la carte ne change pas les chiffres qu'on avait sous
            // les yeux une seconde plus tôt.
            HStack(spacing: HZEspace.entreCommandes) {
                valeur(String(format: "%.2f", locale: Locale.current, run.distanceKm),
                       unite: String(localized: "km"))
                valeur(PaceModel.formatDuration(Double(run.durationSeconds)), unite: "")
                valeur(run.avgPace, unite: String(localized: "/km"))
            }
        }
        .padding(.horizontal, HZEspace.tuile)
        .padding(.vertical, HZTraceEnGrand.margeVerticaleDeLaPlaque)
        // Posée sur une carte, donc sur un contenu imprévisible : une surface opaque, et le contraste des
        // chiffres ne dépend plus de ce qui défile dessous.
        .background(HZCouleur.blanc, in: RoundedRectangle(cornerRadius: HZRayon.vignette, style: .continuous))
    }

    private func valeur(_ texte: String, unite: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: HZTraceEnGrand.entreValeurEtUnite) {
            Text(texte)
                .hzTexte(.c16, .gras, tabulaire: true)
                .foregroundStyle(HZCouleur.encre)
            if !unite.isEmpty {
                Text(unite)
                    .hzTexte(.c12, .medium)
                    .foregroundStyle(HZCouleur.secondaireSurClair)
            }
        }
    }

    private var fermer: some View {
        HZBoutonRond(dessin: .fermer, nom: String(localized: "Fermer le tracé"), diametre: .outil,
                     fond: HZCouleur.blanc, couleur: HZCouleur.encre,
                     cote: HZHub.coteDeLaCroix, trait: HZHub.traitDeLaCroix) {
            dismiss()
        }
    }
}
