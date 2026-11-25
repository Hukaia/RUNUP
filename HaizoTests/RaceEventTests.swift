import XCTest
@testable import Haizo

/// La date d'une course ne doit pas changer selon l'endroit d'où on la regarde.
///
/// # LE DÉFAUT QUE CES TESTS EMPÊCHENT DE REVENIR
///
/// `races.race_date` est une colonne `DATE` : un jour, sans heure. Une colonne DATE traverse le
/// pilote Postgres en objet `Date` JavaScript, donc en ISO complet avec un fuseau — et le 4 avril
/// devient « 2027-04-03T22:00:00.000Z » pour un serveur en heure de Paris. Décodée telle quelle,
/// la course du Marathon de Paris s'affichait le 3 avril à qui lisait en UTC.
///
/// La route rend donc le jour en CLAIR (`to_char`), et c'est cette chaîne que `RaceEvent` garde.
///
/// # ET MIDI UTC NE SUFFIT PAS — C'EST CE TEST QUI L'A MONTRÉ
///
/// La première version de `jour` posait l'instant à MIDI UTC, en se disant que douze heures de
/// marge de chaque côté couvraient tous les fuseaux. Faux : les fuseaux habités vont de UTC−12 à
/// UTC+14, soit VINGT-SIX heures d'amplitude. À Kiritimati (+14), midi UTC est déjà le lendemain
/// à deux heures du matin, et ce test-ci lisait le 4 avril comme un 5. Aucun instant n'est le même
/// jour au calendrier partout — la question n'a pas de bonne réponse sous cette forme.
///
/// Le jour est donc FORMATÉ en UTC (`dateLisible`) : la langue et l'ordre des mots suivent le
/// téléphone, le jour ne suit personne. `joursRestants` est le seul endroit où le fuseau de la
/// personne compte, parce que « J-42 » répond à « combien de jours me reste-t-il ».
final class RaceEventTests: XCTestCase {

    private func course(_ date: String, distanceKm: Double? = nil, elevationGainM: Int? = nil,
                        city: String? = nil) -> RaceEvent {
        RaceEvent(id: "1", name: "Marathon de Paris", city: city, raceDate: date,
                  distanceKm: distanceKm, elevationGainM: elevationGainM,
                  discipline: "run", website: nil, followerCount: nil)
    }

    // MARK: - Le jour ne bouge pas

    func testLeJourEstCeluiQuiEstEcrit() {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        guard let jour = course("2027-04-04").jour else { return XCTFail("date illisible") }
        let parties = utc.dateComponents([.year, .month, .day], from: jour)
        XCTAssertEqual(parties.year, 2027)
        XCTAssertEqual(parties.month, 4)
        XCTAssertEqual(parties.day, 4)
    }

    func testLeJourAfficheEstCeluiDuDossardOuQueSoitLeTelephone() {
        // LE TEST QUI COMPTE. Pas « l'instant tombe-t-il le bon jour quelque part », mais « la
        // phrase affichée porte-t-elle le bon jour ». `dateLisible` formate en UTC, donc elle ne
        // dépend pas du fuseau de l'appareil : le 4 avril est le 4 avril partout.
        //
        // Le fuseau du simulateur ne se change pas depuis un test, alors on vérifie la propriété
        // directement : le même instant, relu dans le fuseau du formateur, redonne le jour écrit.
        let lisible = course("2027-04-04").dateLisible
        XCTAssertTrue(lisible.contains("4"), "« \(lisible) » ne porte pas le 4")
        XCTAssertTrue(lisible.contains("2027"), "« \(lisible) » ne porte pas 2027")
        // Les deux jours voisins : ce sont EXACTEMENT les deux valeurs qu'un instant mal placé
        // produisait (3 à l'ouest avec minuit, 5 à l'est avec midi).
        XCTAssertFalse(lisible.contains(" 3 ") || lisible.contains(" 5 "),
                       "« \(lisible) » a glissé d'un jour")
    }

