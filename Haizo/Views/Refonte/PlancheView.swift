#if DEBUG
import SwiftUI

/// LA PLANCHE DE LA REFONTE — les jetons et les composants de base, photographiables.
///
/// # CE QU'ELLE EST
///
/// L'étape 1 de la méthode du 17 novembre : « Écris les tokens et les composants de base. Montre-
/// moi une capture de la planche. J'approuve avant la suite. » Rien ici n'est un écran de l'app :
/// aucune donnée n'est branchée, aucune commande ne mène nulle part.
///
/// # POURQUOI QUATRE DE SES SIX PAGES RECOPIENT UN MORCEAU DU CANVAS
///
/// Un composant montré seul sur un fond gris ne prouve rien : on ne peut le comparer à rien. Les
/// pages 3 à 6 remontent donc, avec les seuls composants, le haut de l'accueil, sa feuille, le
/// haut du plan et le haut des stats — aux contenus d'exemple du canvas, mot pour mot. Chaque
/// capture se pose alors à côté du rendu de la référence, et l'écart se mesure.
///
/// Ces contenus sont des SPÉCIMENS, pas des textes de l'app : ils ne passent pas par le
/// catalogue, et tout le fichier est sous `#if DEBUG`. La construction livrée n'en contient pas
/// une ligne.
///
/// `--planche=3`, avec `--captures` : voir `CaptureSeed.plancheDemandee`.
struct PlancheView: View {
    let page: HZPlanche.Page
    @State private var onglet: HZOnglet = .aujourdhui
    @State private var ongletDesStats: HZOnglet = .stats

    var body: some View {
        Group {
            switch page {
            case .jetons: jetons
            case .typographie: typographie
            case .accueilHaut: accueilHaut
            case .accueilBas: accueilBas
            case .plan: plan
            case .stats: stats
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea()
    }

    private func legende(_ texte: String) -> some View {
        Text(verbatim: texte)
            .font(HZPolice.texte(.c12, .semi))
            .foregroundStyle(HZCouleur.secondaireSurClair)
            .padding(.top, HZPlanche.avantUneLegende)
            .padding(.bottom, HZPlanche.apresUneLegende)
    }

    // MARK: - 1. Couleurs, formes, icônes

    private var constat: String {
        let c = HZPolice.constat
        return "Fonte résolue : \(c.famille) · axe de largeur \(c.largeurActive ? "actif" : "en panne")"
            + " · axe de graisse \(c.graisseActive ? "actif" : "en panne")"
    }

    private var neutres: [Color] {
        [HZCouleur.noir, HZCouleur.encre, HZCouleur.surfaceSombre, HZCouleur.filetSombre,
         HZCouleur.pointEteint, HZCouleur.secondaireSurClair, HZCouleur.chevron,
         HZCouleur.secondaireSurSombre, HZCouleur.ongletEteint, HZCouleur.contour,
         HZCouleur.filetGroupe, HZCouleur.filetFeuille, HZCouleur.surfaceClaire]
    }

    private var rayons: [CGFloat] {
        [HZRayon.carte, HZRayon.carteDeClub, HZRayon.feuille, HZRayon.carteDuFil, HZRayon.tuile,
         HZRayon.groupe, HZRayon.mesure, HZRayon.bandeau, HZRayon.proposition, HZRayon.vignette]
    }

    private var jetons: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(verbatim: "Couleurs, formes, icônes")
                .hzAffichage(.section)
                .foregroundStyle(HZCouleur.encre)
            Text(verbatim: constat)
                .font(HZPolice.texte(.c12, .semi))
                .foregroundStyle(HZCouleur.secondaireSurClair)
                .padding(.top, HZPlanche.fin)

            legende("Les quatre couleurs de l'app, avec l'encre de leurs petits textes")
            HStack(spacing: HZPlanche.ecart) {
                ForEach(HZAccent.allCases) { accent in
                    Text(verbatim: "Libellé")
                        .font(HZPolice.texte(.c13, .gras))
                        .foregroundStyle(accent.encre)
                        .frame(maxWidth: .infinity)
                        .frame(height: HZPlanche.echantillon)
                        .background(accent.couleur,
                                    in: RoundedRectangle(cornerRadius: HZRayon.groupe, style: .circular))
                }
            }

            legende("Les trois intensités, et le point qui les signale sur le noir")
            HStack(spacing: HZPlanche.ecart) {
                ForEach(Array(HZIntensite.allCases.enumerated()), id: \.offset) { _, intensite in
                    Circle()
                        .fill(intensite.point)
                        .frame(width: HZSemaineEnPoints.point, height: HZSemaineEnPoints.point)
                        .frame(width: HZPlanche.nuance, height: HZPlanche.nuance)
                        .background(HZCouleur.noir, in: Circle())
                        .frame(maxWidth: .infinity)
                        .frame(height: HZPlanche.echantillon)
                        .background(intensite.couleur,
                                    in: RoundedRectangle(cornerRadius: HZRayon.groupe, style: .circular))
                }
            }

            suiteDesJetons
        }
        .padding(.top, HZEspace.haut)
        .padding(.horizontal, HZEspace.marge)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(HZCouleur.blanc)
    }

