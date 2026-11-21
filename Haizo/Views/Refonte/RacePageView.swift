import SwiftUI
import UIKit

/// LA PAGE D'UNE COURSE.
///
/// Quatre choses, dans cet ordre, parce que c'est l'ordre dans lequel on s'en sert :
///
///   1. la course — quand, où, combien ;
///   2. ce que MOI j'y vise, et ce que j'accepte de montrer ;
///   3. qui la prépare aussi, celles et ceux qui cherchent quelqu'un d'abord, puis les plus
///      proches de mon allure ;
///   4. le mur : questions, recherches de partenaire, dossards à céder ou à trouver.
///
/// # LE PARTAGE DE L'ENTRAÎNEMENT EST UN CHOIX, PAS UN RÉGLAGE PAR DÉFAUT
///
/// Montrer à des inconnus où quelqu'un en est de sa préparation n'est pas la même chose que lui
/// montrer qu'il court la même course. Le volume ne sort du serveur que pour qui a coché la case —
/// et quand elle n'est pas cochée, il n'est même pas CALCULÉ (voir api/races/[action].js). Ici,
/// `nil` s'affiche « n'a pas partagé », jamais « 0 km » : confondre les deux serait accuser
/// quelqu'un de ne pas s'entraîner parce qu'il tient à sa vie privée.
///
/// # LE MUR DE DOSSARDS N'ENCAISSE RIEN
///
/// Il met deux personnes en contact et s'arrête là : aucun paiement, aucune garantie, aucune
/// vérification. La plupart des organisateurs INTERDISENT le transfert de dossard — courir sous le
/// nom d'un autre, c'est la disqualification, et surtout des secours qui liraient le mauvais
/// dossier médical. L'avertissement est écrit sur chaque annonce et au moment d'en écrire une,
/// plutôt que de faire comme si la question ne se posait pas.
struct RacePageView: View {
    var race: RaceEvent
    /// Appelé quand je me mets à suivre la course, ou que j'arrête : la liste d'où l'on vient
    /// porte « Je prépare », et elle serait fausse au retour.
    ///
    /// Facultatif depuis que la page s'ouvre aussi depuis le Club, où il n'y a aucune liste de
    /// courses derrière à rafraîchir.
    var onParticipationChanged: () -> Void = {}

    @Environment(AppState.self) private var appState
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss

    @State private var page: RacePage?
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var enCours = false

    // Ma participation
    @State private var chrono = ""
    @State private var cherchePartenaire = false
    @State private var partageEntrainement = false
    @State private var formulairePresente = false
    /// Le retrait de la page demande confirmation — voir le bouton « RETIRER ».
    @State private var retraitAConfirmer = false
    /// Le calage proposé après « Je prépare cette course », en attente de la réponse.
    @State private var calageAConfirmer: ProgrammePourUneCourse.Calage?
    @State private var calageEstPropose = false

    // Le mur
    @State private var genreDuMessage = "message"
    @State private var brouillon = ""
    @State private var reponseA: RacePost?
    @State private var filtrePartenaires = false

    // Modération
    @State private var signalementPresente = false
    @State private var motifDuSignalement = ""
    @State private var cibleDuSignalement: CibleSignalee?

    private struct CibleSignalee: Identifiable {
        var id: String { targetId }
        var targetType: String
        var targetId: String
    }

    private var clubService: ClubService { ClubService(auth: appState.auth) }
    private var courante: RaceEvent { page?.race ?? race }
    private var jeLaPrepare: Bool { page?.me != nil }

    var body: some View {
        HZPage(basDePage: HZResume.basDePage) {
            hautDePage
        } contenu: {
            feuille
        }
        .task { if page == nil { await charger() } }
        .alert("Signaler", isPresented: $signalementPresente) {
            TextField("Pourquoi ?", text: $motifDuSignalement)
            Button("Envoyer") { envoyerLeSignalement() }
            Button("Annuler", role: .cancel) { cibleDuSignalement = nil }
        } message: {
            Text("Ce signalement sera examiné. Merci de préciser ce qui pose problème.")
        }
    }

    // MARK: - Le haut, sur le noir : la course

