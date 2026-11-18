import SwiftUI

/// LA COURBE D'ALLURE de `Stats.dc.html` : un trait à l'accent, 4 points, les bouts arrondis, et
/// rien d'autre — ni aplat dessous, ni point sur le dernier relevé. Seul le RECORD est marqué : un
/// anneau, le fond de la carte au milieu, un trait d'encre autour.
///
/// Elle reçoit des valeurs DÉJÀ ramenées entre 0 (la plus rapide, en haut) et 1 (la plus lente, en
/// bas) : ce qu'elle dessine est une forme, et le calcul des allures reste dans l'écran qui les
/// connaît.
struct HZCourbeDAllure: View {
    /// 0 = la plus rapide, 1 = la plus lente. Une valeur par sortie, de la plus ancienne à la plus
    /// récente.
    let valeurs: [Double]
    /// L'indice de la sortie qui est le record, quand il tombe dans la fenêtre.
    var record: Int?

    var body: some View {
        Canvas { contexte, taille in
            guard valeurs.count > 1 else { return }
            let pas = (taille.width - HZStats.bordDeLaCourbe * 2) / CGFloat(valeurs.count - 1)
            let points = valeurs.enumerated().map { index, valeur in
                CGPoint(x: HZStats.bordDeLaCourbe + CGFloat(index) * pas,
                        y: taille.height * (HZStats.sousLeHaut + HZStats.etendueDeLaCourbe * CGFloat(valeur)))
            }
            var trace = Path()
            trace.move(to: points[0])
            for point in points.dropFirst() { trace.addLine(to: point) }
            contexte.stroke(trace, with: .color(HZCouleur.accent),
                            style: StrokeStyle(lineWidth: HZStats.traitDeLaCourbe, lineCap: .round,
                                               lineJoin: .round))
            if let record, points.indices.contains(record) {
                let centre = points[record]
                let rayon = HZStats.rayonDuRecord
                let anneau = Path(ellipseIn: CGRect(x: centre.x - rayon, y: centre.y - rayon,
                                                    width: HZStats.diametreDuRecord,
                                                    height: HZStats.diametreDuRecord))
                contexte.fill(anneau, with: .color(HZCouleur.surfaceClaire))
                contexte.stroke(anneau, with: .color(HZCouleur.encre), lineWidth: HZStats.traitDuRecord)
            }
        }
        .frame(height: HZStats.hauteurDeLaCourbe)
    }
}

/// LA CARTE D'ALLURE : le chiffre et son écart, la courbe, puis les deux extrêmes.
struct HZCarteDAllure: View {
    let allure: String
    /// « 1 s plus vite ». Absent quand il n'y a rien à comparer.
    var ecart: String? = nil
    let valeurs: [Double]
    var record: Int? = nil
    var pireAllure: String? = nil
    var meilleureAllure: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                HStack(alignment: .lastTextBaseline, spacing: HZStats.sousLaCourbe) {
                    Text(allure)
                        .hzAffichage(.chiffre)
                        .foregroundStyle(HZCouleur.encre)
                    Text(HZStats.uniteDAllure)
                        .hzTexte(.c15, .semi)
                        .foregroundStyle(HZCouleur.secondaireSurClair)
                }
                Spacer(minLength: HZEspace.entreCommandes)
                if let ecart {
                    Text(ecart)
                        .hzTexte(.c13, .gras)
                        .foregroundStyle(HZCouleur.encre)
                        .padding(.horizontal, HZStats.margeDuChip)
                        .padding(.vertical, HZStats.margeVerticaleDuChip)
                        .background(HZCouleur.blanc,
                                    in: RoundedRectangle(cornerRadius: HZRayon.vignette, style: .circular))
                }
            }
            HZCourbeDAllure(valeurs: valeurs, record: record)
                .padding(.top, HZStats.sousLEnteteDeCarte)
            if pireAllure != nil || meilleureAllure != nil {
                HStack {
                    if let pireAllure {
                        Text(pireAllure).foregroundStyle(HZCouleur.secondaireSurClair)
                    }
                    Spacer(minLength: 0)
                    if let meilleureAllure {
                        Text(meilleureAllure).foregroundStyle(HZCouleur.encre)
                    }
                }
                .hzTexte(.c13, .semi, tabulaire: true)
                .padding(.top, HZStats.sousLaCourbe)
            }
        }
        .padding(.horizontal, HZStats.margeHautDeCarte)
        .padding(.top, HZStats.margeHautDeCarte)
        .padding(.bottom, HZStats.margeBasDeCarte)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HZCouleur.surfaceClaire,
                    in: RoundedRectangle(cornerRadius: HZRayon.tuile, style: .circular))
        .accessibilityElement(children: .combine)
    }
}

/// UNE LIGNE « TES TEMPS POSSIBLES » : la distance à gauche, le temps à droite, en gras large.
struct HZLigneDeTemps: View {
    let distance: String
    let temps: String
    var filet: Bool = true

    var body: some View {
        HZLigneDeListe(titre: distance, marge: HZEspace.groupe, filet: filet) {
            EmptyView()
        } queue: {
            Text(temps)
                .hzAffichage(.chiffreDeLigne)
                .foregroundStyle(HZCouleur.encre)
        }
    }
}

/// UNE CARTE QUI MÈNE AILLEURS : un disque blanc avec son dessin, un titre, une précision, un
/// chevron — sur la surface claire. C'est « Mes routes » dans les Stats.
struct HZCarteDeLien: View {
    let dessin: HZDessin
    let titre: String
    let precision: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: HZMesuresDeLigne.ecart) {
                HZIcone(dessin: dessin, cote: HZStats.coteDeLIconeDeLien, couleur: HZCouleur.encre)
                    .frame(width: HZStats.tailleDuCercleDeLien, height: HZStats.tailleDuCercleDeLien)
                    .background(HZCouleur.blanc, in: Circle())
                VStack(alignment: .leading, spacing: 0) {
                    Text(titre)
                        .hzTexte(.c16, .gras)
                        .foregroundStyle(HZCouleur.encre)
                    Text(precision)
                        .hzTexte(.c13, .medium)
                        .foregroundStyle(HZCouleur.secondaireSurClair)
                }
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                HZChevron()
            }
            .padding(.horizontal, HZEspace.groupe)
            .padding(.vertical, HZEspace.tuile)
            .background(HZCouleur.surfaceClaire,
                        in: RoundedRectangle(cornerRadius: HZRayon.groupe, style: .circular))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}
