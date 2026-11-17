import SwiftUI

/// « TA SEMAINE », refait à partir des composants de la refonte.
///
/// Le canvas dessine sept cartes qu'on fait glisser, une par jour, la rangée des sept points au-dessus
/// d'elles, « Démarrer » et « Déplacer » dessous, puis une feuille blanche : le coach, et « Passer à
/// un objectif ». Rien de ce qu'il montre — le mardi, le fractionné, les 4 séances — n'est écrit ici :
/// chaque carte vient de la vraie semaine, par `PlanSemaineModele`.
///
/// # CE QUE L'ANCIEN ÉCRAN FAISAIT ET QUE LE CANVAS NE DESSINE PAS
///
/// L'ancien « Plan complet » montrait la forme de TOUT le programme — une barre par semaine, ses
/// phases, ses semaines allégées — et laissait parcourir les autres semaines. Le canvas ne montre
/// que la semaine en cours. Cette forme est ce que Haizo Plus vend, et la supprimer serait retirer
/// une fonction : « Le plan complet » reste donc joignable, sous les objectifs, et mène à l'ancien
/// écran, qui sera habillé comme les autres au moment où il le sera (écran hors canvas).
///
/// # LES ÉTATS QUE LE CANVAS NE DESSINE PAS
///
/// - **Une séance passée et non faite** : sa pilule dit « Non faite ». Le canvas n'a que « Fait »,
///   « Aujourd'hui », « À venir » et « Repos ».
/// - **Plan verrouillé** (Haizo Plus) : la carte du jour seule, les autres jours ne se choisissent
///   pas, et l'offre prend la place du coach et des objectifs.
/// - **Aucune semaine** : une phrase, pas sept cartes de repos — sept « Off » diraient que la
///   coureuse n'a rien à faire de la semaine.
struct PlanSemaineView: View {
    @Environment(AppState.self) private var appState
    @Environment(SubscriptionService.self) private var subscriptions

    /// Le jour regardé. `nil` tant qu'on n'a rien touché : c'est alors aujourd'hui.
    @State private var choix: Int?
    /// Combien de fois la sélection d'un jour a été demandée. Diagnostic : trois gestes ne
    /// changeaient rien, et il fallait savoir si l'action s'exécute.
    @State private var demandes = 0
    @State private var planCompletOuvert = false

    private var profile: UserProfile { appState.profile }
    private var planDebloque: Bool { subscriptions.unlocks(.adaptivePlan) }

    // MARK: - Les données

    private var aujourdHui: Int { PlanSemaineModele.indiceDuJour(Demonstration.maintenant) }
    private var lundi: Date { PlanSemaineModele.lundi(de: Demonstration.maintenant) }

    private var jours: [PlanSemaineModele.Jour] {
        PlanSemaineModele.jours(profile.weekSessions, aujourdHui: aujourdHui, lundi: lundi,
                                titreDuRepos: String(localized: "Jour de repos"))
    }

    /// Les jours qu'on peut regarder : tous, ou celui d'aujourd'hui seul quand le plan est
    /// verrouillé — la séance du jour est gratuite, la semaine est ce que Plus vend.
    private var visibles: [PlanSemaineModele.Jour] {
        planDebloque ? jours : jours.filter { $0.id == aujourdHui }
    }

    private var choisi: Int {
        let voulu = planDebloque ? (choix ?? aujourdHui) : aujourdHui
        return visibles.contains { $0.id == voulu } ? voulu : (visibles.first?.id ?? aujourdHui)
    }

    private var position: Int {
        visibles.firstIndex { $0.id == choisi } ?? 0
    }

    // MARK: - La page

    var body: some View {
        let _ = DiagnosticRefonte.sans("journal") ? () : DiagnosticRefonte.noter("PlanSemaineView.body choix=\(String(describing: choix)) demandes=\(demandes)")
        if DiagnosticRefonte.sans("modificateur") {
            habillee
        } else {
            habillee.modifier(CouvertureDuPlan(ouverte: $planCompletOuvert))
        }
    }

    /// La pile de la page : le haut sur le noir, la feuille blanche qui remonte dessus.
    ///
    /// La feuille REMONTE sur le haut de page d'un rayon de coin : le noir passe derrière ses coins
    /// arrondis. Sans ce recouvrement, ils sont blancs sur du blanc — mesuré sur la capture.
    @ViewBuilder private var pile: some View {
        VStack(alignment: .leading, spacing: DiagnosticRefonte.sans("recouvrement") ? 0 : -HZRayon.feuille) {
            if DiagnosticRefonte.sans("surcouche") { sonde }
            if !DiagnosticRefonte.sans("hautdepage") { hautDePage }
            if !DiagnosticRefonte.sans("feuille") { feuille }
        }
    }

