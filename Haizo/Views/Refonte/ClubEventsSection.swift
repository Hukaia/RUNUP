import SwiftUI

/// LES SORTIES DE GROUPE — la seule chose qui fasse d'un classement un club.
///
/// Sortie de `ClubView` en dernier, et après mesure : des trois régions qui restaient, c'est
/// celle dont l'interface est la plus étroite. 228 lignes pour QUATRE points de contact, soit
/// 57 lignes par port — contre 25 pour le mur et 15 pour l'entrée du club, dont les actions
/// sont présentées par le parent et ne se détachent donc pas. Un découpage ne gagne rien s'il
/// échange de la longueur contre de la surface d'interface.
///
/// Ce qui entre : le magasin, la liste des badges — elle vient de `@Query`, qui n'existe que
/// dans une vue, et `loadIfSignedIn` la redemande — et la liaison du drapeau qui ouvre la
/// feuille de création, parce que la carte « réveiller le club » la pose aussi.
///
/// Ce qui reste dedans : `eventEnModification`. Son bouton et sa feuille sont tous deux ici,
/// donc dans la même branche de l'arbre — la condition qui manquait aux deux feuilles mal
/// placées trouvées le 8 novembre.
struct ClubEventsSection: View {
    let magasin: ClubStore
    let badges: [ClubBadge]
    @Binding var showCreateEvent: Bool

    /// LA SORTIE QU'ON MODIFIE. Son bouton est dans `menuDeLaSortie`, juste en dessous : le
    /// déclencheur et la feuille sont dans la même vue, donc la feuille s'ouvre toujours.
    @State private var eventEnModification: ClubEvent?
    /// Annuler une sortie la retire pour tous ceux qui s'y étaient inscrits : le geste se confirme.
    @State private var sortieAAnnuler: ClubEvent?

    var body: some View {
        eventsCard
            .alert("Annuler cette sortie ?",
                   isPresented: Binding(get: { sortieAAnnuler != nil },
                                        set: { if !$0 { sortieAAnnuler = nil } })) {
                // Lue AVANT la fermeture de l'alerte, qui remet l'état à `nil`.
                Button("Annuler la sortie", role: .destructive) {
                    if let sortie = sortieAAnnuler { magasin.deleteEvent(sortie) }
                }
                Button("Garder la sortie", role: .cancel) {}
            } message: {
                Text("Elle disparaîtra pour tous ceux qui s'y étaient inscrits.")
            }
    }

