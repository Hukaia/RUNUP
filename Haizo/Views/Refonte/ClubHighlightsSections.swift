import SwiftUI

/// CE QU'UN CLASSEMENT NE DIT PAS : vers quoi le club court, ce qu'il a tenu, ce qu'il a battu.
///
/// Un tableau hebdomadaire dit qui court le plus. Les trois sections ci-dessous ne demandent aucune
/// donnée de plus : elles étaient dans les courses suivies et dans les sorties publiées, jamais
/// regardées ensemble. Chacune se tait quand elle n'a rien à dire.
struct ClubHighlightsSections: View {
    let highlights: ClubHighlights?

    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: HZEspace.entreSections) {
            coursesDuClub
            seancesTenues
            recordsDuClub
        }
    }

    // MARK: Ce que le club prépare

    @ViewBuilder
    private var coursesDuClub: some View {
        if let courses = highlights?.races, !courses.isEmpty {
            VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
                HZTitreDeSection(titre: String(localized: "Ce que le club prépare"))
                LazyVStack(spacing: 0) {
                    ForEach(Array(courses.enumerated()), id: \.element.id) { rang, course in
                        ligneDeCourseDuClub(course, dernier: rang == courses.count - 1)
                    }
                }
            }
        }
    }

    private func ligneDeCourseDuClub(_ course: ClubRace, dernier: Bool) -> some View {
        Button(action: { appState.ouvrirLaCourse(course.race) }) {
            HZLigneDeListe(titre: course.race.name, sousTitre: sousTitreDeCourse(course), filet: !dernier) {
                HZVignette {
                    HZIcone(dessin: .drapeau, cote: HZHub.coteDeLIcone, couleur: HZCouleur.blanc)
                }
            } queue: {
                HStack(spacing: HZEspace.entrePilules) {
                    HZPileDAvatars(
                        personnes: course.runners.map {
                            HZPileDAvatars.Personne(id: $0.id, initiales: HZInitiales.de($0.name),
                                                    urlString: $0.avatarUrl, base64: $0.avatarBase64)
                        },
                        total: course.runners.count, cote: HZHub.avatarEmpile, fondDuLise: HZCouleur.blanc)
                    if course.members > course.runners.count {
                        Text(verbatim: "+\(course.members - course.runners.count)")
                            .hzTexte(.c13, .gras)
                            .foregroundStyle(HZCouleur.secondaireSurClair)
                    }
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Pluriel.choisir(course.members,
            String(localized: "\(course.race.name), \(course.members) membre la prépare"),
            String(localized: "\(course.race.name), \(course.members) membres la préparent")))
    }

    private func sousTitreDeCourse(_ course: ClubRace) -> String? {
        var morceaux: [String] = []
        if let jours = course.race.joursRestants, jours >= 0 {
            morceaux.append(jours == 0 ? String(localized: "C'est aujourd'hui") : String(localized: "J-\(jours)"))
        }
        if !course.race.sousTitre.isEmpty { morceaux.append(course.race.sousTitre) }
        return morceaux.isEmpty ? nil : morceaux.joined(separator: " · ")
    }

    // MARK: Les séances tenues

    @ViewBuilder
    private var seancesTenues: some View {
        if let histo = highlights?.sessionHistory, histo.total > 0 {
            VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
                HZTitreDeSection(titre: String(localized: "Les séances tenues"))
                HZTuileChiffre(libelle: String(localized: "au départ en moyenne"),
                               valeur: "\(histo.averageAttendees)")
                Text(Pluriel.choisir(histo.total,
                                     String(localized: "\(histo.total) séance"),
                                     String(localized: "\(histo.total) séances")))
                    .hzTexte(.c13, .medium)
                    .foregroundStyle(HZCouleur.secondaireSurClair)
                LazyVStack(spacing: 0) {
                    ForEach(Array(histo.recent.enumerated()), id: \.element.id) { rang, seance in
                        HZLigneDeListe(titre: seance.title,
                                       sousTitre: Self.semaineFormatter.string(from: seance.heldAt),
                                       filet: rang < histo.recent.count - 1) {
                            EmptyView()
                        } queue: {
                            Text("\(seance.attendees) au départ")
                                .hzTexte(.c14, .semi)
                                .foregroundStyle(HZCouleur.encre)
                        }
                    }
                }
            }
        }
    }

    // MARK: Les records du club

    @ViewBuilder
    private var recordsDuClub: some View {
        let records = highlights?.records ?? []
        if !records.isEmpty || highlights?.bestWeek != nil {
            VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
                HZTitreDeSection(titre: String(localized: "Les records du club"))
                LazyVStack(spacing: 0) {
                    if let semaine = highlights?.bestWeek {
                        ligneDeLaMeilleureSemaine(semaine, dernier: records.isEmpty)
                    }
                    ForEach(Array(records.enumerated()), id: \.element.id) { rang, record in
                        ligneDeRecord(record, dernier: rang == records.count - 1)
                    }
                }
            }
        }
    }

    private func ligneDeLaMeilleureSemaine(_ semaine: ClubBestWeek, dernier: Bool) -> some View {
        HZLigneDeListe(
            titre: String(localized: "La plus grosse semaine"),
            sousTitre: Pluriel.choisir(semaine.runners,
                                       String(localized: "\(semaine.runners) coureuse"),
                                       String(localized: "\(semaine.runners) coureuses"))
                + " · " + Self.semaineFormatter.string(from: semaine.startsAt),
            filet: !dernier) {
            HZVignette {
                HZIcone(dessin: .trophee, cote: HZHub.coteDeLIcone, couleur: HZCouleur.blanc)
            }
        } queue: {
            Text(verbatim: Distances.km(semaine.km))
                .hzAffichage(.chiffreDeLigne)
                .foregroundStyle(HZCouleur.encre)
        }
    }

    private static let semaineFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale.current
        f.setLocalizedDateFormatFromTemplate("d MMM")
        return f
    }()

    private func ligneDeRecord(_ record: ClubRecord, dernier: Bool) -> some View {
        Button(action: { appState.ouvrirLaSortie(record.activityId) }) {
            HZLigneDeListe(titre: libelleDuRecord(record.genre),
                           sousTitre: "\(record.nomComplet) · \(record.createdAt.relativeDescription)",
                           filet: !dernier) {
                HZPhotoDePersonne(urlString: record.avatarUrl, base64DataURI: record.avatarBase64,
                                  initiales: HZInitiales.de(record.name), cote: HZHub.avatar)
            } queue: {
                Text(verbatim: valeurDuRecord(record))
                    .hzAffichage(.chiffreDeLigne)
                    .foregroundStyle(HZCouleur.encre)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }

    private func libelleDuRecord(_ genre: String) -> String {
        switch genre {
        case "distance": return String(localized: "La plus longue")
        case "allure": return String(localized: "La plus rapide")
        default: return String(localized: "Le plus de dénivelé")
        }
    }

    private func valeurDuRecord(_ record: ClubRecord) -> String {
        switch record.genre {
        case "distance":
            guard let km = record.distanceKm else { return "—" }
            return Distances.km(km)
        case "allure":
            guard let sec = record.secPerKm else { return "—" }
            return "\(TimeFormat.allure(secondesParKm: sec))/km"
        default:
            guard let m = record.elevationGainM else { return "—" }
            return "\(m) m"
        }
    }
}
