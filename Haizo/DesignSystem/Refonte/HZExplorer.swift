import SwiftUI

/// LES PIÈCES D'EXPLORER : le champ qui ouvre la recherche, la carte d'un itinéraire en vedette, la
/// tuile d'une course. Les mesures sont celles du canvas « Explorer ».

/// LE CHAMP : une pilule claire, la loupe, une question et sa précision, et à droite un disque noir
/// de réglages. C'est tout entier un bouton qui mène à la carte de recherche.
struct HZChampDExploration: View {
    let question: String
    let precision: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: HZEspace.entreTuiles) {
                HZIcone(dessin: .recherche, cote: HZExplorer.coteDeLaLoupe, couleur: HZCouleur.encre)
                VStack(alignment: .leading, spacing: 0) {
                    Text(question).hzTexte(.c15, .gras)
                    Text(precision)
                        .hzTexte(.c12, .medium)
                        .foregroundStyle(HZCouleur.secondaireSurClair)
                }
                .foregroundStyle(HZCouleur.encre)
                .frame(maxWidth: .infinity, alignment: .leading)
                HZIcone(dessin: .curseurs, cote: HZExplorer.coteDesReglages, couleur: HZCouleur.blanc)
                    .frame(width: HZDiametre.filtre.rawValue, height: HZDiametre.filtre.rawValue)
                    .background(HZCouleur.encre, in: Circle())
            }
            .padding(.leading, HZEspace.groupe)
            .padding(.trailing, HZExplorer.margeDuDisque)
            .frame(height: HZExplorer.hauteurDuChamp)
            .background(HZCouleur.surfaceClaire, in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

/// L'ITINÉRAIRE EN VEDETTE : un grand bloc noir, le tracé en accent, une pastille d'où il est et sa
/// distance en très grand. Le tracé est le vrai parcours, ramené dans un carré à droite du bloc.
struct HZCarteDItineraire: View {
    let distance: String
    let pastille: String?
    /// Le parcours dans [0, 1] × [0, 1], voir `HZMiniatureDeSortie.normaliser`.
    let trace: [CGPoint]
    let nom: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: HZExplorer.hauteurDeLaCarte)
                .background {
                    RoundedRectangle(cornerRadius: HZRayon.feuille, style: .circular)
                        .fill(HZCouleur.noir)
                        .overlay { traceDessinee }
                }
                .overlay(alignment: .topLeading) {
                    if let pastille {
                        HZPilule(texte: pastille, style: .etiquetteGrasse, fond: HZCouleur.voile)
                            .padding(HZExplorer.margeDeLaPastille)
                    }
                }
                .overlay(alignment: .bottomLeading) {
                    Text(verbatim: distance)
                        .hzAffichage(.heros)
                        .foregroundStyle(HZCouleur.blanc)
                        .lineLimit(1)
                        .minimumScaleFactor(HZExplorer.reductionDeLaDistance)
                        .padding(.leading, HZExplorer.margeDeLaDistance)
                        .padding(.bottom, HZExplorer.sousLaDistance)
                }
                .contentShape(RoundedRectangle(cornerRadius: HZRayon.feuille, style: .circular))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(nom)
    }

    private var traceDessinee: some View {
        Canvas { contexte, taille in
            guard trace.count > 1 else { return }
            let zone = CGRect(x: taille.width * HZExplorer.traceX, y: taille.height * HZExplorer.traceY,
                              width: taille.width * HZExplorer.traceLargeur,
                              height: taille.height * HZExplorer.traceHauteur)
            let cote = min(zone.width, zone.height)
            let origine = CGPoint(x: zone.midX - cote / HZExplorer.moitie, y: zone.midY - cote / HZExplorer.moitie)
            var chemin = Path()
            for (index, point) in trace.enumerated() {
                let position = CGPoint(x: origine.x + point.x * cote, y: origine.y + point.y * cote)
                if index == 0 { chemin.move(to: position) } else { chemin.addLine(to: position) }
            }
            contexte.stroke(chemin, with: .color(HZCouleur.accent),
                            style: StrokeStyle(lineWidth: HZExplorer.traitDuTrace, lineCap: .round,
                                               lineJoin: .round))
        }
        .accessibilityHidden(true)
    }
}

/// LA TUILE D'UNE COURSE : un carré de couleur avec le mois en haut à gauche et la distance en grand
/// en bas, puis le nom de la course et une ligne sur qui la prépare.
struct HZTuileDeCourse: View {
    let mois: String
    let distance: String
    let nom: String
    let note: String?
    let couleur: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: HZEspace.entrePilules) {
                Color.clear
                    .frame(height: HZExplorer.hauteurDeLaTuile)
                    .background(couleur, in: RoundedRectangle(cornerRadius: HZRayon.tuile, style: .circular))
                    // En pile et non en superposition alignée : la boîte de ligne de `hzTexte` déplace
                    // son repère haut, et superposée au coin elle remontait à 1,5 point du bord au
                    // lieu des 14 du canvas. Dans une pile, la place vient des tailles, pas du repère.
                    .overlay {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(mois)
                                .hzTexte(.c13, .semi)
                                .foregroundStyle(HZCouleur.blanc)
                            Spacer(minLength: 0)
                        }
                        .padding(HZExplorer.margeDeLaTuile)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .overlay(alignment: .bottomLeading) {
                        Text(verbatim: distance)
                            .hzAffichage(.tuileDeCourse)
                            .foregroundStyle(HZCouleur.blanc)
                            .lineLimit(1)
                            .minimumScaleFactor(HZExplorer.reductionDeLaDistance)
                            .padding(.horizontal, HZExplorer.margeDeLaTuile)
                            .padding(.bottom, HZExplorer.sousLaDistanceDeTuile)
                    }
                VStack(alignment: .leading, spacing: 0) {
                    Text(nom).hzTexte(.c15, .gras).foregroundStyle(HZCouleur.encre)
                    if let note {
                        Text(note).hzTexte(.c13, .medium).foregroundStyle(HZCouleur.secondaireSurClair)
                    }
                }
            }
            .frame(width: HZExplorer.largeurDeLaTuile, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}