    @ViewBuilder private var defilement: some View {
        if DiagnosticRefonte.sans("enveloppe") {
            ScrollView { pile }
        } else {
            DiagnosticDefilement { pile }
        }
    }

    private var habillee: some View {
        defilement
            .scrollIndicators(DiagnosticRefonte.sans("indicateurs") ? .automatic : .hidden)
            // Deux moitiés de fond : le noir en haut, le blanc en bas — un défilement qui dépasse son
            // bord montre la couleur de ce qui s'y trouve.
            .background {
                if !DiagnosticRefonte.sans("fond") {
                    VStack(spacing: 0) {
                        HZCouleur.noir
                        HZCouleur.blanc
                    }
                    .ignoresSafeArea()
                }
            }
            .ignoresSafeArea(edges: DiagnosticRefonte.sans("zonesure") ? [] : .top)
            .statusBarHidden(!DiagnosticRefonte.sans("statusbar"))
            // La sonde est posée PAR-DESSUS la page : dans la pile, le haut de page remonte sur elle
            // (espacement négatif) et la cache.
            .overlay(alignment: .center) {
                if !DiagnosticRefonte.sans("surcouche") { sonde }
            }
    }

    /// DIAGNOSTIC : un bouton et un compteur sans rien d'autre, pour savoir si un `@State` de CET
    /// écran le réévalue.
    @ViewBuilder private var sonde: some View {
        if DiagnosticRefonte.sans("sonde") {
            Button { demandes += 1 } label: { Text(verbatim: "sonde-\(demandes)").foregroundStyle(HZCouleur.blanc) }
                .background(HZCouleur.noir)
        }
    }

    // MARK: - Le haut, sur le noir