    /// Le retour — un écran plein n'a rien d'une feuille qu'on referme d'un glissement, et sans ce
    /// bouton on serait enfermé dedans — puis la date, le nom et ce qu'on en sait, comme l'affiche
    /// d'une course dans Explorer.
    private var hautDePage: some View {
        VStack(alignment: .leading, spacing: 0) {
            HZCommandesDuHaut(retour: { dismiss() }) { EmptyView() }
            Text(courante.dateLisible)
                .hzTexte(.c15, .semi)
                .foregroundStyle(HZCouleur.secondaireSurSombre)
                .minimumScaleFactor(HZCourse.reductionDeLaDate)
                .padding(.horizontal, HZEspace.margeDeTitre)
                .padding(.top, HZHub.sousLesCommandes)
            Text(courante.name)
                .hzAffichage(.titreDEcran)
                .foregroundStyle(HZCouleur.blanc)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, HZEspace.margeDeTitre)
            if !courante.sousTitre.isEmpty {
                Text(courante.sousTitre)
                    .hzParagraphe(.c15, .medium, interligne: HZBandeauDuCoach.interligne)
                    .foregroundStyle(HZCouleur.secondaireSurSombre)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, HZEspace.margeDeTitre)
                    .padding(.top, HZPlan.sousLeTitre)
            }
            pastillesDuHaut
            siteOfficiel
        }
    }

    /// Dans combien de jours, et combien de coureurs. Un nombre de jours négatif n'arrive presque
    /// jamais (voir `joursRestants`), mais la page reste honnête s'il arrive : elle ne l'affiche pas.
    @ViewBuilder private var pastillesDuHaut: some View {
        let jours = courante.joursRestants.flatMap { $0 >= 0 ? $0 : nil }
        let coureurs = page?.runners.count ?? 0
        if jours != nil || coureurs > 0 {
            HStack(spacing: HZEspace.entrePilules) {
                if let jours {
                    HZPilule(texte: jours == 0
                                 ? String(localized: "C'est aujourd'hui")
                                 : Pluriel.choisir(jours,
                                                   String(localized: "Dans \(jours) jour"),
                                                   String(localized: "Dans \(jours) jours")),
                             style: .etiquetteGrasse, fond: HZCouleur.accent, couleur: HZCouleur.encreSurAccent)
                }
                if coureurs > 0 {
                    HZPilule(texte: Pluriel.choisir(coureurs,
                                                    String(localized: "\(coureurs) coureur"),
                                                    String(localized: "\(coureurs) coureurs")),
                             fond: HZCouleur.surfaceSombre)
                }
            }
            .padding(.horizontal, HZEspace.margeDeTitre)
            .padding(.top, HZHub.sousLaCarte)
        }
    }

    /// Le seul lien sortant de la page, et il est écrit par un coureur. Le serveur n'accepte que
    /// http(s) — ni `javascript:`, ni `data:`, voir lib/courses.js.
    @ViewBuilder private var siteOfficiel: some View {
        if let site = courante.website, let url = URL(string: site) {
            HZBoutonPilule(libelle: String(localized: "Site officiel"), hauteur: .petite,
                           fond: HZCouleur.surfaceSombre) { openURL(url) }
                .padding(.horizontal, HZEspace.margeDeTitre)
                .padding(.top, HZHub.sousLaCarte)
        }
    }

    // MARK: - La feuille

    private var feuille: some View {
        VStack(alignment: .leading, spacing: HZEspace.entreSections) {
            if isLoading {
                ProgressView().frame(maxWidth: .infinity).padding(.vertical, HZFil.enAttente)
            } else if let loadError {
                HZPhrase(texte: String(localized: "Impossible de charger cette page : \(loadError)."))
            } else {
                maParticipation
                quiLaPrepare
                leMur
                boutonSignalerLaCourse
            }
        }
    }

    // MARK: - 2. Ma participation

    private var maParticipation: some View {
        VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
            if jeLaPrepare {
                participationDeclaree
            } else {
                participationAbsente
            }
        }
        .sheet(isPresented: $formulairePresente) {
            formulaireDeParticipation.hzFeuille(detents: [.large], gereSonBas: true)
        }
        // `role: .destructive` sur l'action et `.cancel` sur le refus : iOS colore et place les
        // deux boutons lui-même, et VoiceOver annonce lequel retire. Le texte dit ce qu'on perd
        // ET que c'est réversible — sans la seconde phrase, une confirmation fait hésiter sur un
        // geste qui ne coûte rien à défaire.
        .alert("Te retirer de cette course ?", isPresented: $retraitAConfirmer) {
            Button("Me retirer", role: .destructive) { Task { await nePlusPreparer() } }
            Button("Annuler", role: .cancel) { }
        } message: {
            Text("Tu disparaîtras de la page et des groupes d'allure. Tu pourras te redéclarer quand tu veux.")
        }
        // Le programme actuel est REMPLACÉ : la confirmation le dit, et le refus ne coûte rien.
        .alert("Caler ton programme sur cette course ?", isPresented: $calageEstPropose) {
            Button("Caler mon programme") {
                if let calage = calageAConfirmer { appliquerLeCalage(calage) }
            }
            Button("Pas maintenant", role: .cancel) { calageAConfirmer = nil }
        } message: {
            Text("Ton programme actuel sera remplacé par un programme qui se termine à la date de la course.")
        }
    }

    @ViewBuilder private var participationDeclaree: some View {
        HZTitreDeSection(titre: String(localized: "Je prépare cette course"))

        VStack(spacing: 0) {
            if let objectif = page?.me?.targetChrono, !objectif.isEmpty {
                ligneDInfo(titre: String(localized: "Objectif"), valeur: objectif,
                           filet: page?.me?.targetPaceSecPerKm != nil)
            }
            if let allure = page?.me?.targetPaceSecPerKm {
                ligneDInfo(titre: String(localized: "Allure visée"),
                           valeur: String(localized: "\(TimeFormat.allure(secondesParKm: Double(allure))) /km"),
                           filet: false)
            }
        }

        HStack(spacing: HZEspace.entreCommandes) {
            HZBoutonPilule(libelle: String(localized: "Modifier"), hauteur: .moyenne,
                           fond: HZCouleur.surfaceClaire, couleur: HZCouleur.encre,
                           etendu: true) { ouvrirLeFormulaire() }

            // « RETIRER » DEMANDE, IL N'AGIT PLUS TOUT DE SUITE.
            //
            // Les deux boutons ont le même poids côte à côte : l'un ouvre un formulaire, l'autre te
            // fait disparaître de la page et des groupes d'allure. Deux conséquences très
            // différentes, et le retrait partait au premier appui.
            HZBoutonPilule(libelle: String(localized: "Retirer"), hauteur: .moyenne,
                           fond: HZCouleur.surfaceClaire, couleur: HZCouleur.encre,
                           etendu: true) { retraitAConfirmer = true }
                .opacity(enCours ? HZHub.opaciteEteinte : HZHub.opaciteNormale)
                .disabled(enCours)
        }
    }

    @ViewBuilder private var participationAbsente: some View {
        HZTitreDeSection(titre: String(localized: "Tu la prépares ?"))
        HZPhrase(texte: String(localized: "Dis-le et tu apparaîtras sur cette page. Tu pourras y trouver quelqu'un à ton allure, et suivre où en sont les autres."))
        HZBoutonPilule(libelle: String(localized: "Je prépare cette course"), etendu: true) {
            ouvrirLeFormulaire()
        }
        .opacity(enCours ? HZHub.opaciteEteinte : HZHub.opaciteNormale)
        .disabled(enCours)
    }

    private func ligneDInfo(titre: String, valeur: String, filet: Bool) -> some View {
        HZLigneDeListe(titre: titre, filet: filet) {
            EmptyView()
        } queue: {
            Text(verbatim: valeur)
                .hzTexte(.c16, .gras, tabulaire: true)
                .foregroundStyle(HZCouleur.encre)
                .minimumScaleFactor(HZCourse.reductionDUneValeur)
        }
    }

    private func ouvrirLeFormulaire() {
        chrono = page?.me?.targetChrono ?? ""
        cherchePartenaire = page?.me?.lookingForPartner ?? false
        partageEntrainement = page?.me?.sharesTraining ?? false
        formulairePresente = true
    }

    /// La feuille « Ce que tu vises » : le chrono, ce que j'accepte de montrer, et l'enregistrement
    /// épinglé en bas (`gereSonBas: true` à la présentation).
    private var formulaireDeParticipation: some View {
        HZFeuilleModale(titre: String(localized: "Ce que tu vises")) {
            ScrollView {
                VStack(alignment: .leading, spacing: HZEspace.entreSections) {
                    champDuChrono
                    interrupteursDeLaParticipation
                }
                .padding(.horizontal, HZEspace.marge)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HZActionEpinglee(libelle: enCours ? String(localized: "Enregistrement…") : String(localized: "Enregistrer"),
                             eteinte: enCours) { Task { await enregistrerMaParticipation() } }
        }
    }

    private var champDuChrono: some View {
        VStack(alignment: .leading, spacing: HZEspace.entrePilules) {
            HZChampDeTexte(titre: String(localized: "Chrono visé · facultatif"),
                           invite: String(localized: "3:30, sub-4, finir…"), texte: $chrono)
            // Le chrono est libre, mais s'il se lit comme un temps l'app en tire une allure — et
            // c'est elle qui range la page par proximité. « Finir » reste un objectif valable ; il
            // ne donne simplement personne à comparer.
            if let allure = allureVisee {
                Text("Soit \(TimeFormat.allure(secondesParKm: allure)) /km")
                    .hzTexte(.c13, .medium)
                    .foregroundStyle(HZCouleur.secondaireSurClair)
            }
        }
    }

    /// DEUX INTERRUPTEURS DANS UN GROUPE, PAS DEUX CARTES : ils appartiennent à la même question —
    /// « qu'est-ce que j'accepte de montrer ? » — séparés par un filet.
    private var interrupteursDeLaParticipation: some View {
        VStack(spacing: 0) {
            interrupteurDeCourse(
                titre: String(localized: "Je cherche quelqu'un pour courir avec moi"),
                detail: String(localized: "Tu apparais en haut de la liste, pour celles et ceux qui visent la même allure."),
                actif: $cherchePartenaire, filet: true)
            interrupteurDeCourse(
                titre: String(localized: "Montrer où j'en suis de ma préparation"),
                detail: String(localized: "Les autres coureurs de cette course verront ton volume des 4 dernières semaines. Rien d'autre : ni tes parcours, ni tes allures réelles, ni tes dates de sortie."),
                actif: $partageEntrainement, filet: false)
        }
        .padding(.horizontal, HZEspace.groupe)
        .background(HZCouleur.surfaceClaire,
                    in: RoundedRectangle(cornerRadius: HZRayon.groupe, style: .circular))
    }

    /// Le titre et le détail sont des paragraphes : « Je cherche quelqu'un pour courir avec moi »
    /// ne tient pas sur une ligne à côté d'un interrupteur.
    private func interrupteurDeCourse(titre: String, detail: String, actif: Binding<Bool>,
                                      filet: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: HZEspace.tuile) {
                VStack(alignment: .leading, spacing: HZReglages.entreTitreEtPrecision) {
                    Text(titre)
                        .hzParagraphe(.c16, .semi, interligne: HZBandeauDuCoach.interligne)
                        .foregroundStyle(HZCouleur.encre)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(detail)
                        .hzParagraphe(.c13, .medium, interligne: HZReglages.interligne)
                        .foregroundStyle(HZCouleur.secondaireSurClair)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Toggle("", isOn: actif)
                    .labelsHidden()
                    .toggleStyle(HZStyleDInterrupteur())
                    .accessibilityLabel(titre)
            }
            .padding(.vertical, HZReglages.margeDUneLigneALaPrecision)
            if filet {
                Rectangle()
                    .fill(HZCouleur.filetGroupe)
                    .frame(height: HZMesuresDeLigne.filet)
            }
        }
    }

    /// L'allure que l'app tire du chrono tapé, quand la course a une distance et que le chrono se
    /// lit comme un temps. Sinon nil — et la page ne perd rien, elle range par nom.
    private var allureVisee: Double? {
        guard let km = courante.distanceKm, km > 0 else { return nil }
        let propre = chrono.trimmingCharacters(in: .whitespaces)
        guard !propre.isEmpty, let secondes = PaceModel.parseChronoSeconds(propre, distance: nil) else { return nil }
        let allure = secondes / km
        // Bornes du serveur : 2 min/km est plus rapide qu'un record du monde, 20 min/km est de la
        // marche. Au-delà, c'est une lecture ratée, pas un objectif.
        guard allure >= HZCourse.allureMinimaleVisee, allure <= HZCourse.allureMaximaleVisee else { return nil }
        return allure
    }

    // MARK: - 3. Qui la prépare

    private var coureursAffiches: [RaceRunner] {
        let tous = page?.runners ?? []
        return filtrePartenaires ? tous.filter(\.lookingForPartner) : tous
    }

    private var quiLaPrepare: some View {
        VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
            HZTitreDeSection(titre: String(localized: "Qui la prépare"))

            if (page?.runners ?? []).contains(where: \.lookingForPartner) {
                filtreDesPartenaires
            }

            if coureursAffiches.isEmpty {
                // Tournure sans accord : « sois le premier » obligerait à passer par `Accord`, et
                // « la première / le premier » pour une phrase de vide n'en vaut pas les deux clés.
                HZPhrase(texte: String(localized: "Personne encore. Dis-le et les suivants te trouveront."))
            } else {
                // DES LIGNES, PAS DES BOÎTES : un filet entre deux lignes sépare aussi bien et ne
                // fabrique rien.
                LazyVStack(spacing: 0) {
                    ForEach(Array(coureursAffiches.enumerated()), id: \.element.id) { rang, coureur in
                        ligneDeCoureur(coureur, filet: rang < coureursAffiches.count - 1)
                    }
                }
            }
        }
    }

    private var filtreDesPartenaires: some View {
        HStack(spacing: HZEspace.tuile) {
            Text("Seulement ceux qui cherchent quelqu'un")
                .hzParagraphe(.c14, .semi, interligne: HZBandeauDuCoach.interligne)
                .foregroundStyle(HZCouleur.encre)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            Toggle("", isOn: $filtrePartenaires)
                .labelsHidden()
                .toggleStyle(HZStyleDInterrupteur())
                .accessibilityLabel("Seulement ceux qui cherchent quelqu'un")
        }
    }

    /// Les trois points d'un menu : la zone tactile fait 44, le dessin reste petit.
    private var iconeDOptions: some View {
        HZIcone(dessin: .options, cote: HZFil.coteDuBravo, couleur: HZCouleur.secondaireSurClair)
            .frame(width: HZBoutonRond.zoneTactile, height: HZBoutonRond.zoneTactile)
            .contentShape(Rectangle())
    }

    private func ligneDeCoureur(_ coureur: RaceRunner, filet: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: HZMesuresDeLigne.ecart) {
                Button(action: { appState.ouvrirLeProfil(coureur.id) }) {
                    HZPhotoDePersonne(urlString: coureur.avatarUrl, base64DataURI: coureur.avatarBase64,
                                      initiales: HZInitiales.de(coureur.name, coureur.lastName))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "Voir le profil de \(coureur.nomComplet)"))

                detailsDuCoureur(coureur)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Menu {
                    Button("Signaler ce coureur") {
                        demanderUnSignalement(type: "user", id: coureur.id)
                    }
                    Button("Bloquer", role: .destructive) {
                        Task { await bloquer(coureur) }
                    }
                } label: {
                    iconeDOptions
                }
                .accessibilityLabel("Plus d'options")
            }
            .padding(.vertical, HZMesuresDeLigne.margeDeSortie)
            if filet {
                Rectangle()
                    .fill(HZCouleur.filetFeuille)
                    .frame(height: HZMesuresDeLigne.filet)
            }
        }
    }

    private func detailsDuCoureur(_ coureur: RaceRunner) -> some View {
        VStack(alignment: .leading, spacing: HZReglages.entreTitreEtPrecision) {
            HStack(spacing: HZEspace.entrePilules) {
                // Un nom est une porte. « Margaux Hubert » ne doit pas écraser la pastille à sa
                // droite : le nom se tronque avec ses points de suspension, la capsule jamais.
                Button(action: { appState.ouvrirLeProfil(coureur.id) }) {
                    Text(coureur.nomComplet)
                        .hzTexte(.c16, .semi)
                        .foregroundStyle(HZCouleur.encre)
                        .truncationMode(.tail)
                }
                .buttonStyle(.plain)
                .layoutPriority(0)
                if coureur.lookingForPartner {
                    HZPilule(texte: String(localized: "cherche quelqu'un"),
                             fond: HZCouleur.surfaceClaire, couleur: HZCouleur.encre)
                        .fixedSize(horizontal: true, vertical: false)
                        .layoutPriority(HZCourse.prioriteDeLaPastille)
                }
            }

            if let objectif = coureur.targetChrono, !objectif.isEmpty {
                Text(ligneDObjectif(coureur, objectif: objectif))
                    .hzParagraphe(.c14, .medium, interligne: HZBandeauDuCoach.interligne)
                    .foregroundStyle(HZCouleur.encre)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // La ligne qui demande le plus de soin de la page : « n'a pas partagé » et « 0 km »
            // ne sont pas la même phrase.
            if let km = coureur.km4Weeks {
                Text(String(localized: "\(Distances.km(km)) sur 4 semaines · \(sortiesLisibles(coureur.runs4Weeks ?? 0))"))
                    .hzParagraphe(.c13, .medium, interligne: HZBandeauDuCoach.interligne)
                    .foregroundStyle(HZCouleur.secondaireSurClair)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("préparation non partagée")
                    .hzParagraphe(.c13, .medium, interligne: HZBandeauDuCoach.interligne)
                    .foregroundStyle(HZCouleur.secondaireSurClair)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    /// « 14 sorties ». À part, et non imbriqué dans l'interpolation de la ligne au-dessus : une
    /// clé de catalogue qui contient elle-même un appel ne se relit pas, et ne se traduit pas.
    private func sortiesLisibles(_ sorties: Int) -> String {
        Pluriel.choisir(sorties,
                        String(localized: "\(sorties) sortie"),
                        String(localized: "\(sorties) sorties"))
    }

    /// « 3:30 · 4:59 /km » et, quand c'est le cas, « à ton allure ». Le rapprochement d'allure est
    /// le seul service que cette liste rende vraiment : courir avec quelqu'un de deux minutes plus
    /// rapide au kilomètre n'est pas courir ensemble.
    private func ligneDObjectif(_ coureur: RaceRunner, objectif: String) -> String {
        var morceaux = [objectif]
        if let allure = coureur.targetPaceSecPerKm {
            morceaux.append(String(localized: "\(TimeFormat.allure(secondesParKm: Double(allure))) /km"))
            if let mienne = page?.me?.targetPaceSecPerKm, abs(allure - mienne) <= HZCourse.ecartDAllureProche {
                morceaux.append(String(localized: "à ton allure"))
            }
        }
        return morceaux.joined(separator: " · ")
    }

    // MARK: - 4. Le mur

    private static let genres = ["message", "partner", "bib_offer", "bib_wanted"]

    private static func libelleDuGenre(_ genre: String) -> String {
        switch genre {
        case "partner": return String(localized: "Partenaire")
        case "bib_offer": return String(localized: "Je cède")
        case "bib_wanted": return String(localized: "Je cherche")
        default: return String(localized: "Message")
        }
    }

    /// Le plus récent en haut. `sorted` et non `reversed` : le serveur rend le fil dans l'ordre
    /// chronologique pour que les réponses suivent leur message, et trier explicitement dit ce
    /// qu'on veut au lieu de dépendre de cet ordre.
    private var messagesDeTete: [RacePost] {
        (page?.posts ?? []).filter { $0.parentId == nil }.sorted { $0.createdAt > $1.createdAt }
    }

    private func reponses(a message: RacePost) -> [RacePost] {
        (page?.posts ?? []).filter { $0.parentId == message.id }
    }

    private var leMur: some View {
        VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
            HZTitreDeSection(titre: String(localized: "Le mur"))

            redaction

            if messagesDeTete.isEmpty {
                HZPhrase(texte: String(localized: "Rien d'écrit encore. Une question sur le parcours, le ravitaillement, l'hébergement : c'est ici."))
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(Array(messagesDeTete.enumerated()), id: \.element.id) { rang, message in
                        bloc(message, rang: rang)
                    }
                }
            }
        }
    }

    private var redaction: some View {
        VStack(alignment: .leading, spacing: HZEspace.entreCommandes) {
            selecteurDeGenre

            if let reponseA {
                enteteDeLaReponse(reponseA)
            }

            // L'avertissement est écrit AU MOMENT D'ÉCRIRE, et pas seulement sous les annonces
            // publiées : c'est là qu'il peut encore changer quelque chose.
            if genreDuMessage == "bib_offer" || genreDuMessage == "bib_wanted", reponseA == nil {
                avertissementDossard
            }

            champDeRedaction

            HZBoutonPilule(libelle: String(localized: "Publier"), hauteur: .moyenne, etendu: true) {
                Task { await publier() }
            }
            .opacity(publicationImpossible ? HZHub.opaciteEteinte : HZHub.opaciteNormale)
            .disabled(publicationImpossible)
        }
    }

    private var publicationImpossible: Bool {
        brouillon.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || enCours
    }

    /// Message, partenaire, dossard à céder, dossard cherché : quatre pilules, qui défilent plutôt
    /// que de se couper à 390 points.
    private var selecteurDeGenre: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: HZEspace.entrePilules) {
                ForEach(Self.genres, id: \.self) { genre in
                    HZFiltre(libelle: Self.libelleDuGenre(genre), actif: genreDuMessage == genre,
                             fond: .clair) { genreDuMessage = genre }
                }
            }
        }
        .opacity(reponseA == nil ? HZHub.opaciteNormale : HZHub.opaciteEteinte)
        .disabled(reponseA != nil)
    }

    private func enteteDeLaReponse(_ reponse: RacePost) -> some View {
        HStack(spacing: HZEspace.entrePilules) {
            Text("Réponse à \(reponse.author.nomComplet)")
                .hzTexte(.c14, .semi)
                .foregroundStyle(HZCouleur.encre)
                .frame(maxWidth: .infinity, alignment: .leading)
            HZBoutonRond(dessin: .fermer, nom: String(localized: "Annuler la réponse"), diametre: .pas,
                         fond: HZCouleur.surfaceClaire, couleur: HZCouleur.encre,
                         cote: HZHub.coteDeLaCroix, trait: HZHub.traitDeLaCroix) { reponseA = nil }
        }
    }

    private var champDeRedaction: some View {
        TextField(reponseA == nil ? placeholderDuGenre : String(localized: "Ta réponse…"),
                  text: $brouillon, axis: .vertical)
            .lineLimit(HZCourse.lignesDeLaRedaction)
            .font(HZPolice.texte(.c16, .semi))
            .foregroundStyle(HZCouleur.encre)
            .tint(HZCouleur.encre)
            .padding(.horizontal, HZEspace.groupe)
            .padding(.vertical, HZEspace.tuile)
            .frame(minHeight: HZHub.hauteurDuChamp, alignment: .leading)
            .background(HZCouleur.surfaceClaire,
                        in: RoundedRectangle(cornerRadius: HZRayon.bandeau, style: .circular))
    }

    private var placeholderDuGenre: String {
        switch genreDuMessage {
        case "partner": return String(localized: "Ton allure, ton objectif, et à partir de quand tu veux courir accompagné")
        case "bib_offer": return String(localized: "Ta distance, et pourquoi tu cèdes ton dossard")
        case "bib_wanted": return String(localized: "La distance que tu cherches")
        default: return String(localized: "Une question, un conseil, un repère sur le parcours…")
        }
    }

    /// UNE PLAQUE GRISE, PAS UNE BOÎTE COLORÉE. Elle avertit, elle ne demande rien : le texte dit
    /// « attention » sans repeindre un dixième de l'écran. (Le système n'a pas de teinte d'alerte :
    /// l'ancien filet ambre est devenu une plaque neutre.)
    private var avertissementDossard: some View {
        HZPlaque {
            Text("Haizo ne vend rien et ne garantit rien : vous vous arrangez entre vous. La plupart des organisateurs interdisent le transfert de dossard. Vérifie leur règlement. Courir sous le nom d'un autre, c'est la disqualification, et des secours qui liraient le mauvais dossier médical.")
                .hzParagraphe(.c13, .medium, interligne: HZBandeauDuCoach.interligne)
                .foregroundStyle(HZCouleur.encre)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// UN FILET ENTRE DEUX MESSAGES, ET RIEN AUTOUR : un mur de conversation se descend, une pile de
    /// cartes se parcourt.
    private func bloc(_ message: RacePost, rang: Int) -> some View {
        VStack(alignment: .leading, spacing: HZEspace.entrePilules) {
            if rang > 0 {
                Rectangle()
                    .fill(HZCouleur.filetFeuille)
                    .frame(height: HZMesuresDeLigne.filet)
                    .padding(.bottom, HZEspace.entrePilules)
            }
            messageEnTete(message)

            if message.kind == "bib_offer" || message.kind == "bib_wanted" {
                avertissementDossard
            }

            ForEach(reponses(a: message)) { reponse in
                HStack(alignment: .top, spacing: HZEspace.entrePilules) {
                    Rectangle()
                        .fill(HZCouleur.filetGroupe)
                        .frame(width: HZMesuresDeLigne.filet)
                    messageEnTete(reponse)
                }
                .padding(.leading, HZEspace.entreCommandes)
            }

            gestesDuMessage(message)
        }
        .padding(.bottom, HZEspace.entreCommandes)
    }

    private func gestesDuMessage(_ message: RacePost) -> some View {
        HStack(spacing: HZEspace.entrePilules) {
            // Applaudir : la réponse la moins coûteuse qui dise « lu, et oui ». Sans elle, un
            // message sans réponse ne distingue pas « personne ne m'a lu » de « personne n'est
            // à mon rythme ».
            geste(dessin: .coeur, compte: message.kudos, actif: message.kudoedByMe) {
                Task { await applaudir(message) }
            }
            .accessibilityLabel(message.kudoedByMe ? String(localized: "Retirer ton applaudissement")
                                                   : String(localized: "Applaudir ce message"))
            .accessibilityValue("\(message.kudos)")

            // LA MÊME BULLE QUE DANS LE FIL, AVEC LE MÊME COMPTE : l'icône dit « répondre », le
            // nombre dit en plus s'il y a déjà une conversation.
            geste(dessin: .bulle, compte: reponses(a: message).count, actif: false) {
                reponseA = message
                brouillon = ""
            }
            .accessibilityLabel(String(localized: "Répondre à \(message.author.name)"))

            Spacer(minLength: 0)
        }
    }

    /// Un geste : une pilule claire, une icône, et le compte quand il y en a un.
    private func geste(dessin: HZDessin, compte: Int, actif: Bool,
                       action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: HZBoutonPilule.ecart) {
                HZIcone(dessin: dessin, cote: HZFil.coteDuBravo,
                        couleur: actif ? HZCouleur.accent : HZCouleur.encre)
                if compte > 0 {
                    Text("\(compte)")
                        .hzTexte(.c14, .gras, tabulaire: true)
                        .foregroundStyle(HZCouleur.encre)
                }
            }
            .padding(.horizontal, HZHauteurDeBouton.moyenne.marge)
            .frame(height: HZHauteurDeBouton.moyenne.rawValue)
            .background(HZCouleur.surfaceClaire, in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func messageEnTete(_ message: RacePost) -> some View {
        VStack(alignment: .leading, spacing: HZEspace.entrePilules) {
            HStack(spacing: HZEspace.entrePilules) {
                // Tout le bloc d'identité ouvre la page de la personne — la photo, le nom et
                // l'heure ensemble, comme partout ailleurs.
                Button(action: { appState.ouvrirLeProfil(message.author.id) }) {
                    HStack(spacing: HZEspace.entrePilules) {
                        HZPhotoDePersonne(urlString: message.author.avatarUrl,
                                          base64DataURI: message.author.avatarBase64,
                                          initiales: HZInitiales.de(message.author.name, message.author.lastName),
                                          cote: HZHub.avatarCompact)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(message.author.nomComplet)
                                .hzTexte(.c15, .gras)
                                .foregroundStyle(HZCouleur.encre)
                            Text(message.createdAt.relativeDescription)
                                .hzTexte(.c13, .medium)
                                .foregroundStyle(HZCouleur.secondaireSurClair)
                        }
                        .lineLimit(1)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "Voir le profil de \(message.author.name)"))
                Spacer(minLength: 0)
                if message.kind != "message" {
                    HZPilule(texte: Self.libelleDuGenre(message.kind),
                             fond: HZCouleur.surfaceClaire, couleur: HZCouleur.encre)
                }
                Menu {
                    Button("Signaler ce message") {
                        demanderUnSignalement(type: "race_post", id: message.id)
                    }
                    // « Retiré » n'est proposé qu'à l'auteur : le serveur le revérifie de toute
                    // façon, mais montrer un bouton qui répondra « non » est une promesse fausse.
                    if !message.closed, message.isMine {
                        Button("Marquer comme réglé") { Task { await clore(message) } }
                    }
                } label: {
                    iconeDOptions
                }
                .accessibilityLabel("Plus d'options")
            }

            Text(message.text)
                .strikethrough(message.closed, color: HZCouleur.secondaireSurClair)
                .hzParagraphe(.c14, .medium, interligne: HZBandeauDuCoach.interligne)
                .foregroundStyle(message.closed ? HZCouleur.secondaireSurClair : HZCouleur.encre)
                .fixedSize(horizontal: false, vertical: true)

            if message.closed {
                HZPilule(texte: String(localized: "réglé"), style: .etiquetteGrasse, fond: HZCouleur.encre)
            }
        }
    }

    // MARK: - Modération

    private var boutonSignalerLaCourse: some View {
        Button(action: { demanderUnSignalement(type: "race", id: courante.id) }) {
            Text("Signaler cette course")
                .hzTexte(.c14, .semi)
                .foregroundStyle(HZCouleur.secondaireSurClair)
                .frame(maxWidth: .infinity, minHeight: HZBoutonRond.zoneTactile)
        }
        .buttonStyle(.plain)
    }

    private func demanderUnSignalement(type: String, id: String) {
        cibleDuSignalement = CibleSignalee(targetType: type, targetId: id)
        motifDuSignalement = ""
        signalementPresente = true
    }

    private func envoyerLeSignalement() {
        guard let cible = cibleDuSignalement else { return }
        let motif = motifDuSignalement.trimmingCharacters(in: .whitespacesAndNewlines)
        cibleDuSignalement = nil
        motifDuSignalement = ""
        guard !motif.isEmpty else { return }
        Task {
            try? await clubService.report(targetType: cible.targetType, targetId: cible.targetId, reason: motif)
            appState.toast(String(localized: "Signalement envoyé"))
        }
    }

    private func bloquer(_ coureur: RaceRunner) async {
        do {
            try await clubService.blockUser(userId: coureur.id)
            appState.toast(String(localized: "\(coureur.name) ne verra plus rien de toi."))
            await charger()
        } catch {
            appState.toast(String(localized: "Impossible de bloquer cette personne."))
        }
    }

    // MARK: - Actions

    private func charger() async {
        loadError = nil
        // En démonstration, le cache est tout — quatrième écran dans ce cas, même raison que les
        // trois autres : pas de serveur en face d'un simulateur.
        if Demonstration.enCours {
            page = appState.cachedRacePage
            isLoading = false
            return
        }
        do {
            page = try await clubService.racePage(raceId: race.id)
        } catch {
            loadError = PanneReseau.motif(pour: error)
        }
        isLoading = false
    }

    private func enregistrerMaParticipation() async {
        enCours = true
        let propre = chrono.trimmingCharacters(in: .whitespaces)
        do {
            try await clubService.followRace(
                raceId: race.id,
                targetChrono: propre.isEmpty ? nil : propre,
                targetPaceSecPerKm: allureVisee.map { Int($0.rounded()) },
                sharesTraining: partageEntrainement,
                lookingForPartner: cherchePartenaire
            )
            Haptics.impact(.light)
            formulairePresente = false
            await charger()
            onParticipationChanged()
            caler(chrono: propre)
        } catch {
            appState.toast(String(localized: "Impossible d'enregistrer : \(PanneReseau.motif(pour: error))."))
        }
        enCours = false
    }

    /// « Je prépare cette course » donne au programme sa date. Juste après l'inscription, quand la
    /// personne a dit qu'elle prépare une course, le programme d'attente se recale tout seul ; ailleurs,
    /// remplacer un programme qu'elle suit déjà se demande.
    private func caler(chrono: String) {
        let profil = appState.profile
        guard let calage = ProgrammePourUneCourse.calage(pour: courante, chrono: chrono,
                                                         joursDeCourse: profil.runningDays),
              !ProgrammePourUneCourse.estDejaCale(profil, sur: calage)
        else { return }
        if appState.calerLeProgrammeSurLaCourseChoisie {
            appliquerLeCalage(calage)
        } else {
            calageAConfirmer = calage
            calageEstPropose = true
        }
    }

    private func appliquerLeCalage(_ calage: ProgrammePourUneCourse.Calage) {
        let profil = appState.profile
        ProgrammePourUneCourse.appliquer(calage, a: profil)
        NotificationService.shared.rescheduleDailyReminder(for: profil)
        appState.calerLeProgrammeSurLaCourseChoisie = false
        calageAConfirmer = nil
        Haptics.success()
        appState.toast(String(localized: "Ton programme est calé sur \(calage.nomDeLaCourse)"))
    }

    private func nePlusPreparer() async {
        enCours = true
        do {
            try await clubService.unfollowRace(raceId: race.id)
            await charger()
            onParticipationChanged()
        } catch {
            appState.toast(String(localized: "Impossible de te retirer. Réessaie."))
        }
        enCours = false
    }

    private func publier() async {
        let texte = brouillon.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !texte.isEmpty else { return }
        enCours = true
        do {
            try await clubService.postToRace(raceId: race.id,
                                             kind: reponseA == nil ? genreDuMessage : "message",
                                             text: texte,
                                             parentId: reponseA?.id)
            brouillon = ""
            reponseA = nil
            genreDuMessage = "message"
            await charger()
        } catch ClubServiceError.badResponse(let code, _) where code == HZHub.refuse {
            appState.toast(String(localized: "Ce message ne passe pas."))
        } catch ClubServiceError.badResponse(let code, _) where code == HZCourse.tropDeRequetes {
            appState.toast(String(localized: "Trop de messages aujourd'hui. Réessaie demain."))
        } catch {
            appState.toast(String(localized: "Impossible de publier : \(PanneReseau.motif(pour: error))."))
        }
        enCours = false
    }

    /// Le compte vient du SERVEUR, pas d'un « +1 » posé ici : deux personnes qui applaudissent en
    /// même temps feraient sinon diverger les deux écrans jusqu'au rechargement.
    private func applaudir(_ message: RacePost) async {
        guard let index = page?.posts.firstIndex(where: { $0.id == message.id }) else { return }
        do {
            let reponse = try await clubService.toggleRacePostKudos(postId: message.id)
            page?.posts[index].kudoedByMe = reponse.kudoed
            page?.posts[index].kudos = reponse.kudos
            Haptics.impact(.light)
        } catch {
            appState.toast(String(localized: "Impossible d'applaudir. Réessaie."))
        }
    }

    private func clore(_ message: RacePost) async {
        do {
            try await clubService.closeRacePost(postId: message.id)
            await charger()
        } catch {
            appState.toast(String(localized: "Impossible de marquer ce message. Réessaie."))
        }
    }
}
