import SwiftUI
import UIKit
import MapKit

/// LES PIÈCES COMMUNES DES ÉCRANS QUI SUIVENT LE CANVAS : le hub du Club, l'autour de la course,
/// l'entrée dans l'app. Aucune n'est nouvelle dans son dessin : c'est le haut noir, la feuille
/// blanche à coins de 30, la ligne de liste et la pilule des écrans déjà refaits, rangées ici pour
/// ne pas être récrites écran par écran.

enum HZHub {
    /// Du dernier élément du haut noir au bord de la feuille (avant le rayon, que la feuille remonte).
    static let sousLeHaut: CGFloat = 22
    static let sousLesCommandes: CGFloat = 16
    static let sousLaCarte: CGFloat = 16
    static let basDePage: CGFloat = 112
    static let hauteurMiniDeLaFeuille: CGFloat = 400
    static let avatar: CGFloat = 44
    static let avatarCompact: CGFloat = 32
    static let avatarEmpile: CGFloat = 28
    static let chevauchementDesAvatars: CGFloat = -8
    static let liseDesAvatars: CGFloat = 2
    static let avatarsMax = 6
    static let rapportDeLaCouverture: CGFloat = 2.67
    static let hauteurDuChamp: CGFloat = 48
    static let loupe: CGFloat = 16
    static let coteDeLaCroix: CGFloat = 14
    static let traitDeLaCroix: CGFloat = 2.2
    static let largeurDuRang: CGFloat = 24
    static let rayonDeLaPlaque: CGFloat = 22
    static let epaisseurDeLaJauge: CGFloat = 8
    static let epaisseurDeLaJaugeFine: CGFloat = 6
    static let hauteurDeLaProgression: CGFloat = 6
    static let opaciteDuFondDeMoi: Double = 0.09
    static let moitie: CGFloat = 2
    static let coteDeLaCouronne: CGFloat = 20
    static let traitDeLaCouronne: CGFloat = 3
    static let lignesDuTexteDeCarte = 3
    static let ecartDesGroupes: CGFloat = 6
    static let hauteurDuGroupe: CGFloat = 32
    static let coteDeLIcone: CGFloat = 16
    static let traitDeLIcone: CGFloat = 2
    static let lignesDuChamp: ClosedRange<Int> = 1...4
}

/// UNE PAGE À FEUILLE : un haut noir, puis la feuille blanche qui remonte d'un rayon dessus.
///
/// C'est la structure de `ProfileView`, de `WallView` et de `ExplorerView`, écrite une fois : le
/// défilement, le fond en deux moitiés (noir en haut, blanc en bas, pour qu'un tirage vers le bas
/// ou vers le haut ne montre jamais le fond du système), la zone sûre ignorée en haut, la barre
/// d'état masquée. `HZEspace.haut` est une constante : la lire dans la zone sûre de la fenêtre
/// figeait le défilement (voir son commentaire).
struct HZPage<Haut: View, Contenu: View>: View {
    var basDePage: CGFloat = HZHub.basDePage
    @ViewBuilder var haut: () -> Haut
    @ViewBuilder var contenu: () -> Contenu

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: -HZRayon.feuille) {
                haut()
                    .padding(.top, HZEspace.haut)
                    .padding(.bottom, HZHub.sousLeHaut + HZRayon.feuille)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(HZCouleur.noir)
                    .foregroundStyle(HZCouleur.blanc)
                HZFeuille {
                    contenu()
                    Color.clear.frame(height: basDePage)
                }
                .frame(minHeight: HZHub.hauteurMiniDeLaFeuille, alignment: .top)
            }
        }
        .scrollIndicators(.hidden)
        .background {
            VStack(spacing: 0) {
                HZCouleur.noir
                HZCouleur.blanc
            }
            .ignoresSafeArea()
        }
        .ignoresSafeArea(edges: .top)
        .statusBarHidden()
    }
}

/// LA RANGÉE DES COMMANDES DU HAUT : un retour rond à gauche, ce qu'on veut à droite.
struct HZCommandesDuHaut<Droite: View>: View {
    let retour: () -> Void
    @ViewBuilder var droite: () -> Droite

