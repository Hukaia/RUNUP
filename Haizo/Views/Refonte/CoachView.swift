import SwiftUI
import SwiftData
import UIKit

/// LE COACH, refait à partir des composants de la refonte (`Coach.dc.html`).
///
/// Un titre sur le noir, trois tuiles — la forme, la séance du jour, la dernière sortie —, puis la
/// feuille blanche du fil : des bulles, des suggestions qui défilent, la saisie. Rien de ce que le
/// canvas montre (« 97 », « 5×500 », « 8,9 ») n'est écrit ici : chaque tuile vient du profil et de
/// l'historique, et disparaît quand sa donnée n'existe pas.
///
/// LA LOGIQUE N'A PAS BOUGÉ : le fil persistant, l'échange verrouillé de qui n'a pas souscrit, la
/// réponse du coach, l'annulation d'un changement, le « Réessayer ». Seul le dessin change.
///
/// # CE QUE LE CANVAS NE DESSINE PAS, ET QUI RESTE
///
/// - **Le séparateur de jour** (« Aujourd'hui », « Hier »…) : sans lui, une réponse de mardi dernier
///   se lit comme une phrase d'aujourd'hui.
/// - **L'effacement de la conversation** : un bouton rond à droite du titre, tant qu'il y a un fil.
/// - **Le compte rendu d'un changement** (« J'ai déplacé… », avec « Annuler ») : le coach applique
///   ses changements lui-même, il ne les propose pas derrière un bouton « Appliquer ».
/// - **L'indicateur de frappe**, la bulle d'erreur et son « Réessayer ».
///
/// # CE QUE LE CANVAS DESSINE ET QUE L'ÉCRAN RETIRE
///
/// Le ruban des sept jours qui était dans « Ce qu'il regarde » : le canvas ne l'a pas. La forme de
/// la semaine est sur l'accueil et sur le plan, où elle a sa place.
struct CoachView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(SubscriptionService.self) private var subscriptions
    @Query(sort: \ChatMessage.timestamp) private var messages: [ChatMessage]
    /// La dernière course, et elle seule. `fetchLimit = 1` plutôt qu'une requête ouverte qu'on
    /// trierait ensuite : cet écran n'a besoin que d'une ligne, et une requête sans plafond grossit
    /// avec l'historique jusqu'à coûter cher sur un onglet qu'on ouvre tous les jours.
    @Query private var dernieresCourses: [RunRecord]

    init() {
        var d = FetchDescriptor<RunRecord>(sortBy: [SortDescriptor(\RunRecord.date, order: .reverse)])
        d.fetchLimit = 1
        _dernieresCourses = Query(d)
    }
    @State private var vm: CoachViewModel?
    @State private var typingBounce = false
    @State private var showClearConfirm = false

    /// Chaque puce tapée part telle quelle au coach comme message : elle doit donc être dans la
    /// langue de l'utilisatrice, pas juste affichée traduite.
    private let chips = [
        String(localized: "Adapte ma semaine"),
        Accord.selon(f: String(localized: "Je suis fatiguée"), m: String(localized: "Je suis fatigué")),
        String(localized: "Nutrition"),
        String(localized: "Analyse ma sortie")
    ]

    private var profile: UserProfile { appState.profile }

    /// Le coach est la fonctionnalité qui se vend le mieux d'elle-même : il suffit de le laisser
    /// dire bonjour. L'écran garde donc son en-tête, son message d'accueil et l'historique s'il y
    /// en a un — ce qui disparaît, c'est la possibilité de répondre.
    private var coachLocked: Bool { !subscriptions.unlocks(.coach) }

    /// Ce qu'une personne sans abonnement vient d'écrire. VOLONTAIREMENT NON ENREGISTRÉ.
    ///
    /// Rien de cet échange ne part au serveur et rien n'entre dans `ChatMessage` : il n'y a pas de
    /// réponse à produire, donc pas d'appel à payer, et le jour où elle s'abonne son fil démarre
    /// vierge au lieu de s'ouvrir sur une publicité qu'elle a déjà lue.
    @State private var demandeVerrouillee: String?

    var body: some View {
        VStack(spacing: 0) {
            entete
            tuiles
                .padding(.top, HZCoach.sousLEntete)
            feuille
                .padding(.top, HZCoach.sousLesTuiles)
        }
        // Deux moitiés de fond : le noir en haut, le blanc en bas — la feuille remonte sous les
        // tuiles, et c'est le noir qui est derrière ses coins arrondis.
        .background {
            VStack(spacing: 0) {
                HZCouleur.noir
                HZCouleur.blanc
            }
            .ignoresSafeArea()
        }
        .ignoresSafeArea(edges: .top)
        .statusBarHidden()
        .onAppear {
            if vm == nil { vm = CoachViewModel(modelContext: modelContext, profile: profile) }
        }
    }

    // MARK: - Le haut, sur le noir

    private var entete: some View {
        HStack(spacing: HZCoach.ecartDeLEntete) {
            HZIcone(dessin: .marque, cote: HZCoach.coteDeLaMarque, couleur: HZCouleur.noir)
                .frame(width: HZDiametre.outil.rawValue, height: HZDiametre.outil.rawValue)
                .background(HZCouleur.blanc, in: Circle())
            VStack(alignment: .leading, spacing: 0) {
                Text(String(localized: "Coach"))
                    .hzAffichage(.titreDuCoach)
                    .foregroundStyle(HZCouleur.blanc)
                // Un sous-titre honnête : l'ancien point vert « en ligne » ne mesurait rien (il
                // était écrit en dur, allumé même en mode avion).
                Text(String(localized: "Connaît ton programme"))
                    .hzTexte(.c13, .medium)
                    .foregroundStyle(HZCouleur.secondaireSurSombre)
            }
            Spacer(minLength: 0)
            if !messages.isEmpty {
                // TROIS POINTS, PAS UNE CROIX. Une croix en haut à droite d'une conversation se lit
                // « fermer » : on la touchait pour sortir, et on tombait sur « Effacer toute la
                // conversation ? ». Les trois points annoncent un choix, et le choix dit son nom.
                HZBoutonRond(dessin: .options, nom: String(localized: "Effacer la conversation"),
                             diametre: .outil, fond: HZCouleur.surfaceSombre) {
                    showClearConfirm = true
                }
                .confirmationDialog("Effacer toute la conversation ?", isPresented: $showClearConfirm,
                                    titleVisibility: .visible) {
                    Button("Effacer", role: .destructive) {
                        for message in messages { modelContext.delete(message) }
                    }
                    Button("Annuler", role: .cancel) {}
                } message: {
                    Text("Le coach garde ton programme et ta forme en tête. Seul l'historique des messages est effacé.")
                }
            }
        }
        .padding(.horizontal, HZEspace.marge)
        .padding(.top, HZEspace.haut)
    }

    /// CE QU'IL REGARDE : trois tuiles, toutes tirées du profil et de l'historique. Chacune
    /// disparaît quand sa donnée n'existe pas : une forme sans un seul ressenti derrière serait un
    /// nombre inventé, et « — » n'apprend rien à personne.
    private var tuiles: some View {
        HStack(spacing: HZCoach.ecartDesTuiles) {
            if profile.hasReadinessData {
                HZTuileDuCoach(libelle: String(localized: "Forme"), valeur: "\(profile.readiness)",
                               encreDuLibelle: HZCouleur.secondaireSurSombre)
            }
            HZTuileDuCoach(libelle: String(localized: "Aujourd'hui"),
                           valeur: profile.todaySession.displayTitle, style: .seanceDuCoach)
            if let derniere = dernieresCourses.first, derniere.distanceKm > 0 {
                HZTuileDuCoach(libelle: String(localized: "Dernière, km"),
                               valeur: kilometres(derniere))
            }
        }
        .padding(.horizontal, HZEspace.marge)
    }

    /// « 8,9 ». `locale:` et pas `String(format:)` nu : sans lui, la virgule décimale française
    /// devient un point.
    private func kilometres(_ course: RunRecord) -> String {
        String(format: "%.1f", locale: Locale.current, course.distanceKm)
    }

    // MARK: - La feuille : le fil, les suggestions, la saisie

    private var feuille: some View {
        HZFeuille(retrait: .serre) {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    // Paresseux : tout l'historique persistant vit dans un seul fil, et chaque
                    // bulle ne se construit que lorsqu'on s'en approche.
                    LazyVStack(alignment: .leading, spacing: HZCoach.ecartDeFil) {
                        if messages.isEmpty {
                            daySeparator(.now)
                            coachBubble(welcomeMessage)
                        }

                        // Un séparateur entre deux jours (« Aujourd'hui », « Hier », la date) :
                        // sans lui, une réponse de mardi dernier se lit comme une phrase d'aujourd'hui.
                        ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
                            if index == 0 || !Calendar.current.isDate(message.timestamp, inSameDayAs: messages[index - 1].timestamp) {
                                daySeparator(message.timestamp)
                            }
                            bubble(for: message)
                                .id(message.id)
                        }

                        if vm?.isTyping == true {
                            typingIndicator
                        }

                        // L'échange verrouillé : sa question, puis la réponse qui explique
                        // ce qu'il manque pour y répondre.
                        if let demande = demandeVerrouillee {
                            HZBulle(auteur: .coureuse) { HZTexteDeBulle(texte: demande, auteur: .coureuse) }
                            lockedReplyBubble
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollIndicators(.hidden)
                .onChange(of: messages.count) {
                    if let last = messages.last { withAnimation { scrollProxy.scrollTo(last.id, anchor: .bottom) } }
                }
                // Atterrir sur le dernier message en rouvrant l'onglet : `onChange` seul ne se
                // déclenche que sur un NOUVEAU message.
                .onAppear {
                    if let last = messages.last { scrollProxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
            .frame(maxHeight: .infinity)

            // Les suggestions restent, verrouillées ou non : elles sont le chemin le plus court
            // vers la question — donc, sans abonnement, vers la réponse qui dit ce que
            // l'abonnement apporte.
            suggestions
                .padding(.top, HZCoach.avantLesPuces)

            // La saisie reste ouverte à tout le monde, et c'est LA RÉPONSE qui dit ce qui manque.
            HZSaisie(texte: Binding(get: { vm?.draft ?? "" }, set: { vm?.draft = $0 }),
                     invite: String(localized: "Écris à ton coach"),
                     nomDuBouton: String(localized: "Envoyer"),
                     peutEnvoyer: canSend) {
                send(vm?.draft ?? "")
            }
            .padding(.top, HZCoach.avantLaSaisie)
            // Au-dessus de la barre flottante, qui est posée par l'écran racine.
            .padding(.bottom, HZEspace.sousLaBarre + HZBarreFlottante.hauteur + HZEspace.entreCommandes)
        }
    }

    private var suggestions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: HZEspace.entrePilules) {
                ForEach(chips, id: \.self) { chip in
                    HZFiltre(libelle: chip, fond: .contour, graisse: .semi) { send(chip) }
                }
            }
        }
        // Même règle que le bouton d'envoi : pas de suggestion pendant que le coach répond.
        .disabled(vm?.isTyping == true)
        .opacity(vm?.isTyping == true ? HZCoach.suggestionsEnAttente : HZCoach.suggestionsPretes)
        // Le canvas laisse la rangée sortir par le bord droit de la feuille.
        .padding(.trailing, -HZEspace.marge)
    }

    // MARK: - Le fil

    private static let separatorFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "EEEE d MMMM"
        return f
    }()

    private func daySeparator(_ date: Date) -> some View {
        let label: String
        if Calendar.current.isDateInToday(date) { label = String(localized: "Aujourd'hui") }
        else if Calendar.current.isDateInYesterday(date) { label = String(localized: "Hier") }
        else { label = Self.separatorFormatter.string(from: date) }
        return Text(verbatim: label)
            .hzTexte(.c13, .medium)
            .foregroundStyle(HZCouleur.secondaireSurClair)
            .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func bubble(for message: ChatMessage) -> some View {
        switch message.role {
        case .error:
            HZBulle(auteur: .coach) {
                VStack(alignment: .leading, spacing: HZCoach.ecartDansUneBulle) {
                    HZTexteDeBulle(texte: message.text, auteur: .coach)
                    // Pas de « Réessayer » sous un REFUS : la même question recevra la même
                    // réponse, et le message dit déjà quoi faire (reformuler).
                    if message.text != CoachViewModel.texteDuRefus {
                        HZBoutonPilule(libelle: String(localized: "Réessayer"), hauteur: .reponse,
                                       etendu: true) { retryLast() }
                    }
                }
            }
        case .system:
            appliedChangeRow(message)
        case .coach:
            coachBubble(message.text)
        case .user:
            HZBulle(auteur: .coureuse) { HZTexteDeBulle(texte: message.text, auteur: .coureuse) }
        }
    }

    private func coachBubble(_ text: String) -> some View {
        HZBulle(auteur: .coach) { HZTexteDeBulle(texte: text, auteur: .coach) }
    }

    /// Ce que le coach vient de changer au programme.
    ///
    /// Volontairement PAS une bulle : ce n'est pas quelqu'un qui parle, c'est l'app qui rend
    /// compte. Une bulle de plus dans le fil se lirait comme une phrase du coach, et la coureuse
    /// n'aurait aucun moyen de distinguer ce qu'il a dit de ce qu'il a fait.
    ///
    /// `Text(message.text)` et pas `Text(LocalizedStringKey(...))` : la phrase arrive déjà
    /// traduite d'`applyCoachAction`. La repasser par une clé la traduirait deux fois.
    private func appliedChangeRow(_ message: ChatMessage) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: HZEspace.entrePilules) {
            HZIcone(dessin: .coche, cote: HZCoach.coteDeLaCoche, trait: HZCoach.traitDeLEnvoi,
                    couleur: HZCouleur.encre)
            Text(message.text)
                .hzParagraphe(.c14, .semi, interligne: HZBandeauDuCoach.interligne)
                .foregroundStyle(HZCouleur.secondaireSurClair)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            if vm?.canUndo(message) == true {
                Button { vm?.undoLastAction() } label: {
                    Text(String(localized: "Annuler"))
                        .hzTexte(.c14, .gras)
                        .foregroundStyle(HZCouleur.encre)
                        .frame(minHeight: HZBoutonRond.zoneTactile)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, HZEspace.groupe)
        .padding(.vertical, HZEspace.entreCommandes)
        .background(HZCouleur.surfaceClaire,
                    in: RoundedRectangle(cornerRadius: HZRayon.proposition, style: .circular))
        .accessibilityElement(children: .combine)
    }

    /// La réponse du coach à qui n'a pas souscrit : la même bulle que les autres, et un bouton.
    ///
    /// Une bulle plutôt qu'une carte d'offre, parce que c'est le coach qui parle — il dit ce qui
    /// lui manque pour répondre, dans sa voix et à sa place dans le fil.
    private var lockedReplyBubble: some View {
        HZBulle(auteur: .coach) {
            VStack(alignment: .leading, spacing: HZCoach.ecartDansUneBulle) {
                HZTexteDeBulle(texte: String(localized: "Je peux te répondre vraiment, mais il me faut Haizo Plus. Le coach lit ton programme, ta forme et tes dernières sorties avant de te répondre. C'est ce qui fait la différence avec une réponse générique."),
                               auteur: .coach)
                HZBoutonPilule(libelle: String(localized: "Découvrir Haizo Plus"), hauteur: .reponse,
                               etendu: true) { appState.plusPrompt = .coach }
            }
        }
    }

    /// Les trois points du coach qui écrit, qui rebondissent l'un après l'autre.
    private enum PointDeFrappe: Int, CaseIterable {
        case premier, deuxieme, troisieme
    }

    private var typingIndicator: some View {
        HZBulle(auteur: .coach) {
            HStack(spacing: HZCoach.ecartDesPointsDeFrappe) {
                ForEach(PointDeFrappe.allCases, id: \.rawValue) { point in
                    Circle().fill(HZCouleur.secondaireSurClair)
                        .frame(width: HZCoach.pointDeFrappe, height: HZCoach.pointDeFrappe)
                        .offset(y: typingBounce && !reduceMotion ? -HZCoach.rebondDuPoint : 0)
                        .animation(reduceMotion ? nil : .easeInOut(duration: HZCoach.dureeDuRebond)
                            .repeatForever(autoreverses: true)
                            .delay(Double(point.rawValue) * HZCoach.decalageDuRebond), value: typingBounce)
                }
            }
        }
        .onAppear { typingBounce = true }
        // Sinon, le silence en attendant une réponse : les points ne disent rien à VoiceOver.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Le coach écrit…")
    }

    /// Y a-t-il quelque chose à envoyer.
    /// Et le coach n'est pas en train d'écrire : `CoachViewModel.send` refuse un envoi pendant
    /// qu'une réponse arrive. Le bouton restait allumé, on touchait, et le message n'était ni
    /// envoyé ni refusé à l'écran.
    private var canSend: Bool {
        !(vm?.draft ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && vm?.isTyping != true
    }

    /// The zero-message welcome bubble used to always claim "Ta forme est au top" regardless of
    /// the real `readiness` score (even a low one) and regardless of whether any real data backed
    /// it at all — gated on `hasReadinessData` so it's honest instead.
    private var welcomeMessage: String {
        // « J'ai relevé ta séance à Repos. » — la phrase ne veut rien dire en français, et c'est
        // la deuxième du premier message que lit quelqu'un qui découvre le coach.
        let sessionPart = String(localized: "Aujourd'hui, c'est \(profile.todaySession.displayTitle).")
        guard profile.hasReadinessData else {
            return String(localized: "Salut \(profile.name). \(sessionPart) Une question avant de te lancer ?")
        }
        let formPart: String
        if profile.readiness >= HZCoach.formeAuTop {
            formPart = String(localized: "Ta forme est au top aujourd'hui (\(profile.readiness)/100).")
        } else if profile.readiness >= HZCoach.formeCorrecte {
            formPart = String(localized: "Ta forme est correcte aujourd'hui (\(profile.readiness)/100).")
        } else if profile.readiness >= HZCoach.formeMoyenne {
            formPart = String(localized: "Un peu de fatigue aujourd'hui (\(profile.readiness)/100).")
        } else {
            formPart = String(localized: "Fatigue accumulée aujourd'hui (\(profile.readiness)/100).")
        }
        return String(localized: "Salut \(profile.name). \(formPart) \(sessionPart) Une question avant de te lancer ?")
    }

    private func send(_ text: String) {
        // Sans abonnement, rien ne part : pas d'appel au modèle, pas d'enregistrement. La bulle
        // d'en face est écrite ici.
        guard !coachLocked else {
            let propre = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !propre.isEmpty else { return }
            vm?.draft = ""
            withAnimation { demandeVerrouillee = propre }
            Analytics.shared.track(.coachMessageSent, ["thread_length": .int(0)])
            return
        }
        // Only the fact that a message was sent, and how deep into the conversation it was — never
        // the message itself. The coach is the one place in this app where what she types is
        // genuinely private (PRIVACY_POLICY.md promises those messages are never stored on our
        // server, only relayed), and an event's `props` bag is a stored Postgres column.
        Analytics.shared.track(.coachMessageSent, ["thread_length": .int(messages.count)])
        vm?.send(text, history: messages)
    }

    private func retryLast() {
        // The error bubble sits after her message in `messages` — the VM re-sends from the
        // existing history without inserting a duplicate user bubble.
        vm?.retry(history: messages.filter { $0.role != .error })
    }
}
