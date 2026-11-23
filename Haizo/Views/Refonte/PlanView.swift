import SwiftUI

/// Le plan complet. Les séances de la semaine en cours viennent des données générées par
/// `AdaptivePlanEngine`, adaptées une fois par semaine à partir du RPE moyen de la semaine
/// précédente (voir `refreshProgramForCurrentDate`) — jamais après une seule course. Les autres
/// semaines montrent un aperçu type généré de la même façon, annoncé comme tel puisque leur
/// difficulté exacte dépend d'une adaptation qui n'a pas encore eu lieu.
///
/// # Pourquoi une courbe plutôt qu'une liste
///
/// Un plan périodisé N'EST PAS une liste. C'est une forme : le volume monte pendant la Base,
/// culmine en Spécifique, retombe à l'Affûtage, avec une semaine allégée qui revient. C'est
/// exactement ce qu'on achète en payant un plan adaptatif. L'écran montre donc une barre par
/// semaine, en couleur de phase, et sous elle la semaine choisie, dépliée. La semaine en cours est
/// celle qui est choisie à l'ouverture, parce que c'est celle qu'on vient voir ; les autres sont à
/// un geste.
///
/// # Une page, pas une feuille
///
/// L'écran s'ouvre en plein écran depuis « Ta semaine » : c'est une page, le haut noir et la
/// feuille blanche des écrans refaits (`HZPage`).
struct PlanView: View {
    @Environment(AppState.self) private var appState
    private var profile: UserProfile { appState.profile }

    /// Ce que fait le bouton de retour. `nil` : revenir à l'accueil, comme quand l'écran était un
    /// écran de l'app. Depuis « Ta semaine » (refonte), l'écran s'ouvre PAR-DESSUS et se referme.
    private let retour: (() -> Void)?

    init(retour: (() -> Void)? = nil) {
        self.retour = retour
    }

    /// La semaine que la page détaille. `nil` avant le premier calcul, puis toujours une valeur —
    /// la semaine en cours à l'ouverture.
    @State private var selectedWeek: Int?
    /// LES TROIS FEUILLES DE CET ÉCRAN SONT LES SIENNES.
    ///
    /// Elles passaient par les drapeaux d'`AppState`, dont les feuilles sont accrochées à
    /// `RootTabView`. Or cet écran s'ouvre en couverture plein écran par-dessus la racine : une
    /// feuille présentée par la racine restait DERRIÈRE la couverture. « Déplacer une séance »,
    /// « Les modifier » et la ligne d'aujourd'hui ne montraient rien, puis la feuille surgissait
    /// au moment de fermer le plan. Présentées d'ici, elles s'ouvrent au-dessus.
    @State private var deplacementOuvert = false
    @State private var reglagesDuProgrammeOuverts = false
    @State private var seanceOuverte = false
    /// Instantané de `computeWeekSummaries()`, calculé au premier affichage et rafraîchi seulement
    /// quand la semaine avance. En propriété calculée, il relancerait
    /// `AdaptivePlanEngine.generateWeekSessions` pour CHAQUE semaine du plan à la moindre
    /// re-évaluation de la vue — et le graphique en dépend, donc à chaque changement de sélection.
    @State private var weekSummaries: [WeekSummary] = []
    /// Les jours de la semaine affichée, mis en cache pour la même raison que `weekSummaries`.
    ///
    /// Pour une semaine autre que celle en cours, `dayList` régénère les séances par
    /// `AdaptivePlanEngine`. La liste est visible en permanence — elle n'est plus derrière un
    /// dépliement — donc l'appeler depuis le corps de la vue relancerait cette génération à chaque
    /// re-évaluation, y compris celles que la sélection déclenche.
    @State private var selectedDays: [(String, PlannedDay, DayStatus.State?)] = []

    private struct WeekSummary: Identifiable {
        var id: Int { number }
        var number: Int
        var block: AdaptivePlanEngine.TrainingBlock
        var estimatedKm: Int
        var isDone: Bool
        var isCurrent: Bool
    }

    /// Une phase du plan et son avancement : « 3 semaines de Base sur 6 ».
    private struct PhaseDuPlan: Identifiable {
        var id: String { block.rawValue }
        var block: AdaptivePlanEngine.TrainingBlock
        var done: Int
        var total: Int
    }

