import SwiftUI

/// LES MESURES DES ÉCRANS DE COURSE : l'objectif (`RaceGoalView`), la page d'une course
/// (`RacePageView`), l'ajout d'une course (`CreateRaceSheet`) et les trois feuilles du jour J
/// (ultra, triathlon, duathlon).
///
/// Une vue de la refonte ne contient pas un nombre : ce qui était écrit en dur dans ces six écrans —
/// une marge, un seuil, une part de la distance, un code de réponse du serveur — est nommé ici, par
/// ce à quoi il sert. Les valeurs sont celles que les écrans portaient avant d'être refaits.
enum HZCourse {

    // MARK: - Mise en page

    /// Sous la date, dans le haut noir de l'objectif : les trois mesures.
    static let sousLaDate: CGFloat = 22
    /// Une date longue (« mercredi 17 septembre ») rétrécit plutôt que de se couper.
    static let reductionDeLaDate: CGFloat = 0.8
    /// Un chrono libre (« Sous 1h30 ») dans un tiers de l'écran rétrécit plutôt que de se couper.
    static let reductionDUneMesure: CGFloat = 0.5
    /// Une valeur en bout de ligne (un chrono visé libre) rétrécit avant de pousser son titre.
    static let reductionDUneValeur: CGFloat = 0.7
    /// Un chiffre du jour J (« 60-90 », « 300-600 ») dans un tiers de largeur.
    static let reductionDUnChiffre: CGFloat = 0.5
    /// La forme du plan, verrouillée hors abonnement : de quoi la reconnaître, pas la lire.
    static let hauteurDeLApercu: CGFloat = 140

    // MARK: - Les puces des feuilles du jour J

    static let entreLesPuces: CGFloat = 8
    static let diametreDeLaPuce: CGFloat = 5
    /// De quoi centrer la puce sur la première ligne d'un paragraphe de 14 points à 1,35.
    static let hautDeLaPuce: CGFloat = 7

    // MARK: - Le tableau d'allure du jour J

    /// Faute de distance de course : celle d'un 10 km.
    static let kilometresParDefaut: Double = 10
    /// Une course plus courte n'est pas découpée en phases.
    static let kilometresMinimauxDuTableau = 3
    /// Le départ contrôlé occupe le premier cinquième, le rythme cible court jusqu'aux trois quarts.
    static let partDuDepart: Double = 0.2
    static let partDeLaCroisiere: Double = 0.75
    /// En secondes au kilomètre : le départ est plus lent que l'allure cible, la relance et le
    /// sprint plus rapides. Jamais sous la minute au kilomètre.
    static let retardDuDepart: Double = 8
    static let gainDeLaRelance: Double = 5
    static let gainDuSprint: Double = 20
    static let allureMinimale: Double = 60

    // MARK: - Le temps visé

    /// Le chrono d'un triathlon s'écrit toujours « H:MM » : deux morceaux.
    static let boutsDUnChrono = 2
    static let minutesParHeure = 60
    static let secondesParMinute = 60
    /// Sous trente minutes — donc quand on ne sait pas — les totaux se taisent.
    static let minutesMinimalesPourUnTotal = 30
    /// Faute de jours restants, le pluriel : « Jours » et non « Jour ».
    static let nombreDeRepliPourLePluriel = 2
    /// Sur une ligne de coureur, la pastille « cherche quelqu'un » garde sa place avant le nom.
    static let prioriteDeLaPastille: Double = 1

    // MARK: - La participation à une course

    /// 2 min/km est plus rapide qu'un record du monde, 20 min/km est de la marche : au-delà, c'est
    /// une lecture ratée du chrono, pas un objectif.
    static let allureMinimaleVisee: Double = 120
    static let allureMaximaleVisee: Double = 1200
    /// Deux allures à moins de quinze secondes l'une de l'autre se courent ensemble.
    static let ecartDAllureProche = 15
    /// Le message qu'on écrit sur le mur : de une à cinq lignes.
    static let lignesDeLaRedaction: ClosedRange<Int> = 1...5

    // MARK: - Ajouter une course

    static let secondesParJour: TimeInterval = 86_400
    /// La date proposée à la création : dans deux mois.
    static let joursAvantLaCourseParDefaut = 60
    static let delaiParDefaut: TimeInterval = secondesParJour * TimeInterval(joursAvantLaCourseParDefaut)

    // MARK: - Les réponses du serveur

    /// « Trop de courses créées », « trop de messages » : le serveur limite par jour.
    static let tropDeRequetes = 429
}

/// UN PARAGRAPHE DES FEUILLES DU JOUR J : du texte à lire, en gris, qui passe à la ligne.
///
/// Il prend un `Text` et non une chaîne : plusieurs phrases portent du gras (`**ta**`), et seul un
/// `Text(LocalizedStringKey)` le lit comme tel.
struct HZParagrapheDeCourse: View {
    let texte: Text

    init(_ texte: Text) { self.texte = texte }