    func testRelireLInstantAilleursQuEnUTCFaitGlisserLeJour() {
        // POURQUOI L'AFFICHAGE EST FORMATÉ EN UTC, démontré plutôt qu'affirmé.
        //
        // `jour` vaut minuit UTC. Relu en UTC c'est bien le 4 ; relu à Los Angeles (−7 en avril),
        // c'est le 3 à 17 h. Minuit glisse donc vers l'OUEST, exactement comme midi glissait vers
        // l'EST (Kiritimati, +14, le lisait comme le 5 — c'est l'échec qui a fait réécrire tout
        // ça). Il n'existe pas d'heure qui règle les deux : vingt-six heures d'amplitude de
        // fuseaux contre vingt-quatre dans une journée. D'où un jour FORMATÉ en UTC, et non un
        // instant qu'on espère bien placé.
        guard let jour = course("2027-04-04").jour else { return XCTFail("date illisible") }

        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        XCTAssertEqual(utc.component(.day, from: jour), 4)

        var losAngeles = Calendar(identifier: .gregorian)
        losAngeles.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        XCTAssertEqual(losAngeles.component(.day, from: jour), 3,
                       "minuit UTC devrait se lire la veille à l'ouest — c'est tout l'intérêt de ne pas afficher cet instant tel quel")
    }

    func testUneDateIllisibleNeFaitPasTomberLAffichage() {
        // Le serveur ne devrait jamais rendre ça. Si ça arrive, la page doit afficher quelque
        // chose plutôt que rien : `dateLisible` retombe sur la chaîne brute.
        let abimee = course("pas-une-date")
        XCTAssertNil(abimee.jour)
        XCTAssertNil(abimee.joursRestants)
        XCTAssertEqual(abimee.dateLisible, "pas-une-date")
    }

    // MARK: - Le compte à rebours

    func testCeMatinLaCourseDuJourEstAZero() {
        let formateur = DateFormatter()
        formateur.locale = Locale(identifier: "en_US_POSIX")
        formateur.dateFormat = "yyyy-MM-dd"
        // Le jour COURANT de l'appareil : `joursRestants` compare des minuits locaux, donc une
        // date construite en UTC ferait échouer le test la moitié de la journée.
        let aujourdhui = formateur.string(from: Date())
        XCTAssertEqual(course(aujourdhui).joursRestants, 0)
    }

    func testDemainEstAUn() {
        let formateur = DateFormatter()
        formateur.locale = Locale(identifier: "en_US_POSIX")
        formateur.dateFormat = "yyyy-MM-dd"
        let demain = formateur.string(from: Date().addingTimeInterval(86400))
        XCTAssertEqual(course(demain).joursRestants, 1)
    }

    // MARK: - Le sous-titre

    func testLeSousTitreGardeLOrdreEtOmetLeVide() {
        XCTAssertEqual(course("2027-04-04", distanceKm: 42.195, elevationGainM: 120, city: "Paris").sousTitre,
                       "Paris · \(Distances.km(42.195)) · 120 m D+")
        // Pas de ville, pas de dénivelé : aucun point médian orphelin.
        XCTAssertEqual(course("2027-04-04", distanceKm: 10).sousTitre, Distances.km(10))
        XCTAssertEqual(course("2027-04-04").sousTitre, "")
    }

    func testUnDeniveleNulNEstPasAffiche() {
        // Un marathon sur route porte 0 m D+ en base : « 0 m D+ » n'apprend rien et prend la
        // place de la distance.
        XCTAssertEqual(course("2027-04-04", distanceKm: 42.195, elevationGainM: 0).sousTitre,
                       Distances.km(42.195))
    }

    func testLaDistanceSuitLaLangueEtPasLePointAnglais() {
        // La raison d'être de `Distances` : `String(format:)` sans `locale:` écrit un POINT dans
        // les trois langues, et « 42.2 km » en français est faux.
        let attendu = (42.2 as Double).formatted(.number.precision(.fractionLength(1)).locale(.current))
        XCTAssertTrue(Distances.km(42.195).hasPrefix(attendu),
                      "« \(Distances.km(42.195)) » ne commence pas par « \(attendu) »")
    }

    func testUnNombreRondPerdSaDecimale() {
        XCTAssertEqual(Distances.km(10), "10 km")
        XCTAssertEqual(Distances.km(10.04), "10 km")
    }

    // MARK: - Le pictogramme