    var body: some View {
        HStack {
            HZBoutonRond(dessin: .retour, nom: String(localized: "Retour"),
                         fond: HZCouleur.surfaceSombre, trait: HZBoutonRond.traitDuRetour, action: retour)
            Spacer(minLength: 0)
            droite()
        }
        .padding(.horizontal, HZEspace.marge)
    }
}

/// LA PHOTO D'UNE PERSONNE : l'image si on en a une (octets, adresse ou data-URI), sinon ses
/// initiales en blanc sur l'encre. Un seul rendu pour toutes les listes de gens.
struct HZPhotoDePersonne: View {
    var imageData: Data? = nil
    var urlString: String? = nil
    var base64DataURI: String? = nil
    let initiales: String
    var cote: CGFloat = HZHub.avatar

    var body: some View {
        ZStack {
            if let image = HZPhotoDePersonne.decoder(imageData, base64DataURI) {
                Image(uiImage: image).resizable().scaledToFill()
            } else if let urlString, let adresse = URL(string: urlString) {
                AsyncImage(url: adresse) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        repli
                    }
                }
            } else {
                repli
            }
        }
        .frame(width: cote, height: cote)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }

    private var repli: some View {
        Text(initiales)
            .hzTexte(.c14, .gras)
            .foregroundStyle(HZCouleur.blanc)
            .lineLimit(1)
            .frame(width: cote, height: cote)
            .background(HZCouleur.encre, in: Circle())
    }

    private static func decoder(_ octets: Data?, _ dataURI: String?) -> UIImage? {
        if let octets, let image = UIImage(data: octets) { return image }
        if let dataURI, let virgule = dataURI.firstIndex(of: ","),
           let octets = Data(base64Encoded: String(dataURI[dataURI.index(after: virgule)...])) {
            return UIImage(data: octets)
        }
        return nil
    }
}

/// LES INITIALES D'UNE PERSONNE : la première lettre du prénom et du nom, en capitales.
enum HZInitiales {
    static func de(_ prenom: String, _ nom: String? = nil) -> String {
        HZAvatar.initiales(prenom: prenom, nom: nom?.isEmpty == false ? nom : nil)
    }
}

/// UNE PILE D'AVATARS qui se chevauchent, avec le « +n » de ceux qu'on ne montre pas.
struct HZPileDAvatars: View {
    struct Personne: Identifiable {
        let id: String
        let initiales: String
        var urlString: String? = nil
        var base64: String? = nil
    }

    let personnes: [Personne]
    var total: Int
    var cote: CGFloat = HZHub.avatarEmpile
    var fondDuLise: Color = HZCouleur.surfaceClaire

    var body: some View {
        HStack(spacing: HZHub.chevauchementDesAvatars) {
            ForEach(personnes.prefix(HZHub.avatarsMax)) { personne in
                HZPhotoDePersonne(urlString: personne.urlString, base64DataURI: personne.base64,
                                  initiales: personne.initiales, cote: cote)
                    .overlay(Circle().strokeBorder(fondDuLise, lineWidth: HZHub.liseDesAvatars))
            }
            if total > HZHub.avatarsMax {
                Text(verbatim: "+\(total - HZHub.avatarsMax)")
                    .hzTexte(.c13, .gras)
                    .foregroundStyle(HZCouleur.encre)
                    .frame(width: cote, height: cote)
                    .background(HZCouleur.filetGroupe, in: Circle())
                    .overlay(Circle().strokeBorder(fondDuLise, lineWidth: HZHub.liseDesAvatars))
            }
        }
        .accessibilityHidden(true)
    }
}

/// LE CHAMP DE RECHERCHE : une pilule où l'on écrit. Sur la surface claire par défaut, voilée quand
/// il est posé sur le noir ou sur une carte.
struct HZChampDeRecherche: View {
    let invite: String
    @Binding var texte: String
    var surNoir: Bool = false
    var enRecherche: Bool = false
    var avecLoupe: Bool = true

