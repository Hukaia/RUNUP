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
    /// Quand on SAIT qu'aucune sortie n'est prévue : la phrase qui le dit, et, pour qui peut en
    /// proposer une, le bouton. Sans eux la carte restait un grand aplat bleu vide sous le nom.
    var sansSortie: String? = nil
    var boutonSansSortie: String? = nil
    var actionSansSortie: () -> Void = {}
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
            } else if let sansSortie {
                HStack {
                    Text(sansSortie)
                        .hzTexte(.c15, .semi)
                        .foregroundStyle(HZCouleur.blanc)
                        .lineLimit(1)
                        .minimumScaleFactor(HZCarteDeClub.retraitDuNom)
                    Spacer(minLength: HZEspace.entreCommandes)
                    if let boutonSansSortie {
                        HZBoutonPilule(libelle: boutonSansSortie, hauteur: .petite, fond: HZCouleur.blanc,
                                       couleur: HZCouleur.noir, action: actionSansSortie)
                    }
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
    /// « Aimé par Camille et 3 autres » : ce qui transforme « 7 » en gens.
    var aimePar: String? = nil
    /// Le dernier commentaire en aperçu : qui, et quoi.
    var dernierCommentaire: (auteur: String, texte: String)? = nil
    let ouvrirLaPersonne: () -> Void
    let ouvrirLaSortie: () -> Void
    let applaudir: () -> Void
    let commenter: () -> Void
    @ViewBuilder var avatar: () -> Avatar
    @ViewBuilder var menu: () -> Options

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Le cœur qui s'ouvre au centre du bloc quand on le touche deux fois.
    @State private var eclat = false

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
            // DEUX GESTES SUR LE MÊME BLOC : un tap ouvre la sortie, deux taps applaudissent. Le
            // double-tap est déclaré en premier : c'est ce qui laisse au tap simple le temps de
            // savoir qu'il n'en sera pas un.
            bloc
                .overlay { eclatDApplaudissement }
                .contentShape(Rectangle())
                .onTapGesture(count: HZFil.tapsDuDoubleTape) { applaudirParDoubleTape() }
                .onTapGesture(perform: ouvrirLaSortie)
                .accessibilityAddTraits(.isButton)
                .accessibilityAction(named: Text(bravo)) { applaudir() }
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
            if let aimePar {
                Text(aimePar)
                    .hzParagraphe(.c13, .medium, interligne: HZBandeauDuCoach.interligne)
                    .foregroundStyle(HZCouleur.secondaireSurClair)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, HZFil.sousLesGestes)
            }
            if let dernierCommentaire {
                (Text(dernierCommentaire.auteur).fontWeight(.bold) + Text(verbatim: "  ")
                    + Text(dernierCommentaire.texte))
                    .hzParagraphe(.c13, .medium, interligne: HZBandeauDuCoach.interligne)
                    .foregroundStyle(HZCouleur.encre)
                    .lineLimit(HZFil.lignesDuCommentaire)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, HZFil.moitieDeLEcart)
            }
        }
    }

    // MARK: - Le double-tape

    /// Le cœur au centre du bloc, une demi-seconde. Sans lui, un double-tape réussi ne se distingue
    /// pas d'un double-tape manqué : le compteur bouge de un, sous le pli, là où le doigt vient de
    /// passer.
    private var eclatDApplaudissement: some View {
        HZIcone(dessin: .coeur, cote: HZFil.coteDeLEclat, trait: HZFil.traitDeLEclat,
                couleur: HZCouleur.blanc)
            .shadow(color: HZCouleur.noirFranc.opacity(HZFil.opaciteDeLOmbreDeLEclat),
                    radius: HZFil.rayonDeLOmbreDeLEclat)
            .scaleEffect(eclat ? HZFil.echelleDeLEclat : HZFil.echelleDeDepartDeLEclat)
            .opacity(eclat ? HZPlan.pleine : 0)
            .allowsHitTesting(false)
    }

    private func applaudirParDoubleTape() {
        // Déjà applaudi : rien ne part au serveur, mais le cœur repasse quand même. Un geste qui ne
        // répond pas se lit comme un geste qui n'a pas été vu.
        if !bravoFait {
            applaudir()
            Haptics.impact(.light)
        }
        jouerLEclat()
    }

    private func jouerLEclat() {
        // Sous « Réduire les animations », l'éclat apparaît et disparaît sans ressort : le geste
        // garde son accusé de réception, c'est le rebond qui part.
        let entree: Animation = reduceMotion
            ? .easeOut(duration: HZFil.entreeSansRessort)
            : .spring(response: HZFil.ressortDeLEclat, dampingFraction: HZFil.amortissementDeLEclat)
        withAnimation(entree) { eclat = true }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(HZFil.dureeDeLEclatEnMillisecondes))
            withAnimation(.easeOut(duration: HZFil.sortieDeLEclat)) { eclat = false }
        }
    }

    private var surAccent: Bool { record }

    /// Le bloc : un fond, le tracé dessus, « kilomètres » en haut à gauche, la distance en bas à
    /// gauche. Le fond est posé EN ARRIÈRE-PLAN d'une surface de la bonne taille — et pas comme
    /// premier enfant d'une pile : posé ainsi, il ne s'affichait pas, et les textes blancs se
    /// lisaient blanc sur blanc.
    private var bloc: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: HZFil.hauteurDeLaCarte)
            .background { fondDuBloc }
            .overlay(alignment: .topLeading) {
                Text(unite)
                    .hzTexte(.c20, .gras)
                    .foregroundStyle(HZCouleur.blanc)
                    .padding(.leading, HZFil.margeDuLibelle)
                    // UN DÉCALAGE ET NON `.padding(.top)` : `hzTexte` pose une ligne de repère `.top`
                    // sur le texte, et un remplissage du haut posé derrière, dans un `overlay` aligné
                    // en haut, est ANNULÉ par cet alignement. « kilomètres » se collait au bord de la
                    // carte (3 points au lieu de 16) sur la capture de Charlotte, et dans toutes les
                    // captures CI du Club depuis le début.
                    .offset(y: HZFil.margeHautDuLibelle)
            }
            .overlay(alignment: .bottomLeading) {
                Text(distance)
                    .hzAffichage(.fil)
                    .foregroundStyle(HZCouleur.blanc)
                    .padding(.leading, HZFil.margeGaucheDuNombre)
                    .padding(.bottom, HZFil.margeBasDuNombre)
            }
            .clipShape(RoundedRectangle(cornerRadius: HZRayon.carteDuFil, style: .circular))
            .accessibilityElement(children: .combine)
    }

    @ViewBuilder private var fondDuBloc: some View {
        if let photo {
            AsyncImage(url: photo) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Rectangle().fill(HZCouleur.noir)
            }
            .overlay { Rectangle().fill(HZCouleur.noirFranc.opacity(HZFil.voileDePhoto)) }
        } else {
            Rectangle()
                .fill(surAccent ? HZCouleur.accent : HZCouleur.noir)
                .overlay { traceDessinee }
        }
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
        let ramenes = points.map { point in
            CGPoint(x: (((point.lng - minLng) * correction) + decalageX) / cote,
                    y: 1 - (((point.lat - minLat) + decalageY) / cote))
        }
        return lisser(ramenes)
    }

    /// Un tracé GPS brut est dentelé : le bruit du capteur à l'arrêt ou sous les arbres dessine des
    /// pointes que le trait épais du fil rend aussi visibles qu'un détour. Le canvas dessine une
    /// courbe nette. Chaque passe coupe chaque coin à un quart de sa longueur (Chaikin) ; les deux
    /// extrémités restent où elles sont, et le tracé reste dans son carré.
    static func lisser(_ points: [CGPoint]) -> [CGPoint] {
        var courant = points
        for _ in 0..<HZFil.passesDeLissage {
            guard courant.count > HZFil.pointsMinimumPourLisser else { return courant }
            var suivant = [courant[0]]
            for index in 0..<(courant.count - 1) {
                let a = courant[index], b = courant[index + 1]
                suivant.append(CGPoint(x: a.x + (b.x - a.x) * HZFil.coupeDuLissage,
                                       y: a.y + (b.y - a.y) * HZFil.coupeDuLissage))
                suivant.append(CGPoint(x: b.x - (b.x - a.x) * HZFil.coupeDuLissage,
                                       y: b.y - (b.y - a.y) * HZFil.coupeDuLissage))
            }
            suivant.append(courant[courant.count - 1])
            courant = suivant
        }
        return courant
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
