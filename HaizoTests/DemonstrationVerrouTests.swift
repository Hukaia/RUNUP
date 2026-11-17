import XCTest
@testable import Haizo

/// LE VERROU DE LA DÉMONSTRATION : ce que `--verrouille` allume, et ce qu'il ne doit pas laisser
/// allumé derrière lui.
///
/// # CE QUE CE FICHIER PROTÈGE
///
/// L'accueil de qui n'a pas souscrit était le dernier écran que personne n'avait jamais vu, et il
/// ne pouvait PAS être photographié : `SubscriptionService.unlocks` ouvre tout en démonstration,
/// pour une raison qui reste bonne — une capture de l'App Store doit montrer le produit, pas son
/// verrou. `Demonstration.verrouille` renverse cette réponse, en démonstration seulement.
///
/// LE DANGER N'EST PAS QU'IL S'ALLUME, C'EST QU'IL RESTE ALLUMÉ. Une campagne prend trente-neuf
/// écrans ; si le verrou survivait à la prise de diagnostic, les six images de la fiche
/// partiraient chez Apple avec un `PlusLockCard` dessus. C'est le même genre de fuite que
/// l'horloge figée du 17 novembre, par l'autre bout : là un état ne se propageait pas assez, ici
/// il se propagerait trop.
///
/// Chaque prise relance l'app, donc le drapeau ne traverse pas vraiment deux captures. Le cas
/// vaut quand même : il décrit l'invariant que `arreter()` doit tenir, et c'est précisément le
/// genre de ligne qu'on supprime « parce qu'elle est symétrique » le jour où on refactore.
final class DemonstrationVerrouTests: XCTestCase {

    override func tearDown() {
        Demonstration.arreter()
        super.tearDown()
    }

    func testLeVerrouEstEteintParDefaut() {
        Demonstration.arreter()
        XCTAssertFalse(Demonstration.verrouille,
                       "une app qui démarre sans drapeau n'est pas une app verrouillée")
    }

    func testVerrouillerAllumeLeVerrouSansToucherALaDemonstration() {
        Demonstration.arreter()
        Demonstration.commencer()
        Demonstration.verrouiller()
        XCTAssertTrue(Demonstration.verrouille)
        XCTAssertTrue(Demonstration.enCours,
                      "le verrou n'a de sens QUE pendant une démonstration — voir `unlocks`")
    }

    /// LE CAS QUI COMPTE. `arreter()` remettait `enCours` et `filme` ; le verrou doit suivre.
    func testArreterEteintAussiLeVerrou() {
        Demonstration.commencer()
        Demonstration.verrouiller()
        XCTAssertTrue(Demonstration.verrouille, "sans ça, le cas ne vérifie rien")

        Demonstration.arreter()

        XCTAssertFalse(Demonstration.verrouille,
                       "un verrou qui survit à la démonstration verrouille les prises suivantes, "
                       + "et l'image de la fiche part avec un PlusLockCard dessus")
        XCTAssertFalse(Demonstration.enCours)
        XCTAssertFalse(Demonstration.filme)
    }

    /// Le verrou ne s'allume pas tout seul en entrant en démonstration : c'est `--verrouille` qui
    /// le demande, et rien d'autre. Sans ce cas, les trente-sept autres captures pourraient se
    /// verrouiller sans que rien ne sonne.
    func testEntrerEnDemonstrationNAllumePasLeVerrou() {
        Demonstration.arreter()
        Demonstration.commencer()
        XCTAssertTrue(Demonstration.enCours)
        XCTAssertFalse(Demonstration.verrouille,
                       "les six images de la fiche doivent montrer le produit, pas son verrou")
    }
}