    private static let eventDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "EEE d MMM · HH:mm"
        return f
    }()

    private static let eventTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "HH:mm"
        return f
    }()

    /// « CE SOIR · 18:00 » plutôt que « MER 13 AOÛT · 18:00 » quand la sortie est aujourd'hui.
    ///
    /// La maquette insiste sur ce point et elle a raison : une sortie de groupe est une chose à
    /// laquelle on décide de se joindre MAINTENANT, et une date complète oblige à comparer
    /// mentalement avec le jour qu'on est. Purement du formatage — la donnée reste `startsAt`.
    private func eventDateLabel(_ date: Date) -> String {
        let time = Self.eventTimeFormatter.string(from: date)
        if Calendar.current.isDateInToday(date) {
            return Calendar.current.component(.hour, from: date) >= HZHub.heureDuSoir
                ? String(localized: "Ce soir · \(time)")
                : String(localized: "Aujourd'hui · \(time)")
        }
        if Calendar.current.isDateInTomorrow(date) { return String(localized: "Demain · \(time)") }
        // Les trois branches au-dessus rendent « Ce soir · 18:30 », « Aujourd'hui · … »,
        // « Demain · … » en casse normale. Celle-ci les mettait en capitales : le MÊME libellé
        // changeait de casse selon la distance de la date.
        return Self.eventDateFormatter.string(from: date)
    }

    /// Sorties de groupe — real proposed group runs with RSVP. The one feature that turns a
    /// leaderboard into an actual club: people running TOGETHER.
    /// Une SECTION, plus une carte par sortie — et c'est le seul endroit de l'onglet où
    /// l'intertitre reste sur le fond.
    ///
    /// Les sorties sont une LISTE d'objets qu'on prend un par un : chacune porte sa date, son
    /// lieu, son « J'y serai » et ses groupes d'allure. Les poser dans une carte commune
    /// donnerait une carte dans une carte, deux chromes emboîtés pour une seule hiérarchie.
    /// L'intertitre passe donc sur la page — le motif de « Mon équipement » sur le Profil — et
    /// chaque sortie devient sa propre petite carte.
    ///
    /// Ce raisonnement ne valait que pour une liste, et il avait été étendu à tout l'onglet : la
    /// semaine, le défi, les courses, les séances et les records l'avaient perdu aussi, et quatre
    /// sections flottaient sur le lavande. Elles sont redevenues des cartes ; celle-ci reste une
    /// section, parce qu'elle en contient déjà.
    private var eventsCard: some View {
        VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
            HZTitreDeSection(titre: String(localized: "Sorties de groupe"), lien: String(localized: "Proposer")) {
                showCreateEvent = true
            }
            if (magasin.board.events ?? []).isEmpty {
                HZPhrase(texte: String(localized: "Aucune sortie prévue. Propose un créneau, les autres n'ont qu'à dire « J'y serai »."))
            }
            ForEach(magasin.board.events ?? []) { event in
                HZPlaque {
                    HStack(spacing: HZEspace.groupe) {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(spacing: HZEspace.entrePilules) {
                                Text(eventDateLabel(event.startsAt))
                                    .hzTexte(.c13, .gras)
                                    .foregroundStyle(HZCouleur.encre)
                                if event.repeatsWeekly == true {
                                    HZPilule(texte: String(localized: "Chaque semaine"), style: .etiquette,
                                             fond: HZCouleur.filetGroupe, couleur: HZCouleur.encre)
                                }
                            }
                            .lineLimit(1)
                            Text(event.title)
                                .hzTexte(.c16, .gras)
                                .foregroundStyle(HZCouleur.encre)
                            if let location = event.location, !location.isEmpty {
                                Text(location)
                                    .hzTexte(.c13, .medium)
                                    .foregroundStyle(HZCouleur.secondaireSurClair)
                            }
                        }
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        VStack(alignment: .trailing, spacing: HZEspace.entrePilules) {
                            HZBoutonPilule(libelle: event.goingByMe ? String(localized: "Tu y vas")
                                                                    : String(localized: "J'y vais"),
                                           hauteur: .petite,
                                           fond: event.goingByMe ? HZCouleur.accent : HZCouleur.encre,
                                           couleur: event.goingByMe ? HZCouleur.encreSurAccent : HZCouleur.blanc) {
                                magasin.toggleRsvp(event)
                            }
                            Text("\(event.going) au départ")
                                .hzTexte(.c12, .medium)
                                .foregroundStyle(HZCouleur.secondaireSurClair)
                        }
                    }
                    groupesDAllure(event)
                }
                .contextMenu { menuDeLaSortie(event) }
            }
        }
        .sheet(item: $eventEnModification) { event in
            CreateEventSheet(onCreate: { title, location, date, chaqueSemaine, groupes in
                try await magasin.modifierLaSortie(event, title: title, location: location,
                                                   startsAt: date, repeatsWeekly: chaqueSemaine,
                                                   paceGroups: groupes, badges: badges)
            }, existant: event)
            .hzFeuille(detents: [.large], gereSonBas: true)
        }
    }

    @ViewBuilder
    private func menuDeLaSortie(_ event: ClubEvent) -> some View {
        // La sortie se modifie par qui l'a proposée, ET par qui tient le club. Le serveur
        // l'autorisait déjà aux organisateurs ; l'app ne le proposait qu'à l'auteur, donc une
        // organisatrice ne pouvait pas corriger l'heure d'une sortie posée par quelqu'un d'autre.
        if event.isMine || magasin.jAdministreLeClub {
            Button("Modifier cette sortie") { eventEnModification = event }
            Button("Annuler cette sortie", role: .destructive) { sortieAAnnuler = event }
        }
    }

    /// LES GROUPES D'ALLURE, SANS LESQUELS UNE SORTIE DE CREW NE FONCTIONNE PAS.
    ///
    /// Trente personnes au départ ne courent pas ensemble : elles partent par groupes — « 4:30 »,
    /// « 5:15 », « 6:00 et on discute ». Dire « j'y serai » sans dire à quelle allure laisse
    /// l'organisateur sans la seule information dont il ait besoin : combien de meneurs prévoir.
    ///
    /// Taper un autre groupe que le sien DÉPLACE, ça ne décommande pas : c'est le geste qu'on
    /// fait vraiment, et le contraire aurait fait disparaître sa présence d'un doigt mal posé.
    /// Les groupes d'allure d'une sortie : une pastille par groupe, la mienne pleine. Un doigt de 44
    /// points de haut, comme tout bouton : la pastille est dessinée plus petite, la zone ne l'est pas.
    @ViewBuilder
    private func groupesDAllure(_ event: ClubEvent) -> some View {
        let groupes = event.paceGroups ?? []
        if !groupes.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: HZHub.ecartDesGroupes) {
                    ForEach(groupes, id: \.self) { groupe in
                        let choisi = event.myPaceGroup == groupe
                        let compte = event.paceCounts?[groupe] ?? 0
                        HZFiltre(libelle: compte > 0 ? "\(groupe) · \(compte)" : groupe, actif: choisi,
                                 fond: .clair, margeVerticale: HZFiltre.margeDePeriode) {
                            magasin.toggleRsvp(event, groupe: groupe)
                        }
                        .accessibilityLabel(String(localized: "Groupe \(groupe)"))
                        .accessibilityValue(Pluriel.choisir(compte,
                                                            String(localized: "\(compte) personne"),
                                                            String(localized: "\(compte) personnes")))
                    }
                }
            }
        }
    }
}