    func testChaqueDisciplineAUnPictogramme() {
        for discipline in ["run", "trail", "hyrox", "triathlon", "duathlon", "inconnue"] {
            let course = RaceEvent(id: "1", name: "X", city: nil, raceDate: "2027-04-04",
                                   distanceKm: nil, elevationGainM: nil, discipline: discipline,
                                   website: nil, followerCount: nil)
            XCTAssertFalse(course.disciplineSymbole.isEmpty, "rien pour « \(discipline) »")
        }
    }
}

/// Les caractéristiques d'une course : pays, formats, surface, profil, départ, inscription.
///
/// # LA RÈGLE QUE CES TESTS TIENNENT : UNE VALEUR ABSENTE N'EST PAS UNE LIGNE
///
/// Chaque champ est facultatif et `nil` veut dire « personne ne l'a publié ». La page n'affiche
/// jamais une ligne vide ni un tiret : une course saisie à la main n'a que son nom et sa date, et
/// c'est la bonne page, pas une page à moitié remplie. Et un serveur plus ancien, ou plus récent,
/// ne doit pas faire tomber le décodage : les clés qui manquent sont `nil`, celles qu'on ne connaît
/// pas sont ignorées.
final class RaceEventCaracteristiquesTests: XCTestCase {

    private func decoder(_ json: String) throws -> RaceEvent {
        try JSONDecoder().decode(RaceEvent.self, from: Data(json.utf8))
    }

    private let minimale = """
    {"id":"1","name":"Marathon de Paris","raceDate":"2027-04-04","discipline":"run"}
    """

    // MARK: - Le décodage

    func testUneCourseDAvantLesCaracteristiquesSeDecodeEncore() throws {
        // Ce que rend un serveur qui ne connaît pas les nouveaux champs, ou qu'une app plus ancienne
        // a mis en cache : aucune des clés ajoutées.
        let course = try decoder(minimale)
        XCTAssertNil(course.country)
        XCTAssertNil(course.distancesKm)
        XCTAssertNil(course.surface)
        XCTAssertNil(course.profile)
        XCTAssertNil(course.startTime)
        XCTAssertNil(course.registrationStatus)
        XCTAssertNil(course.registrationUrl)
        XCTAssertNil(course.registrationOpens)
        XCTAssertNil(course.verifiedOn)
        XCTAssertNil(course.officialDate)
    }

    func testLesClesNullesDuServeurSontDesAbsences() throws {
        let course = try decoder("""
        {"id":"1","name":"X","raceDate":"2027-04-04","discipline":"run","country":null,"distancesKm":null,
         "surface":null,"profile":null,"startTime":null,"registrationStatus":null,"registrationUrl":null,
         "registrationOpens":null,"verifiedOn":null,"officialDate":null}
        """)
        XCTAssertTrue(course.rubriques.isEmpty)
    }

    func testUneCleInconnueEstIgnoree() throws {
        // Un serveur plus récent que l'app envoie des champs que celle-ci ne connaît pas.
        XCTAssertNoThrow(try decoder("""
        {"id":"1","name":"X","raceDate":"2027-04-04","discipline":"run","champDeDemain":{"a":[1,2]}}
        """))
    }

    func testUneCourseCompleteSeDecode() throws {
        let course = try decoder("""
        {"id":"1","name":"Rome Marathon","city":"Rome","raceDate":"2027-03-14","discipline":"run",
         "country":"IT","distancesKm":[21.0975,42.195],"surface":"route","profile":"plat",
         "startTime":"08:30","registrationStatus":"ouverte","registrationUrl":"https://exemple.fr/inscription",
         "registrationOpens":null,"verifiedOn":"2026-11-22","officialDate":true}
        """)
        XCTAssertEqual(course.country, "IT")
        XCTAssertEqual(course.distancesKm, [21.0975, 42.195])
        XCTAssertEqual(course.startTime, "08:30")
        XCTAssertTrue(course.dateEstAnnoncee)
    }

    // MARK: - Une ligne n'existe que si elle a une valeur

    func testUneCourseSansCaracteristiqueNAfficheAucuneLigne() throws {
        XCTAssertTrue(try decoder(minimale).rubriques.isEmpty)
    }

