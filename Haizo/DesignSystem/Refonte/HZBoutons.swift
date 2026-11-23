import SwiftUI

/// Les diamètres des boutons ronds. Le canvas en emploie sept, chacun pour un usage.
enum HZDiametre: CGFloat {
    /// Le « − » et le « + » d'un compteur, dans les réglages.
    case pas = 36
    /// Une commande d'en-tête : avatar, cloche, retour.
    case commande = 40
    /// Le bouton de filtres, au bout du champ de recherche.
    case filtre = 42
    /// Un outil posé sur la carte, ou l'envoi d'un message.
    case outil = 44
    /// Une catégorie à explorer.
    case categorie = 56
    /// Une des quatre actions de l'accueil.
    case action = 58
    /// Terminer, ou parler au coach, pendant la séance.
    case controle = 62
    /// La pause.
    case principal = 88
}

/// LE BOUTON ROND : un disque, une icône du canvas dedans.
///
/// Le fond, la couleur, la taille de l'icône et son trait sont donnés par l'appelant, parce que
/// le canvas les fait varier d'un emploi à l'autre et que les deviner ici serait réinterpréter.
/// Ce que le composant tient, c'est la forme, la zone tactile et le nom lu par VoiceOver.
struct HZBoutonRond: View {
    let dessin: HZDessin
    /// Ce que VoiceOver annonce. Le bouton n'a pas de texte : sans nom, il serait muet.
    let nom: String
    var diametre: HZDiametre = .commande
    var fond: Color = HZCouleur.voile
    var couleur: Color = HZCouleur.blanc
    var cote: CGFloat = 18
    var trait: CGFloat = 2
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HZIcone(dessin: dessin, cote: cote, trait: trait, couleur: couleur)
                .frame(width: diametre.rawValue, height: diametre.rawValue)
                .background(fond, in: Circle())
                // Un disque de 36 ou de 40 est plus petit que les 44 points qu'un doigt demande :
                // la zone tactile s'étend, le dessin ne bouge pas.
                .frame(minWidth: HZBoutonRond.zoneTactile, minHeight: HZBoutonRond.zoneTactile)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(width: diametre.rawValue, height: diametre.rawValue)
        .accessibilityLabel(nom)
    }

    static let zoneTactile: CGFloat = 44
    /// La flèche de retour est tracée un cran plus gras que les autres commandes.
    static let traitDuRetour: CGFloat = 2.2
}

/// UNE ACTION DE L'ACCUEIL : un bouton rond de 58, son libellé dessous.
///
/// Le libellé s'écrit dans l'encre de l'accent — c'est la règle du rose : un petit texte posé à
/// même la couleur n'est jamais blanc.
struct HZAction: View {
    let dessin: HZDessin
    let libelle: String
    /// La première des quatre est pleine : disque blanc, icône noire. Les autres sont voilées.
    var pleine: Bool = false
    var cote: CGFloat = 20
    var trait: CGFloat = 2
    /// Sur l'accent, la pastille est un voile noir et le libellé l'encre de l'accent ; sur le noir, une
    /// surface sombre et du blanc.
    var fondDeLaPastille: Color = HZCouleur.voile
    var encreDuLibelle: Color = HZCouleur.encreSurAccent
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: HZAction.ecart) {
                HZIcone(dessin: dessin, cote: cote, trait: trait,
                        couleur: pleine ? HZCouleur.noir : HZCouleur.blanc)
                    .frame(width: HZDiametre.action.rawValue, height: HZDiametre.action.rawValue)
                    .background(pleine ? HZCouleur.blanc : fondDeLaPastille, in: Circle())
                Text(libelle)
                    .hzTexte(.c13, .gras)
                    .foregroundStyle(encreDuLibelle)
                    .lineLimit(1)
                    .minimumScaleFactor(HZAction.retraitDuLibelle)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    static let ecart: CGFloat = 8
    /// Le triangle de lecture est plein : à 20 il pèserait plus lourd que les trois icônes au
    /// trait qui le suivent. Le canvas le dessine à 18.
    static let coteDeLecture: CGFloat = 18
    /// Un libellé allemand ou espagnol plus long rétrécit avant de se couper.
    static let retraitDuLibelle: CGFloat = 0.8
}

/// Les quatre hauteurs d'un bouton en pilule.
enum HZHauteurDeBouton: CGFloat {
    /// Inviter, J'y vais, Voir l'offre.
    case petite = 40
    /// Bravo, Commenter.
    case moyenne = 44
    /// La pilule noire d'une réponse du coach : « Appliquer à ma semaine », « Découvrir Haizo Plus ».
    case reponse = 46
    /// Démarrer, Partager.
    case grande = 56

    var corps: HZCorps {
        switch self {
        case .grande: return .c16
        case .reponse: return .c15
        default: return .c14
        }
    }

    var marge: CGFloat {
        switch self {
        case .petite: return 16
        case .moyenne, .reponse: return 18
        case .grande: return 22
        }
    }
}

