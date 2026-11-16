import XCTest
@testable import Haizo

/// La fausse conversation du coach tombe-t-elle toujours AUJOURD'HUI ?
///
/// # CE QUE CE FICHIER PROTÈGE
///
/// `3-coach` est une des six captures livrées à Apple. Le message du coach y est planté cinq
/// heures en arrière — assez pour qu'il ait l'air d'une vraie conversation du matin. Sans borne,
/// une chaîne qui tourne à 03 h 00 le pose à 22 h 00 la VEILLE, et la capture affiche un
/// séparateur « HIER » au-dessus de la conversation. L'image livrée ne dit alors plus ce qu'on
/// veut qu'elle dise : un coach qui a répondu ce matin.
///
/// Le défaut est passé une fois. Deux exécutions comparées, à 01 h 18 et 04 h 37, s'accordaient ;
/// une troisième à 07 h 00 ne s'accordait plus. « Deux exécutions qui s'accordent ne font pas une
/// reproductibilité » — l'en-tête de `ci_scripts/comparer.py`.
///
/// # POURQUOI CE N'EST PAS LA CHAÎNE QUI LE VÉRIFIE
///
/// Parce qu'elle ne le peut pas. Le cas qui casse n'existe qu'entre minuit et 05 h 00, et une
/// exécution d'intégration continue tombe à l'heure où quelqu'un pousse. Attendre qu'elle tombe
/// la nuit pour savoir si la borne tient, c'est confier la vérification au hasard. Ici, les
/// vingt-quatre heures sont éprouvées en une seconde.
final class CaptureSeedHeureTests: XCTestCase {

    private let calendrier = Calendar.current

    private func a(_ heure: Int, _ minute: Int = 0) -> Date {
        // Une date FIXE : un test ancré sur l'heure courante finirait par ne plus éprouver le
        // cas qu'il vise, et par échouer tout seul un jour de changement d'heure.
        var morceaux = DateComponents()
        morceaux.year = 2026; morceaux.month = 11; morceaux.day = 8
        morceaux.hour = heure; morceaux.minute = minute
        return calendrier.date(from: morceaux)!
    }

    /// LE CAS QUI JUSTIFIE TOUT CE FICHIER.
    func testAvantCinqHeuresLaPoseResteAujourdHui() {
        for heure in 0..<5 {
            let maintenant = a(heure, 30)
            let pose = CaptureSeed.poseDeLaConversation(maintenant)
            XCTAssertEqual(calendrier.startOfDay(for: pose),
                           calendrier.startOfDay(for: maintenant),
                           "à \(heure) h 30, le message tombe un autre jour")
            XCTAssertLessThanOrEqual(pose, maintenant, "le message est dans le futur")
        }
    }

    /// Et à toute heure, pas seulement sur les cinq qui cassent.
    func testLesVingtQuatreHeuresTombentAujourdHui() {
        for heure in 0..<24 {
            let maintenant = a(heure, 17)
            let pose = CaptureSeed.poseDeLaConversation(maintenant)
            XCTAssertEqual(calendrier.startOfDay(for: pose),
                           calendrier.startOfDay(for: maintenant),
                           "à \(heure) h 17, le message tombe un autre jour")
        }
    }

    /// Passé 05 h 00, la borne ne doit RIEN faire : le message garde ses cinq heures d'écart,
    /// qui sont ce qui le fait ressembler à une vraie conversation plutôt qu'à l'instant présent.
    func testApresCinqHeuresLeReculDeCinqHeuresEstIntact() {
        for heure in 5..<24 {
            let maintenant = a(heure, 30)
            let pose = CaptureSeed.poseDeLaConversation(maintenant)
            XCTAssertEqual(pose.timeIntervalSince(maintenant), -3600.0 * 5, accuracy: 1.0,
                           "à \(heure) h 30, le recul de cinq heures a été raboté")
        }
    }

    /// À minuit pile, la pose EST minuit — pas une seconde avant.
    func testAMinuitLaPoseEstLeDebutDuJour() {
        let minuit = a(0, 0)
        XCTAssertEqual(CaptureSeed.poseDeLaConversation(minuit), calendrier.startOfDay(for: minuit))
    }

    // MARK: « N sorties aujourd'hui », et le recul qui changeait de jour

