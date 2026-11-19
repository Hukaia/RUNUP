import SwiftUI

/// LES MESURES DES FEUILLES DU FIL : commentaires, modifier une sortie, modifier une annonce,
/// publier un itinéraire, fiche d'un itinéraire. Les marges, les rayons et les teintes viennent de
/// `HZEspace`, `HZRayon` et `HZCouleur` : ne sont déclarées ici que les mesures propres à ces
/// feuilles, et les bornes de leur logique (longueurs permises, taille d'une photo).
enum HZFeuillesDuFil {
    // MARK: - Les champs

    /// Un titre de sortie : 80 signes au plus.
    static let longueurDUnTitre = 80
    /// Une note de sortie, ou le texte d'une annonce : 500 signes, la même borne que le serveur.
    static let longueurDUnTexte = 500
    /// À moins de 80 signes de la borne, le compteur apparaît.
    static let margeDuCompteur = 80
    /// Les lignes d'une annonce qu'on corrige.
    static let lignesDUneAnnonce: ClosedRange<Int> = 4...12
    /// Les lignes de la note d'une sortie.
    static let lignesDUneNote: ClosedRange<Int> = 3...8
    /// Les lignes de ce qu'il faut savoir d'un itinéraire.
    static let lignesDesNotes: ClosedRange<Int> = 2...4

    // MARK: - Les photos

    /// Le côté long d'une photo avant l'envoi, et sa qualité JPEG : ce qui tient sous les 500 ko
    /// que le serveur accepte.
    static let coteMaxDUnePhoto: CGFloat = 1080
    static let qualiteDUnePhoto: CGFloat = 0.6
    /// La photo d'une sortie qu'on modifie, celle d'un itinéraire qu'on publie, celle de sa fiche.
    static let hauteurDeLaPhotoDeSortie: CGFloat = 170
    static let hauteurDeLaPhotoAjoutee: CGFloat = 150
    static let hauteurDeLaPhotoDeFiche: CGFloat = 200

    // MARK: - Les cartes

    /// L'aperçu du tracé qui sera publié, et la carte de la fiche.
    static let hauteurDeLApercu: CGFloat = 160
    static let hauteurDeLaCarte: CGFloat = 220
    /// Un parcours sans point : la carte s'ouvre sur son départ, à 0,02 degré de large. Un parcours
    /// minuscule ne se cadre pas plus serré que 0,005.
    static let etendueSansTrace: Double = 0.02
    static let etendueMinimale: Double = 0.005

    // MARK: - Les rangées

    /// Les deux tuiles par ligne de la fiche d'un itinéraire.
    static let colonnesDeMesures = 2
    /// Le nom de la personne et la date, au-dessus du texte d'un commentaire.
    static let ecartDuCommentaire: CGFloat = 4
}

/// UN COMMENTAIRE : la photo de la personne, son nom, la date en gris, puis ce qu'elle a écrit sur
/// plusieurs lignes. Toucher la photo ou le nom ouvre son profil ; le texte, lui, se sélectionne.
///
/// `HZLigneDePersonne` ne convient pas : elle tient sur une ligne, et un commentaire n'en a pas la
/// mesure.
struct HZLigneDeCommentaire: View {
    let nom: String
    let date: String
    let texte: String
    let photo: HZPhotoDePersonne
    /// Ce que VoiceOver annonce sur la photo et le nom.
    let nomDuProfil: String
    /// Faux sur ses propres commentaires : on n'ouvre pas son propre profil depuis ici.
    var ouvrable: Bool = true
    var filet: Bool = true
    let ouvrir: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: HZMesuresDeLigne.ecart) {
                Button(action: ouvrir) { photo }
                    .buttonStyle(.plain)
                    .disabled(!ouvrable)
                    .accessibilityLabel(nomDuProfil)
                corps
            }
            .padding(.vertical, HZMesuresDeLigne.margeDeSortie)
            if filet {
                Rectangle()
                    .fill(HZCouleur.filetFeuille)
                    .frame(height: HZMesuresDeLigne.filet)
            }
        }
    }

    private var corps: some View {
        VStack(alignment: .leading, spacing: HZFeuillesDuFil.ecartDuCommentaire) {
            VStack(alignment: .leading, spacing: 0) {
                Button(action: ouvrir) {
                    Text(nom)
                        .hzTexte(.c16, .semi)
                        .foregroundStyle(HZCouleur.encre)
                        .lineLimit(1)
                }
                .buttonStyle(.plain)
                .disabled(!ouvrable)
                Text(date)
                    .hzTexte(.c13, .medium)
                    .foregroundStyle(HZCouleur.secondaireSurClair)
                    .lineLimit(1)
            }
            Text(texte)
                .hzParagraphe(.c15, .medium, interligne: HZBandeauDuCoach.interligne)
                .foregroundStyle(HZCouleur.encre)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// UN AVIS dans une feuille : une erreur à dire, une note à lire. Un bandeau de la surface claire,
/// le texte en encre — la même forme que l'erreur de la connexion.
struct HZAvisDeFeuille: View {
    let texte: String
    var graisse: HZGraisse = .semi

    var body: some View {
        Text(texte)
            .hzParagraphe(.c14, graisse, interligne: HZBandeauDuCoach.interligne)
            .foregroundStyle(HZCouleur.encre)
            .fixedSize(horizontal: false, vertical: true)
            .padding(HZEspace.groupe)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(HZCouleur.surfaceClaire,
                        in: RoundedRectangle(cornerRadius: HZRayon.bandeau, style: .circular))
    }
}

/// LE BAS D'UNE FEUILLE : ce qu'on épingle sous le défilement — l'action principale, ou le champ
/// d'écriture. Il se pose dans `.safeAreaInset(edge: .bottom)` ; la feuille qui l'emploie se
/// présente avec `gereSonBas: true`.
struct HZBasDeFeuille<Contenu: View>: View {
    @ViewBuilder var contenu: () -> Contenu

    var body: some View {
        VStack(alignment: .leading, spacing: HZEspace.entreCommandes) {
            contenu()
        }
        .padding(.horizontal, HZEspace.marge)
        .padding(.top, HZEspace.entreCommandes)
        .padding(.bottom, HZEspace.entreCommandes)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HZCouleur.blanc)
    }
}