    var body: some View {
        HStack(spacing: HZEspace.entrePilules) {
            if avecLoupe {
                HZIcone(dessin: .recherche, cote: HZHub.loupe, trait: HZAmorceDeRecherche.trait,
                        couleur: encre)
            }
            TextField(text: $texte, prompt: Text(invite).foregroundStyle(secondaire)) {
                EmptyView()
            }
            .accessibilityLabel(invite)
            .font(HZPolice.texte(.c15, .semi))
            .foregroundStyle(encre)
            .tint(encre)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.search)
            if enRecherche {
                ProgressView().tint(encre)
            } else if !texte.isEmpty {
                Button { texte = "" } label: {
                    HZIcone(dessin: .fermer, cote: HZHub.coteDeLaCroix, trait: HZHub.traitDeLaCroix,
                            couleur: encre)
                        .frame(width: HZBoutonRond.zoneTactile, height: HZBoutonRond.zoneTactile)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "Effacer"))
            }
        }
        .padding(.leading, HZAmorceDeRecherche.marge)
        .padding(.trailing, enRecherche || !texte.isEmpty ? 0 : HZAmorceDeRecherche.marge)
        .frame(height: HZHub.hauteurDuChamp)
        .background(surNoir ? HZCouleur.voile : HZCouleur.surfaceClaire, in: Capsule())
    }

    private var encre: Color { surNoir ? HZCouleur.blanc : HZCouleur.encre }
    private var secondaire: Color { surNoir ? HZCouleur.secondaireSurSombre : HZCouleur.secondaireSurClair }
}

/// UNE PHRASE sur la surface claire : un vide, une erreur, une invitation. Un titre d'affichage
/// optionnel, puis ce qu'il y a à dire.
struct HZPhrase: View {
    let texte: String
    var titre: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: HZEspace.entrePilules) {
            if let titre {
                Text(titre)
                    .hzAffichage(.section)
                    .foregroundStyle(HZCouleur.encre)
            }
            Text(texte)
                .hzParagraphe(.c14, .medium, interligne: HZBandeauDuCoach.interligne)
                .foregroundStyle(HZCouleur.secondaireSurClair)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// UNE PLAQUE : un bloc de la surface claire, coins de 22 — la carte de la feuille qui n'est ni une
/// tuile de chiffre ni une ligne.
struct HZPlaque<Contenu: View>: View {
    var fond: Color = HZCouleur.surfaceClaire
    @ViewBuilder var contenu: () -> Contenu

    var body: some View {
        VStack(alignment: .leading, spacing: HZEspace.entreCommandes) {
            contenu()
        }
        .padding(HZEspace.groupe)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(fond, in: RoundedRectangle(cornerRadius: HZRayon.groupe, style: .circular))
    }
}

/// UNE JAUGE : un rail et son remplissage. `fraction` entre 0 et 1.
struct HZJauge: View {
    let fraction: Double
    var couleur: Color = HZCouleur.encre
    var rail: Color = HZCouleur.filetGroupe
    var epaisseur: CGFloat = HZHub.epaisseurDeLaJauge

    var body: some View {
        GeometryReader { geometrie in
            ZStack(alignment: .leading) {
                Capsule().fill(rail)
                Capsule().fill(couleur)
                    .frame(width: geometrie.size.width * HZHub.borner(fraction))
            }
        }
        .frame(height: epaisseur)
        .accessibilityHidden(true)
    }
}

/// LA COURONNE D'UN POURCENTAGE : un anneau qui se remplit, pour le « % de l'objectif » d'une ligne.
struct HZCouronne: View {
    let fraction: Double
    var couleur: Color = HZCouleur.encre

    var body: some View {
        ZStack {
            Circle().stroke(HZCouleur.filetGroupe, lineWidth: HZHub.traitDeLaCouronne)
            Circle()
                .trim(from: 0, to: HZHub.borner(fraction))
                .stroke(couleur, style: StrokeStyle(lineWidth: HZHub.traitDeLaCouronne, lineCap: .round))
                .rotationEffect(.degrees(-HZHub.quartDeTour))
        }
        .frame(width: HZHub.coteDeLaCouronne, height: HZHub.coteDeLaCouronne)
        .accessibilityHidden(true)
    }
}

extension HZHub {
    static let quartDeTour: Double = 90
    static let dureeDeLOnglet: Double = 0.2
    static let dureeDeLaJauge: Double = 0.4
    static let tailleDuNiveau: CGFloat = 52
    static let largeurDuPrix: CGFloat = 0.5
    static let centPourcent: Double = 100
    static let opaciteNormale: Double = 1
    static let opaciteEteinte: Double = 0.4
}

// MARK: - La feuille modale, la même partout

extension HZHub {
    static let hautDeFeuille: CGFloat = 12
    static let basDeFeuille: CGFloat = 28
}

/// LA FEUILLE QU'ON PRÉSENTE PAR-DESSUS UN ÉCRAN — une seule, pour toutes : coins de 30 en haut, la
/// poignée du système, un titre d'affichage de 22, un bouton rond de fermeture de 44, et des actions
/// en pilules (`HZBoutonPilule`) dans le contenu.
///
/// On l'utilise EN DEHORS de la présentation : `.sheet { HZFeuilleModale(titre:) { … }.hzFeuille() }`.
/// `HZFeuilleModale` dessine le contenu de la feuille, `hzFeuille` règle la présentation (hauteurs,
/// rayon, fond, poignée) — deux choses, parce que la seconde ne se pose que sur la vue présentée.
struct HZFeuilleModale<Contenu: View>: View {
    @Environment(\.dismiss) private var dismiss

    let titre: String
    var fermer: (() -> Void)? = nil
    @ViewBuilder var contenu: () -> Contenu

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: HZEspace.entreCommandes) {
                Text(titre)
                    .hzAffichage(.section)
                    .foregroundStyle(HZCouleur.encre)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HZBoutonRond(dessin: .fermer, nom: String(localized: "Fermer"), diametre: .outil,
                             fond: HZCouleur.surfaceClaire, couleur: HZCouleur.encre,
                             cote: HZHub.coteDeLaCroix, trait: HZHub.traitDeLaCroix) {
                    if let fermer { fermer() } else { dismiss() }
                }
            }
            .padding(.horizontal, HZEspace.marge)
            .padding(.top, HZHub.hautDeFeuille)
            .padding(.bottom, HZEspace.sousUnTitre)
            contenu()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(HZCouleur.blanc)
    }
}