    func testLaVilleSeuleFaitUneLigneLieu() throws {
        let course = try decoder("""
        {"id":"1","name":"X","city":"Paris","raceDate":"2027-04-04","discipline":"run"}
        """)
        XCTAssertEqual(course.rubriques, [.lieu])
        XCTAssertEqual(course.lieuLisible, "Paris")
    }

    func testLePaysSeNommeDansLaLangueDuTelephone() throws {
        let course = try decoder("""
        {"id":"1","name":"X","city":"Rome","raceDate":"2027-04-04","discipline":"run","country":"IT"}
        """)
        // Jamais écrit à la main : c'est `Locale` qui nomme, donc le test compare à `Locale`.
        let pays = Locale.current.localizedString(forRegionCode: "IT")
        XCTAssertNotNil(pays)
        XCTAssertEqual(course.lieuLisible, "Rome, \(pays ?? "")")
    }

    func testUnCodeDePaysInconnuNeDonneAucuneLigne() throws {
        let course = try decoder("""
        {"id":"1","name":"X","raceDate":"2027-04-04","discipline":"run","country":"ZZ"}
        """)
        XCTAssertNil(course.paysLisible)
        XCTAssertNil(course.lieuLisible)
    }

    func testUneValeurInconnueNeDonneAucuneLigne() throws {
        // Un serveur plus récent peut ajouter une surface ou un statut : l'app n'invente pas de mot.
        let course = try decoder("""
        {"id":"1","name":"X","raceDate":"2027-04-04","discipline":"run","surface":"glace",
         "profile":"vertical","registrationStatus":"liste_d_attente","startTime":"tôt"}
        """)
        XCTAssertNil(course.surfaceLisible)
        XCTAssertNil(course.profilLisible)
        XCTAssertNil(course.inscriptionLisible)
        XCTAssertNil(course.departLisible)
        XCTAssertTrue(course.rubriques.isEmpty)
    }

    func testLesRubriquesSuiventLOrdreDeLaPage() throws {
        let course = try decoder("""
        {"id":"1","name":"X","city":"Rome","raceDate":"2027-04-04","discipline":"run","country":"IT",
         "distancesKm":[42.195],"elevationGainM":80,"surface":"route","profile":"plat","startTime":"08:30",
         "registrationStatus":"complete"}
        """)
        XCTAssertEqual(course.rubriques, [.lieu, .distances, .denivele, .surface, .profil, .depart, .inscription])
    }

    // MARK: - Les distances

    func testLesFormatsSontLusDuPlusCourtAuPlusLong() throws {
        let course = try decoder("""
        {"id":"1","name":"X","raceDate":"2027-04-04","discipline":"run","distancesKm":[42.195,10,21.0975]}
        """)
        XCTAssertEqual(course.formats, [10, 21.0975, 42.195])
        XCTAssertEqual(course.grandeEtiquette, Distances.valeur(42.195))
    }

    func testUneSeuleDistanceEstUnFormat() throws {
        // Compatibilité : une course d'avant les formats multiples n'a que `distanceKm`.
        let course = try decoder("""
        {"id":"1","name":"X","raceDate":"2027-04-04","discipline":"run","distanceKm":10}
        """)
        XCTAssertEqual(course.formats, [10])
        XCTAssertEqual(course.rubriques, [.distances])
    }

    func testPlusieursFormatsNeChoisissentPasUneDistanceALaPlaceDeLOrganisateur() throws {
        // Le sous-titre dit combien de formats, pas lequel : « 120 km » pour une EcoTrail qui en
        // propose sept serait faux pour six personnes sur sept.
        let course = try decoder("""
        {"id":"1","name":"X","city":"Paris","raceDate":"2027-04-04","discipline":"trail",
         "distancesKm":[10,20,30,35,45,80,120]}
        """)
        XCTAssertNil(course.distanceKm)
        XCTAssertTrue(course.sousTitre.hasPrefix("Paris · "))
        XCTAssertTrue(course.sousTitre.contains("7"))
        XCTAssertFalse(course.sousTitre.contains("120"))
    }