    @ViewBuilder
    private var suiteDesJetons: some View {
            legende("Du noir au clair : fonds, surfaces, filets, textes secondaires")
            HStack(spacing: HZPlanche.fin) {
                ForEach(Array(neutres.enumerated()), id: \.offset) { _, couleur in
                    Circle()
                        .fill(couleur)
                        .overlay(Circle().strokeBorder(HZCouleur.contour, lineWidth: HZFiltre.filet))
                        .frame(maxWidth: .infinity)
                        .frame(height: HZPlanche.nuance)
                }
            }

            legende("Les dix rayons : 36, 32, 30, 28, 24 puis 22, 20, 18, 16, 14")
            VStack(spacing: HZPlanche.ecart) {
                rangeeDeRayons(Array(rayons.prefix(HZPlanche.rayonsParRangee)))
                rangeeDeRayons(Array(rayons.suffix(HZPlanche.rayonsParRangee)))
            }

            legende("Les vingt-neuf icônes du canvas, au trait de 2")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: HZPlanche.colonnesDIcones),
                      spacing: HZPlanche.iconesParLigne) {
                ForEach(Array(HZDessin.toutes.enumerated()), id: \.offset) { _, icone in
                    HZIcone(dessin: icone.dessin, couleur: HZCouleur.encre)
                }
            }
    }

    private func rangeeDeRayons(_ valeurs: [CGFloat]) -> some View {
        HStack(spacing: HZPlanche.ecart) {
            ForEach(Array(valeurs.enumerated()), id: \.offset) { _, rayon in
                RoundedRectangle(cornerRadius: rayon, style: .circular)
                    .fill(HZCouleur.surfaceClaire)
                    .overlay(RoundedRectangle(cornerRadius: rayon, style: .circular)
                        .strokeBorder(HZCouleur.contour, lineWidth: HZFiltre.filet))
                    .frame(maxWidth: .infinity)
                    .frame(height: HZPlanche.forme)
            }
        }
    }

    // MARK: - 2. Typographie

    private var typographie: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(verbatim: "Typographie")
                .hzAffichage(.section)
            legende("Affichage, largeur 125 et graisse 800 : 128, 76, 52, 36, 34, 22")
            Group {
                Text(verbatim: "500").hzAffichage(.seance)
                    .padding(.leading, HZCarteAffiche.rattrapageOptique)
                Text(verbatim: "5,9").hzAffichage(.fil)
                Text(verbatim: "6:08").hzAffichage(.record)
                Text(verbatim: "12h25").hzAffichage(.chiffreDeTuile)
                    .padding(.top, HZPlanche.fin)
                Text(verbatim: "Ta semaine").hzAffichage(.titreDePage)
                    .padding(.top, HZPlanche.fin)
                Text(verbatim: "La suite").hzAffichage(.section)
            }
            legende("Interface, largeur 100 et graisses 700, 600, 500 : 20, 16, 15, 14, 13, 12")
            Group {
                Text(verbatim: "Fractionné léger").font(HZPolice.texte(.c20, .gras))
                Text(verbatim: "Sortie longue").font(HZPolice.texte(.c16, .semi))
                Text(verbatim: "Où cours-tu aujourd'hui ?").font(HZPolice.texte(.c15, .semi))
                Text(verbatim: "Tu as peu dormi. J'ai gardé le fractionné.")
                    .font(HZPolice.texte(.c14, .medium))
                Text(verbatim: "Dim. 15 nov. · 19h · récupération")
                    .font(HZPolice.texte(.c13, .medium))
                    .foregroundStyle(HZCouleur.secondaireSurClair)
                Text(verbatim: "Route · Trail · HYROX · Clubs · Courses")
                    .font(HZPolice.texte(.c12, .semi))
            }
            .padding(.bottom, HZPlanche.fin)
            legende("Chiffres tabulaires, puis proportionnels : les deux lignes du haut s'alignent")
            Group {
                Text(verbatim: "1111 · 11:11").font(HZPolice.texte(.c20, .gras, tabulaire: true))
                Text(verbatim: "0000 · 00:00").font(HZPolice.texte(.c20, .gras, tabulaire: true))
                Text(verbatim: "1111 · 11:11").font(HZPolice.texte(.c20, .gras))
            }
        }
        .foregroundStyle(HZCouleur.encre)
        .padding(.top, HZEspace.haut)
        .padding(.horizontal, HZEspace.marge)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(HZCouleur.blanc)
    }

    // MARK: - 3. Sur l'accent : le haut de l'accueil du canvas

    private var accueilHaut: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: HZEspace.entreCommandes) {
                HZAvatar(initiales: HZAvatar.initiales(prenom: "Camille", nom: "Garnier"), nom: "Profil") {}
                HZAmorceDeRecherche(invite: "Où cours-tu aujourd'hui ?") {}
                HZBoutonRond(dessin: .cloche, nom: "Notifications") {}
            }
            .padding(.horizontal, HZEspace.marge)

            HZSemaineEnPoints(jours: [
                (initiale: "L", etat: .fait), (initiale: "M", etat: .aujourdhui),
                (initiale: "M", etat: .repos), (initiale: "J", etat: .aVenir),
                (initiale: "V", etat: .repos), (initiale: "S", etat: .repos),
                (initiale: "D", etat: .aVenir),
            ])
            .padding(.horizontal, HZEspace.marge)
            .padding(.top, HZAccueil.sousLesCommandes)

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(verbatim: "Mardi 17 novembre")
                        .font(HZPolice.texte(.c15, .gras))
                        .foregroundStyle(HZCouleur.encreSurAccent)
                    Spacer(minLength: 0)
                    HZPilule(texte: "Aujourd'hui")
                }
                Text(verbatim: "5 ×")
                    .hzAffichage(.prefixeDeSeance)
                    .padding(.top, HZAccueil.sousLaDate)
                Text(verbatim: "500")
                    .hzAffichage(.seance)
                    .padding(.leading, -HZAccueil.debordDuNombre)
                Text(verbatim: "Fractionné léger")
                    .font(HZPolice.texte(.c20, .gras))
                    .padding(.top, HZAccueil.sousLeNombre)
                HZPilule(texte: "45 min · 4:22/km · Z3", style: .chiffres)
                    .padding(.top, HZAccueil.sousLeNom)
            }
            .foregroundStyle(HZCouleur.blanc)
            .padding(.horizontal, HZEspace.margeDeTitre)
            .padding(.top, HZAccueil.sousLaSemaine)

            HStack(spacing: 0) {
                HZAction(dessin: .lecture, libelle: "Démarrer", pleine: true,
                         cote: HZAction.coteDeLecture) {}
                HZAction(dessin: .deplacer, libelle: "Déplacer") {}
                HZAction(dessin: .bulle, libelle: "Coach") {}
                HZAction(dessin: .calendrier, libelle: "Semaine") {}
            }
            .padding(.horizontal, HZEspace.groupe)
            .padding(.top, HZAccueil.sousLaSeance)

            HZFeuille(retrait: .ample) {
                HZBandeauDuCoach(texte: "Tu as peu dormi. J'ai gardé le fractionné et allégé dimanche.")
                HZTitreDeSection(titre: "La suite", lien: "Ma semaine")
                    .padding(.top, HZEspace.entreSections)
                Spacer(minLength: 0)
            }
            .padding(.top, HZAccueil.sousLesActions)
        }
        .padding(.top, HZEspace.haut)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(HZCouleur.accent)
    }

    // MARK: - 4. Sur la feuille : le bas de l'accueil du canvas

    private func tuileLegendee(_ jour: String, _ duree: String, _ fond: Color,
                               _ titre: String, _ precision: String) -> some View {
        VStack(alignment: .leading, spacing: HZAction.ecart) {
            HZTuile(libelle: jour, valeur: duree, fond: fond)
            VStack(alignment: .leading, spacing: 0) {
                Text(verbatim: titre)
                    .font(HZPolice.texte(.c15, .gras))
                    .foregroundStyle(HZCouleur.encre)
                Text(verbatim: precision)
                    .font(HZPolice.texte(.c13, .medium))
                    .foregroundStyle(HZCouleur.secondaireSurClair)
            }
            .lineLimit(1)
        }
        .frame(width: HZFormatDeTuile.seance.largeur, alignment: .leading)
    }

    private var accueilBas: some View {
        HZFeuille(retrait: .ample) {
            HZBandeauDuCoach(texte: "Tu as peu dormi. J'ai gardé le fractionné et allégé dimanche.")
            HZTitreDeSection(titre: "La suite", lien: "Ma semaine")
                .padding(.top, HZEspace.entreSections)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: HZEspace.entreTuiles) {
                    tuileLegendee("Jeudi", "50'", HZIntensite.recuperation.couleur,
                                  "Sortie avec le club", "19h · récupération")
                    tuileLegendee("Dimanche", "1h20", HZIntensite.longue.couleur,
                                  "Sortie longue", "Endurance · allégée")
                    RoundedRectangle(cornerRadius: HZRayon.tuile, style: .circular)
                        .fill(HZIntensite.facile.couleur)
                        .frame(width: HZFormatDeTuile.seance.largeur,
                               height: HZFormatDeTuile.seance.hauteur)
                }
            }
            .padding(.trailing, -HZEspace.marge)
            .padding(.top, HZEspace.sousUnTitre)
            HZTitreDeSection(titre: "Explorer")
                .padding(.top, HZAccueil.avantUneSectionBasse)
            HStack(spacing: 0) {
                HZCategorie(dessin: .route, libelle: "Route") {}
                HZCategorie(dessin: .relief, libelle: "Trail") {}
                HZCategorie(dessin: .haltere, libelle: "HYROX") {}
                HZCategorie(dessin: .groupe, libelle: "Clubs") {}
                HZCategorie(dessin: .drapeau, libelle: "Courses") {}
            }
            .padding(.top, HZEspace.sousUnTitre)
            HZTitreDeSection(titre: "Dernières sorties", lien: "Tout voir")
                .padding(.top, HZAccueil.avantUneSectionBasse)
            HZLigneDeListe(titre: "Sortie longue", sousTitre: "Dim. 15 nov.") {
                HZVignette { HZIcone(dessin: .itineraire, cote: HZMesuresDeLigne.trace,
                                     trait: HZMesuresDeLigne.traitDuTrace, couleur: HZCouleur.blanc) }
            } queue: {
                HZValeurDeLigne(valeur: "8,9 km", precision: "6:14/km")
            }
            .padding(.top, HZAccueil.sousLeTitreDesSorties)
            HZLigneDeListe(titre: "Course · record d'allure", sousTitre: "Sam. 14 nov.", filet: false) {
                HZVignette { HZIcone(dessin: .itineraire, cote: HZMesuresDeLigne.trace,
                                     trait: HZMesuresDeLigne.traitDuTrace, couleur: HZCouleur.blanc) }
            } queue: {
                HZValeurDeLigne(valeur: "5,9 km", precision: "6:08/km")
            }
            Spacer(minLength: 0)
        }
        .padding(.top, HZEspace.haut + HZPlanche.bandeDAccent)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(HZCouleur.accent)
    }

    // MARK: - 5. Sur le noir : le haut du plan du canvas

    private var plan: some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    HZBoutonRond(dessin: .retour, nom: "Retour", fond: HZCouleur.surfaceSombre,
                                 trait: HZBoutonRond.traitDuRetour) {}
                    Spacer(minLength: 0)
                    HZPilule(texte: "Mode course libre", style: .etat, fond: HZCouleur.surfaceSombre)
                }
                .padding(.horizontal, HZEspace.marge)

                VStack(alignment: .leading, spacing: HZPlan.sousLeTitre) {
                    Text(verbatim: "Ta semaine")
                        .hzAffichage(.titreDePage)
                        .foregroundStyle(HZCouleur.blanc)
                    Text(verbatim: "16 au 22 novembre · 4 séances")
                        .font(HZPolice.texte(.c15, .semi))
                        .foregroundStyle(HZCouleur.secondaireSurSombre)
                }
                .padding(.horizontal, HZEspace.margeDeTitre)
                .padding(.top, HZPlan.sousLeRetour)

                // La rangée des jours du plan n'est pas un composant de base : sa place reste
                // libre, pour que la carte tombe là où le canvas la pose.
                HStack(spacing: HZEspace.entreTuiles) {
                    HZCarteAffiche(jour: "Lundi 16 novembre", etiquette: "Fait", nombre: "40'",
                                   titre: "Footing facile",
                                   mesures: [HZMesure(valeur: "40", libelle: "minutes"),
                                             HZMesure(valeur: "Z2", libelle: "zone")],
                                   fond: HZIntensite.facile.couleur)
                    HZCarteAffiche(jour: "Mardi 17 novembre", etiquette: "Aujourd'hui",
                                   prefixe: "5 ×", nombre: "500", style: .carteDuJour,
                                   titre: "Fractionné léger",
                                   mesures: [HZMesure(valeur: "45", libelle: "minutes"),
                                             HZMesure(valeur: "4:22", libelle: "par km"),
                                             HZMesure(valeur: "Z3", libelle: "zone")],
                                   fond: HZCouleur.accent,
                                   encreSecondaire: HZCouleur.encreSurAccent)
                    HZCarteAffiche(jour: "Mercredi 18 novembre", etiquette: "Repos", nombre: "Off",
                                   titre: "Jour de repos",
                                   mesures: [HZMesure(valeur: "10", libelle: "min mobilité")],
                                   fond: HZCouleur.surfaceSombre)
                }
                .fixedSize()
                .offset(x: HZPlan.departDeLaCarte - (HZCarteAffiche.largeur + HZEspace.entreTuiles))
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: HZCarteAffiche.hauteur)
                .clipped()
                .padding(.top, HZPlan.sousLEntete + HZPlan.rangeeDesJours + HZPlan.sousLesJours)

                HStack(spacing: HZEspace.entreCommandes) {
                    HZBoutonPilule(libelle: "Démarrer", dessin: .lecture, fond: HZCouleur.blanc,
                                   couleur: HZCouleur.noir, etendu: true,
                                   cote: HZBoutonPilule.coteDeLecture,
                                   ecart: HZBoutonPilule.ecartDeLecture) {}
                    HZBoutonPilule(libelle: "Déplacer", dessin: .deplacer,
                                   fond: HZCouleur.surfaceSombre) {}
                }
                .padding(.horizontal, HZEspace.margeDeTitre)
                .padding(.top, HZPlan.sousLaCarte)

                HZFeuille {
                    HZBandeauDuCoach(texte: "Glisse une carte pour changer de jour. Si tu déplaces une séance, je réorganise le reste.")
                    Spacer(minLength: 0)
                }
                .padding(.top, HZPlan.sousLesBoutons)
            }
            .padding(.top, HZEspace.haut)

            HZBarreFlottante(selection: $onglet)
                .padding(.bottom, HZEspace.sousLaBarre)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(HZCouleur.noir)
    }

    // MARK: - 6. Sur le noir, puis sur la feuille : le haut des stats du canvas

    private var stats: some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(verbatim: "Stats")
                        .hzAffichage(.titreDEcran)
                        .foregroundStyle(HZCouleur.blanc)
                    Spacer(minLength: 0)
                    HZBoutonPilule(libelle: "Historique", hauteur: .petite,
                                   fond: HZCouleur.surfaceSombre) {}
                }
                .padding(.horizontal, HZEspace.marge)

                VStack(alignment: .leading, spacing: 0) {
                    Text(verbatim: "Depuis le 11 octobre")
                        .font(HZPolice.texte(.c15, .semi))
                        .foregroundStyle(HZCouleur.secondaireSurSombre)
                    Text(verbatim: "118")
                        .hzAffichage(.total)
                        .padding(.leading, -HZStats.debordDuTotal)
                    Text(verbatim: "kilomètres courus")
                        .font(HZPolice.texte(.c20, .gras))
                        .padding(.top, HZStats.sousLeTotal)
                }
                .foregroundStyle(HZCouleur.blanc)
                .padding(.horizontal, HZEspace.margeDeTitre)
                .padding(.top, HZStats.sousLeTitre)

                HStack(spacing: HZEspace.entrePilules) {
                    HZFiltre(libelle: "7 j", margeVerticale: HZFiltre.margeDePeriode) {}
                    HZFiltre(libelle: "4 sem.", actif: true, margeVerticale: HZFiltre.margeDePeriode) {}
                    HZFiltre(libelle: "3 mois", margeVerticale: HZFiltre.margeDePeriode) {}
                    HZFiltre(libelle: "1 an", margeVerticale: HZFiltre.margeDePeriode) {}
                }
                .padding(.horizontal, HZEspace.margeDeTitre)
                .padding(.top, HZStats.sousLeLibelle)

                HZFeuille {
                    VStack(spacing: HZEspace.entreTuiles) {
                        HStack(spacing: HZEspace.entreTuiles) {
                            HZTuileChiffre(libelle: "Sorties", valeur: "18")
                            HZTuileChiffre(libelle: "Temps cumulé", valeur: "12h25")
                        }
                        HStack(spacing: HZEspace.entreTuiles) {
                            HZTuileChiffre(libelle: "Cette semaine", valeur: "0 km")
                            HZTuileChiffre(libelle: "Série en cours", valeur: "2 j", sombre: true)
                        }
                    }
                    HZTitreDeSection(titre: "Records")
                        .padding(.top, HZEspace.entreSections)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: HZEspace.entreTuiles) {
                            HZTuile(libelle: "Plus longue, km", valeur: "8,9", format: .record,
                                    fond: HZCouleur.accent, encreDuLibelle: HZCouleur.encreSurAccent,
                                    graisseDuLibelle: .gras)
                            HZTuile(libelle: "Meilleure allure", valeur: "6:08", format: .record,
                                    fond: HZCouleur.noir, encreDuLibelle: HZCouleur.secondaireSurSombre)
                            HZTuile(libelle: "Meilleure semaine, km", valeur: "19", format: .record,
                                    fond: HZIntensite.longue.couleur)
                        }
                    }
                    .padding(.trailing, -HZEspace.marge)
                    .padding(.top, HZEspace.sousUnTitre)
                    Spacer(minLength: 0)
                }
                .padding(.top, HZStats.sousLesPeriodes)
            }
            .padding(.top, HZEspace.haut)

            HZBarreFlottante(selection: $ongletDesStats)
                .padding(.bottom, HZEspace.sousLaBarre)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(HZCouleur.noir)
    }
}
#endif