struct HZReglageDeFeuille: ViewModifier {
    var detents: Set<PresentationDetent> = [.medium, .large]
    var gereSonBas: Bool = false

    func body(content: Content) -> some View {
        Group {
            if gereSonBas {
                content
            } else {
                content.safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: HZHub.basDeFeuille)
                }
            }
        }
        .presentationDetents(detents)
        .presentationDragIndicator(.visible)
        .presentationBackground(HZCouleur.blanc)
        .presentationCornerRadius(HZRayon.feuille)
    }
}

extension View {
    /// La présentation d'une feuille : ses hauteurs, son rayon de 30, son fond, sa poignée.
    func hzFeuille(detents: Set<PresentationDetent> = [.medium, .large],
                   gereSonBas: Bool = false) -> some View {
        modifier(HZReglageDeFeuille(detents: detents, gereSonBas: gereSonBas))
    }
}

/// UNE LIGNE DE PERSONNE : sa photo, son nom, une ligne en gris dessous, et ce qu'on veut à droite
/// (un bouton pilule, un chevron, deux boutons ronds). Toucher la personne ouvre son profil ; la
/// queue a ses propres boutons, qui ne se confondent pas avec la ligne.
struct HZLigneDePersonne<Queue: View>: View {
    let nom: String
    var sousTitre: String? = nil
    let photo: HZPhotoDePersonne
    var filet: Bool = true
    var nomDuBouton: String
    let ouvrir: () -> Void
    @ViewBuilder var queue: () -> Queue

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: HZMesuresDeLigne.ecart) {
                Button(action: ouvrir) {
                    HStack(spacing: HZMesuresDeLigne.ecart) {
                        photo
                        VStack(alignment: .leading, spacing: 0) {
                            Text(nom)
                                .hzTexte(.c16, .semi)
                                .foregroundStyle(HZCouleur.encre)
                            if let sousTitre {
                                Text(sousTitre)
                                    .hzTexte(.c13, .medium)
                                    .foregroundStyle(HZCouleur.secondaireSurClair)
                            }
                        }
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(nomDuBouton)
                queue()
            }
            .padding(.vertical, HZMesuresDeLigne.margeDeSortie)
            if filet {
                Rectangle()
                    .fill(HZCouleur.filetFeuille)
                    .frame(height: HZMesuresDeLigne.filet)
            }
        }
    }
}

