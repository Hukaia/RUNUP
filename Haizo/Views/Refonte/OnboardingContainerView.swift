import SwiftUI

/// L'INSCRIPTION : cinq écrans, une question chacun. Le nom, l'objectif, les jours, le niveau, puis le
/// compte — comme dans les applis de course : on dit qui on est et ce qu'on veut, et le compte (Apple ou
/// e-mail, puis un pseudo) enregistre le programme et donne ses identifiants au réseau social. La question en très grand, les réponses en grandes lignes sur la
/// surface claire (la choisie en noir), la progression en segments, un bouton pilule noir en bas.
/// Aucun tutoriel, aucun carrousel.
///
/// # CE QUE LES TROIS QUESTIONS REMPLACENT
///
/// L'inscription en comptait dix : le prénom et le nom, la date de naissance, l'objectif, ses détails
/// (distance, chrono, date, division, format), le point de départ, le bien-être, les jours, le niveau,
/// les statistiques et Santé. Le prénom et le nom restent : ce sont les identifiants du Club et des amis.
/// Ce qui n'est plus demandé prend une valeur que le niveau choisi décrit (volume actuel, plus longue
/// sortie, temps disponible) ou reste vide — le moteur accepte les deux, c'est ce que fait déjà un profil
/// de démonstration. Santé se connecte dans les Réglages.
///
/// # UNE COURSE SE CHOISIT APRÈS
///
/// Un objectif daté — une course, un HYROX, un ultra — demande une distance, un chrono visé et une
/// date : trois questions à lui seul. « Préparer une course » crée donc un programme de progression,
/// puis ouvre la liste des courses, où l'on choisit la sienne.
struct OnboardingContainerView: View {
    @Environment(AppState.self) private var appState
    @State private var vm = OnboardingViewModel()
    @State private var etape = 0
    @State private var prenom = ""
    @State private var nom = ""
    @State private var objectif: Objectif?
    @State private var jours: Int?
    @State private var niveau: ExperienceLevel?

    /// Les objectifs sans date, et « Préparer une course » qui mène à la liste des courses.
    private enum Objectif: Hashable, Identifiable {
        case but(GoalType)
        case course

        var id: String {
            switch self {
            case .but(let but): return but.rawValue
            case .course: return "course"
            }
        }

        static var proposes: [Objectif] {
            [.course] + GoalType.allCases.filter { $0.estProposable && !$0.periodiseVersUneDate }.map { .but($0) }
        }
    }

    /// Les quatre questions, dans l'ordre : le rang de l'écran dit laquelle on pose.
    private enum Question: Int {
        case nom, objectif, jours, niveau, compte
    }

    private var question: Question { Question(rawValue: etape) ?? .niveau }

    private var butChoisi: GoalType {
        if case .but(let but) = objectif { return but }
        return .progress
    }

