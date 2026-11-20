import XCTest
@testable import Haizo

/// « Je prépare cette course » donne au programme sa date.
///
/// Le défaut qu'ils gardent : l'inscription disait « le plan se calera sur sa date » alors que rien
/// ne reliait la course choisie au programme. Chaque cas ci-dessous est une façon de refaire cette
/// promesse fausse : une course qu'on range dans le mauvais format, une date décalée d'un jour, un
/// triathlon dont on devinerait le format, un programme qui ne reçoit pas la date.
final class ProgrammePourUneCourseTests: XCTestCase {

    private var utc: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    /// Une course du calendrier, décodée comme le serveur la rend.
    private func course(discipline: String = "run", km: Double? = 10, denivele: Int? = nil,
                        jour: String = ProgrammePourUneCourseTests.dansQuatreMois(),
                        nom: String = "Le Marathon de Test") throws -> RaceEvent {
        var champs: [String: Any] = ["id": "r1", "name": nom, "raceDate": jour, "discipline": discipline]
        if let km { champs["distanceKm"] = km }
        if let denivele { champs["elevationGainM"] = denivele }
        let data = try JSONSerialization.data(withJSONObject: champs)
        return try JSONDecoder().decode(RaceEvent.self, from: data)
    }

    /// Une date de course toujours dans le futur, quel que soit le jour où les tests tournent.
    static func dansQuatreMois() -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Calendar.current.date(byAdding: .month, value: 4, to: Date()) ?? Date())
    }

    private let maintenant = Date()

    private func calage(_ c: RaceEvent, chrono: String? = nil) -> ProgrammePourUneCourse.Calage? {
        ProgrammePourUneCourse.calage(pour: c, chrono: chrono, joursDeCourse: [0, 2, 5],
                                      maintenant: maintenant, calendrier: utc)
    }

    // MARK: Les formats

    func testLesDistancesDeRouteSontRangeesDansLeurFormat() throws {
        XCTAssertEqual(try calage(course(km: 5.0))?.resultat.distance, .k5)
        XCTAssertEqual(try calage(course(km: 10.05))?.resultat.distance, .k10)
        XCTAssertEqual(try calage(course(km: 21.1))?.resultat.distance, .semi)
        XCTAssertEqual(try calage(course(km: 42.195))?.resultat.distance, .marathon)
        for km in [5.0, 10.0, 21.0975, 42.195] {
            XCTAssertEqual(try calage(course(km: km))?.resultat.goal, .race, "\(km) km")
            XCTAssertNil(try calage(course(km: km))?.distanceLibre, "\(km) km n'a pas de distance libre")
        }
    }

    /// 15 km n'est pas un format : la course reste une course, et sa distance s'écrit en toutes lettres.
    func testUneDistanceHorsFormatDevientUneDistanceLibre() throws {
        let c = try calage(course(km: 15))
        XCTAssertEqual(c?.resultat.goal, .race)
        XCTAssertEqual(c?.resultat.distance, .other)
        XCTAssertEqual(c?.distanceLibre, "15 km")
        let virgule = try calage(course(km: 12.5))
        XCTAssertEqual(virgule?.distanceLibre, "12.5 km")
    }

    func testUnTrailCourtResteUneCourseUnUltraDevientUnUltra() throws {
        let court = try calage(course(discipline: "trail", km: 22, denivele: 1200))
        XCTAssertEqual(court?.resultat.goal, .race)
        XCTAssertEqual(court?.distanceLibre, "22 km")

        let ultra = try calage(course(discipline: "trail", km: 80, denivele: 4500))
        XCTAssertEqual(ultra?.resultat.goal, .ultraTrail)
        XCTAssertEqual(ultra?.resultat.distance, .ultra80)
        XCTAssertEqual(ultra?.resultat.raceElevationGainM, 4500, "le dénivelé d'un ultra dimensionne le plan")

        let horsFormat = try calage(course(discipline: "trail", km: 110, denivele: 5000))
        XCTAssertEqual(horsFormat?.resultat.goal, .ultraTrail)
        XCTAssertEqual(horsFormat?.resultat.distance, .other)
        XCTAssertEqual(horsFormat?.distanceLibre, "110 km")
    }

    // MARK: Ce qu'on ne devine pas

    /// Le triathlon, le duathlon et le HYROX ont besoin d'un format ou d'une division que le
    /// calendrier ne porte pas : pas de calage plutôt qu'un plan sans natation ni transitions.
    func testLesDisciplinesSansFormatNeCalentRien() throws {
        for discipline in ["triathlon", "duathlon", "hyrox", "inconnue"] {
            XCTAssertNil(try calage(course(discipline: discipline, km: 10)), discipline)
        }
    }

    func testSansDistanceOuUneDatePasseeOuIllisiblePasDeCalage() throws {
        XCTAssertNil(try calage(course(km: nil)))
        XCTAssertNil(try calage(course(km: 10, jour: "2026-01-01")), "une course passée ne cale rien")
        XCTAssertNil(try calage(course(km: 10, jour: "pas une date")))
    }

    func testUnChronoQuiNeSeLitPasNEstPasRecopie() throws {
        XCTAssertEqual(try calage(course(km: 10), chrono: "47:30")?.resultat.chrono, "47:30")
        XCTAssertNil(try calage(course(km: 10), chrono: "bientôt")?.resultat.chrono)
        XCTAssertNil(try calage(course(km: 10), chrono: "  ")?.resultat.chrono)
    }

    // MARK: La date

    /// « 2027-04-04 » est une date sans fuseau. Lue à minuit UTC puis rendue dans un fuseau à l'ouest
    /// de Greenwich, elle tomberait le 3 : le programme finirait un jour trop tôt.
    func testLeJourDeLaCourseResteLeMemeJourDansTousLesFuseaux() throws {
        let c = try course(jour: "2027-04-04")
        for id in ["Pacific/Auckland", "Europe/Paris", "UTC", "America/New_York", "Pacific/Honolulu"] {
            var local = Calendar(identifier: .gregorian)
            local.timeZone = TimeZone(identifier: id)!
            let date = try XCTUnwrap(ProgrammePourUneCourse.jourLocal(de: c, calendrier: local), id)
            let jour = local.dateComponents([.year, .month, .day], from: date)
            XCTAssertEqual([jour.year, jour.month, jour.day], [2027, 4, 4], id)
        }
    }

    // MARK: L'application

    /// LE POINT DE TOUT : après le calage, le programme a une date, donc un bloc spécifique et un affûtage.
    func testLeProgrammeRecoitLaDateEtDevientPeriodise() throws {
        let profil = UserProfile(name: "Test")
        profil.goalId = .progress
        XCTAssertNil(profil.raceDate)

        let c = try XCTUnwrap(calage(course(km: 10), chrono: "47:30"))
        ProgrammePourUneCourse.appliquer(c, a: profil)

        XCTAssertEqual(profil.goalId, .race)
        XCTAssertEqual(profil.raceDistance, .k10)
        XCTAssertEqual(profil.raceChrono, "47:30")
        XCTAssertNotNil(profil.raceDate, "le programme n'a pas reçu la date")
        XCTAssertEqual(profil.runningDays, [0, 2, 5])
        XCTAssertEqual(profil.programPhase, .active)
        let forme = AdaptivePlanEngine.ProgramShape.compute(goal: profil.goalId, raceDate: profil.raceDate,
                                                            from: .now)
        XCTAssertNotNil(forme.totalWeeks, "sans date, le plan reste ouvert")
    }

    /// `startNewProgram` efface la distance libre ; le calage la rétablit, sinon « 15 km » redeviendrait
    /// « Ta course » et le moteur perdrait la distance.
    func testLaDistanceLibreSurvitAuCalage() throws {
        let profil = UserProfile(name: "Test")
        let c = try XCTUnwrap(calage(course(km: 15)))
        ProgrammePourUneCourse.appliquer(c, a: profil)
        XCTAssertEqual(profil.raceDistance, .other)
        XCTAssertEqual(profil.raceDistanceCustom, "15 km")
        XCTAssertEqual(profil.effectiveRaceDistanceKm, 15)
        XCTAssertTrue(profil.goalDisplay.contains("15 km"), profil.goalDisplay)
    }

    func testUnProfilDejaCaleNeSeVoitRienProposer() throws {
        let profil = UserProfile(name: "Test")
        let c = try XCTUnwrap(calage(course(km: 10)))
        XCTAssertFalse(ProgrammePourUneCourse.estDejaCale(profil, sur: c, calendrier: utc))
        ProgrammePourUneCourse.appliquer(c, a: profil)
        XCTAssertTrue(ProgrammePourUneCourse.estDejaCale(profil, sur: c, calendrier: utc))
    }
}