    /// Real program shape — a race goal periodizes toward the actual race date (variable length,
    /// not a fixed 9 weeks); every other goal is open-ended (`totalWeeks == nil`), so there's no
    /// fixed "whole plan" to show — the preview window below just looks a reasonable distance ahead.
    private var shape: AdaptivePlanEngine.ProgramShape {
        AdaptivePlanEngine.ProgramShape.compute(goal: profile.goalId, raceDate: profile.raceDate, from: profile.programStartDate ?? .now)
    }

    /// Les semaines que la page dessine et laisse parcourir.
    ///
    /// Un plan de course est borné (20 semaines au plus, voir `ProgramShape.compute`) et sa forme
    /// EST l'information : on le montre en entier. Un programme ouvert n'a pas de fin — après un
    /// an, l'ancienne borne `weekNumber + 7` aurait dessiné 59 barres de trois points et généré
    /// 59 semaines de séances à chaque ouverture de l'écran. Sa forme se répète toutes les
    /// 4 semaines : une fenêtre autour de la semaine en cours dit tout ce qu'il y a à dire.
    private var weekRange: ClosedRange<Int> {
        if let total = shape.totalWeeks { return 1...max(1, total) }
        let hi = profile.weekNumber + HZPlanComplet.semainesAVenir
        return max(1, profile.weekNumber - HZPlanComplet.semainesPassees)...max(hi, HZPlanComplet.semainesMinimum)
    }

    private func computeWeekSummaries() -> [WeekSummary] {
        weekRange.map { number in
            let sessions = number == profile.weekNumber
                ? profile.weekSessions
                : AdaptivePlanEngine.generateWeekSessions(weekNumber: number, tier: profile.weekTier, profile: profile)
            return WeekSummary(
                number: number,
                block: AdaptivePlanEngine.trainingBlock(forWeek: number, shape: shape),
                estimatedKm: estimatedKm(for: sessions),
                isDone: number < profile.weekNumber,
                isCurrent: number == profile.weekNumber
            )
        }
    }

    private var currentWeek: WeekSummary? { weekSummaries.first { $0.isCurrent } }

    private var selected: WeekSummary? {
        weekSummaries.first { $0.number == selectedWeek } ?? currentWeek
    }

    var body: some View {
        HZPage {
            hautDePage
        } contenu: {
            feuille
        }
        .onAppear {
            weekSummaries = computeWeekSummaries()
            if selectedWeek == nil { selectedWeek = profile.weekNumber }
            refreshSelectedDays()
        }
        .onChange(of: selectedWeek) { _, _ in refreshSelectedDays() }
        // La liste des jours est mise en cache dans `selectedDays` — sans ceci, une séance
        // déplacée depuis la feuille resterait affichée à son ancien jour jusqu'à ce qu'on quitte
        // l'écran. Le déplacement aurait bien eu lieu, et l'écran dirait le contraire.
        .onChange(of: profile.weekSessions) { _, _ in refreshSelectedDays() }
        .onChange(of: profile.weekNumber) { _, week in
            weekSummaries = computeWeekSummaries()
            // La semaine avance pendant que l'écran est ouvert : suivre le mouvement plutôt que
            // laisser la page détailler une semaine qui vient de devenir passée.
            selectedWeek = week
            refreshSelectedDays()
        }
        .sheet(isPresented: $deplacementOuvert) {
            MoveSessionSheet()
                .hzFeuille(detents: [.medium, .large])
        }
        .sheet(isPresented: $reglagesDuProgrammeOuverts) {
            ProgramSettingsSheet()
                .hzFeuille(detents: [.large], gereSonBas: true)
        }
        .sheet(isPresented: $seanceOuverte) {
            SessionDetailSheet()
                .hzFeuille(detents: [.medium, .large], gereSonBas: true)
        }
    }

    // MARK: Le haut, sur le noir

    private var hautDePage: some View {
        VStack(alignment: .leading, spacing: 0) {
            HZCommandesDuHaut(retour: { if let retour { retour() } else { appState.go(.home) } }) {
                EmptyView()
            }
            Text(String(localized: "Ton programme · \(profile.goalDisplay)"))
                .hzTexte(.c15, .semi)
                .foregroundStyle(HZCouleur.secondaireSurSombre)
                .minimumScaleFactor(HZPlanComplet.reductionDuTexte)
                .padding(.horizontal, HZEspace.margeDeTitre)
                .padding(.top, HZHub.sousLesCommandes)
            Text(String(localized: "Le plan complet"))
                .hzAffichage(.titreDEcran)
                .foregroundStyle(HZCouleur.blanc)
                .padding(.horizontal, HZEspace.margeDeTitre)
        }
    }

