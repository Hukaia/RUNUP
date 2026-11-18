import SwiftUI

/// LA CARTE DU CLUB, en haut du fil : bleue, 214 points, le nom en grand en bas à gauche.
///
/// Une pastille (le nombre de membres) en haut ; le nom du club ; puis, tout en bas, la prochaine
/// sortie et le bouton pour y aller. Toute la carte mène au club ; le bouton, lui, ne mène qu'à la
/// sortie.
struct HZCarteDeClub: View {
    let membres: String
    let nom: String
    /// « Prochaine sortie jeudi 19 h ». Absente quand rien n'est prévu.
    var prochaineSortie: String? = nil
    var boutonDeSortie: String? = nil
    var actionDeSortie: () -> Void = {}
    let ouvrir: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HZPilule(texte: membres)
            Spacer(minLength: 0)
            Text(nom)
                .hzAffichage(.titreDeCarte)
                .foregroundStyle(HZCouleur.blanc)
                .lineLimit(HZCarteDeClub.lignesDuNom)
                .minimumScaleFactor(HZCarteDeClub.retraitDuNom)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let prochaineSortie, let boutonDeSortie {
                HStack {
                    Text(prochaineSortie)
                        .hzTexte(.c15, .semi)
                        .foregroundStyle(HZCouleur.blanc)
                    Spacer(minLength: HZEspace.entreCommandes)
                    HZBoutonPilule(libelle: boutonDeSortie, hauteur: .petite, fond: HZCouleur.blanc,
                                   couleur: HZCouleur.noir, action: actionDeSortie)
                }
                .padding(.top, HZCarteDeClub.sousLeNom)
            }
        }
        .padding(HZFil.margeDeLaCarteDeClub)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: HZFil.hauteurDeLaCarteDeClub)
        .background(HZIntensite.recuperation.couleur,
                    in: RoundedRectangle(cornerRadius: HZRayon.carteDeClub, style: .circular))
        .contentShape(Rectangle())
        .onTapGesture(perform: ouvrir)
        .accessibilityElement(children: .contain)
    }

    static let retraitDuNom: CGFloat = 0.6
    static let lignesDuNom = 2
    static let sousLeNom: CGFloat = 14
}

