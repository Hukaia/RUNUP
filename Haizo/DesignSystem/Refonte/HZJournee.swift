import CoreText
import SwiftUI
import UIKit

/// LES MESURES DE LA JOURNÉE ET DES FEUILLES DE SÉANCE : le détail d'une séance, son déplacement,
/// son enregistrement à la main, le bilan d'après une sortie, l'ajout d'une sortie, la page
/// « Ta journée », et les deux images qu'on partage (la carte, la vidéo).
///
/// Aucune de ces vues n'écrit un nombre : tout ce qui est une marge, une taille, une opacité, une
/// durée, un seuil ou un plafond se déclare ici, nommé par ce qu'il sert.
enum HZJournee {

    // MARK: - Le détail d'une séance

    /// Un bloc de travail ne descend pas sous cette durée, même sur une séance courte.
    static let minutesMiniDUnBloc = 10
    /// L'échauffement et le retour au calme que la séance compte avant et après son bloc tempo.
    static let minutesDEchauffementEtDeRetour = 20
    /// La barre colorée qui ouvre une étape, ou un jour dans la liste du déplacement.
    static let largeurDeLaBarre: CGFloat = 3
    static let rayonDeLaBarre: CGFloat = 2
    static let hauteurDeLaBarreDeJour: CGFloat = 34
    static let entreTitreEtDetail: CGFloat = 2

    // MARK: - L'enregistrement d'une séance faite

    static let dureeMaximaleDUneSeance = 600
    static let distanceMaximaleDUneSeance: Double = 300
    static let dureeMaximaleDUneJournee: Double = 1440
    static let uniteDeDuree = "min"
    static let uniteDeDistance = "km"
    static let exempleDeDuree = "45"
    static let largeurDuChampNumerique: CGFloat = 72

    // MARK: - Le bilan

    /// En dessous, une séance n'a pas de distance mesurée : le fil ne dit pas « a couru 0,0 km ».
    static let distanceMiniMesuree: Double = 0.05
    /// Ce que crédite une séance validée, en points d'expérience.
    static let xpDUneSeance = 120
    static let dixiemes: Double = 10
    static let secondesParMinute = 60
    /// Le délai laissé à la demande d'avis pour s'accrocher à la fenêtre avant qu'on la ferme.
    static let attenteAvantLaFermeture = 600
    static let largeurDeLIcone: CGFloat = 20

    // MARK: - La page « Ta journée »

    static let objectifsUnJourDeRepos = 2
    static let objectifsUnJourDeSeance = 3
    static let coteDeLAnneau: CGFloat = 196
    static let traitDeLAnneau: CGFloat = 24
    static let dureeDeLAnneau: Double = 0.9
    static let dureeDuChargement: Double = 0.2
    static let echelleInitiale: CGFloat = 0.85
    static let echelleFinale: CGFloat = 1
    static let reponseDuRessort: Double = 0.45
    static let amortissementDuRessort: Double = 0.6
    static let uniteDEnergie = "kcal"

    // MARK: - Les images qu'on partage : la même taille d'un téléphone, quel que soit l'écran

    static let largeurDeLImage: CGFloat = 360
    static let hauteurDeLImage: CGFloat = 640
    static let deuxCotes: CGFloat = 2
    static let metresParKilometre: Double = 1000

    /// La fonte d'interface à une taille FIXE : une image rendue ne suit pas le réglage de taille
    /// du texte de celui qui la partage.
    static func police(_ taille: CGFloat, _ graisse: HZGraisse, tabulaire: Bool = false) -> Font {
        Font(HZPolice.uiFonte(taille: taille, graisse: graisse.rawValue,
                              largeur: HZPolice.largeurDInterface, tabulaire: tabulaire) as CTFont)
    }

    /// Le carré qui entoure un point, pour dessiner un disque centré dessus.
    static func pastille(en point: CGPoint, rayon: CGFloat) -> CGRect {
        CGRect(x: point.x - rayon, y: point.y - rayon, width: rayon * deuxCotes, height: rayon * deuxCotes)
    }

    // MARK: - La carte de partage

    static let sousLeRecord: CGFloat = 10
    static let coteDuTrace: CGFloat = 200
    static let sousLeTrace: CGFloat = 8
    static let entreLesMesures: CGFloat = 18
    static let entreLibelleEtValeur: CGFloat = 2
    static let auDessusDeLaSignature: CGFloat = 24
    static let entreLesLignesDeLaSignature: CGFloat = 6
    static let entreLaMarqueEtLeMot: CGFloat = 8
    static let coteDeLaMarque: CGFloat = 22
    static let rayonDeLaMarque: CGFloat = 6
    static let tailleDuLibelle: CGFloat = 16
    static let tailleDeLaDate: CGFloat = 9.5
    static let tailleDeLAdresse: CGFloat = 8
    /// Une mesure qui ne tient pas sur sa ligne rétrécit avant de se couper.
    static let reductionDeLaMesure: CGFloat = 0.6
    /// La distance, en grand ; le temps et l'allure, en chiffres de tuile.
    static let distanceDeLaCarte = HZAffichage(58, -2.5)
    static let mesureDeLaCarte = HZAffichage.chiffre

    /// L'UNIQUE OMBRE de la carte : une seule, douce, posée sur le texte blanc. La carte est
    /// transparente et se pose sur la photo de la coureuse : du blanc sur un ciel clair ne se lit
    /// pas sans elle. Les deux autres styles n'en ont pas : le noir est écrit pour les photos
    /// claires, le style Haizo porte son propre fond.
    static let ombreDuTexte = HZCouleur.noirFranc.opacity(0.35)
    static let flouDeLOmbre: CGFloat = 3
    static let decalageDeLOmbre: CGFloat = 1

    // Le tracé : un seul trait net, en aplat d'accent.
    static let margeDuTrace: CGFloat = 20
    static let traitDuTrace: CGFloat = 4
    static let rayonDuDepart: CGFloat = 4
    static let rayonDeLArrivee: CGFloat = 5

    // MARK: - L'image de la vidéo

    /// Trois : 1080 × 1920, le neuf-seizièmes que tous les réseaux acceptent sans recadrer.
    static let echelleDeLaVideo: CGFloat = 3
    static let hautDeLaVideo: CGFloat = 52
    static let basDeLaVideo: CGFloat = 44
    static let coteDuTraceDeLaVideo: CGFloat = 300
    static let autourDuTraceDeLaVideo: CGFloat = 14
    static let traitDuTraceDeLaVideo: CGFloat = 4
    static let pointsDuTrace = 320
    static let entreTitreEtDate: CGFloat = 6
    static let margeDuTitreDeLaVideo: CGFloat = 30
    static let lignesDuTitreDeLaVideo = 2
    static let tailleDuLibelleDeLaVideo: CGFloat = 14
    static let margeDesCompteurs: CGFloat = 18
    static let reductionDuCompteur: CGFloat = 0.5
    static let coteDeLaSignature: CGFloat = 24
}