    // MARK: La feuille

    /// Le plan COMPLET est ce que Plus vend : la périodisation sur plusieurs semaines, sa forme, et
    /// son recalcul après chaque sortie. La séance du jour reste gratuite sur l'accueil — c'est
    /// elle qui donne envie de voir la suite, et la cacher reviendrait à vendre quelque chose que
    /// personne n'a goûté.
    private var feuille: some View {
        PlusSection(feature: .adaptivePlan, teaserHeight: HZPlanComplet.hauteurDeLApercu) {
            VStack(alignment: .leading, spacing: HZEspace.entreSections) {
                volumeChart
                weekNavigator
                if let week = selected {
                    weekCard(week)
                }
                planShapeNote
            }
        }
    }

    // MARK: La forme du plan

    /// Une barre par semaine, en couleur de phase, hauteur proportionnelle au volume estimé.
    ///
    /// Les barres sont étroites — seize semaines dans une largeur d'écran — donc bien en dessous
    /// des 44 pt des règles d'Apple. C'est le même arbitrage que pour un contrôle segmenté : elles
    /// sont jointives, une frappe imprécise tombe sur la voisine et non dans le vide, et la zone
    /// tapable couvre toute la hauteur du graphique. Pour viser sans se tromper, le sélecteur
    /// juste en dessous offre deux vraies cibles de 44 pt.
    ///
    /// Les deux chiffres ne sont écrits nulle part ailleurs : le nombre de semaines, et le plus
    /// gros volume du plan. Ils passent AU-DESSUS du dessin plutôt que dessus.
    private var volumeChart: some View {
        let maxKm = max(1, weekSummaries.map(\.estimatedKm).max() ?? 1)
        return VStack(alignment: .leading, spacing: HZEspace.groupe) {
            Text(String(localized: "La forme du plan, semaine par semaine"))
                .hzTexte(.c13, .medium)
                .foregroundStyle(HZCouleur.secondaireSurClair)
                .minimumScaleFactor(HZPlanComplet.reductionDuTexte)
            HStack(spacing: HZEspace.entreTuiles) {
                HZTuileChiffre(libelle: String(localized: "semaines"), valeur: String(weekSummaries.count))
                HZTuileChiffre(libelle: String(localized: "km au plus fort"), valeur: String(maxKm))
            }
            HStack(alignment: .bottom, spacing: HZPlanComplet.ecartDesBarres) {
                ForEach(weekSummaries) { week in
                    volumeBar(week, maxKm: maxKm)
                }
            }
            phaseBar
            deloadNote
        }
    }

    private func volumeBar(_ week: WeekSummary, maxKm: Int) -> some View {
        let isSelected = week.number == selected?.number
        let height = max(HZPlanComplet.hauteurMiniDeLaBarre,
                         CGFloat(week.estimatedKm) / CGFloat(maxKm) * HZPlanComplet.hauteurDesBarres)
        return Button(action: {
            Haptics.selection()
            withAnimation(.easeOut(duration: HZHub.dureeDeLOnglet)) { selectedWeek = week.number }
        }) {
            VStack(spacing: HZPlanComplet.ecartBarreEtRepere) {
                Spacer(minLength: 0)
                RoundedRectangle(cornerRadius: HZPlanComplet.rayonDeLaBarre, style: .circular)
                    .fill(couleurDeBloc(week.block))
                    // Les semaines faites reculent sans disparaître : elles font partie de la
                    // forme — c'est même par elles qu'on voit la progression — mais elles ne sont
                    // plus d'actualité.
                    .opacity(week.isDone ? HZPlanComplet.opaciteDesSemainesFaites : HZPlan.pleine)
                    .frame(height: height)
                // Le repère de la semaine en cours. Il ne dépend pas de la sélection : on doit
                // pouvoir regarder la semaine 12 sans perdre de vue où l'on en est.
                Circle()
                    .fill(week.isCurrent ? HZCouleur.encre : Color.clear)
                    .frame(width: HZPlanComplet.repereDeLaSemaine, height: HZPlanComplet.repereDeLaSemaine)
            }
            .frame(maxWidth: .infinity)
            .frame(height: HZPlanComplet.hauteurDeLaColonne)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                if isSelected {
                    cadreDeSelection(hauteurDeLaBarre: height)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "Semaine \(week.number), \(week.block.label), environ \(week.estimatedKm) kilomètres"))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// Le cadre posé autour de la barre de la semaine choisie : la couleur ne porte pas seule ce
    /// qui est choisi.
    private func cadreDeSelection(hauteurDeLaBarre: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: HZPlanComplet.rayonDeLaSelection, style: .circular)
            .stroke(HZCouleur.encre.opacity(HZPlanComplet.opaciteDeLaSelection),
                    lineWidth: HZPlanComplet.traitDeLaSelection)
            .frame(height: hauteurDeLaBarre + HZPlanComplet.margeDeLaSelection)
            .padding(.bottom, HZPlanComplet.basDeLaSelection)
    }