    func testSansDistanceLaGrandeEtiquetteEstLeTypeDEpreuveEtPasUnTiret() throws {
        for discipline in ["run", "trail", "hyrox", "triathlon", "duathlon"] {
            let course = try decoder("""
            {"id":"1","name":"X","raceDate":"2027-04-04","discipline":"\(discipline)"}
            """)
            XCTAssertFalse(course.grandeEtiquette.isEmpty)
            XCTAssertFalse(course.grandeEtiquette.contains("—"), "un tiret pour « \(discipline) »")
        }
    }

    // MARK: - L'heure et l'inscription

    func testLHeureDeDepartNeDependPasDuFuseauDuTelephone() throws {
        let course = try decoder("""
        {"id":"1","name":"X","raceDate":"2027-04-04","discipline":"run","startTime":"08:30"}
        """)
        let lisible = try XCTUnwrap(course.departLisible)
        XCTAssertTrue(lisible.contains("8") && lisible.contains("30"), "« \(lisible) »")
    }

    func testUneHeureMalFormeeNEstPasAffichee() throws {
        for mauvaise in ["8h30", "25:00", "08:60", "", "08:30:00"] {
            let course = try decoder("""
            {"id":"1","name":"X","raceDate":"2027-04-04","discipline":"run","startTime":"\(mauvaise)"}
            """)
            XCTAssertNil(course.departLisible, "« \(mauvaise) » ne devrait rien afficher")
        }
    }

    func testLeBoutonDInscriptionNeMentPas() throws {
        func course(_ statut: String, site: String?, inscription: String? = nil) throws -> RaceEvent {
            let website = site.map { "\"website\":\"\($0)\"," } ?? ""
            let lien = inscription.map { "\"registrationUrl\":\"\($0)\"," } ?? ""
            return try decoder("""
            {"id":"1","name":"X","raceDate":"2027-04-04","discipline":"run",\(website)\(lien)
             "registrationStatus":"\(statut)"}
            """)
        }
        // Ouverte ou au tirage : le site mène à l'inscription.
        XCTAssertEqual(try course("ouverte", site: "https://exemple.fr").adresseDInscription, "https://exemple.fr")
        XCTAssertEqual(try course("tirage_au_sort", site: "https://exemple.fr").adresseDInscription, "https://exemple.fr")
        // Complète, fermée, pas encore ouverte : un bouton « s'inscrire » promettrait ce que le site ne tient pas.
        XCTAssertNil(try course("complete", site: "https://exemple.fr").adresseDInscription)
        XCTAssertNil(try course("fermee", site: "https://exemple.fr").adresseDInscription)
        XCTAssertNil(try course("bientot", site: "https://exemple.fr").adresseDInscription)
        // Pas de site : pas de bouton.
        XCTAssertNil(try course("ouverte", site: nil).adresseDInscription)
        // Une adresse d'inscription propre à la course passe avant le site, y compris avant l'ouverture.
        XCTAssertEqual(try course("bientot", site: "https://exemple.fr", inscription: "https://exemple.fr/i").adresseDInscription,
                       "https://exemple.fr/i")
        // Mais pas sur une course complète ou fermée : le bouton s'afficherait sous « Complète ».
        XCTAssertNil(try course("complete", site: "https://exemple.fr", inscription: "https://exemple.fr/i").adresseDInscription)
        XCTAssertNil(try course("fermee", site: "https://exemple.fr", inscription: "https://exemple.fr/i").adresseDInscription)
    }

    func testUneInscriptionPasEncoreOuverteNommeSonJourQuandOnLeConnait() throws {
        let avecJour = try decoder("""
        {"id":"1","name":"X","raceDate":"2027-06-06","discipline":"trail",
         "registrationStatus":"bientot","registrationOpens":"2027-01-11"}
        """)
        let lisible = try XCTUnwrap(avecJour.inscriptionLisible)
        XCTAssertTrue(lisible.contains("2027"), "« \(lisible) » ne dit pas quand")
        let sansJour = try decoder("""
        {"id":"1","name":"X","raceDate":"2027-06-06","discipline":"trail","registrationStatus":"bientot"}
        """)
        XCTAssertNotNil(sansJour.inscriptionLisible)
        XCTAssertFalse(try XCTUnwrap(sansJour.inscriptionLisible).contains("2027"))
    }

    // MARK: - La date annoncée

