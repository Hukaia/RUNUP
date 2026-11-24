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
    /// La séance d'un autre jour que le jour même, ouverte en touchant sa carte.
    @State private var seanceDUnAutreJour: SeanceDUnAutreJour?
    @State private var planCompletOuvert = false

    private var profile: UserProfile { appState.profile }
    private var planDebloque: Bool { subscriptions.unlocks(.adaptivePlan) }

    // MARK: - Les données

    private var aujourdHui: Int { PlanSemaineModele.indiceDuJour(Demonstration.maintenant) }
    private var lundi: Date { PlanSemaineModele.lundi(de: Demonstration.maintenant) }

    /// En course libre, la semaine n'existe pas : voir `PlanSemaineModele.joursEnCourseLibre`.
    private var estEnCourseLibre: Bool { profile.programPhase == .freerun }

    private var jours: [PlanSemaineModele.Jour] {
        if estEnCourseLibre {
            return PlanSemaineModele.joursEnCourseLibre(
                semaine: profile.weekSessions, seance: profile.todaySession,
                faite: profile.seanceDoneToday, aujourdHui: aujourdHui, lundi: lundi,
                titreDuRepos: String(localized: "Jour de repos"))
        }
        return PlanSemaineModele.jours(profile.weekSessions, aujourdHui: aujourdHui, lundi: lundi,
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

    /// Plus d'une carte à faire défiler : faux pour un plan verrouillé ou la course libre.
    private var aPlusieursCartes: Bool { !visibles.dropFirst().isEmpty }

    private var position: Int {
        visibles.firstIndex { $0.id == choisi } ?? 0
    }

    // MARK: - La page

    var body: some View {
        ScrollView {
            // La feuille REMONTE sur le haut de page d'un rayon de coin : le noir passe derrière ses
            // coins arrondis. Sans ce recouvrement, ils sont blancs sur du blanc — mesuré sur la
            // capture, où le coin était carré.
            VStack(alignment: .leading, spacing: -HZRayon.feuille) {
                hautDePage
                feuille
            }
        }
        .scrollIndicators(.hidden)
        // Deux moitiés de fond : le noir en haut, le blanc en bas — un défilement qui dépasse son
        // bord montre la couleur de ce qui s'y trouve.
        .background {
            VStack(spacing: 0) {
                HZCouleur.noir
                HZCouleur.blanc
            }
            .ignoresSafeArea()
        }
        .ignoresSafeArea(edges: .top)
        .statusBarHidden()
        .sheet(item: $seanceDUnAutreJour) { jour in
            SessionDetailSheet(autreJour: jour)
                .hzFeuille(detents: [.medium, .large], gereSonBas: true)
        }
        .fullScreenCover(isPresented: $planCompletOuvert) {
            PlanView(retour: { planCompletOuvert = false })
                .toastDeModale()
        }
    }

    // MARK: - Le haut, sur le noir

    private var hautDePage: some View {
        VStack(alignment: .leading, spacing: 0) {
            entete
            titre
            if !visibles.isEmpty {
                // Une seule carte (course libre) : sept jours à choisir n'auraient pas de sens.
                if jours.count > 1 {
                    rangeeDesJours
                        .padding(.horizontal, HZEspace.marge)
                        .padding(.top, HZPlan.sousLEntete)
                }
                carrousel
                    .padding(.top, HZPlan.sousLesJours)
                boutons
            }
        }
        .padding(.top, HZEspace.haut)
        // Le noir se prolonge SOUS les boutons : c'est lui qui est derrière les coins arrondis de
        // la feuille. Posé en marge de la feuille, cet espace montrait le fond de la page — du blanc
        // dans la moitié basse de l'écran, donc des coins blancs sur du blanc.
        .padding(.bottom, HZPlan.sousLesBoutons + HZRayon.feuille)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HZCouleur.noir)
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
            Text(sousLeTitre)
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
        // Les séances qu'on voit sur les cartes, pas celles de `weekSessions` : en course libre
        // la carte d'aujourd'hui est la séance proposée.
        let seances = jours.filter { !$0.estUnRepos }.count
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
        /// Le grand nombre prend l'accent sur les cartes neutres (le noir doux) ; sur une teinte
        /// d'intensité il reste blanc.
        var nombreEnVedette = false
    }

    /// Une couleur par jour, comme le canvas : le noir doux d'un repos, aujourd'hui avec la couleur de sa
    /// séance (son point est blanc), et les trois teintes d'intensité pour l'endurance, la récupération et la
    /// sortie longue. Le seuil, le fractionné et le renforcement n'ont pas de teinte : ils prennent le
    /// noir doux. Le rose n'est plus une surface, c'est une touche (décision du 19 novembre).
    private func couleurs(de jour: PlanSemaineModele.Jour) -> Couleurs {
        let base: Couleurs
        if jour.estUnRepos {
            base = Couleurs(fond: HZCouleur.surfaceSombre, point: HZCouleur.pointEteint, encre: HZCouleur.blanc,
                            nombreEnVedette: true)
        } else if let intensite = AccueilModele.intensite(de: jour.famille) {
            base = Couleurs(fond: intensite.couleur, point: intensite.point, encre: HZCouleur.blanc)
        } else {
            base = Couleurs(fond: HZCouleur.surfaceSombre, point: HZCouleur.secondaireSurSombre, encre: HZCouleur.blanc,
                            nombreEnVedette: true)
        }
        // Aujourd'hui garde la couleur de sa séance ; seul son point passe au blanc.
        guard jour.etat == .aujourdhui else { return base }
        return Couleurs(fond: base.fond, point: HZCouleur.blanc, encre: base.encre,
                        nombreEnVedette: base.nombreEnVedette)
    }

    /// Les appelants ont déjà tenu compte du verrou : la rangée est éteinte quand le plan l'est, et
    /// le glissement le vérifie lui-même.
    private func selectionner(_ jour: Int) {
        withAnimation(HZCarrousel.animation) { choix = jour }
    }

    // MARK: - Le carrousel

    /// LE CARROUSEL EST UN DÉFILEMENT HORIZONTAL NATIF, calé sur les cartes.
    ///
    /// Trois versions maison l'ont précédé : un geste sur une pile de cartes décalée à la main, avec
    /// un seuil, une prévision de fin, une résistance au bout. Chacune se comportait mal sur
    /// l'appareil — le geste se disputait avec le défilement vertical de la page, ne pouvait pas
    /// être repris en cours de route, n'avait ni l'élan ni le rebond du reste du système. Un
    /// `ScrollView` les a tous, et le calage sur les cartes (`viewAligned`) en fait un carrousel.
    ///
    /// La carte du jour commence à `departDeLaCarte` du bord (la précédente dépasse à gauche) : c'est
    /// la marge du contenu. Et une dernière place vide, de la largeur de l'écran moins une carte,
    /// laisse dimanche se poser au même endroit que les autres jours plutôt que collé à droite.
    private var carrousel: some View {
        ScrollViewReader { lecteur in
            ScrollView(.horizontal) {
                HStack(spacing: HZEspace.entreTuiles) {
                    HStack(spacing: HZEspace.entreTuiles) {
                        ForEach(visibles) { jour in
                            // Un toucher, et non un `Button` : un bouton posé sur chaque carte se
                            // dispute le geste avec le défilement qui les porte (la rangée des
                            // jours faisait glisser la carte, le doigt non, sur l'appareil).
                            carte(jour)
                                .contentShape(Rectangle())
                                .onTapGesture { toucher(jour) }
                                // Bouton seulement quand le toucher fait quelque chose : amener la
                                // carte au premier plan, ou ouvrir la séance d'aujourd'hui. La
                                // carte d'un autre jour, déjà devant, n'ouvre rien : l'annoncer
                                // comme un bouton à VoiceOver était faux.
                                .accessibilityAddTraits(repondAuToucher(jour) ? .isButton : [])
                                .id(jour.id)
                        }
                    }
                    .scrollTargetLayout()
                    Color.clear
                        // `largeur` est celle du défilement SANS ses marges de contenu : la marge de
                        // départ en est déjà retranchée. Elle y figurait aussi, et la place valait 0 :
                        // dimanche se posait collé à droite, 24 points trop loin (vu sur la capture).
                        .containerRelativeFrame(.horizontal) { largeur, _ in
                            max(0, largeur - HZCarteAffiche.largeur - HZEspace.entreTuiles)
                        }
                }
            }
            .contentMargins(.leading, HZPlan.departDeLaCarte, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            // `choix` LUI-MÊME, sans liaison fabriquée : le système l'écrit quand le doigt pose une
            // carte au bord, et défile quand la rangée des jours l'écrit. Une liaison calculée
            // (lue depuis `choisi`, écrite avec des garde-fous) ne bougeait que pour la rangée.
            .scrollPosition(id: $choix, anchor: .leading)
            .scrollIndicators(.hidden)
            // Une seule carte (plan verrouillé, course libre) : rien à faire défiler.
            .scrollDisabled(!aPlusieursCartes)
            .frame(height: HZCarteAffiche.hauteur)
            // Ouvert sur le jour choisi (aujourd'hui) : la position initiale du système n'est pas
            // toujours honorée avant la première mise en page.
            .onAppear {
                // Venue d'une tuile « La suite » de l'accueil : le jour demandé, une seule fois.
                if let demande = appState.jourDuPlanAOuvrir {
                    appState.jourDuPlanAOuvrir = nil
                    if planDebloque, visibles.contains(where: { $0.id == demande }) { choix = demande }
                }
                if choix == nil { choix = choisi }
                lecteur.scrollTo(choisi, anchor: .leading)
            }
            // Le cran du doigt ou de la rangée : un seul endroit pour le retour tactile.
            .onChange(of: choix) { Haptics.selection() }
        }
    }

    private func repondAuToucher(_ jour: PlanSemaineModele.Jour) -> Bool {
        jour.id != choisi || jour.etat == .aujourdhui || seanceDuJour(jour) != nil
    }

    /// La séance prévue un AUTRE jour que le jour même, s'il y en a une (pas un repos).
    private func seanceDuJour(_ jour: PlanSemaineModele.Jour) -> SeanceDUnAutreJour? {
        guard jour.etat != .aujourdhui, !jour.estUnRepos,
              let prevu = appState.profile.weekSessions.first(where: { $0.weekday == jour.id }),
              let seance = prevu.session, seance.durationMinutes > 0 else { return nil }
        return SeanceDUnAutreJour(id: jour.id, seance: seance, date: jour.date, faite: prevu.completed)
    }

    private func toucher(_ jour: PlanSemaineModele.Jour) {
        if jour.id == choisi {
            // La carte déjà au premier plan ouvre le détail de sa séance : celle d'aujourd'hui avec
            // « Démarrer », celle d'un autre jour pour voir ce qui est prévu.
            if jour.etat == .aujourdhui {
                appState.openSessionDetail()
            } else if let autre = seanceDuJour(jour) {
                seanceDUnAutreJour = autre
            }
        } else {
            selectionner(jour.id)
        }
    }

    private func carte(_ jour: PlanSemaineModele.Jour) -> some View {
        let couleur = couleurs(de: jour)
        let nombre = texte(du: jour.nombre)
        return HZCarteAffiche(jour: AccueilModele.dateDuJour(jour.date), etiquette: etiquette(de: jour),
                              prefixe: jour.prefixe ?? "", nombre: nombre, style: style(de: nombre),
                              titre: jour.titre, mesures: jour.mesures.map(colonne(de:)),
                              fond: couleur.fond, encreSecondaire: couleur.encre,
                              nombreEnVedette: couleur.nombreEnVedette)
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
            if planDebloque && aPlusieursCartes && appState.peutDeplacerUneSeance {
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
                if aPlusieursCartes {
                    HZBandeauDuCoach(texte: String(localized: "Glisse une carte pour changer de jour. Déplacer te laisse changer le jour d'une séance de cette semaine."))
                }
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
    /// l'assistant de programme SUR CET OBJECTIF (`AppState.ouvrirLAssistant(sur:)`).
    /// Sans « (Re)commencer » : l'assistant ne le propose pas, la tuile menait à une liste où il
    /// n'était pas.
    private var autresObjectifs: [GoalType] {
        Array(GoalType.allCases.filter { $0.estProposable && $0 != .restart && $0 != profile.goalId }
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
                                appState.ouvrirLAssistant(sur: objectif)
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