    /// Ce que la barre grise veut dire.
    ///
    /// La barre de phases sert de légende aux trois couleurs de périodisation — Base, Spécifique,
    /// Affûtage. Elle ne pouvait pas nommer la quatrième : une semaine de décharge n'est pas une
    /// phase, c'en est un creux À L'INTÉRIEUR d'une phase.
    ///
    /// Résultat : la seule barre qui rompt le rythme, celle que l'œil va chercher en premier
    /// parce qu'elle est grise et courte, était la seule que rien n'expliquait. C'est d'autant
    /// plus dommage que c'est la meilleure chose que le graphique ait à raconter — le moment où le
    /// programme allège de lui-même pour laisser la charge se transformer en progrès.
    ///
    /// Une ligne, et seulement quand le plan affiché en contient : une légende qui nomme une
    /// couleur absente apprend à ignorer les légendes.
    @ViewBuilder private var deloadNote: some View {
        if weekSummaries.contains(where: { $0.block == .deload }) {
            HStack(alignment: .firstTextBaseline, spacing: HZPlanComplet.ecartDeLaPastille) {
                pastille(couleurDeBloc(.deload))
                Text(String(localized: "En gris, les semaines de décharge : le volume baisse exprès, c'est là que les progrès se fixent."))
                    .hzParagraphe(.c13, .medium, interligne: HZPlanComplet.interligne)
                    .foregroundStyle(HZCouleur.secondaireSurClair)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    /// La barre de phases, sous le graphique.
    ///
    /// Le graphique et elle ne disent pas la même chose : l'un montre le VOLUME semaine par
    /// semaine, elle montre où l'on en est dans la périodisation — « 3 semaines de Base sur 6 » se
    /// lit sur elle d'un coup d'œil, alors qu'il faut compter les barres pour le déduire du
    /// graphique. Ses libellés nomment aussi les trois couleurs du graphique.
    ///
    /// Elle ne s'affiche que pour un plan à date de course. Un programme ouvert n'a ni Spécifique
    /// ni Affûtage : trois segments dont deux resteraient vides décriraient un plan qui n'existe
    /// pas.
    @ViewBuilder private var phaseBar: some View {
        if shape.totalWeeks != nil {
            VStack(alignment: .leading, spacing: HZPlanComplet.sousLaBarreDePhases) {
                phaseSegments
                legende([.base, .specifique, .affutage])
            }
        } else {
            phaseLegend
        }
    }

    private var phasesDuPlan: [PhaseDuPlan] {
        let forme = shape
        let semaine = profile.weekNumber
        let base = min(semaine, forme.baseWeeks)
        let specifique = max(0, min(semaine - forme.baseWeeks, forme.specificWeeks))
        let affutage = max(0, min(semaine - forme.baseWeeks - forme.specificWeeks, forme.taperWeeks))
        return [
            PhaseDuPlan(block: .base, done: base, total: forme.baseWeeks),
            PhaseDuPlan(block: .specifique, done: specifique, total: forme.specificWeeks),
            PhaseDuPlan(block: .affutage, done: affutage, total: forme.taperWeeks)
        ]
    }

    /// Trois jauges, de largeur proportionnelle à la durée de leur phase.
    private var phaseSegments: some View {
        let phases = phasesDuPlan
        let somme = max(1, phases.reduce(0) { $0 + $1.total })
        return GeometryReader { geometrie in
            let ecarts = HZPlanComplet.ecartDesSegments * CGFloat(max(0, phases.count - 1))
            let disponible = geometrie.size.width - ecarts
            HStack(spacing: HZPlanComplet.ecartDesSegments) {
                ForEach(phases) { phase in
                    HZJauge(fraction: fraction(de: phase),
                            couleur: couleurDeBloc(phase.block),
                            epaisseur: HZHub.hauteurDeLaProgression)
                        .frame(width: disponible * CGFloat(phase.total) / CGFloat(somme))
                }
            }
        }
        .frame(height: HZHub.hauteurDeLaProgression)
    }

    private func fraction(de phase: PhaseDuPlan) -> Double {
        phase.total == 0 ? 0 : Double(phase.done) / Double(phase.total)
    }

    /// La légende de repli, pour un programme ouvert : ses phases réellement présentes, dans leur
    /// ordre d'apparition. La barre à trois segments ne convient pas là — il n'y a ni Spécifique
    /// ni Affûtage à remplir — mais les couleurs du graphique ont quand même besoin d'être nommées.
    private var phaseLegend: some View {
        var seen: [AdaptivePlanEngine.TrainingBlock] = []
        for week in weekSummaries where !seen.contains(week.block) { seen.append(week.block) }
        return legende(seen)
    }

    /// Les phases nommées, chacune derrière une pastille à sa couleur.
    private func legende(_ blocs: [AdaptivePlanEngine.TrainingBlock]) -> some View {
        HStack(spacing: HZPlanComplet.ecartDeLegende) {
            ForEach(blocs, id: \.rawValue) { bloc in
                HStack(spacing: HZPlanComplet.ecartDeLaPastille) {
                    pastille(couleurDeBloc(bloc))
                    Text(bloc.label)
                        .hzTexte(.c13, .semi)
                        .foregroundStyle(HZCouleur.secondaireSurClair)
                }
            }
            Spacer(minLength: 0)
        }
        .accessibilityHidden(true)
    }

    private func pastille(_ couleur: Color) -> some View {
        Circle()
            .fill(couleur)
            .frame(width: HZPlanComplet.pastille, height: HZPlanComplet.pastille)
    }

    /// LES QUATRE BLOCS, ET UNE SEULE TABLE : les barres reprennent exactement les couleurs que
    /// leur propre légende annonce juste en dessous. La Base prend l'accent, le Spécifique l'encre,
    /// l'Affûtage la teinte de la sortie longue ; la décharge est grise.
    private func couleurDeBloc(_ block: AdaptivePlanEngine.TrainingBlock) -> Color {
        switch block {
        case .base: return HZCouleur.accent
        case .specifique: return HZCouleur.encre
        case .affutage: return HZIntensite.longue.couleur
        case .deload: return HZCouleur.secondaireSurClair
        }
    }

    // MARK: Le sélecteur de semaine

    /// Deux flèches de 44 pt et le nom de la semaine. Le graphique au-dessus sert à voir et à
    /// sauter ; celui-ci sert à viser — et il donne à VoiceOver un chemin linéaire là où seize
    /// barres n'en donnent pas.
    private var weekNavigator: some View {
        HStack(spacing: HZEspace.entreCommandes) {
            navButton(dessin: .retour, nom: String(localized: "Semaine précédente"),
                      enabled: (selected?.number ?? weekRange.lowerBound) > weekRange.lowerBound) {
                step(-1)
            }
            VStack(spacing: 0) {
                Text(selected.map { String(localized: "Semaine \($0.number)") } ?? "")
                    .hzTexte(.c16, .gras)
                    .foregroundStyle(HZCouleur.encre)
                Text(weekSubtitle)
                    .hzTexte(.c13, .medium)
                    .foregroundStyle(HZCouleur.secondaireSurClair)
                    .minimumScaleFactor(HZPlanComplet.reductionDuTexte)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
            navButton(dessin: .chevron, nom: String(localized: "Semaine suivante"),
                      enabled: (selected?.number ?? weekRange.upperBound) < weekRange.upperBound) {
                step(1)
            }
        }
    }

    private var weekSubtitle: String {
        guard let week = selected else { return "" }
        if week.isCurrent { return String(localized: "Cette semaine · \(week.block.label)") }
        if week.isDone { return String(localized: "Faite · \(week.block.label)") }
        return String(localized: "À venir · \(week.block.label)")
    }

    private func navButton(dessin: HZDessin, nom: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        HZBoutonRond(dessin: dessin, nom: nom, diametre: .outil,
                     fond: HZCouleur.surfaceClaire, couleur: HZCouleur.encre, action: action)
            .disabled(!enabled)
            .opacity(enabled ? HZPlan.pleine : HZPlan.eteint)
    }

    private func step(_ delta: Int) {
        let next = (selected?.number ?? profile.weekNumber) + delta
        guard weekRange.contains(next) else { return }
        Haptics.selection()
        withAnimation(.easeOut(duration: HZHub.dureeDeLOnglet)) { selectedWeek = next }
    }

    // MARK: La semaine choisie

    /// Une seule section, quelle que soit la semaine regardée. Il y en avait trois formes — la
    /// semaine en cours, une ligne dépliable pour les suivantes, la même en plus pâle pour les
    /// passées — pour montrer exactement le même contenu.
    private func weekCard(_ week: WeekSummary) -> some View {
        VStack(alignment: .leading, spacing: HZEspace.groupe) {
            weekHeader(week)
            VStack(spacing: HZPlanComplet.ecartEntreJours) {
                ForEach(selectedDays, id: \.0) { letter, day, state in
                    dayRow(letter: letter, day: day, state: state)
                }
            }
            weekAction(week)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Le numéro de la semaine, sa phase en pastille, et ce qu'elle pèse.
    private func weekHeader(_ week: WeekSummary) -> some View {
        VStack(alignment: .leading, spacing: HZEspace.entrePilules) {
            HStack(spacing: HZEspace.entreCommandes) {
                Text(String(localized: "Semaine \(week.number)"))
                    .hzAffichage(.section)
                    .foregroundStyle(HZCouleur.encre)
                blockPill(week.block)
                Spacer(minLength: 0)
            }
            Text(weekSummaryLine(week))
                .hzParagraphe(.c14, .medium, interligne: HZPlanComplet.interligne)
                .foregroundStyle(HZCouleur.secondaireSurClair)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func weekSummaryLine(_ week: WeekSummary) -> String {
        if week.isCurrent {
            return String(localized: "~\(week.estimatedKm) km · \(completedCount)/\(plannedCount) séances faites")
        }
        if week.isDone {
            return String(localized: "~\(week.estimatedKm) km · résumé type de cette semaine passée")
        }
        return String(localized: "~\(week.estimatedKm) km · s'ajustera selon ta forme")
    }

    /// Le décalage, offert sur la semaine en cours et sur elle seule.
    ///
    /// C'est la seule semaine qui existe vraiment : `weekSessions` la persiste, les suivantes sont
    /// régénérées à chaque affichage. Proposer le geste sur une semaine future donnerait un
    /// déplacement effacé à la prochaine ouverture de l'écran, sans que rien ne le signale — pire
    /// qu'une fonction absente.
    ///
    /// Une semaine à venir ne porte AUCUN déplacement, et sans l'autre ligne rien ne le dit : on
    /// décale une séance cette semaine, on avance d'une semaine, on la retrouve à son ancien jour,
    /// et on conclut que le déplacement n'a pas marché. Elle donne aussi le vrai remède : si le
    /// conflit revient chaque semaine, ce sont les jours de course qui se règlent, une fois pour
    /// toutes.
    @ViewBuilder private func weekAction(_ week: WeekSummary) -> some View {
        if week.isCurrent && plannedCount > 0 && appState.peutDeplacerUneSeance {
            HZBoutonPilule(libelle: String(localized: "Déplacer une séance"), dessin: .deplacer,
                           hauteur: .moyenne, fond: HZCouleur.surfaceClaire,
                           couleur: HZCouleur.encre, etendu: true) {
                Haptics.selection()
                deplacementOuvert = true
            }
        } else if !week.isCurrent && !week.isDone {
            Button(action: { Haptics.selection(); reglagesDuProgrammeOuverts = true }) {
                HStack(spacing: HZMesuresDeLigne.ecart) {
                    HZIcone(dessin: .calendrier, cote: HZPlanComplet.coteDeLIcone, couleur: HZCouleur.encre)
                    Text(String(localized: "Cette semaine suit tes jours de course · Les modifier"))
                        .hzParagraphe(.c14, .semi, interligne: HZPlanComplet.interligne)
                        .foregroundStyle(HZCouleur.encre)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    HZChevron()
                }
                .padding(.horizontal, HZEspace.groupe)
                .padding(.vertical, HZEspace.tuile)
                .background(HZCouleur.surfaceClaire,
                            in: RoundedRectangle(cornerRadius: HZRayon.bandeau, style: .circular))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    /// La phrase qui décrit la forme du programme, en bas et en petit : elle est la même toutes
    /// les semaines, et le graphique en haut la montre désormais mieux qu'elle ne la dit.
    @ViewBuilder private var planShapeNote: some View {
        if let total = shape.totalWeeks {
            Text(String(localized: "\(total) semaines en 3 phases, calées sur ta date de course. Le plan s'ajuste chaque semaine selon ta forme, pas séance par séance."))
                .hzParagraphe(.c13, .medium, interligne: HZPlanComplet.interligne)
                .foregroundStyle(HZCouleur.secondaireSurClair)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Text(String(localized: "Programme ouvert, sans date de fin : une semaine plus légère toutes les 4 semaines. Il s'ajuste chaque semaine selon ta forme."))
                .hzParagraphe(.c13, .medium, interligne: HZPlanComplet.interligne)
                .foregroundStyle(HZCouleur.secondaireSurClair)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// La phase, en pastille, à côté du numéro de la semaine regardée.
    private func blockPill(_ block: AdaptivePlanEngine.TrainingBlock) -> some View {
        HZPilule(texte: block.label, fond: HZCouleur.surfaceClaire, couleur: HZCouleur.encre)
    }

    private var completedCount: Int { profile.weekSessions.filter(\.completed).count }
    private var plannedCount: Int { profile.weekSessions.filter { ($0.session?.durationMinutes ?? 0) > 0 }.count }

    /// Rendues par un `Text(String)` nu (elles transitent par un tuple), donc localisées ici :
    /// une abréviation de jour n'est pas la même dans les trois langues.
    private static let dayLetters = [
        String(localized: "Lun"), String(localized: "Mar"), String(localized: "Mer"),
        String(localized: "Jeu"), String(localized: "Ven"), String(localized: "Sam"),
        String(localized: "Dim")
    ]

    private func refreshSelectedDays() {
        selectedDays = selected.map { dayList(for: $0) } ?? []
    }

    private func dayList(for week: WeekSummary) -> [(String, PlannedDay, DayStatus.State?)] {
        if week.isCurrent {
            return profile.weekSessions.map { day in
                (Self.dayLetters[day.weekday], day, profile.weekStrip.first { $0.weekday == day.weekday }?.state)
            }
        }
        let preview = AdaptivePlanEngine.generateWeekSessions(weekNumber: week.number, tier: profile.weekTier, profile: profile)
        return preview.map { (Self.dayLetters[$0.weekday], $0, nil) }
    }

    // MARK: Une ligne de jour

    /// L'initiale du jour, la bande de couleur de la séance, son titre, et à droite ses mesures.
    ///
    /// La bande est ce qui fait de la semaine une forme : on voit trois séances d'endurance, un
    /// fractionné, une sortie longue, sans lire une seule ligne. La couleur est celle de
    /// l'intensité, comme sur l'accueil et sur « Ta semaine ».
    private func dayRow(letter: String, day: PlannedDay, state: DayStatus.State?) -> some View {
        let session = day.session
        let isRest = session == nil || session?.durationMinutes == 0
        let isToday = state == .today
        let family = isRest ? SessionFamily.rest : (session?.family ?? .endurance)
        return HStack(spacing: HZPlanComplet.ecartDeLigne) {
            Text(letter)
                .hzTexte(.c13, .semi)
                .foregroundStyle(HZCouleur.secondaireSurClair)
                .frame(width: HZPlanComplet.colonneDuJour, alignment: .leading)
            Capsule()
                .fill(isRest ? Color.clear : couleurDeFamille(family))
                .frame(width: HZPlanComplet.largeurDeLaBande, height: HZPlanComplet.hauteurDeLaBande)
            dayTitles(session: session, isRest: isRest, isToday: isToday)
            // Le ✓ d'une séance faite : « c'est fait » répond à une question plus pressante que
            // « c'était quoi ». Le type de la séance, lui, reste dans sa couleur et son titre.
            if day.completed {
                HZIcone(dessin: .coche, cote: HZPlanComplet.coteDeLaCoche,
                        trait: HZPlanComplet.traitDeLaCoche, couleur: HZCouleur.encre)
            }
            if let session, !isRest {
                dayMeasures(session)
            }
        }
        .padding(.vertical, HZPlanComplet.margeVerticaleDeJour)
        .padding(.horizontal, HZPlanComplet.margeHorizontaleDeJour)
        // La ligne du jour se détache par un fond de la surface claire, au lieu d'une puce
        // « aujourd'hui » posée au milieu de la ligne, qui poussait le titre de la séance et
        // décalait la colonne durée/allure d'un jour à l'autre.
        .background(isToday ? HZCouleur.surfaceClaire : Color.clear,
                    in: RoundedRectangle(cornerRadius: HZRayon.vignette, style: .circular))
        .contentShape(Rectangle())
        // Le détail complet d'une séance vit dans `SessionDetailSheet`, qui dérive sa structure par
        // archétype : on ouvre cette feuille plutôt que d'en dupliquer une version appauvrie ici.
        // Seule la ligne d'aujourd'hui réagit : c'est la seule séance dont `todaySession` décrit
        // vraiment le contenu.
        .onTapGesture { if isToday { seanceOuverte = true } }
        // Chaque ligne était 3 à 5 arrêts VoiceOver sans lien (jour, titre, sous-titre, durée,
        // allure), et « aujourd'hui » / « faite » ne vivaient plus que dans la couleur.
        .accessibilityElement(children: .combine)
        .accessibilityLabel(dayRowAccessibilityLabel(day: day, isToday: isToday, isRest: isRest))
        .accessibilityAddTraits(isToday ? .isButton : [])
    }

    /// Le titre de la séance, et sur la seule ligne d'aujourd'hui son sous-titre.
    ///
    /// C'est une phrase de coaching — « installe l'endurance de fond, allure confort » — tirée d'un
    /// petit répertoire : sur sept lignes, elle se répétait presque à l'identique. Sur la seule
    /// séance qu'on va faire aujourd'hui, elle redevient un conseil. Les deux se replient sur
    /// plusieurs lignes plutôt que de se couper.
    private func dayTitles(session: WorkoutSession?, isRest: Bool, isToday: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(session?.displayTitle ?? String(localized: "Repos"))
                .hzParagraphe(.c16, isToday ? .semi : .medium, interligne: HZPlanComplet.interligne)
                .foregroundStyle(isRest ? HZCouleur.secondaireSurClair : HZCouleur.encre)
                .fixedSize(horizontal: false, vertical: true)
            if isToday, let subtitle = session?.displaySubtitle, !isRest {
                Text(subtitle)
                    .hzParagraphe(.c13, .medium, interligne: HZPlanComplet.interligne)
                    .foregroundStyle(HZCouleur.secondaireSurClair)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Les deux chiffres pour lesquels on ouvre la ligne : durée et zone, puis allure.
    private func dayMeasures(_ session: WorkoutSession) -> some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text(verbatim: "\(session.durationMinutes)′ · \(session.zone)")
                .hzTexte(.c13, .semi, tabulaire: true)
                .foregroundStyle(HZCouleur.encre)
            Text(verbatim: session.pace + HZAccueil.uniteDAllure)
                .hzTexte(.c13, .medium, tabulaire: true)
                .foregroundStyle(HZCouleur.secondaireSurClair)
        }
        .layoutPriority(HZPlanComplet.prioriteDesMesures)
    }

    /// La couleur d'une séance : celle de son intensité. Le seuil, le fractionné et le renforcement
    /// n'ont pas de teinte dans le canvas : ils prennent l'accent, comme sur l'accueil.
    private func couleurDeFamille(_ family: SessionFamily) -> Color {
        AccueilModele.intensite(de: family)?.couleur ?? HZCouleur.accent
    }

    private func dayRowAccessibilityLabel(day: PlannedDay, isToday: Bool, isRest: Bool) -> String {
        var parts: [String] = [isToday ? String(localized: "\(DayStatus.fullNames[day.weekday]), aujourd'hui") : DayStatus.fullNames[day.weekday]]
        parts.append(isRest ? String(localized: "repos") : (day.session?.displayTitle ?? String(localized: "repos")))
        if let session = day.session, !isRest {
            parts.append(String(localized: "\(session.durationMinutes) minutes, \(session.zone), allure \(session.pace) par kilomètre"))
        }
        if day.completed { parts.append(String(localized: "séance faite")) }
        return parts.joined(separator: ", ")
    }

    // MARK: Les kilomètres d'une semaine

    private func paceMinutesPerKm(_ pace: String) -> Double? {
        let parts = pace.split(separator: ":")
        guard parts.count == HZPlanComplet.partiesDUneAllure, let m = Double(parts[0]), let s = Double(parts[1]) else { return nil }
        return m + s / HZPlanComplet.secondesParMinute
    }

    private func estimatedKm(for sessions: [PlannedDay]) -> Int {
        let total = sessions.compactMap { day -> Double? in
            guard let session = day.session, session.durationMinutes > 0, let paceMin = paceMinutesPerKm(session.pace) else { return nil }
            return Double(session.durationMinutes) / paceMin
        }.reduce(0, +)
        return Int(total.rounded())
    }
}