    private var hautDePage: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !DiagnosticRefonte.sans("entete") { entete }
            if DiagnosticRefonte.sans("titre") { Text(verbatim: "t") } else { titre }
            if !visibles.isEmpty {
                if !DiagnosticRefonte.sans("rangee") {
                    rangeeDesJours
                        .padding(.horizontal, HZEspace.marge)
                        .padding(.top, HZPlan.sousLEntete)
                }
                if !DiagnosticRefonte.sans("carrousel") {
                    carrousel
                        .padding(.top, HZPlan.sousLesJours)
                }
                if !DiagnosticRefonte.sans("boutons") { boutons }
            }
        }
        .padding(.top, HZEspace.haut)
        // Le noir se prolonge SOUS les boutons : c'est lui qui est derrière les coins arrondis de
        // la feuille. Posé en marge de la feuille, cet espace montrait le fond de la page — du blanc
        // dans la moitié basse de l'écran, donc des coins blancs sur du blanc.
        .padding(.bottom, HZPlan.sousLesBoutons + HZRayon.feuille)
        .frame(maxWidth: DiagnosticRefonte.sans("cadre") ? nil : .infinity, alignment: .leading)
        .background(DiagnosticRefonte.sans("fondhaut") ? Color.clear : HZCouleur.noir)
    }

    private var entete: some View {
        HStack {
            HZBoutonRond(dessin: .retour, nom: String(localized: "Retour"),
                         fond: HZCouleur.surfaceSombre, trait: HZBoutonRond.traitDuRetour) {
                appState.go(.home)
            }
            Spacer(minLength: 0)
            if let etat = etatDuProgramme {
                HZPilule(texte: etat, style: .etat, fond: HZCouleur.surfaceSombre)
            }
        }
        .padding(.horizontal, HZEspace.marge)
    }

    /// En course libre : le mode, comme le canvas. Sinon l'objectif du programme en cours.
    private var etatDuProgramme: String? {
        if profile.programPhase == .freerun { return String(localized: "Mode course libre") }
        return profile.goalDisplay.isEmpty ? nil : profile.goalDisplay
    }

    private var titre: some View {
        VStack(alignment: .leading, spacing: HZPlan.sousLeTitre) {
            Text(String(localized: "Ta semaine"))
                .hzAffichage(.titreDePage)
                .foregroundStyle(HZCouleur.blanc)
                #if DEBUG
                // L'ÉTAT DE LA SÉLECTION, lisible par le test de capture : trois gestes de suite ne
                // changeaient aucun pixel, et l'image seule ne dit pas si l'action s'est déclenchée.
                .accessibilityIdentifier("plan-diagnostic")
                .accessibilityValue(DiagnosticRefonte.sans("titrediag") ? "" : "choix=\(String(describing: choix)) choisi=\(choisi) debloque=\(planDebloque) visibles=\(visibles.count) demandes=\(demandes)")
                #endif
            Text(DiagnosticRefonte.sans("soustitre") ? "" : sousLeTitre)
                .hzTexte(.c15, .semi)
                .foregroundStyle(HZCouleur.secondaireSurSombre)
        }
        .padding(.horizontal, HZEspace.margeDeTitre)
        .padding(.top, HZPlan.sousLeRetour)
    }

    /// « 16 au 22 novembre · 4 séances ». Sans séance au plan, la période seule.
    private var sousLeTitre: String {
        let periode = PlanSemaineModele.periode(lundi: lundi)
        let dates = periode.surDeuxMois
            ? String(localized: "\(periode.premierJour) \(periode.moisDuPremier) au \(periode.dernierJour) \(periode.moisDuDernier)")
            : String(localized: "\(periode.premierJour) au \(periode.dernierJour) \(periode.moisDuPremier)")
        let seances = PlanSemaineModele.nombreDeSeances(profile.weekSessions)
        guard seances > 0 else { return dates }
        let compte = Pluriel.choisir(seances,
                                     String(localized: "\(seances) séance"),
                                     String(localized: "\(seances) séances"))
        return dates + " · " + compte
    }

    // MARK: - Les jours

    /// Sept boutons, un par jour. L'action est écrite ICI, dans la vue : posée dans un composant et
    /// reçue en paramètre, elle ne partait jamais (voir `HZColonneDeJour`).
    private var rangeeDesJours: some View {
        HStack(spacing: 0) {
            ForEach(jours) { jour in
                Button {
                    selectionner(jour.id)
                } label: {
                    HZColonneDeJour(initiale: PlanSemaineModele.initiale(duJour: jour.id),
                                    point: couleurs(de: jour).point,
                                    choisi: jour.id == choisi)
                }
                .buttonStyle(.plain)
                .disabled(!planDebloque)
                .accessibilityLabel(AccueilModele.dateDuJour(jour.date))
                .accessibilityIdentifier("rangee-des-jours-\(jour.id)")
                .accessibilityAddTraits(jour.id == choisi ? .isSelected : [])
            }
        }
    }

    private struct Couleurs {
        var fond: Color
        var point: Color
        var encre: Color
    }

    /// Une couleur par jour, comme le canvas : le noir doux d'un repos, l'accent d'aujourd'hui, et
    /// les trois teintes d'intensité pour l'endurance, la récupération et la sortie longue. Le
    /// seuil, le fractionné et le renforcement n'ont pas de teinte dans le canvas : ils prennent
    /// l'accent, comme sur l'accueil. C'est une hypothèse, écrite dans PROGRESS.md.
    private func couleurs(de jour: PlanSemaineModele.Jour) -> Couleurs {
        let accent = Couleurs(fond: HZCouleur.accent, point: HZCouleur.accent, encre: HZCouleur.encreSurAccent)
        if jour.etat == .aujourdhui { return accent }
        if jour.estUnRepos {
            return Couleurs(fond: HZCouleur.surfaceSombre, point: HZCouleur.pointEteint, encre: HZCouleur.blanc)
        }
        guard let intensite = AccueilModele.intensite(de: jour.famille) else { return accent }
        return Couleurs(fond: intensite.couleur, point: intensite.point, encre: HZCouleur.blanc)
    }

    /// Les appelants ont déjà tenu compte du verrou : la rangée est éteinte quand le plan l'est, et
    /// le glissement le vérifie lui-même.
    private func selectionner(_ jour: Int) {
        demandes += 1
        DiagnosticRefonte.noter("PlanSemaineView.selectionner jour=\(jour)")
        if DiagnosticRefonte.sans("animation") {
            choix = jour
        } else {
            withAnimation(HZCarrousel.animation) { choix = jour }
        }
        Haptics.selection()
    }

    // MARK: - Le carrousel

    /// Les cartes font plus de deux largeurs d'écran. Posées dans un cadre, elles l'élargissent, et
    /// toute la pile — en-tête, titre, boutons, feuille — se recentre sur cette largeur : le plan
    /// entier glisse de moitié. Le cadre est donc une surface vide de la bonne hauteur, et les
    /// cartes y débordent en superposition, alignées sur son bord de départ.
    private var carrousel: some View {
        Color.clear
            .frame(height: HZCarteAffiche.hauteur)
            .overlay(alignment: .leading) {
                HStack(spacing: HZEspace.entreTuiles) {
                    ForEach(visibles) { jour in
                        Button {
                            toucher(jour)
                        } label: {
                            carte(jour)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .fixedSize()
                .offset(x: HZPlan.departDeLaCarte - CGFloat(position) * HZPlan.pasDuCarrousel)
            }
            .clipped()
            .simultaneousGesture(
                DragGesture(minimumDistance: HZCarrousel.seuilDeGlissement)
                    .onEnded { geste in glisser(geste.translation) })
    }

    private func toucher(_ jour: PlanSemaineModele.Jour) {
        if jour.id == choisi {
            // La carte déjà au premier plan : celle d'aujourd'hui ouvre le détail de la séance.
            if jour.etat == .aujourdhui { appState.openSessionDetail() }
        } else {
            selectionner(jour.id)
        }
    }

    private func glisser(_ deplacement: CGSize) {
        // Un geste surtout vertical est un défilement de la page, pas un changement de jour.
        guard planDebloque, abs(deplacement.width) > abs(deplacement.height) else { return }
        let sens = deplacement.width < 0 ? 1 : -1
        let cible = position + sens
        guard visibles.indices.contains(cible) else { return }
        selectionner(visibles[cible].id)
    }

    private func carte(_ jour: PlanSemaineModele.Jour) -> some View {
        let couleur = couleurs(de: jour)
        let nombre = texte(du: jour.nombre)
        return HZCarteAffiche(jour: AccueilModele.dateDuJour(jour.date), etiquette: etiquette(de: jour),
                              prefixe: jour.prefixe ?? "", nombre: nombre, style: style(de: nombre),
                              titre: jour.titre, mesures: jour.mesures.map(colonne(de:)),
                              fond: couleur.fond, encreSecondaire: couleur.encre)
    }

    private func etiquette(de jour: PlanSemaineModele.Jour) -> String {
        if jour.faite { return String(localized: "Fait") }
        switch jour.etat {
        case .fait: return String(localized: "Fait")
        case .aujourdhui: return String(localized: "Aujourd'hui")
        case .aVenir: return String(localized: "À venir")
        case .nonFait: return String(localized: "Non faite")
        case .repos: return String(localized: "Repos")
        }
    }

    private func texte(du nombre: AccueilModele.Nombre) -> String {
        switch nombre {
        case .valeur(let valeur): return valeur
        case .repos: return String(localized: "Off")
        case .libre: return String(localized: "Libre")
        }
    }

    /// Le canvas règle le corps et le serrage du grand nombre carte par carte : 112 pour « 500 » et
    /// « 40' », 84 pour « 1h20 ». La règle qu'on en tire — quatre signes ou plus passent au corps
    /// réduit, des chiffres seuls se serrent un peu plus que du texte.
    private func style(de nombre: String) -> HZAffichage {
        if nombre.count >= HZPlan.signesDuGrandNombre { return .carteLongue }
        return nombre.allSatisfy(\.isNumber) ? .carteDuJour : .carte
    }

    private func colonne(de mesure: AccueilModele.Mesure) -> HZMesure {
        switch mesure {
        case .minutes(let minutes): return HZMesure(valeur: String(minutes), libelle: String(localized: "minutes"))
        case .allure(let allure): return HZMesure(valeur: allure, libelle: String(localized: "par km"))
        case .zone(let zone): return HZMesure(valeur: zone, libelle: String(localized: "zone"))
        }
    }

    // MARK: - Démarrer, Déplacer

    private var boutons: some View {
        HStack(spacing: HZEspace.entreCommandes) {
            HZBoutonPilule(libelle: String(localized: "Démarrer"), dessin: .lecture, fond: HZCouleur.blanc,
                           couleur: HZCouleur.noir, etendu: true, cote: HZBoutonPilule.coteDeLecture,
                           ecart: HZBoutonPilule.ecartDeLecture) {
                appState.startRun()
            }
            // On ne démarre que la séance d'AUJOURD'HUI : celle d'un autre jour n'est pas encore (ou
            // plus) à courir. Le bouton reste là, éteint, plutôt que de disparaître à chaque
            // glissement et de faire sauter la mise en page.
            .disabled(choisi != aujourdHui)
            .opacity(choisi == aujourdHui ? HZPlan.pleine : HZPlan.eteint)
            if planDebloque {
                HZBoutonPilule(libelle: String(localized: "Déplacer"), dessin: .deplacer,
                               fond: HZCouleur.surfaceSombre) {
                    appState.openMoveSession()
                }
            }
        }
        .padding(.horizontal, HZEspace.margeDeTitre)
        .padding(.top, HZPlan.sousLaCarte)
    }

    // MARK: - La feuille

    private var feuille: some View {
        HZFeuille {
            if planDebloque {
                HZBandeauDuCoach(texte: String(localized: "Glisse une carte pour changer de jour. Déplacer te laisse changer le jour d'une séance de cette semaine."))
                objectifs
                planComplet
            } else {
                PlusLockCard(feature: .adaptivePlan, showsFreeReminder: false)
            }
            if jours.isEmpty {
                Text(String(localized: "Ta semaine apparaîtra ici dès que ton plan sera prêt."))
                    .hzTexte(.c14, .medium)
                    .foregroundStyle(HZCouleur.secondaireSurClair)
                    .padding(.top, HZEspace.sousUnTitre)
            }
            Color.clear.frame(height: HZPlan.basDePage)
        }
        .frame(minHeight: HZPlan.hauteurMiniDeLaFeuille, alignment: .top)
    }

    // MARK: - Passer à un objectif

    /// Les objectifs que l'app propose, hors celui qu'on suit déjà. Toucher une tuile ouvre
    /// l'assistant de programme : il pose les questions de l'objectif, et l'objectif choisi n'y est
    /// pas encore présélectionné.
    private var autresObjectifs: [GoalType] {
        Array(GoalType.allCases.filter { $0.estProposable && $0 != profile.goalId }
            .prefix(HZPlan.objectifsAffiches))
    }

    /// Les teintes des tuiles : le noir, puis les trois couleurs du canvas, qui sont aussi celles de
    /// l'intensité. Ici elles ne disent PAS une intensité, seulement une rangée de choix.
    private var fondsDesObjectifs: [Color] {
        [HZCouleur.noir, HZIntensite.recuperation.couleur, HZIntensite.facile.couleur, HZIntensite.longue.couleur]
    }

    @ViewBuilder private var objectifs: some View {
        if !autresObjectifs.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                HZTitreDeSection(titre: String(localized: "Passer à un objectif"))
                    .padding(.top, HZPlan.avantLesObjectifs)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: HZEspace.entreTuiles) {
                        ForEach(autresObjectifs) { objectif in
                            let rang = autresObjectifs.firstIndex(of: objectif) ?? 0
                            Button {
                                appState.newGoalWizardPresented = true
                            } label: {
                                HZTuile(libelle: precision(de: objectif), valeur: objectif.title,
                                        format: .objectif,
                                        fond: fondsDesObjectifs[rang % fondsDesObjectifs.count],
                                        encreDuLibelle: rang == 0 ? HZCouleur.secondaireSurSombre : HZCouleur.blanc)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.trailing, -HZEspace.marge)
                .padding(.top, HZEspace.sousUnTitre)
            }
        }
    }

    /// La ligne du haut d'une tuile d'objectif : ce que l'objectif a de propre, en quelques mots.
    private func precision(de objectif: GoalType) -> String {
        switch objectif {
        case .race: return String(localized: "Un dossard en vue")
        case .progress: return String(localized: "Sans course précise")
        case .restart: return String(localized: "En douceur")
        case .weight: return String(localized: "Course et équilibre")
        case .health: return String(localized: "Une routine")
        case .hyrox: return String(localized: "Course et force")
        case .ultraTrail: return String(localized: "Dénivelé")
        case .triathlon: return String(localized: "Trois sports")
        case .duathlon: return String(localized: "Deux courses, un vélo")
        }
    }

    // MARK: - Le plan complet

    /// L'ancien écran du plan, avec la forme de tout le programme et les autres semaines : le
    /// canvas ne le dessine pas, il reste joignable. Voir l'en-tête de ce fichier.
    private var planComplet: some View {
        Button {
            planCompletOuvert = true
        } label: {
            HZLigneDeListe(titre: String(localized: "Le plan complet"),
                           sousTitre: String(localized: "Toutes les semaines du programme"),
                           filet: false) {
                EmptyView()
            } queue: {
                HZChevron()
            }
        }
        .buttonStyle(.plain)
        .padding(.top, HZPlan.avantLePlanComplet)
    }
}

/// Le plein écran de l'ancien plan, posé en modificateur pour que le diagnostic puisse le retirer.
private struct CouvertureDuPlan: ViewModifier {
    @Binding var ouverte: Bool

    func body(content: Content) -> some View {
        if DiagnosticRefonte.sans("couverture") {
            content
        } else {
            content.fullScreenCover(isPresented: $ouverte) {
                PlanView(retour: { ouverte = false })
                    .background(RUColor.bg.ignoresSafeArea())
            }
        }
    }
}