    /// LE DEUXIÈME ÉCART ENTRE LES RUNS 160 ET 162, sur la même image que les badges.
    ///
    /// Les trois activités d'amies sont posées 3 h, 9 h et 22 h en arrière, et `ProfileView` en
    /// compte celles du jour. « Il y a 22 h » est HIER à 6 h du matin et AUJOURD'HUI à 23 h : la
    /// carte disait « 2 sorties aujourd'hui » ou « 3 » selon l'heure de la machine.
    func testLesTroisActivitesDAmiesTombentToujoursAujourdHui() {
        for heure in 0..<24 {
            let maintenant = a(heure, 26)
            for recul in [3, 9, 22] {
                let pose = CaptureSeed.poseDUneActiviteDuJour(maintenant, ilYA: recul)
                XCTAssertEqual(calendrier.startOfDay(for: pose),
                               calendrier.startOfDay(for: maintenant),
                               "à \(heure) h 26, l'activité d'il y a \(recul) h tombe un autre jour")
                XCTAssertLessThanOrEqual(pose, maintenant, "l'activité est dans le futur")
            }
        }
    }

    /// Et quand le recul tient dans la journée, il n'est PAS raboté : c'est ce qui fait que le
    /// fil ressemble à un fil, avec des « il y a 3 h » plutôt que trois fois la même minute.
    func testUnReculQuiTientDansLaJourneeEstIntact() {
        let maintenant = a(23, 0)
        for recul in [3, 9, 22] {
            XCTAssertEqual(CaptureSeed.poseDUneActiviteDuJour(maintenant, ilYA: recul)
                            .timeIntervalSince(maintenant),
                           -3600.0 * Double(recul), accuracy: 1.0,
                           "à 23 h, le recul de \(recul) h a été raboté sans raison")
        }
    }

    // MARK: L'historique, et les deux badges qui se lisent à l'heure

    /// LE DÉFAUT QUI A FAIT ÉCRIRE CES CAS, ET LA TROISIÈME FOIS QU'IL REVIENT.
    ///
    /// L'historique était planté à `maintenant - N jours`, donc à l'HEURE de la campagne.
    /// `ClubBadgeEngine` lit cette heure : avant 7 h c'est « Lève-tôt », à partir de 21 h c'est
    /// « Course de nuit ». Les runs 160 (18 h) et 162 (22 h) ont rendu « 6 sur 16 » et
    /// « 7 sur 16 » pour le même code, sur neuf images.
    ///
    /// Aucune heure de campagne ne doit plus allumer l'un de ces deux badges.
    func testAucuneSortieNeTombeAvantSeptHeuresNiApresVingtEtUne() {
        for heure in 0..<24 {
            for sortie in CaptureSeed.historique(maintenant: a(heure, 43)) {
                let h = calendrier.component(.hour, from: sortie.date)
                XCTAssertGreaterThanOrEqual(h, 7, "campagne à \(heure) h : une sortie à \(h) h allume « Lève-tôt »")
                XCTAssertLessThan(h, 21, "campagne à \(heure) h : une sortie à \(h) h allume « Course de nuit »")
            }
        }
    }

    /// Et plus largement : l'heure de la campagne ne doit changer AUCUNE heure de l'historique.
    /// Le cas précédent ne tient que les deux bornes ; celui-ci tient la reproductibilité.
    func testLHeureDeLaCampagneNeChangeAucuneHeureDeLHistorique() {
        let tot = CaptureSeed.historique(maintenant: a(3, 12)).map {
            calendrier.dateComponents([.hour, .minute], from: $0.date)
        }
        let tard = CaptureSeed.historique(maintenant: a(22, 51)).map {
            calendrier.dateComponents([.hour, .minute], from: $0.date)
        }
        XCTAssertEqual(tot, tard, "l'historique hérite encore de l'heure de la campagne")
        XCTAssertEqual(tot.count, 16, "l'historique ne compte plus seize sorties")
    }

    /// Le JOUR, lui, doit continuer à suivre la campagne : une capture prise dans six mois
    /// montre un historique récent, pas un historique de six mois.
    func testLeJourSuitToujoursLaCampagne() {
        let sorties = CaptureSeed.historique(maintenant: a(14, 0))
        let plusRecente = sorties.map(\.date).max()!
        let ecart = calendrier.dateComponents([.day], from: plusRecente, to: a(14, 0)).day ?? -1
        XCTAssertEqual(ecart, 2, "la sortie la plus récente n'est plus à deux jours de la campagne")
    }

    /// Les heures posées sont plausibles, et chacune dit quelque chose : la sortie longue le
    /// matin, le fractionné le soir comme une séance de club. Un jour où quelqu'un ajoutera un
    /// type de séance, ce cas lui rappellera que l'heure se décide.
    func testChaqueTypeDeSeanceAUneHeurePlausible() {
        for kind in SessionKind.allCases {
            let h = CaptureSeed.heureDeLaSortie(kind)
            XCTAssertTrue((7..<21).contains(h), "\(kind) est posée à \(h) h")
        }
    }

