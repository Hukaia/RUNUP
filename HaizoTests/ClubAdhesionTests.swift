import XCTest
@testable import Haizo

/// L'adhésion à un club : trois modes, au choix de son propriétaire.
///
/// Ce que ces tests tiennent, sans écran et sans réseau :
///
///   · un serveur plus ancien, ou plus récent, que l'app ne la déconnecte pas du Club : aucun champ
///     d'adhésion n'est exigé au décodage, et un mode absent ou inconnu retombe sur l'ancien
///     interrupteur « ouvert » ;
///   · le bouton de la fiche dit la bonne chose pour chaque mode et chaque état de la personne —
///     c'est la seule décision de ce chantier qui puisse mentir sans rien casser ;
///   · la teinte d'un club est toujours la même pour le même club.
final class ClubAdhesionTests: XCTestCase {

    private func decoder<T: Decodable>(_ type: T.Type, _ json: String,
                                       fichier: StaticString = #filePath,
                                       ligne: UInt = #line) throws -> T {
        let decodeur = JSONDecoder()
        decodeur.dateDecodingStrategy = .iso8601
        return try XCTUnwrap(try? decodeur.decode(T.self, from: Data(json.utf8)),
                             "\(T.self) exige encore une clé : \(json)", file: fichier, line: ligne)
    }

    // MARK: - Le mode, tel que le serveur le dit

    func testLeServeurDitLeMode() {
        XCTAssertEqual(ClubJoinMode(serveur: "open", isOpen: nil), .open)
        XCTAssertEqual(ClubJoinMode(serveur: "request", isOpen: nil), .request)
        XCTAssertEqual(ClubJoinMode(serveur: "code", isOpen: nil), .code)
        // Le mode dit par le serveur l'emporte sur l'ancien interrupteur : un club sur demande est
        // « fermé » pour une app ancienne, et ce n'est pas la même chose pour celle-ci.
        XCTAssertEqual(ClubJoinMode(serveur: "request", isOpen: false), .request)
    }

    /// Un serveur d'avant les trois modes ne rend que `isOpen`.
    func testSansMotUnClubFermeEstSurCodeEtLeResteEstOuvert() {
        XCTAssertEqual(ClubJoinMode(serveur: nil, isOpen: false), .code)
        XCTAssertEqual(ClubJoinMode(serveur: nil, isOpen: true), .open)
        XCTAssertEqual(ClubJoinMode(serveur: nil, isOpen: nil), .open)
    }

    /// Un serveur plus récent pourrait rendre un mode que cette version ne connaît pas.
    func testUnModeInconnuRetombeSurLInterrupteur() {
        XCTAssertEqual(ClubJoinMode(serveur: "invitation", isOpen: false), .code)
        XCTAssertEqual(ClubJoinMode(serveur: "invitation", isOpen: true), .open)
        XCTAssertEqual(ClubJoinMode(serveur: "", isOpen: nil), .open)
        XCTAssertEqual(ClubJoinMode(serveur: "OPEN", isOpen: nil), .open, "la casse n'est pas tolérée : retour à l'interrupteur")
    }

    func testLesTroisModesOntChacunUnLibelleEtUnePrecisionDistincts() {
        XCTAssertEqual(ClubJoinMode.allCases.count, 3)
        for liste in [ClubJoinMode.allCases.map(\.libelle),
                      ClubJoinMode.allCases.map(\.precisionDuProprietaire),
                      ClubJoinMode.allCases.map(\.precisionDuVisiteur)] {
            XCTAssertEqual(Set(liste).count, 3)
            XCTAssertFalse(liste.contains(where: \.isEmpty))
        }
    }

    // MARK: - Le décodage tolère l'absence

