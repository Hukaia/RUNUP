import SwiftUI

/// L'assistant « nouvel objectif » : objectif → détails de la course → jours → construction.
/// Plein écran, dans le langage de l'inscription : une question en très grand, ses réponses en
/// grandes lignes grises (la choisie en noir), la progression en segments, une pilule noire en bas.
struct NewGoalWizardView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var step = 0
    @State private var goal: GoalType?
    @State private var distance: RaceDistance = .k10
    @State private var chrono: String = RaceDistance.k10.chronoPresets[HZObjectif.rangDuChronoParDefaut]
    @State private var raceDate = Calendar.current.date(byAdding: .day, value: HZObjectif.joursAvantLaDateParDefaut, to: .now)!
    /// Le D+ de la course, saisi en texte libre — même champ, mêmes règles qu'à l'inscription :
    /// vide et zéro sont la même réponse, « je ne sais pas ».
    @State private var raceElevationGain: String = ""
    /// Le format du triathlon, et ce qu'elle nage aujourd'hui.
    ///
    /// Le format a une valeur par défaut — l'olympique, le plus couru — et le niveau de natation
    /// n'en a PAS, volontairement : c'est ce qui le rend obligatoire. Même règle qu'à
    /// l'inscription, et pour la même raison (voir `NiveauDeNage`) : c'est la seule réponse de
    /// cet écran dont une valeur supposée peut faire du mal.
    @State private var triathlonFormat: TriathlonFormat = .olympique
    /// Le format du duathlon. Pas de compagnon « niveau de vélo » : l'app mesure le vélo,
    /// donc il n'y a rien à demander dessus. Voir `DuathlonFormat`.
    @State private var duathlonFormat: DuathlonFormat = .standard
    @State private var nageNiveau: NiveauDeNage?
    @State private var days: Set<Int> = Set(HZEntree.joursDeQuatre)
    @State private var building = false
    @State private var buildPct: Double = 0
    /// Séparé de `buildPct`, et c'est tout l'objet du correctif ci-dessous.
    @State private var buildFinished = false

    private let goals: [GoalType] = GoalType.allCases.filter { $0 != .restart && $0.estProposable }

    /// L'étape « ta course » sert à la course ET à l'ultra — un ultra-trail EST une course, avec
    /// une question de plus. Sans ce branchement, choisir « Préparer un ultra-trail » ici sautait
    /// directement aux jours de la semaine : ni distance, ni date, ni dénivelé. Le plan produit
    /// n'avait alors aucune ligne d'arrivée à viser, donc ni bloc spécifique ni affûtage.
    private var estCourseOuUltra: Bool { goal == .race || goal == .ultraTrail }
    private var estTriathlon: Bool { goal == .triathlon }
    private var estDuathlon: Bool { goal == .duathlon }
    /// Le minimum exigé par l'objectif en cours de choix. Voir `GoalType.joursMinimumParSemaine`.
    private var minimumJours: Int { goal?.joursMinimumParSemaine ?? HZObjectif.joursMinimumParDefaut }
    /// Les trois objectifs qui ont une deuxième étape. `periodiseVersUneDate` dit presque la
    /// même chose et pas tout à fait : HYROX a une date et n'a jamais eu d'étape ici, son format
    /// étant fixe. Garder les deux notions distinctes évite de donner au triathlon la mauvaise
    /// étape le jour où HYROX en gagnerait une.
    private var aUneDeuxiemeEtape: Bool { estCourseOuUltra || estTriathlon || estDuathlon }

    /// Les formats à proposer, selon l'objectif. « Autre distance » n'en fait pas partie : cet
    /// assistant n'a pas de champ de texte libre, contrairement à l'inscription.
    private var formats: [RaceDistance] { RaceDistance.choix(pour: goal).filter { $0 != .other } }

    /// Le D+ exigé pour un ultra, et seulement pour lui — même règle qu'à l'inscription.
    private var deniveleManquant: Bool {
        goal == .ultraTrail && (Int(raceElevationGain.trimmingCharacters(in: .whitespaces)) ?? 0) <= 0
    }

    /// Le niveau de natation exigé pour un triathlon, et seulement pour lui — même forme que le
    /// dénivelé juste au-dessus, et même raison : sans ce nombre le plan ne peut pas dimensionner
    /// la seule discipline qu'il ne saura jamais mesurer.
    private var nageManquante: Bool { estTriathlon && nageNiveau == nil }

    @Environment(SubscriptionService.self) private var subscriptions

    /// L'écran qu'on voit, selon l'étape et l'objectif choisi.
    private enum Ecran {
        case objectif, course, triathlon, duathlon, jours
    }

    private var ecran: Ecran {
        switch step {
        case 0: return .objectif
        case 1 where estCourseOuUltra: return .course
        case 1 where estTriathlon: return .triathlon
        case 1 where estDuathlon: return .duathlon
        default: return .jours
        }
    }

    /// Un segment par écran de questions : l'écran de construction ne demande rien, et le compter
    /// donnerait une barre qui n'atteint jamais son bout.
    private var segments: Int {
        aUneDeuxiemeEtape ? HZObjectif.etapesAvecDetails : HZObjectif.etapesSansDetails
    }

    private var rang: Int { min(step, segments - 1) }

    /// Demain : on ne se fixe pas une course dans le passé.
    private var demain: Date {
        Calendar.current.date(byAdding: .day, value: HZObjectif.joursAvantLaPremiereDate, to: .now) ?? .now
    }

    var body: some View {
        cadreDuWizard {
            if !subscriptions.unlocks(.raceGoal) {
                // Se fixer une nouvelle course, c'est demander à Haizo de construire une
                // périodisation — base, spécifique, affûtage, calée sur une date. C'est
                // exactement ce que Plus vend. L'objectif DÉJÀ en cours, lui, reste consultable :
                // on ne reprend pas ce qui a été donné.
                //
                // LE RETOUR VIT ICI AUSSI, ET C'EST LA CORRECTION. Cette branche n'en avait
                // aucun — ni croix, ni chevron — et l'écran est un `fullScreenCover`, donc pas
                // renvoyable au doigt. Une personne non abonnée qui touchait « Refaire un
                // programme » tombait sur une carte de vente dont on ne sortait QU'EN TUANT
                // L'APP. Et la seconde porte était pire : programme terminé, l'app lui demande
                // de choisir la suite, et l'écran du choix se referme sur elle.
                verrou
            } else if building {
                buildingView
            } else {
                content
            }
        }
        .onAppear {
            // Ouvert depuis une tuile « Passer à un objectif » : l'objectif est déjà choisi, on
            // arrive sur sa première question. Le retour ramène à la liste des objectifs.
            if let demande = appState.objectifDeLAssistant, goals.contains(demande), goal == nil {
                goal = demande
                step = aUneDeuxiemeEtape ? 1 : HZObjectif.etapeDesJours
            }
            appState.objectifDeLAssistant = nil
        }
    }

    /// Le fond blanc de l'inscription, la barre d'état masquée, le contenu qui part du haut.
    private func cadreDuWizard<Contenu: View>(@ViewBuilder _ contenu: () -> Contenu) -> some View {
        contenu()
            .padding(.horizontal, HZEspace.marge)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(HZCouleur.blanc.ignoresSafeArea())
            .ignoresSafeArea(edges: .top)
            .statusBarHidden()
    }

    private func boutonDeRetour(_ action: @escaping () -> Void) -> some View {
        HZBoutonRond(dessin: .retour, nom: String(localized: "Retour"), diametre: .outil,
                     fond: HZCouleur.surfaceClaire, couleur: HZCouleur.encre,
                     trait: HZBoutonRond.traitDuRetour, action: action)
    }

    private var verrou: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: HZEspace.entreCommandes) {
                boutonDeRetour { dismiss() }
                Spacer(minLength: 0)
            }
            .frame(minHeight: HZDiametre.outil.rawValue)
            .padding(.top, HZEspace.haut)
            ScrollView {
                PlusLockCard(feature: .raceGoal)
                    .padding(.top, HZEntree.sousLaProgression)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: HZEspace.entreCommandes) {
                boutonDeRetour {
                    // Sans deuxième étape, les jours sont à l'étape 2 et l'étape 1 les redessine :
                    // « step -= 1 » y laissait l'écran identique, le retour semblait mort.
                    if step == 0 {
                        dismiss()
                    } else if step == HZObjectif.etapeDesJours && !aUneDeuxiemeEtape {
                        step = 0
                    } else {
                        step -= 1
                    }
                }
                HZSegments(total: segments, courant: rang)
            }
            .frame(minHeight: HZDiametre.outil.rawValue)
            .padding(.top, HZEspace.haut)

            etape
            pied
        }
    }

    @ViewBuilder private var etape: some View {
        switch ecran {
        case .objectif: goalStep
        case .course: raceStep
        case .triathlon: triathlonStep
        case .duathlon: duathlonStep
        case .jours: daysStep
        }
    }

    /// La pilule du bas : « Continuer », ou « Construire mon programme » à la dernière question.
    @ViewBuilder private var pied: some View {
        switch ecran {
        case .objectif:
            boutonDuPied(String(localized: "Continuer"), actif: goal != nil) {
                step = aUneDeuxiemeEtape ? 1 : HZObjectif.etapeDesJours
            }
        case .course:
            boutonDuPied(String(localized: "Continuer"), actif: !deniveleManquant) { step = HZObjectif.etapeDesJours }
        case .triathlon:
            boutonDuPied(String(localized: "Continuer"), actif: !nageManquante) { step = HZObjectif.etapeDesJours }
        case .duathlon:
            boutonDuPied(String(localized: "Continuer"), actif: true) { step = HZObjectif.etapeDesJours }
        case .jours:
            // Le minimum vient de l'objectif CHOISI ICI, et pas de celui en cours : c'est
            // le nouveau plan qu'on dimensionne. Un triathlon en exige trois.
            boutonDuPied(String(localized: "Construire mon programme"), actif: days.count >= minimumJours) {
                building = true
            }
        }
    }

    private func boutonDuPied(_ libelle: String, actif: Bool, action: @escaping () -> Void) -> some View {
        HZBoutonPilule(libelle: libelle,
                       fond: actif ? HZCouleur.encre : HZCouleur.filetGroupe,
                       couleur: actif ? HZCouleur.blanc : HZCouleur.secondaireSurClair,
                       etendu: true, action: action)
            .disabled(!actif)
            .padding(.top, HZEntree.sousLesReponses)
            .padding(.bottom, HZEntree.basDeLEcran)
    }

    // MARK: - Une question, ses blocs

    /// Une question : son titre d'affichage, puis ses réponses, qui défilent quand elles ne tiennent pas.
    private func questionDuWizard<Reponses: View>(_ titre: String,
                                                  @ViewBuilder reponses: () -> Reponses) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(titre)
                .hzAffichage(.titreDeReglages)
                .foregroundStyle(HZCouleur.encre)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, HZEntree.sousLaProgression)
            ScrollView {
                VStack(alignment: .leading, spacing: HZEspace.entreSections) {
                    reponses()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, HZEntree.sousLeTitre)
            }
            .scrollIndicators(.hidden)
        }
    }

    /// Une sous-question d'un écran de détails : son titre de section, puis ce qu'on y répond.
    private func blocDeQuestion<Contenu: View>(_ titre: String,
                                               @ViewBuilder contenu: () -> Contenu) -> some View {
        VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
            Text(titre)
                .hzAffichage(.section)
                .foregroundStyle(HZCouleur.encre)
                .fixedSize(horizontal: false, vertical: true)
            contenu()
        }
    }

    /// Des réponses l'une sous l'autre.
    private func pileDeReponses<Reponses: View>(@ViewBuilder _ reponses: () -> Reponses) -> some View {
        VStack(spacing: HZEntree.ecartDesReponses) {
            reponses()
        }
    }

    private func choixDuChrono(_ propositions: [String]) -> some View {
        blocDeQuestion(String(localized: "Chrono visé")) {
            ChipFlowLayout {
                ForEach(propositions, id: \.self) { t in
                    HZFiltre(libelle: t, actif: chrono == t, fond: .clair) { chrono = t }
                }
            }
        }
    }

    private func choixDeLaDate(_ titre: String) -> some View {
        blocDeQuestion(titre) {
            HStack(spacing: 0) {
                DatePicker(titre, selection: $raceDate, in: demain..., displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(HZCouleur.encre)
                    .environment(\.colorScheme, .light)
                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - Les écrans

    private var goalStep: some View {
        questionDuWizard(String(localized: "Quel est ton objectif ?")) {
            pileDeReponses {
                ForEach(goals) { g in
                    HZReponse(titre: g.title, choisie: goal == g) { goal = g }
                }
            }
        }
        // Sur la question et non sur chaque réponse : posé dans le `ForEach`, ce modificateur serait
        // installé une fois par objectif et se déclencherait autant de fois à chaque choix.
        //
        // Les formats d'ultra et ceux de route ne se mélangent jamais : garder « 10 km »
        // sélectionné après avoir choisi l'ultra-trail aurait fait construire une préparation de
        // cent kilomètres de montagne sur dix kilomètres de route.
        .onChange(of: goal) { _, nouveau in
            // Le triathlon ne se mesure pas en distances de course : son chrono vient du FORMAT.
            // Sans cette branche, choisir « triathlon » laissait un temps de 10 km sélectionné,
            // et le plan se serait affûté vers 47 minutes pour une épreuve de trois heures.
            if nouveau == .triathlon {
                chrono = triathlonFormat.chronoPresets[safe: HZObjectif.rangDuChronoParDefaut] ?? ""
            }
            // Même raison pour le duathlon : son chrono vient du FORMAT, pas d'une distance de
            // course. Sans cette branche, le choisir laisserait un temps de 10 km sélectionné.
            if nouveau == .duathlon {
                chrono = duathlonFormat.chronoPresets[safe: HZObjectif.rangDuChronoParDefaut] ?? ""
                return
            }
            guard let premier = RaceDistance.choix(pour: nouveau).first else { return }
            distance = premier
            chrono = premier.chronoPresets[safe: HZObjectif.rangDuChronoParDefaut] ?? ""
        }
    }

    private var raceStep: some View {
        questionDuWizard((goal ?? .race).etapeTitre) {
            blocDeQuestion(String(localized: "Distance")) {
                pileDeReponses {
                    ForEach(formats, id: \.self) { d in
                        HZReponse(titre: d.label, choisie: distance == d) {
                            distance = d
                            chrono = d.chronoPresets[safe: HZObjectif.rangDuChronoParDefaut] ?? ""
                        }
                    }
                }
            }
            if goal == .ultraTrail {
                HZChampDeTexte(titre: String(localized: "Le dénivelé positif"),
                               invite: String(localized: "Ex. 4000"),
                               texte: $raceElevationGain, clavier: .numberPad)
            }
            choixDuChrono(distance.chronoPresets)
            choixDeLaDate(String(localized: "Date de la course"))
        }
    }

    /// L'ÉTAPE DU DUATHLON : format → chrono → date. Trois questions, pas quatre.
    ///
    /// C'est ici que le triathlon s'est fait prendre : cet assistant liste les objectifs
    /// `estProposable` exactement comme l'inscription, donc ouvrir le robinet sans lui donner
    /// son étape y aurait fait apparaître le duathlon sans sa question de format — et le plan
    /// se serait construit sans distances ni temps d'effort, sous le bon nom.
    ///
    /// Rien sur le vélo, pour la raison écrite partout dans ce lot : l'app le mesure.
    private var duathlonStep: some View {
        questionDuWizard((goal ?? .duathlon).etapeTitre) {
            blocDeQuestion(String(localized: "Format")) {
                pileDeReponses {
                    ForEach(DuathlonFormat.allCases) { f in
                        HZReponse(titre: f.title, precision: f.resume, choisie: duathlonFormat == f) {
                            duathlonFormat = f
                            chrono = f.chronoPresets[safe: HZObjectif.rangDuChronoParDefaut] ?? ""
                        }
                    }
                }
            }
            choixDuChrono(duathlonFormat.chronoPresets)
            choixDeLaDate(String(localized: "Date de l'épreuve"))
        }
    }

    /// L'étape du triathlon : format → ce qu'elle nage aujourd'hui → chrono → date.
    ///
    /// Même forme que `raceStep` — des réponses, un chrono, une date — avec une question de plus,
    /// qui est la plus importante des quatre. Les trois distances sont le sous-titre de chaque
    /// format : c'est ce qui l'identifie sans employer de marque déposée (voir
    /// `TriathlonFormat`).
    private var triathlonStep: some View {
        questionDuWizard((goal ?? .triathlon).etapeTitre) {
            blocDeQuestion(String(localized: "Format")) {
                pileDeReponses {
                    ForEach(TriathlonFormat.allCases) { f in
                        HZReponse(titre: f.title, precision: f.resume, choisie: triathlonFormat == f) {
                            triathlonFormat = f
                            chrono = f.chronoPresets[safe: HZObjectif.rangDuChronoParDefaut] ?? ""
                        }
                    }
                }
            }
            blocDeQuestion(String(localized: "Aujourd'hui, tu nages combien sans t'arrêter ?")) {
                pileDeReponses {
                    ForEach(NiveauDeNage.allCases) { n in
                        HZReponse(titre: n.title, precision: n.subtitle, choisie: nageNiveau == n) {
                            nageNiveau = n
                        }
                    }
                    if let avertissement {
                        Text(avertissement)
                            .hzParagraphe(.c13, .medium, interligne: HZBandeauDuCoach.interligne)
                            .foregroundStyle(HZCouleur.secondaireSurClair)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            choixDuChrono(triathlonFormat.chronoPresets)
            choixDeLaDate(String(localized: "Date de l'épreuve"))
        }
    }

    /// La phrase qui dit l'écart entre le format et ce qu'elle nage, quand il y en a un.
    /// Identique à celle de l'inscription, et pour la même raison : on donne le nombre, pas un
    /// avis. Voir `TriathlonDetailsStepView.avertissement`.
    private var avertissement: LocalizedStringKey? {
        guard let niveau = nageNiveau, niveau.ecartNotable(pour: triathlonFormat) else { return nil }
        guard let metres = niveau.metresEnContinu else {
            return "La natation partira de zéro, et c'est très bien, mais apprendre à durer dans l'eau demande un bassin et quelqu'un sur le bord, pas une case de plus dans un plan. Le programme construira le vélo et la course, et montera la natation prudemment."
        }
        return "\(triathlonFormat.nageMetres) m le jour J, contre \(metres) m aujourd'hui. Le plan montera progressivement, et la natation sera la discipline qui prend le plus de place dans ta semaine."
    }

    private var daysStep: some View {
        questionDuWizard(String(localized: "Tes jours de course")) {
            HStack(spacing: HZEspace.entrePilules) {
                ForEach(0..<HZObjectif.joursDeLaSemaine, id: \.self) { i in
                    caseDuJour(i)
                }
            }
        }
    }

    private func caseDuJour(_ i: Int) -> some View {
        let on = days.contains(i)
        return Button(action: { if on { days.remove(i) } else { days.insert(i) } }) {
            Text(DayStatus.letters[i])
                .hzTexte(.c16, .gras)
                .foregroundStyle(on ? HZCouleur.blanc : HZCouleur.encre)
                .frame(maxWidth: .infinity)
                .frame(height: HZDiametre.outil.rawValue)
                .background(on ? HZCouleur.encre : HZCouleur.surfaceClaire,
                            in: RoundedRectangle(cornerRadius: HZRayon.bandeau, style: .circular))
                .contentShape(RoundedRectangle(cornerRadius: HZRayon.bandeau, style: .circular))
        }
        .buttonStyle(.plain)
        // « M » et « M » : VoiceOver lit le nom du jour, pas son initiale ambiguë.
        .accessibilityLabel(DayStatus.fullNames[i])
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private var buildingView: some View {
        VStack(spacing: HZObjectif.ecartDeLaConstruction) {
            Spacer(minLength: 0)
            // `buildFinished` et non `buildPct >= 100`. `withAnimation` change la valeur
            // IMMÉDIATEMENT et n'anime que le rendu : `buildPct` valait donc 100 dès la
            // première image, et la coche de fin s'affichait avant que la jauge ne commence à
            // se remplir. Deux secondes de contradiction à l'écran.
            HZIcone(dessin: buildFinished ? .coche : .marque, cote: HZObjectif.coteDuSigne,
                    couleur: HZCouleur.blanc)
                .frame(width: HZDiametre.principal.rawValue, height: HZDiametre.principal.rawValue)
                .background(HZCouleur.encre, in: Circle())
            Text("Ton nouveau\nprogramme arrive")
                .hzAffichage(.titreDeReglages)
                .foregroundStyle(HZCouleur.encre)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            // Was a fixed pct: 70 — a gauge that never actually moved or finished reads as fake
            // progress; this now genuinely animates to 100% over the same wait `runBuild`
            // uses before the new program is actually ready.
            HZJauge(fraction: buildPct / HZHub.centPourcent)
                .padding(.horizontal, HZEspace.margeDeTitre)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // L'animation démarrait dans l'action du bouton, donc dans le même tour de boucle que le
        // basculement qui fait APPARAÎTRE cet écran : la jauge n'avait jamais été rendue à zéro
        // quand on lui demandait d'aller à cent, et elle surgissait déjà remplie avant de se
        // reprendre — le saut. Ici, la vue est posée à zéro, puis animée.
        .task { await runBuild() }
    }

    private func runBuild() async {
        withAnimation(.easeInOut(duration: HZObjectif.dureeDeLaConstruction)) { buildPct = HZHub.centPourcent }
        try? await Task.sleep(for: .seconds(HZObjectif.dureeDeLaConstruction))
        guard !Task.isCancelled else { return }
        buildFinished = true
        finish()
    }

    private func finish() {
        let result = AdaptivePlanEngine.NewGoalResult(
            goal: goal ?? .health,
            distance: estCourseOuUltra ? distance : nil,
            // Le chrono et la date appartiennent aussi au triathlon — il a une ligne d'arrivée,
            // donc un affûtage à caler dessus. Les lui refuser aurait rendu son plan OUVERT :
            // ni bloc spécifique, ni affûtage, donc aucun enchaînement vélo→course et aucune
            // séance de transition. Exactement le défaut que `periodiseVersUneDate` décrit pour
            // l'ultra-trail, reproduit un objectif plus loin.
            chrono: aUneDeuxiemeEtape ? chrono : nil,
            raceDate: aUneDeuxiemeEtape ? raceDate : nil,
            runningDays: Array(days),
            raceElevationGainM: goal == .ultraTrail ? Int(raceElevationGain.trimmingCharacters(in: .whitespaces)) : nil,
            triathlonFormat: estTriathlon ? triathlonFormat.rawValue : nil,
            nageNiveau: estTriathlon ? nageNiveau?.rawValue : nil,
            duathlonFormat: estDuathlon ? duathlonFormat.rawValue : nil
        )
        AdaptivePlanEngine.startNewProgram(result, profile: appState.profile)
        NotificationService.shared.rescheduleDailyReminder(for: appState.profile)
        Haptics.success()
        appState.toast(String(localized: "Ton nouveau programme est prêt"))
        dismiss()
        appState.go(.home)
    }
}