    /// Le message du coach arrive APRÈS la question : la réponse est posée 40 secondes plus tard
    /// (voir `conversation`), et une borne qui écraserait la pose sans toucher à ce décalage
    /// inverserait la conversation. Ici on vérifie seulement que la pose laisse la place.
    func testLaPoseLaisseLaPlaceALaReponse() {
        for heure in 0..<24 {
            let maintenant = a(heure, 0)
            let pose = CaptureSeed.poseDeLaConversation(maintenant)
            XCTAssertEqual(calendrier.startOfDay(for: pose.addingTimeInterval(40)),
                           calendrier.startOfDay(for: maintenant),
                           "à \(heure) h, la réponse du coach tombe un autre jour que la question")
        }
    }

    // MARK: - L'HORLOGE FIGÉE DE LA DÉMONSTRATION
    //
    // Même famille de défaut que ci-dessus, et même raison de l'éprouver ici : ce qui casse
    // dépend du JOUR où la campagne tourne, et une campagne tombe le jour où quelqu'un pousse.
    // Deux jours sur sept, l'accueil montrait « 0,0 / 24 km » — une app qui paraît vide sur la
    // fiche App Store. Les sept jours sont éprouvés en une seconde.

    /// Une date fixe au jour et à l'heure voulus. Le 16 novembre 2026 est un lundi.
    private func le(_ jour: Int, _ heure: Int) -> Date {
        var m = DateComponents()
        m.year = 2026; m.month = 11; m.day = jour; m.hour = heure; m.minute = 23
        return calendrier.date(from: m)!
    }

    /// QUEL QUE SOIT LE JOUR ET L'HEURE, C'EST UN DIMANCHE À 18 HEURES.
    func testLHorlogeDeLaDemonstrationTombeToujoursUnDimancheASoir() {
        for jour in 16...29 {            // deux semaines pleines, lundi à dimanche
            for heure in [0, 7, 12, 17, 18, 19, 23] {
                let fige = CaptureSeed.maintenantDeLaDemonstration(le(jour, heure), calendrier: calendrier)
                let m = calendrier.dateComponents([.weekday, .hour, .minute, .second], from: fige)
                XCTAssertEqual(m.weekday, 1, "le \(jour) à \(heure) h, ce n'est pas un dimanche")
                XCTAssertEqual(m.hour, 18, "le \(jour) à \(heure) h, il n'est pas 18 h")
                XCTAssertEqual(m.minute, 0)
                XCTAssertEqual(m.second, 0)
            }
        }
    }

    /// ET JAMAIS DANS LE FUTUR — sinon la démonstration montrerait des sorties pas encore
    /// courues, ce qui est la seule chose que cette app ne doit jamais faire.
    func testLHorlogeDeLaDemonstrationNEstJamaisDansLeFutur() {
        for jour in 16...29 {
            for heure in 0..<24 {
                let horloge = le(jour, heure)
                XCTAssertLessThanOrEqual(
                    CaptureSeed.maintenantDeLaDemonstration(horloge, calendrier: calendrier),
                    horloge, "le \(jour) à \(heure) h, l'horloge figée est dans le futur")
            }
        }
    }

    /// LE DIMANCHE MÊME, AVANT 18 HEURES, ON RECULE D'UNE SEMAINE.
    ///
    /// C'est le seul cas où « le dernier dimanche » n'est pas aujourd'hui, et c'est celui qu'un
    /// `nextDate` mal orienté rendrait dans le futur.
    func testLeDimancheMatinOnPrendCeluiDAvant() {
        let dimancheMatin = le(22, 10)       // 22 novembre 2026, un dimanche
        let fige = CaptureSeed.maintenantDeLaDemonstration(dimancheMatin, calendrier: calendrier)
        XCTAssertEqual(calendrier.dateComponents([.day], from: fige).day, 15,
                       "un dimanche matin, on doit reculer au dimanche précédent")

        let dimancheSoir = le(22, 20)
        let fige2 = CaptureSeed.maintenantDeLaDemonstration(dimancheSoir, calendrier: calendrier)
        XCTAssertEqual(calendrier.dateComponents([.day], from: fige2).day, 22,
                       "un dimanche soir, c'est celui du jour")
    }

