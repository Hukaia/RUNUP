import SwiftUI
import SwiftData

/// # L'ACCUEIL OUVRE SUR UNE IMAGE
///
/// Point 5 du brief du 15 novembre : « L'accueil ouvre sur une image plein écran en en-tête […]
/// avec "Charlotte" et la séance du jour par-dessus, comme l'accueil Hukaia mais avec la palette
/// Haizo. »
///
/// ## L'IMAGE, ET POURQUOI CE N'EST PAS UNE PHOTO
///
/// Le brief dit « photo de coureur, lumière naturelle, grain conservé ». L'app n'en possède
/// aucune, et une silhouette fabriquée pour l'occasion est exactement ce que la question 3 de la
/// direction artistique refuse — « est-ce qu'on devine qu'il a été généré ? ». Une photo de
/// banque d'images a la même réponse, avec une question de licence en plus.
///
/// L'app possède UNE image, et le brief la nomme lui-même au point 3 : le tracé GPS, « la seule
/// signature graphique de l'app ». Elle vient de ce qu'on a couru, elle ne ressemble à personne
/// d'autre, et elle change à chaque sortie. Le jour où les photos existent, c'est un fichier à
/// poser derrière ce même cadre.
///
/// ## CE QUI EST ÉCRIT DESSUS, ET POURQUOI PAS LA SÉANCE DU JOUR
///
/// La référence citée tranche la question mieux qu'un raisonnement : sur l'accueil Hukaia, ce
/// qui est posé sur la photo, c'est la salutation, le GRAND MOT et un sous-titre — et la carte
/// « Votre itinéraire » est dans la feuille blanche qui chevauche l'image par le bas. L'image et
/// le mot se répondent : la photo montre l'Islande, le mot dit « Islande ».
///
/// Ici l'image montre la dernière sortie. Ce qui est écrit dessus la NOMME donc, et la carte de
/// la séance du jour est la première de la feuille, juste dessous — « par-dessus » au sens où la
/// référence le montre.
///
/// Et c'est la règle 4 de `CarteDeNuit` : les chiffres se posent SUR le dessin, ils le légendent.
/// Un tracé sans sa ligne deviendrait un papier peint, c'est-à-dire la seule chose que le
/// composant refuse — « un fond sombre n'est pas une signature, c'est un goût ».
///
/// ## LE PRÉNOM À 40
///
/// Point 1 du brief, qui le nomme : « titres d'écran en 40 lourd ("Charlotte", "Ta forme
/// évolue", "Le fil") ». Il était à 24 depuis le 14 novembre, avec un argument qui tenait POUR
/// UNE PAGE BLANCHE : « un prénom qu'on ne lit pas — on le sait déjà — occupait le haut du
/// barème », au-dessus des chiffres qu'on vient voir. Sur l'image, il ne concurrence plus rien :
/// il EST l'en-tête, et les chiffres des cartes sont ailleurs.
///
/// ## POURQUOI CE FICHIER EXISTE
///
/// `check_nuit.py` refuse un jeton de page dans le corps d'un appel à `CarteDeNuit` — et son
/// en-tête dit ce qu'il ne voit pas : « une vue tierce appelée depuis une carte de nuit : son
/// corps est écrit ailleurs ». La rangée du haut, la pastille de série et la cloche sont
/// exactement ce cas : posées SUR la nuit, écrites hors du bloc. Ce fichier est donc inscrit
/// dans `FICHIERS_DE_NUIT`, et tout son contenu est tenu à la règle.
struct EnTeteDAccueil: View {
    @Environment(AppState.self) private var appState
    /// Bornée aux non-lues, comme sur l'accueil : cette requête ne sert qu'à pastiller la cloche.
    @Query(filter: #Predicate<AppNotification> { !$0.read }) private var nonLues: [AppNotification]

    /// Les courses que l'accueil a déjà chargées. PASSÉES plutôt que re-interrogées : une
    /// deuxième `@Query` sur `RunRecord` doublerait l'aller-retour SwiftData le plus coûteux de
    /// l'écran — chaque ligne porte son tracé GPS sérialisé — pour relire ce qui est déjà là.
    var courses: [RunRecord]

    private var profile: UserProfile { appState.profile }
    private var isFreeRun: Bool { profile.programPhase == .freerun }

    /// La hauteur de l'en-tête, qui suit le réglage de taille du texte.
    ///
    /// LE CADRE SUIT LE TEXTE, PARCE QUE C'EST LE TEXTE QUI EST DESSUS. La leçon vient du bandeau
    /// qu'il remplace : à 150 points FIXES, au deuxième cran d'accessibilité, les chiffres
    /// montaient au-delà du voile et le trait rose leur passait en travers — vu sur la capture en
    /// grand texte.
    ///
    /// 320 plutôt que 150, parce qu'il porte maintenant un prénom à 40 lourd en plus des deux
    /// autres lignes. Plafonné à 460, soit 1,44 × : au-delà, l'en-tête occuperait la moitié d'un
    /// iPhone et la carte de la séance du jour passerait sous la ligne de flottaison — ce qui
    /// défait exactement ce que l'ordre des cartes protège.
    @ScaledMetric(relativeTo: .body) private var hauteur: CGFloat = 320

    var body: some View {
        ZStack(alignment: .top) {
            CarteDeNuit(hauteur: min(hauteur, 460), rayon: 0, marge: 0) {
                if let derniere = derniereAvecTrace {
                    SelfDrawingRoute(route: derniere.route, lineWidth: 4,
                                     targetPoints: 140, showsStart: true)
                }
            } legende: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: isFreeRun ? String(localized: "Mode course libre") : dateDuJour)
                        .font(RUFont.sans(.micro, weight: .medium))
                        .foregroundColor(RUColor.surLaNuit2)
                    Text(verbatim: profile.name)
                        .displayStyle(.banner)
                        .foregroundColor(RUColor.surLaNuit)
                        .lineLimit(1).minimumScaleFactor(0.6)
                    if let derniere = derniereAvecTrace {
                        Text(verbatim: ligneDeLaDerniere(derniere))
                            .font(RUFont.sans(.small))
                            .foregroundColor(RUColor.surLaNuit2)
                            .lineLimit(1).minimumScaleFactor(0.8)
                            .padding(.top, 2)
                    }
                }
                .accessibilityElement(children: .combine)
            }
            barreDeMarque
                .padding(.horizontal, RUSpacing.pagePadding)
                .padding(.top, 4)
        }
    }

    /// Le mot de la marque, la série et la cloche — la rangée du haut.
    ///
    /// C'est la rangée de la référence : un logo à gauche, des boutons ronds à droite. Le mot
    /// prend la place que le prénom occupait, parce que le prénom est descendu sur l'image, en
    /// grand.
    private var barreDeMarque: some View {
        HStack(spacing: 8) {
            MotDeMarque(tuile: 54)
                .foregroundStyle(RUColor.surLaNuit)
            Spacer(minLength: 8)
            pastilleDeSerie
            Button(action: { appState.openNotifications() }) {
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(RUColor.surLaNuit.opacity(0.12))
                        .frame(width: 36, height: 36)
                        .overlay(Image(systemName: "bell")
                            .font(RUFont.icone(.medium))
                            .foregroundColor(RUColor.surLaNuit))
                    if !nonLues.isEmpty {
                        Circle().fill(RUColor.accentDeLaNuit).frame(width: 8, height: 8)
                            .overlay(Circle().stroke(RUColor.traceBackground, lineWidth: 1.5))
                    }
                }
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(PressableStyle())
            .accessibilityLabel(nonLues.isEmpty
                ? String(localized: "Notifications")
                : String(localized: "Notifications, \(nonLues.count) non lues"))
        }
    }

    /// La série en cours.
    ///
    /// ELLE ÉTAIT EN AMBRE JUSQU'AU 16 NOVEMBRE, et elle aurait dû cesser de l'être à midi : la
    /// flamme est passée « allumée à l'accent, éteinte au gris » sur l'écran des stats, dans le
    /// bilan hebdo, dans la feuille de débriefing et dans le widget — pas ici, sur l'écran qu'on
    /// ouvre tous les jours. `check_teintes.py` n'inspecte que `RUCardHeader(tint:)` et
    /// `RUStatTile(tint:)` : une couleur posée en `.foregroundColor` est hors de sa portée.
    ///
    /// Sur la nuit, elle prend la même forme que la cloche : un fond blanc voilé, pas de filet.
    /// Deux pastilles côte à côte dans deux habillages différents, ce sont deux objets ; ici ce
    /// sont deux commandes de la même rangée.
    private var pastilleDeSerie: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill").font(RUFont.icone(.body))
            Text(verbatim: "\(profile.streak)").font(RUFont.sans(.label, weight: .bold))
        }
        .foregroundColor(profile.streak > 0 ? RUColor.accentDeLaNuit : RUColor.surLaNuit2)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(RUColor.surLaNuit.opacity(0.12), in: Capsule())
        // Le compte seul se lisait « 5 » à VoiceOver : la flamme qui lui donne son sens ne porte
        // aucune information pour qui ne la voit pas.
        .accessibilityElement(children: .combine)
        // Deux clés entières plutôt qu'un « jour\(s) » recollé : le pluriel ne se fabrique pas en
        // ajoutant un « s » dans les autres langues.
        .accessibilityLabel(Pluriel.choisir(profile.streak,
            String(localized: "Série, \(profile.streak) jour"),
            String(localized: "Série, \(profile.streak) jours")))
    }

    /// La dernière sortie qui a laissé un tracé, ou `nil`.
    ///
    /// `route.count > 1` et pas seulement « la dernière sortie » : une séance saisie à la main ou
    /// validée sans GPS n'a rien à montrer. On remonte donc jusqu'à la dernière qui en a une —
    /// sinon l'en-tête garde sa nuit, sans dessin et sans ligne, et c'est l'état d'une personne
    /// qui vient d'installer l'app.
    private var derniereAvecTrace: RunRecord? {
        courses.filter { $0.route.count > 1 }.max(by: { $0.date < $1.date })
    }

    /// La date du jour, en toutes lettres et en casse normale.
    ///
    /// `EyebrowLabel` la passait en capitales, comme tous les eyebrows de l'app. Point 1 du
    /// brief : « supprimer les majuscules espacées — ce sont des labels en 12 gris, casse
    /// normale ».
    private var dateDuJour: String {
        // `Demonstration.maintenant` : la date écrite ici doit être celle de la SCÈNE, sinon
        // l'en-tête annonce lundi au-dessus d'une semaine qui s'arrête au dimanche précédent.
        // C'est ce que montrait la campagne 215 — « lundi 16 novembre » sur une carte à 28,3 km
        // qui ne comptait que des sorties du 9 au 15.
        Demonstration.maintenant
            .formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale.current))
    }

    /// « Dernière sortie · dim. 15 nov. · 8,1 km · 5:18/km ».
    private func ligneDeLaDerniere(_ course: RunRecord) -> String {
        let date = course.date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)
            .locale(Locale.current))
        return String(localized: "Dernière sortie") + " · " + date
            + " · " + Distances.km(course.distanceKm) + " · " + course.avgPace + "/km"
    }
}