/// UNE SORTIE DU FIL : qui, un grand bloc avec la distance et le tracé, trois mesures, deux gestes.
///
/// Le bloc est à l'accent quand la sortie est un record, noir sinon ; le tracé est blanc sur l'un et
/// à l'accent sur l'autre. Une photo, quand son autrice en a mis une, prend la place du fond. Le nom
/// ouvre la personne, le bloc ouvre la sortie : trois zones, trois destinations.
struct HZSortieDuFil<Avatar: View, Options: View>: View {
    let nom: String
    let sousTitre: String
    var titre: String? = nil
    var record: Bool = false
    var recordLibelle: String = ""
    let distance: String
    let unite: String
    /// Le tracé, déjà ramené dans un carré de 0 à 1 (voir `HZSortieDuFil.normaliser`).
    var trace: [CGPoint] = []
    var photo: URL? = nil
    var mesures: [HZMesure] = []
    var bravo: String
    var bravoFait: Bool = false
    var commentaires: String
    let ouvrirLaPersonne: () -> Void
    let ouvrirLaSortie: () -> Void
    let applaudir: () -> Void
    let commenter: () -> Void
    @ViewBuilder var avatar: () -> Avatar
    @ViewBuilder var menu: () -> Options

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: HZFil.ecartDeLIdentite) {
                Button(action: ouvrirLaPersonne) {
                    HStack(spacing: HZFil.ecartDeLIdentite) {
                        avatar()
                        VStack(alignment: .leading, spacing: 0) {
                            Text(nom)
                                .hzTexte(.c16, .gras)
                                .foregroundStyle(HZCouleur.encre)
                            Text(sousTitre)
                                .hzTexte(.c13, .medium)
                                .foregroundStyle(HZCouleur.secondaireSurClair)
                        }
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if record {
                    HZPilule(texte: recordLibelle, style: .etiquetteGrasse, fond: HZCouleur.encre)
                }
                menu()
            }
            if let titre {
                Text(titre)
                    .hzParagraphe(.c16, .gras, interligne: HZBandeauDuCoach.interligne)
                    .foregroundStyle(HZCouleur.encre)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, HZFil.sousIdentiteDuTitre)
            }
            Button(action: ouvrirLaSortie) {
                bloc
            }
            .buttonStyle(.plain)
            .padding(.top, HZFil.sousLIdentite)
            if !mesures.isEmpty {
                HStack(alignment: .top, spacing: 0) {
                    ForEach(mesures) { mesure in
                        VStack(alignment: .leading, spacing: 0) {
                            Text(mesure.valeur)
                                .hzAffichage(.chiffreDeLigne)
                                .foregroundStyle(HZCouleur.encre)
                            Text(mesure.libelle)
                                .hzTexte(.c13, .medium)
                                .foregroundStyle(HZCouleur.secondaireSurClair)
                        }
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.top, HZFil.sousLaCarteDeSortie)
            }
            HStack(spacing: HZEspace.entrePilules) {
                geste(dessin: .coeur, libelle: bravo, actif: bravoFait, action: applaudir)
                geste(dessin: .bulle, libelle: commentaires, actif: false, action: commenter)
            }
            .padding(.top, HZFil.sousLaCarteDeSortie)
        }
    }

    private var surAccent: Bool { record }

    private var bloc: some View {
        ZStack(alignment: .topLeading) {
            if let photo {
                AsyncImage(url: photo) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    HZCouleur.noir
                }
                HZCouleur.noirFranc.opacity(HZFil.voileDePhoto)
            } else {
                (surAccent ? HZCouleur.accent : HZCouleur.noir)
                traceDessinee
            }
            Text(unite)
                .hzTexte(.c20, .gras)
                .foregroundStyle(HZCouleur.blanc)
                .padding(.leading, HZFil.margeDuLibelle)
                .padding(.top, HZFil.margeHautDuLibelle)
            Text(distance)
                .hzAffichage(.fil)
                .foregroundStyle(HZCouleur.blanc)
                .padding(.leading, HZFil.margeGaucheDuNombre)
                .padding(.bottom, HZFil.margeBasDuNombre)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
        .frame(maxWidth: .infinity)
        .frame(height: HZFil.hauteurDeLaCarte)
        .clipShape(RoundedRectangle(cornerRadius: HZRayon.carteDuFil, style: .circular))
        .accessibilityElement(children: .combine)
    }

    private var traceDessinee: some View {
        Canvas { contexte, taille in
            guard trace.count > 1 else { return }
            let zone = CGRect(x: taille.width * HZFil.zoneDeLaTraceX, y: taille.height * HZFil.zoneDeLaTraceY,
                              width: taille.width * HZFil.zoneDeLaTraceLargeur,
                              height: taille.height * HZFil.zoneDeLaTraceHauteur)
            var chemin = Path()
            for (index, point) in trace.enumerated() {
                let position = CGPoint(x: zone.minX + point.x * zone.width, y: zone.minY + point.y * zone.height)
                if index == 0 { chemin.move(to: position) } else { chemin.addLine(to: position) }
            }
            contexte.stroke(chemin, with: .color(surAccent ? HZCouleur.blanc : HZCouleur.accent),
                            style: StrokeStyle(lineWidth: HZFil.traitDeLaTrace, lineCap: .round,
                                               lineJoin: .round))
        }
    }

    private func geste(dessin: HZDessin, libelle: String, actif: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: HZBoutonPilule.ecart) {
                HZIcone(dessin: dessin, cote: HZFil.coteDuBravo,
                        couleur: actif ? HZCouleur.accent : HZCouleur.encre)
                Text(libelle)
                    .hzTexte(.c14, .gras)
                    .foregroundStyle(HZCouleur.encre)
            }
            .padding(.horizontal, HZHauteurDeBouton.moyenne.marge)
            .frame(height: HZHauteurDeBouton.moyenne.rawValue)
            .background(HZCouleur.surfaceClaire, in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    /// Un tracé GPS ramené dans un carré de 0 à 1, sans déformer : la plus grande des deux
    /// dimensions occupe tout le carré, l'autre est centrée. Le nord est en haut.
    static func normaliser(_ points: [(lat: Double, lng: Double)]) -> [CGPoint] {
        guard points.count > 1,
              let minLat = points.map(\.lat).min(), let maxLat = points.map(\.lat).max(),
              let minLng = points.map(\.lng).min(), let maxLng = points.map(\.lng).max()
        else { return [] }
        // À nos latitudes, un degré de longitude est plus court qu'un degré de latitude.
        let correction = cos(((minLat + maxLat) / HZFil.moitie) * Double.pi / HZFil.demiTour)
        let largeur = (maxLng - minLng) * correction
        let hauteur = maxLat - minLat
        let cote = max(largeur, hauteur, Double.ulpOfOne)
        let decalageX = (cote - largeur) / HZFil.moitie
        let decalageY = (cote - hauteur) / HZFil.moitie
        return points.map { point in
            CGPoint(x: (((point.lng - minLng) * correction) + decalageX) / cote,
                    y: 1 - (((point.lat - minLat) + decalageY) / cote))
        }
    }
}

/// UNE NOTE DU FIL : une phrase sur la surface claire, avec une coche — « a bouclé ses trois
/// objectifs du jour ». Ce n'est pas une sortie : pas de distance, pas de tracé.
struct HZNoteDuFil: View {
    let texte: String

    var body: some View {
        HStack(spacing: HZEspace.groupe - HZFil.moitieDeLEcart) {
            HZIcone(dessin: .coche, cote: HZFil.coteDeLaCocheDeNote, trait: HZFil.traitDeLaCocheDeNote,
                    couleur: HZCouleur.encre)
                .frame(width: HZFil.disqueDeLaNote, height: HZFil.disqueDeLaNote)
                .background(HZCouleur.blanc, in: Circle())
            Text(texte)
                .hzParagraphe(.c14, .medium, interligne: HZBandeauDuCoach.interligne)
                .foregroundStyle(HZCouleur.encre)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, HZEspace.groupe)
        .padding(.vertical, HZEspace.tuile)
        .background(HZCouleur.surfaceClaire,
                    in: RoundedRectangle(cornerRadius: HZFil.rayonDeLaNote, style: .circular))
        .accessibilityElement(children: .combine)
    }
}