    func testUnClubDUnServeurAncienSeDecodeSansAucunChampDAdhesion() throws {
        let info = try decoder(ClubInfo.self,
                               #"{"id":"c","name":"Les Foulées","memberCount":12,"isOpen":false,"isOwner":true}"#)
        XCTAssertNil(info.joinMode)
        XCTAssertNil(info.inviteCode)
        XCTAssertNil(info.pendingRequests)
        // Fermé et rien d'autre : l'ancien interrupteur dit « sur code ».
        XCTAssertEqual(info.modeDAdhesion, .code)
    }

    func testUnClubSurDemandeRendLeModeLeCodeEtLesDemandes() throws {
        let info = try decoder(ClubInfo.self, #"""
        {"id":"c","name":"Les Foulées","memberCount":12,"isOpen":false,"isOwner":true,
         "joinMode":"request","pendingRequests":3}
        """#)
        XCTAssertEqual(info.modeDAdhesion, .request)
        XCTAssertEqual(info.pendingRequests, 3)
        XCTAssertNil(info.inviteCode)

        let surCode = try decoder(ClubInfo.self, #"""
        {"id":"c","name":"Les Foulées","memberCount":12,"isOpen":false,"isOwner":true,
         "joinMode":"code","inviteCode":"AB3K7M"}
        """#)
        XCTAssertEqual(surCode.modeDAdhesion, .code)
        XCTAssertEqual(surCode.inviteCode, "AB3K7M")
    }

    func testToutLeTableauDeBordSeDecodeAvecUnClubSansChampDAdhesion() throws {
        let tableau = try decoder(ClubBoard.self,
                                  #"{"club":{"id":"c","name":"Les Foulées","memberCount":1},"leaderboard":[]}"#)
        XCTAssertEqual(tableau.club?.modeDAdhesion, .open)
    }

    func testUnResultatDeRechercheAncienEstUnClubOuvert() throws {
        let resultat = try decoder(ClubSearchResult.self, #"{"id":"a","name":"A","memberCount":3}"#)
        XCTAssertEqual(resultat.mode, .open)
        XCTAssertNil(resultat.requestPending)
    }

    func testUnResultatDeRechercheDitSonModeEtSaDemande() throws {
        let resultat = try decoder(ClubSearchResult.self, #"""
        {"id":"a","name":"A","city":"Lyon","memberCount":3,"joinMode":"request","requestPending":true}
        """#)
        XCTAssertEqual(resultat.mode, .request)
        XCTAssertEqual(resultat.requestPending, true)
    }

    func testUneFicheNAExigeQueSonIdentite() throws {
        let fiche = try decoder(ClubPreview.self, #"{"id":"a","name":"A","memberCount":3}"#)
        XCTAssertEqual(fiche.mode, .open)
        XCTAssertNil(fiche.description)
        XCTAssertNil(fiche.nextSession)
        XCTAssertNil(fiche.alreadyInClub)
    }

    func testUneFicheDecritLaProchaineSeanceQuandLeServeurLaDit() throws {
        let fiche = try decoder(ClubPreview.self, #"""
        {"id":"a","name":"A","memberCount":3,"joinMode":"open","alreadyInClub":false,
         "nextSession":{"title":"Fractionné","location":null,"startsAt":"2026-11-24T18:30:00Z"}}
        """#)
        XCTAssertEqual(fiche.nextSession?.title, "Fractionné")
        XCTAssertNil(fiche.nextSession?.location)
        XCTAssertNil(fiche.nextSession?.repeatsWeekly)
    }

    func testUneDemandeNExigeQueSaPersonneEtSaDate() throws {
        let demande = try decoder(ClubJoinRequest.self, #"""
        {"id":"r","userId":"u","name":"Camille","createdAt":"2026-11-22T08:00:00Z"}
        """#)
        XCTAssertNil(demande.lastName)
        XCTAssertNil(demande.avatarUrl)
        XCTAssertEqual(demande.nomComplet, "Camille")
    }

    // MARK: - Le bouton de la fiche

    /// LA TABLE ENTIÈRE : trois modes, une demande envoyée ou non, déjà dans un club ou non, code
    /// connu ou non. Cent vingt combinaisons possibles se réduisent à six boutons.
    func testLeBoutonPourChaqueModeEtChaqueEtat() {
        let pour = ClubBoutonDAdhesion.pour
        // Un club ouvert : on rejoint, quoi qu'il en soit de la demande et du code.
        XCTAssertEqual(pour(.open, false, false, false), .rejoindre)
        XCTAssertEqual(pour(.open, true, false, false), .rejoindre, "une demande périmée ne change pas un club ouvert")
        XCTAssertEqual(pour(.open, false, false, true), .rejoindre)
        // Un club sur demande : demander, puis « Demande envoyée ».
        XCTAssertEqual(pour(.request, false, false, false), .demander)
        XCTAssertEqual(pour(.request, true, false, false), .demandeEnvoyee)
        XCTAssertEqual(pour(.request, false, false, true), .demander, "un code ne sert à rien sur un club sur demande")
        // Un club sur code : entrer le code, sauf si la fiche a été ouverte avec lui.
        XCTAssertEqual(pour(.code, false, false, false), .entrerLeCode)
        XCTAssertEqual(pour(.code, false, false, true), .rejoindreAvecLeCode)
        XCTAssertEqual(pour(.code, true, false, false), .entrerLeCode, "une demande ne se fait pas sur un club sur code")
    }

    /// Un seul club à la fois : déjà dans un club, aucun bouton d'adhésion, quel que soit le mode.
    func testDejaDansUnClubIlNYAPlusDeBoutonDAdhesion() {
        for mode in ClubJoinMode.allCases {
            for demande in [false, true] {
                for code in [false, true] {
                    XCTAssertEqual(
                        ClubBoutonDAdhesion.pour(mode: mode, demandeEnvoyee: demande, dejaDansUnClub: true,
                                                 codeConnu: code),
                        .dejaMembre, "\(mode) demande \(demande) code \(code)")
                }
            }
        }
        XCTAssertNil(ClubBoutonDAdhesion.dejaMembre.libelle)
    }

    func testChaqueBoutonAUnLibelleSaufDejaMembre() {
        let boutons: [ClubBoutonDAdhesion] = [.rejoindre, .demander, .demandeEnvoyee, .entrerLeCode,
                                              .rejoindreAvecLeCode]
        for bouton in boutons {
            XCTAssertFalse(bouton.libelle?.isEmpty ?? true, "\(bouton)")
        }
        // Rejoindre est le même mot avec ou sans code déjà vérifié.
        XCTAssertEqual(ClubBoutonDAdhesion.rejoindre.libelle, ClubBoutonDAdhesion.rejoindreAvecLeCode.libelle)
        XCTAssertNotEqual(ClubBoutonDAdhesion.demander.libelle, ClubBoutonDAdhesion.demandeEnvoyee.libelle)
    }

    /// « Demande envoyée » est un état, pas une action : la fiche le dit en gris et non tapable.
    func testSeuleLaDemandeEnvoyeeEstUnEtat() {
        XCTAssertTrue(ClubBoutonDAdhesion.demandeEnvoyee.estUnEtat)
        for bouton in [ClubBoutonDAdhesion.rejoindre, .demander, .entrerLeCode, .rejoindreAvecLeCode, .dejaMembre] {
            XCTAssertFalse(bouton.estUnEtat, "\(bouton)")
        }
    }

    // MARK: - La fiche ouverte depuis une ligne ou depuis un code

    func testUneFicheOuverteDUneLigneNAPasDeCodeNiDeFicheChargee() throws {
        let ligne = try decoder(ClubSearchResult.self, #"""
        {"id":"a","name":"A","city":"Lyon","memberCount":3,"joinMode":"request","requestPending":true}
        """#)
        let fiche = ClubFicheOuverte(ligne)
        XCTAssertEqual(fiche.mode, .request)
        XCTAssertTrue(fiche.requestPending)
        XCTAssertNil(fiche.code)
        XCTAssertNil(fiche.apercu)
    }

    func testUneFicheOuverteParUnCodeGardeLeCodeEtLaFiche() throws {
        let apercu = try decoder(ClubPreview.self, #"{"id":"a","name":"A","memberCount":3,"joinMode":"code"}"#)
        let fiche = ClubFicheOuverte(apercu, code: "AB3K7M")
        XCTAssertEqual(fiche.mode, .code)
        XCTAssertEqual(fiche.code, "AB3K7M")
        XCTAssertEqual(fiche.apercu?.id, "a")
        XCTAssertEqual(
            ClubBoutonDAdhesion.pour(mode: fiche.mode, demandeEnvoyee: fiche.requestPending,
                                     dejaDansUnClub: false, codeConnu: fiche.code != nil),
            .rejoindreAvecLeCode)
    }

    // MARK: - Le code

    func testUnCodeSeTapeCommeOnVeut() {
        XCTAssertEqual(ClubCode.normaliser(" AB3-K7 M "), "AB3K7M")
        XCTAssertTrue(ClubCode.estComplet("AB3 K7M"))
        XCTAssertTrue(ClubCode.estComplet("ab3k7m"), "la casse est l'affaire du serveur")
        XCTAssertFalse(ClubCode.estComplet("AB3K7"))
        XCTAssertFalse(ClubCode.estComplet("AB3K7MX"))
        XCTAssertFalse(ClubCode.estComplet(""))
        XCTAssertFalse(ClubCode.estComplet("      "))
    }

    // MARK: - Ce que dit le serveur d'un refus

    func testLeCodeEtLeStatutDUnRefusSeLisent() {
        let refus = ClubServiceError.badResponse(409, #"{"error":"already_in_club"}"#)
        XCTAssertEqual(refus.statut, 409)
        XCTAssertEqual(refus.codeServeur, "already_in_club")
        XCTAssertNil(ClubServiceError.badResponse(500, "<html>").codeServeur)
        XCTAssertNil(ClubServiceError.badResponse(500, "").codeServeur)
        XCTAssertNil(ClubServiceError.notSignedIn.statut)
    }

    func testChaqueRefusDeLAdhesionAUneDeSesPhrases() {
        let generique = PanneReseau.phrase(pour: ClubServiceError.badResponse(500, ""))
        let refus: [ClubServiceError] = [
            .badResponse(400, #"{"error":"bad_code"}"#),
            .badResponse(409, #"{"error":"already_in_club"}"#),
            .badResponse(409, #"{"error":"request_required"}"#),
            .badResponse(409, #"{"error":"use_join"}"#),
            .badResponse(409, #"{"error":"too_many_pending_requests"}"#),
            .badResponse(429, #"{"error":"too_many_requests"}"#),
            .badResponse(404, #"{"error":"not_found"}"#),
        ]
        var vues = Set<String>()
        for erreur in refus {
            let phrase = ClubAdhesionErreur.phrase(pour: erreur)
            XCTAssertNotEqual(phrase, generique, "\(erreur)")
            vues.insert(phrase)
        }
        XCTAssertEqual(vues.count, refus.count, "deux refus qui ne se disent pas pareil ne partagent pas leur phrase")
    }

    func testUnePanneNEstPasUnRefusDAdhesion() {
        // Pas de réseau, session expirée, serveur en panne : c'est `PanneReseau` qui parle.
        for erreur in [ClubServiceError.badResponse(500, ""), .badResponse(401, ""), .notSignedIn] {
            XCTAssertEqual(ClubAdhesionErreur.phrase(pour: erreur), PanneReseau.phrase(pour: erreur))
        }
    }

    func testLaFicheEstRelueQuandLeClubAChangeDeMode() {
        XCTAssertTrue(ClubAdhesionErreur.faitRelireLaFiche(ClubServiceError.badResponse(409, #"{"error":"request_required"}"#)))
        XCTAssertTrue(ClubAdhesionErreur.faitRelireLaFiche(ClubServiceError.badResponse(409, #"{"error":"use_join"}"#)))
        XCTAssertTrue(ClubAdhesionErreur.faitRelireLaFiche(ClubServiceError.badResponse(404, "")))
        // Un mauvais code ou un club déjà rejoint ne changent rien à ce que la fiche montre.
        XCTAssertFalse(ClubAdhesionErreur.faitRelireLaFiche(ClubServiceError.badResponse(400, #"{"error":"bad_code"}"#)))
        XCTAssertFalse(ClubAdhesionErreur.faitRelireLaFiche(ClubServiceError.badResponse(409, #"{"error":"already_in_club"}"#)))
        XCTAssertFalse(ClubAdhesionErreur.faitRelireLaFiche(ClubServiceError.badResponse(500, "")))
    }

    // MARK: - La ligne sous le nom

    func testLaLigneSousLeNomNeCommenceJamaisParUnSeparateur() {
        let seul = ClubLigne.detail(ville: nil, membres: 18)
        XCTAssertFalse(seul.contains("·"))
        XCTAssertEqual(ClubLigne.detail(ville: "", membres: 18), seul)
        XCTAssertEqual(ClubLigne.detail(ville: "   ", membres: 18), seul)
        XCTAssertEqual(ClubLigne.detail(ville: "Lyon", membres: 18), "Lyon · \(seul)")
        XCTAssertEqual(ClubLigne.detail(ville: " Lyon ", membres: 18), "Lyon · \(seul)")
    }

    // MARK: - La teinte d'un club

    func testLaTeinteEstToujoursLaMemePourLeMemeClub() {
        for identifiant in ["demo", "k1", "44444444-4444-4444-8444-444444444444", ""] {
            XCTAssertEqual(ClubTeinte.indice(pour: identifiant, parmi: 3),
                           ClubTeinte.indice(pour: identifiant, parmi: 3))
            XCTAssertEqual(HZIntensite.pourClub(id: identifiant), HZIntensite.pourClub(id: identifiant))
        }
    }

    /// Des valeurs écrites en dur : la somme ne doit pas changer d'une version à l'autre de l'app,
    /// sans quoi un club changerait de couleur à la mise à jour.
    func testLaTeinteNeChangePasDUneVersionALAutre() {
        XCTAssertEqual(ClubTeinte.indice(pour: "demo", parmi: 3), 2)
        XCTAssertEqual(ClubTeinte.indice(pour: "k1", parmi: 3), 1)
        XCTAssertEqual(ClubTeinte.indice(pour: "k2", parmi: 3), 2)
        XCTAssertEqual(ClubTeinte.indice(pour: "k3", parmi: 3), 0)
        XCTAssertEqual(ClubTeinte.indice(pour: "44444444-4444-4444-8444-444444444444", parmi: 3), 2)
    }

    func testLaTeinteResteDansLaPaletteEtLaParcourt() {
        var vues = Set<Int>()
        for rang in 0..<60 {
            let indice = ClubTeinte.indice(pour: "club-\(rang)", parmi: 3)
            XCTAssertTrue((0..<3).contains(indice))
            vues.insert(indice)
        }
        XCTAssertEqual(vues, [0, 1, 2], "des clubs différents ne prennent pas tous la même teinte")
        // Rien à choisir : un compte qui n'est pas positif rend zéro plutôt que de planter.
        XCTAssertEqual(ClubTeinte.indice(pour: "demo", parmi: 0), 0)
        XCTAssertEqual(ClubTeinte.indice(pour: "demo", parmi: -2), 0)
    }
}