/// LE BOUTON EN PILULE. Noir ou blanc — jamais dans la couleur d'accent : c'est le brief, et
/// c'est ce qui laisse l'accent aux surfaces et aux chiffres.
struct HZBoutonPilule: View {
    let libelle: String
    var dessin: HZDessin? = nil
    /// Un dessin APRÈS le libellé : le chevron de « Historique ».
    var suite: HZDessin? = nil
    var hauteur: HZHauteurDeBouton = .grande
    var graisse: HZGraisse = .gras
    var fond: Color = HZCouleur.encre
    var couleur: Color = HZCouleur.blanc
    /// Prend toute la largeur offerte. Sinon, celle de son contenu.
    var etendu: Bool = false
    var cote: CGFloat = 18
    var trait: CGFloat = 2
    var ecart: CGFloat = HZBoutonPilule.ecart
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: ecart) {
                if let dessin {
                    HZIcone(dessin: dessin, cote: cote, trait: trait, couleur: couleur)
                }
                Text(libelle)
                    .hzTexte(hauteur.corps, graisse)
                    .foregroundStyle(couleur)
                    .lineLimit(1)
                    // En grand texte, « Déplacer à demain » devenait « Déplacer à dem… » dans la moitié
                    // d'une feuille. Un libellé de bouton rétrécit d'un quart avant de se couper.
                    .minimumScaleFactor(HZBoutonPilule.reductionDuLibelle)
                if let suite {
                    HZIcone(dessin: suite, cote: HZBoutonPilule.coteDeSuite,
                            trait: HZBoutonPilule.traitDeSuite, couleur: couleur)
                }
            }
            .padding(.horizontal, hauteur.marge)
            .frame(maxWidth: etendu ? .infinity : nil)
            .frame(height: hauteur.rawValue)
            .background(fond, in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    static let ecart: CGFloat = 8
    /// Devant le triangle de lecture, plus massif qu'une icône au trait.
    static let ecartDeLecture: CGFloat = 10
    /// Jusqu'où un libellé rétrécit avant d'être coupé par des points de suspension.
    static let reductionDuLibelle: CGFloat = 0.75
    /// Le triangle de lecture, dans une pilule : 14, là où une icône au trait en fait 18.
    static let coteDeLecture: CGFloat = 14
    /// Le chevron qui suit un libellé : 14 de côté, tracé à 2,4, à six points du mot.
    static let coteDeSuite: CGFloat = 14
    static let traitDeSuite: CGFloat = 2.4
    static let ecartDeSuite: CGFloat = 6
}

/// L'AVATAR : des initiales dans un disque. Il ouvre le profil — c'est par lui qu'on y entre
/// depuis que le profil a quitté la barre.
struct HZAvatar: View {
    let initiales: String
    /// Ce que VoiceOver annonce : « Profil ».
    let nom: String
    var fond: Color = HZCouleur.voile
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(initiales)
                .hzTexte(.c14, .gras)
                .foregroundStyle(HZCouleur.blanc)
                .lineLimit(1)
                .frame(width: HZDiametre.commande.rawValue, height: HZDiametre.commande.rawValue)
                .background(fond, in: Circle())
                .frame(minWidth: HZBoutonRond.zoneTactile, minHeight: HZBoutonRond.zoneTactile)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(width: HZDiametre.commande.rawValue, height: HZDiametre.commande.rawValue)
        .accessibilityLabel(nom)
    }

    /// Les initiales d'une personne : la première lettre du prénom, celle du nom s'il y en a un.
    ///
    /// La capitale est posée ici, à l'exécution, et c'est voulu : une initiale s'écrit en
    /// capitale quelle que soit la casse dans laquelle la personne a saisi son nom. Ce n'est pas
    /// un libellé en majuscules — voir `PERMIS_A_LA_VOLEE` dans `check_majuscules.py`.
    static func initiales(prenom: String, nom: String?) -> String {
        (prenom.prefix(1) + (nom ?? "").prefix(1)).uppercased()
    }
}

/// L'AMORCE DE RECHERCHE : la pilule voilée de l'accueil, qui mène à Explorer. Ce n'est pas un
/// champ : on n'y écrit pas, on la touche.
struct HZAmorceDeRecherche: View {
    let invite: String
    var fond: Color = HZCouleur.voile
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: HZAmorceDeRecherche.ecart) {
                HZIcone(dessin: .recherche, cote: HZAmorceDeRecherche.loupe,
                        trait: HZAmorceDeRecherche.trait, couleur: HZCouleur.blanc)
                Text(invite)
                    .hzTexte(.c15, .semi)
                    .foregroundStyle(HZCouleur.blanc)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, HZAmorceDeRecherche.marge)
            .frame(height: HZDiametre.commande.rawValue)
            .background(fond, in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    static let ecart: CGFloat = 8
    static let loupe: CGFloat = 16
    static let trait: CGFloat = 2.2
    static let marge: CGFloat = 14
}

/// UNE CATÉGORIE À EXPLORER : un disque clair, une icône au trait fin, son nom dessous.
struct HZCategorie: View {
    let dessin: HZDessin
    let libelle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: HZAction.ecart) {
                HZIcone(dessin: dessin, cote: HZCategorie.icone, trait: HZCategorie.trait,
                        couleur: HZCouleur.encre)
                    .frame(width: HZDiametre.categorie.rawValue, height: HZDiametre.categorie.rawValue)
                    .background(HZCouleur.surfaceClaire, in: Circle())
                Text(libelle)
                    .hzTexte(.c12, .semi)
                    .foregroundStyle(HZCouleur.encre)
                    .lineLimit(1)
                    .minimumScaleFactor(HZAction.retraitDuLibelle)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    static let icone: CGFloat = 22
    /// Plus fin que partout ailleurs : ces cinq icônes sont des illustrations, pas des commandes.
    static let trait: CGFloat = 1.8
}

/// La vignette carrée d'une sortie, dans une liste : son tracé en blanc sur le noir.
struct HZVignette<Contenu: View>: View {
    @ViewBuilder var contenu: () -> Contenu

    var body: some View {
        contenu()
            .frame(width: HZMesuresDeLigne.vignette, height: HZMesuresDeLigne.vignette)
            .background(HZCouleur.encre,
                        in: RoundedRectangle(cornerRadius: HZRayon.vignette, style: .circular))
    }
}