    /// CE QUE TOUT CECI PROTÈGE VRAIMENT : LA VITRINE N'EST JAMAIS VIDE.
    ///
    /// Les trois cas ci-dessus décrivent le MOYEN ; celui-ci décrit la fin. Quel que soit le jour
    /// où la campagne tourne, l'accueil ne montre jamais « 0,0 / 24 km » sur la fiche App Store.
    ///
    /// # CE CAS A DÉJÀ PASSÉ PENDANT QUE L'ÉCRAN ÉTAIT VIDE, ET VOICI POURQUOI
    ///
    /// Sa première version REFAISAIT le filtre de la semaine à la main : elle prenait le début de
    /// semaine de l'instant figé et comptait les sorties entre ce début et lui. Évidemment vert —
    /// elle mesurait la semaine que la graine venait de remplir.
    ///
    /// L'écran, lui, ne fait pas ça. Il appelle `SemaineComparable.kilometres`, dont le paramètre
    /// `maintenant` valait `.now` : la semaine affichée était celle du calendrier RÉEL, pas celle
    /// du dimanche figé. Un lundi, les deux ne se recouvrent pas du tout — et la campagne 214 a
    /// livré une fiche à « 0,0 / 24 km » avec ce cas au vert.
    ///
    /// Il APPELLE donc maintenant la fonction que l'écran appelle, avec l'instant que l'écran
    /// utilise. Un banc qui refait le travail au lieu de l'appeler ne surveille que lui-même.
    func testLaSemaineAFFICHÉENEstJamaisVide() {
        for jour in 16...29 {
            // L'instant que l'app emploiera : `Demonstration.maintenant` rend exactement ça
            // quand la démonstration tourne.
            let fige = Demonstration.instantFige(le(jour, 11), calendrier: calendrier)
            let sorties = CaptureSeed.historique(maintenant: fige)
            let semaine = SemaineComparable.kilometres(sorties, maintenant: fige,
                                                       calendar: calendrier)
            XCTAssertGreaterThan(semaine.cette, 20,
                "le \(jour), l'accueil afficherait \(semaine.cette) km cette semaine")
        }
    }

    /// LA GRAINE SURVIT À LA REMISE À ZÉRO DU JOUR.
    ///
    /// `refreshProgramForCurrentDate`, appelée dès que la scène devient active, passe par
    /// `resetDailyGoalsIfNewDay` : si `lastDailyResetDay` n'est pas « aujourd'hui », elle remet
    /// les pas, les calories et la sortie du jour à ZÉRO.
    ///
    /// LES DEUX ONT VÉCU DANS DEUX JOURS DIFFÉRENTS. La campagne 215 a livré « Ta journée » à
    /// 0/3, 0 kcal, 0 pas sur un profil qui venait de poser 9 240 pas : la graine écrivait le
    /// dimanche figé, la remise à zéro lisait le lundi réel.
    ///
    /// Ce cas ne compare pas deux dates — il appelle la fonction et regarde ce qu'elle laisse.
    /// Comparer les deux horloges supposerait de savoir où elles sont ; les appeler ne suppose
    /// rien, et c'est la leçon du cas précédent.
    func testLaGraineSurvitÀLaRemiseÀZéroDuJour() {
        // L'INVARIANT N'EST VRAI QUE DANS LA SCÈNE, donc le cas y entre. Hors démonstration,
        // remettre les compteurs à zéro un nouveau jour est exactement ce qu'on veut.
        Demonstration.commencer()
        defer { Demonstration.arreter() }

        let profil = UserProfile()
        // Écrit comme `CaptureSeed` l'écrit, et pas « au bon jour » décidé ici : si les deux
        // expressions divergent un jour, c'est CE cas qui doit le dire.
        profil.lastDailyResetDay = Calendar.current.startOfDay(
            for: CaptureSeed.maintenantDeLaDemonstration())
        profil.stepsToday = 9_240
        profil.activeCaloriesToday = 612
        profil.runValue = 8.4

        AdaptivePlanEngine.resetDailyGoalsIfNewDay(profil)

        XCTAssertEqual(profil.stepsToday, 9_240, "les pas de la démonstration ont été effacés")
        XCTAssertEqual(profil.activeCaloriesToday, 612, "les calories ont été effacées")
        XCTAssertEqual(profil.runValue, 8.4, "la sortie du jour a été effacée")
    }

    /// ET L'INSTANT DE L'ÉCRAN EST BIEN CELUI DE LA GRAINE.
    ///
    /// Les deux ont vécu séparément une demi-journée : `CaptureSeed` figeait le sien, l'écran
    /// gardait `.now`. Ils sont la même fonction maintenant, et ce cas le dit — sinon la
    /// prochaine personne qui déplace l'un des deux ne verra rien.
    func testLaGraineEtLÉcranPartagentLeMêmeInstant() {
        for jour in 16...29 {
            let horloge = le(jour, 11)
            XCTAssertEqual(
                CaptureSeed.maintenantDeLaDemonstration(horloge, calendrier: calendrier),
                Demonstration.instantFige(horloge, calendrier: calendrier))
        }
    }
}