/// LE BOUTON « SUIVRE » : pilule noire pour suivre, grise une fois suivi (ou demandé).
struct HZBoutonSuivre: View {
    let libelle: String
    let suivi: Bool
    let action: () -> Void

    var body: some View {
        HZBoutonPilule(libelle: libelle, hauteur: .petite,
                       fond: suivi ? HZCouleur.surfaceClaire : HZCouleur.encre,
                       couleur: suivi ? HZCouleur.encre : HZCouleur.blanc, action: action)
    }
}

extension HZHub {
    static let distanceCourte: Double = 6
    static let distanceLongue: Double = 15
    static let tiers: Double = 3
    static let debordDeLaZone: Double = 0.6
    static let traitDeLaCarte: CGFloat = 3.5
    static let traitDeLaCarteChoisie: CGFloat = 6
    static let cotePuce: CGFloat = 28
    static let opaciteDeLOmbre: Double = 0.18
    static let flouDeLOmbre: CGFloat = 8
    static let decalageDeLOmbre: CGFloat = 3
    static let largeurDeLaCarteDItineraire: CGFloat = 290
}

extension HZHub {
    static let lettresPourChercher = 2
    static let colonnesDAffiches = 2
}

extension HZHub {
    static let heureDuSoir = 17
    static let attenteApresFermeture = 350
    static let attenteApresFermetureDeFeuille = 400
    static let delaiDeRecherche = 300

    /// Une fraction ramenée entre zéro et un : une jauge ne déborde pas de son rail.
    static func borner(_ fraction: Double) -> Double { min(max(fraction, 0), 1) }
}

extension HZHub {
    static let lignesDUnTitre = 3
}

/// LES ALLURES D'UNE SORTIE, ramenées à une forme : 0 pour le kilomètre le plus rapide, 1 pour le plus
/// lent. C'est ce que dessine `HZCourbeDAllure`, et ce qui fixe la longueur des barres de `HZSplits`.
enum HZAllures {
    static let neutre: Double = 0.5

    static func normalisees(_ splits: [String]) -> [Double] {
        let secondes = splits.map { PaceModel.parseSecPerKm($0) }
        let connues = secondes.compactMap { $0 }
        guard let plusRapide = connues.min(), let plusLent = connues.max(), plusLent > plusRapide else {
            return splits.map { _ in neutre }
        }
        return secondes.map { valeur in
            guard let valeur else { return neutre }
            return (valeur - plusRapide) / (plusLent - plusRapide)
        }
    }
}

/// UN CHAMP DE TEXTE de formulaire : son titre en gris au-dessus, la saisie dans une pastille claire.
struct HZChampDeTexte: View {
    let titre: String
    let invite: String
    @Binding var texte: String
    var clavier: UIKeyboardType = .default
    var majuscules: TextInputAutocapitalization = .sentences
    var lignes: ClosedRange<Int> = HZHub.uneLigne

    var body: some View {
        VStack(alignment: .leading, spacing: HZEspace.entrePilules) {
            Text(titre)
                .hzTexte(.c13, .semi)
                .foregroundStyle(HZCouleur.secondaireSurClair)
            TextField(text: $texte,
                      prompt: Text(invite).foregroundStyle(HZCouleur.secondaireSurClair),
                      axis: .vertical) { EmptyView() }
                .accessibilityLabel(titre)
                .keyboardType(clavier)
                .textInputAutocapitalization(majuscules)
                .lineLimit(lignes)
                .font(HZPolice.texte(.c16, .semi))
                .foregroundStyle(HZCouleur.encre)
                .tint(HZCouleur.encre)
                .padding(.horizontal, HZEspace.groupe)
                .padding(.vertical, HZEspace.tuile)
                .frame(minHeight: HZHub.hauteurDuChamp, alignment: .leading)
                .background(HZCouleur.surfaceClaire,
                            in: RoundedRectangle(cornerRadius: HZRayon.bandeau, style: .circular))
        }
    }
}

extension HZHub {
    static let uneLigne: ClosedRange<Int> = 1...1
    static let opaciteDesPaires: Double = 0.55
    static let seuilDUsure: Double = 0.8
    static let cotePuceDeKm: CGFloat = 84
    static let reductionDesKilometres: CGFloat = 0.6
}