    func testSeuleUneDateReleveeChezLOrganisateurSeDitAnnoncee() throws {
        XCTAssertFalse(try decoder(minimale).dateEstAnnoncee)
        XCTAssertFalse(try decoder("""
        {"id":"1","name":"X","raceDate":"2027-04-04","discipline":"run","officialDate":false}
        """).dateEstAnnoncee)
        XCTAssertTrue(try decoder("""
        {"id":"1","name":"X","raceDate":"2027-04-04","discipline":"run","officialDate":true}
        """).dateEstAnnoncee)
    }

    // MARK: - Les pays proposés à la création

    func testLesPaysProposesSontDesCodesATroisLettresExclus() {
        let codes = RaceEvent.paysProposes.map(\.code)
        XCTAssertTrue(codes.contains("FR"))
        XCTAssertTrue(codes.contains("JP"))
        XCTAssertTrue(codes.allSatisfy { $0.count == 2 }, "une zone (trois chiffres) s'est glissée dans les pays")
        XCTAssertEqual(codes.count, Set(codes).count, "un pays en double")
    }

    /// Le serveur écarte une adresse sans protocole. On le pose donc avant d'envoyer.
    func testUneAdresseSansProtocoleLeRecoit() {
        XCTAssertEqual(RaceEvent.adresseComplete("marathon.fr"), "https://marathon.fr")
        XCTAssertEqual(RaceEvent.adresseComplete("  www.exemple.org/inscription "), "https://www.exemple.org/inscription")
        XCTAssertEqual(RaceEvent.adresseComplete("https://marathon.fr"), "https://marathon.fr")
        XCTAssertEqual(RaceEvent.adresseComplete("HTTP://marathon.fr"), "HTTP://marathon.fr")
        XCTAssertEqual(RaceEvent.adresseComplete("   "), "", "un champ vide reste vide : rien à envoyer")
    }

    // MARK: - Le filtre de distance

    func testLesDistancesOfficiellesTombentDansLeurCategorie() {
        XCTAssertEqual(FiltreDeDistance.categorie(de: 5), .cinq)
        XCTAssertEqual(FiltreDeDistance.categorie(de: 10.1), .dix)
        XCTAssertEqual(FiltreDeDistance.categorie(de: 21.0975), .semi)
        XCTAssertEqual(FiltreDeDistance.categorie(de: 42.195), .marathon)
        XCTAssertEqual(FiltreDeDistance.categorie(de: 78), .ultra)
    }

    func testUneDistanceVoisineNEstPasAvaleeParSaCategorie() {
        // Le quart de marathon de Rotterdam et les 10 miles ne sont pas des 10 km.
        XCTAssertEqual(FiltreDeDistance.categorie(de: 10.55), .autres)
        XCTAssertEqual(FiltreDeDistance.categorie(de: 16.0934), .autres)
        XCTAssertNil(FiltreDeDistance.categorie(de: 0))
        XCTAssertNil(FiltreDeDistance.categorie(de: .nan))
    }

    func testUnEvenementAPlusieursFormatsRepondAChacun() throws {
        let course = try decoder("""
        {"id":"v","name":"Vienna City Marathon","raceDate":"2027-04-18","discipline":"run","distancesKm":[42.195,5,10,21.0975]}
        """)
        XCTAssertTrue(course.aUnFormat(.cinq))
        XCTAssertTrue(course.aUnFormat(.semi))
        XCTAssertFalse(course.aUnFormat(.ultra))
        // Sous « 5 km », l'affiche dit 5 et pas 42.
        XCTAssertEqual(course.grandeEtiquette(pour: .cinq), Distances.valeur(5))
        XCTAssertEqual(course.grandeEtiquette(pour: nil), course.grandeEtiquette)
        XCTAssertEqual(course.grandeEtiquette(pour: .ultra), course.grandeEtiquette)
    }

    func testUneCourseSansDistanceNeRepondAAucunFiltre() throws {
        let course = try decoder("""
        {"id":"h","name":"HYROX Paris","raceDate":"2027-04-18","discipline":"hyrox"}
        """)
        for filtre in FiltreDeDistance.allCases { XCTAssertFalse(course.aUnFormat(filtre)) }
    }
}