    private var peutContinuer: Bool {
        switch question {
        case .nom: return !prenom.trimmingCharacters(in: .whitespaces).isEmpty
                    && !nom.trimmingCharacters(in: .whitespaces).isEmpty
        case .objectif: return objectif != nil
        case .jours: return jours != nil
        case .niveau: return niveau != nil
        case .compte: return true
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: HZEspace.entreCommandes) {
                if etape > 0 {
                    HZBoutonRond(dessin: .retour, nom: String(localized: "Retour"), diametre: .outil,
                                 fond: HZCouleur.surfaceClaire, couleur: HZCouleur.encre,
                                 trait: HZBoutonRond.traitDuRetour) { reculer() }
                }
                HZSegments(total: HZEntree.ecrans, courant: etape)
            }
            .frame(minHeight: HZDiametre.outil.rawValue)
            .padding(.top, HZEspace.haut)

            Group {
                switch question {
                case .nom: questionDuNom
                case .objectif: questionDeLObjectif
                case .jours: questionDesJours
                case .niveau: questionDuNiveau
                case .compte:
                    SignInView(dansLInscription: true) { finir() }
                }
            }
            .id(etape)
            .transition(.opacity)
            .onAppear { Analytics.shared.track(.onboardingStepViewed, proprietes) }

            // Une sauvegarde Haizo se restaure d'ici : sans elle, l'inscription obligerait à refaire un
            // programme qu'on a déjà, et les Réglages sont inatteignables avant la fin de l'inscription.
            if question == .nom {
                BoutonDeRestauration {
                    Text("J'ai déjà une sauvegarde Haizo")
                        .hzTexte(.c14, .semi)
                        .foregroundStyle(HZCouleur.secondaireSurClair)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: HZBoutonRond.zoneTactile)
                        .contentShape(Rectangle())
                }
                .padding(.top, HZEntree.sousLesReponses)
            }
            // Le compte a ses propres boutons (Apple, e-mail, « Plus tard ») : pas de « Continuer » dessous.
            if question != .compte {
                HZBoutonPilule(libelle: String(localized: "Continuer"),
                               fond: peutContinuer ? HZCouleur.encre : HZCouleur.filetGroupe,
                               couleur: peutContinuer ? HZCouleur.blanc : HZCouleur.secondaireSurClair,
                               etendu: true) { avancer() }
                    .disabled(!peutContinuer)
                    .padding(.top, HZEntree.sousLesReponses)
                    .padding(.bottom, HZEntree.basDeLEcran)
            }
        }
        .padding(.horizontal, HZEspace.marge)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(HZCouleur.blanc)
        .ignoresSafeArea(edges: .top)
        .statusBarHidden()
        .animation(.easeInOut(duration: HZEntree.dureeDeLaTransition), value: etape)
        .task {
            Analytics.shared.track(.onboardingStarted)
            // Un brouillon d'une inscription interrompue rend le nom déjà saisi.
            if prenom.isEmpty { prenom = vm.name }
            if nom.isEmpty { nom = vm.lastName }
        }
    }

    // MARK: - Les trois questions

    /// Le prénom, pour que le coach s'adresse à toi ; le nom, pour que tes amis te retrouvent dans le Club.
    private var questionDuNom: some View {
        question(String(localized: "Comment tu t'appelles ?")) {
            VStack(alignment: .leading, spacing: HZEspace.entreTuiles) {
                HZChampDeTexte(titre: String(localized: "Prénom"), invite: String(localized: "Ton prénom"),
                               texte: $prenom, majuscules: .words)
                HZChampDeTexte(titre: String(localized: "Nom de famille"),
                               invite: String(localized: "Ton nom de famille"),
                               texte: $nom, majuscules: .words)
                Text("Ton coach s'adressera à toi par ton prénom. Le nom sert à tes amis, pour te retrouver dans le Club.")
                    .hzParagraphe(.c13, .medium, interligne: HZBandeauDuCoach.interligne)
                    .foregroundStyle(HZCouleur.secondaireSurClair)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var questionDeLObjectif: some View {
        question(String(localized: "Quel est ton objectif ?")) {
            ForEach(Objectif.proposes) { choix in
                HZReponse(titre: titre(de: choix), precision: precision(de: choix), choisie: objectif == choix) {
                    objectif = choix
                }
            }
        }
    }

    private var questionDesJours: some View {
        question(String(localized: "Combien de jours par semaine ?")) {
            ForEach(HZEntree.choixDeJours, id: \.self) { nombre in
                HZReponse(titre: Pluriel.choisir(nombre,
                                                 String(localized: "\(nombre) jour"),
                                                 String(localized: "\(nombre) jours")),
                          precision: nombre == HZEntree.choixDeJours.first
                              ? String(localized: "Tu pourras déplacer chaque séance.") : nil,
                          choisie: jours == nombre,
                          disponible: nombre >= butChoisi.joursMinimumParSemaine) {
                    jours = nombre
                }
            }
        }
    }

    private var questionDuNiveau: some View {
        question(String(localized: "Où en es-tu ?")) {
            ForEach(ExperienceLevel.allCases) { valeur in
                HZReponse(titre: valeur.title, precision: valeur.subtitle, choisie: niveau == valeur) {
                    niveau = valeur
                }
            }
        }
    }

    /// Une question : son titre d'affichage, puis ses réponses, qui défilent quand elles ne tiennent pas.
    private func question<Reponses: View>(_ titre: String, @ViewBuilder reponses: () -> Reponses) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(titre)
                .hzAffichage(.titreDeReglages)
                .foregroundStyle(HZCouleur.encre)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, HZEntree.sousLaProgression)
            ScrollView {
                VStack(spacing: HZEntree.ecartDesReponses) {
                    reponses()
                }
                .padding(.top, HZEntree.sousLeTitre)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func titre(de choix: Objectif) -> String {
        switch choix {
        case .but(let but): return but.title
        case .course: return GoalType.race.title
        }
    }

    private func precision(de choix: Objectif) -> String? {
        switch choix {
        case .but(let but): return but.subtitle
        case .course: return String(localized: "Tu choisiras ta course juste après : le plan se calera sur sa date.")
        }
    }

    // MARK: - Avancer, reculer, finir

    private var proprietes: [String: AnalyticsValue] {
        ["step": .int(etape), "name": .string(nom(de: etape))]
    }

    private func nom(de etape: Int) -> String { HZEntree.noms[min(etape, HZEntree.noms.count - 1)] }

    private func reculer() {
        etape = max(0, etape - 1)
    }

    private func avancer() {
        Analytics.shared.track(.onboardingStepCompleted, proprietes)
        if etape < HZEntree.ecrans - 1 {
            // Un objectif plus exigeant que les jours déjà choisis les remet en question.
            if question == .objectif, let jours, jours < butChoisi.joursMinimumParSemaine { self.jours = nil }
            // Le nom donné passe dans le profil avant le compte : c'est lui qui prend le relais quand Apple
            // ne rend pas le sien, et qui préremplit le formulaire.
            if question == .niveau {
                appState.profile.name = prenom.trimmingCharacters(in: .whitespaces)
                appState.profile.lastName = nom.trimmingCharacters(in: .whitespaces)
            }
            etape += 1
        } else {
            finir()
        }
    }

    private func finir() {
        let niveauChoisi = niveau ?? .intermediaire
        vm.name = prenom
        vm.lastName = nom
        vm.goal = butChoisi
        vm.level = niveauChoisi
        vm.levelTouched = true
        vm.runningDays = HZEntree.joursDeCourse(jours ?? HZEntree.parDefaut)
        vm.runningDaysTouched = true
        vm.preferredLongRunDay = HZEntree.jourDeLaSortieLongue
        // Faute de poser la question, le niveau choisi décrit le point de départ.
        switch niveauChoisi {
        case .debutante:
            vm.volumeActuel = .uneOuDeux
            vm.plusLongueSortie = .de3a5
        case .intermediaire:
            vm.volumeActuel = .troisOuQuatre
            vm.plusLongueSortie = .de5a10
        case .confirmee:
            vm.volumeActuel = .cinqEtPlus
            vm.plusLongueSortie = .de10a15
        }
        vm.tempsSemaineMin = HZEntree.minutesEnSemaine
        vm.tempsWeekEndMin = HZEntree.minutesLeWeekEnd

        Analytics.shared.track(.onboardingFinished, [
            "goal": .string(vm.goal?.rawValue ?? "unknown"),
            "level": .string(vm.level.rawValue),
            "running_days": .int(vm.runningDays.count),
        ])
        vm.clearDraft()
        AdaptivePlanEngine.applyOnboarding(vm.buildResult(), to: appState.profile)
        let profile = appState.profile
        let shape = AdaptivePlanEngine.ProgramShape.compute(goal: profile.goalId, raceDate: profile.raceDate,
                                                            from: profile.programStartDate ?? .now)
        let message = shape.totalWeeks.map { String(localized: "Ton programme de \($0) semaines est prêt") }
            ?? String(localized: "Ton programme sur mesure est prêt")
        Haptics.success()
        appState.toast(message)
        if objectif == .course {
            appState.openRacesTabOnNextVisit = true
            appState.go(.club)
        }
        Task {
            await NotificationService.shared.requestAuthorization()
            NotificationService.shared.rescheduleDailyReminder(for: profile)
        }
    }
}