/// LES QUATRE PÉRIODES des Stats et de la carte de chaleur : 7 jours, 4 semaines, 3 mois, 1 an.
enum HZPeriode: CaseIterable, Identifiable {
    case week, month, quarter, year
    var id: Self { self }

    var libelle: String {
        switch self {
        case .week: return String(localized: "7 j")
        case .month: return String(localized: "4 sem.")
        case .quarter: return String(localized: "3 mois")
        case .year: return String(localized: "1 an")
        }
    }

    var days: Int {
        switch self {
        case .week: return HZStats.joursDeLaSemaine
        case .month: return HZStats.joursDuMois
        case .quarter: return HZStats.joursDuTrimestre
        case .year: return HZStats.jourParAn
        }
    }
}

extension HZHub {
    static let margeDuCadrage: Double = 1.3
    static let cadrageMinimal: Double = 0.01
    static let opaciteDUnTrace: Double = 0.3
}

extension HZHub {
    static let moitieDeLEtendue: Double = 2
}

/// UNE RÉPONSE TAPABLE : une grande ligne sur la surface claire, la choisie en noir.
struct HZReponse: View {
    let titre: String
    var precision: String? = nil
    var choisie: Bool = false
    var disponible: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: HZEspace.groupe) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(titre)
                        .hzTexte(.c17, .gras)
                        .foregroundStyle(choisie ? HZCouleur.blanc : HZCouleur.encre)
                    if let precision {
                        Text(precision)
                            .hzParagraphe(.c13, .medium, interligne: HZBandeauDuCoach.interligne)
                            .foregroundStyle(choisie ? HZCouleur.secondaireSurSombre : HZCouleur.secondaireSurClair)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if choisie {
                    HZIcone(dessin: .coche, cote: HZHub.coteDeLIcone, trait: HZHub.traitDeLIcone,
                            couleur: HZCouleur.blanc)
                }
            }
            .padding(.horizontal, HZEspace.marge)
            .padding(.vertical, HZEspace.tuile)
            .frame(maxWidth: .infinity)
            .frame(minHeight: HZEntree.hauteurDUneReponse)
            .background(choisie ? HZCouleur.encre : HZCouleur.surfaceClaire,
                        in: RoundedRectangle(cornerRadius: HZRayon.tuile, style: .circular))
            .contentShape(RoundedRectangle(cornerRadius: HZRayon.tuile, style: .circular))
            .opacity(disponible ? HZHub.opaciteNormale : HZHub.opaciteEteinte)
        }
        .buttonStyle(.plain)
        .disabled(!disponible)
        .accessibilityAddTraits(choisie ? .isSelected : [])
    }
}

/// LA PROGRESSION : un segment par question, plein jusqu'à celle où l'on est.
struct HZSegments: View {
    let total: Int
    let courant: Int

    var body: some View {
        HStack(spacing: HZEntree.ecartDesSegments) {
            ForEach(0..<total, id: \.self) { rang in
                Capsule()
                    .fill(rang <= courant ? HZCouleur.encre : HZCouleur.filetGroupe)
                    .frame(height: HZEntree.hauteurDUnSegment)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Question \(courant + 1) sur \(total)"))
    }
}

extension HZHub {
    /// La région qui contient ces points, avec de l'air autour ; `nil` s'il n'y en a pas.
    static func cadre(de points: [CLLocationCoordinate2D]) -> MKCoordinateRegion? {
        guard let premier = points.first else { return nil }
        var minLat = premier.latitude, maxLat = premier.latitude
        var minLng = premier.longitude, maxLng = premier.longitude
        for point in points {
            minLat = min(minLat, point.latitude); maxLat = max(maxLat, point.latitude)
            minLng = min(minLng, point.longitude); maxLng = max(maxLng, point.longitude)
        }
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: (minLat + maxLat) / moitieDeLEtendue,
                                           longitude: (minLng + maxLng) / moitieDeLEtendue),
            span: MKCoordinateSpan(latitudeDelta: max((maxLat - minLat) * margeDuCadrage, cadrageMinimal),
                                   longitudeDelta: max((maxLng - minLng) * margeDuCadrage, cadrageMinimal)))
    }
}