    var body: some View {
        texte
            .hzParagraphe(.c14, .medium, interligne: HZBandeauDuCoach.interligne)
            .foregroundStyle(HZCouleur.secondaireSurClair)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// DES PUCES : une phrase par ligne, précédée d'un point.
///
/// `Text(verbatim:)` et non `Text(_:)` : les lignes arrivent DÉJÀ traduites, résolues par
/// `String(localized:)` chez l'appelant.
struct HZPucesDeCourse: View {
    let lignes: [String]

    var body: some View {
        LazyVStack(alignment: .leading, spacing: HZCourse.entreLesPuces) {
            ForEach(lignes, id: \.self) { ligne in
                HStack(alignment: .top, spacing: HZEspace.entreCommandes) {
                    Circle()
                        .fill(HZCouleur.secondaireSurClair)
                        .frame(width: HZCourse.diametreDeLaPuce, height: HZCourse.diametreDeLaPuce)
                        .padding(.top, HZCourse.hautDeLaPuce)
                    Text(verbatim: ligne)
                        .hzParagraphe(.c14, .medium, interligne: HZBandeauDuCoach.interligne)
                        .foregroundStyle(HZCouleur.secondaireSurClair)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

/// DEUX OU TROIS CHIFFRES CÔTE À CÔTE : une valeur en grand, ce qu'elle mesure dessous, sur la
/// surface claire. « 60-90 » / « g de glucides / h ».
///
/// `HZTuileChiffre` est calibrée pour une demi-largeur et un chiffre de 36 points ; trois valeurs
/// de sept signes ne tiennent pas dans un tiers d'écran. Celle-ci reprend sa surface et sa
/// typographie de ligne (22) et rétrécit la valeur avant de la couper.
struct HZChiffresDeCourse: View {
    /// La valeur, puis son libellé.
    let chiffres: [(String, String)]

    var body: some View {
        HStack(alignment: .top, spacing: HZEspace.entrePilules) {
            ForEach(chiffres.indices, id: \.self) { index in
                chiffre(chiffres[index].0, chiffres[index].1)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func chiffre(_ valeur: String, _ etiquette: String) -> some View {
        VStack(spacing: HZReglages.entreTitreEtPrecision) {
            Text(verbatim: valeur)
                .hzAffichage(.chiffreDeLigne)
                .foregroundStyle(HZCouleur.encre)
                .lineLimit(1)
                .minimumScaleFactor(HZCourse.reductionDUnChiffre)
            Text(etiquette)
                .hzParagraphe(.c12, .semi, interligne: HZBandeauDuCoach.interligne)
                .foregroundStyle(HZCouleur.secondaireSurClair)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, HZEspace.entrePilules)
        .padding(.vertical, HZEspace.tuile)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(HZCouleur.surfaceClaire,
                    in: RoundedRectangle(cornerRadius: HZRayon.mesure, style: .circular))
        .accessibilityElement(children: .combine)
    }
}

/// UNE LIGNE DE LA JOURNÉE : un disque et son symbole, ce qu'on fait, sa distance, et le temps que
/// ça prend. « Vélo · 90 km · 3h00 ».
struct HZLigneDeJournee: View {
    /// Un symbole SF : la natation et le vélo n'ont pas de dessin dans `HZIcone`. Passé en `Image`
    /// pour que le nom du symbole soit écrit chez l'appelant, là où `check_symboles` le lit.
    let symbole: Image
    let titre: String
    let sousTitre: String
    let duree: String
    var filet: Bool = true

    var body: some View {
        HZLigneDeListe(titre: titre, sousTitre: sousTitre, graisse: .gras, filet: filet) {
            symbole
                .font(HZPolice.texte(.c16, .semi))
                .foregroundStyle(HZCouleur.encre)
                .frame(width: HZProfil.disqueDeDestination, height: HZProfil.disqueDeDestination)
                .background(HZCouleur.surfaceClaire, in: Circle())
                .accessibilityHidden(true)
        } queue: {
            Text(verbatim: duree)
                .hzTexte(.c16, .gras, tabulaire: true)
                .foregroundStyle(HZCouleur.encre)
        }
    }
}

/// L'ACTION D'UNE FEUILLE, ÉPINGLÉE EN BAS : une pilule pleine largeur sur un fond blanc, posée par
/// `.safeAreaInset(edge: .bottom)` dans la feuille. La feuille qui l'emploie se présente avec
/// `gereSonBas: true`.
struct HZActionEpinglee: View {
    let libelle: String
    var eteinte: Bool = false
    let action: () -> Void

    var body: some View {
        HZBoutonPilule(libelle: libelle, etendu: true, action: action)
            .opacity(eteinte ? HZHub.opaciteEteinte : HZHub.opaciteNormale)
            .disabled(eteinte)
            .padding(.horizontal, HZEspace.marge)
            .padding(.vertical, HZEspace.entreCommandes)
            .background(HZCouleur.blanc)
    }
}
