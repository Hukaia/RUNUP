import Foundation

/// Le mode démonstration, celui des captures d'écran de l'App Store.
///
/// Six écrans sont photographiés par `HaizoUITests.CapturesUITests` dans un simulateur, sur un
/// profil posé de toutes pièces par `CaptureSeed`. Un simulateur n'a ni Santé, ni session, ni
/// abonnement, ni serveur en face — et chacun de ces manques se voyait sur l'image :
///
///   — « Trois objectifs par jour » montrait trois zéros ;
///   — « Un plan qui s'adapte » montrait un graphique FLOUTÉ derrière un verrou Haizo Plus ;
///   — « Tu ne cours jamais seule » montrait un bouton SE CONNECTER sur un écran vide.
///
/// Trois accroches sur six affirmaient exactement ce que l'image démentait. Ce drapeau permet
/// aux services concernés de répondre ce qu'ils répondraient à quelqu'un de réellement
/// installé, sans réseau et sans rien inventer que le profil de démonstration ne contienne.
///
/// # CE QU'IL NE PEUT PAS DEVENIR DANS LA CONSTRUCTION ENVOYÉE À L'APP STORE
///
/// `commencer()` n'existe qu'en débogage. La construction de l'App Store ne contient donc PAS
/// une ligne de code capable de mettre ce drapeau à vrai : il y est une constante fausse, et
/// aucun argument de lancement, aucun réglage, aucune réponse de serveur ne peut l'y réveiller.
///
/// Le drapeau lui-même, lui, est compilé partout. C'est délibéré : le mettre sous `#if DEBUG`
/// obligerait chacun des endroits qui le consultent à porter sa propre condition de
/// compilation, et c'est précisément le genre de garde qu'on finit par oublier d'un côté — avec
/// pour seul symptôme un écran qui ne compile plus que dans une configuration sur deux.
enum Demonstration {
    /// `nonisolated(unsafe)` : écrit une seule fois, au tout début du lancement, avant que le
    /// moindre autre fil n'existe. Les lectures qui suivent ne voient jamais qu'une constante.
    nonisolated(unsafe) private(set) static var enCours = false

    /// ON PHOTOGRAPHIE L'APP TELLE QUE LA VOIT QUI N'A PAS SOUSCRIT.
    ///
    /// `SubscriptionService.unlocks` ouvre TOUT en démonstration, et pour une bonne raison, qui
    /// est écrite là-bas : « une capture de l'App Store doit montrer le produit, pas son verrou. »
    /// Elle reste vraie pour les six images livrées à Apple.
    ///
    /// Mais elle rendait un écran IMPHOTOGRAPHIABLE. L'accueil de qui n'a pas souscrit — la carte
    /// `PlusLockCard` en dernière position, pas de carte de programme, pas la ligne du coach —
    /// n'existait sur aucune image, et `HomeView` porte pourtant quatre branches qui ne se
    /// dessinent que dans cet état. Quatre branches jugées de mémoire depuis qu'elles existent.
    ///
    /// Ce drapeau RENVERSE la réponse, et seulement en démonstration. Il ne touche ni le droit
    /// d'accès réel, qui vit dans `Entitlement` et se teste là-bas, ni les captures de la fiche,
    /// qui ne le posent pas.
    ///
    /// POURQUOI UN COURT-CIRCUIT ET PAS `Entitlement` AVEC LES VALEURS D'UN NON-ABONNÉ. Parce
    /// qu'un simulateur n'a pas StoreKit : `products` y est vide, donc `canSell` est faux, et
    /// `Entitlement.unlocks` ouvre tout quand on n'a rien à vendre. Passer par lui rendrait
    /// exactement l'inverse de ce qu'on demande. On affirme donc ici l'état « non-abonnée à qui
    /// on peut vendre », que le simulateur est incapable de produire.
    nonisolated(unsafe) private(set) static var verrouille = false

    /// On FILME plutôt que de photographier. Voir `animationsFigees`.
    nonisolated(unsafe) private(set) static var filme = false

    /// LES ANIMATIONS SONT FIGÉES QUAND ON PHOTOGRAPHIE, PAS QUAND ON FILME.
    ///
    /// La campagne 166 a photographié `4-club.png` — une des six images livrées à Apple —
    /// PENDANT que le tracé de la sortie se dessinait : la tête lumineuse de l'animation figée au
    /// milieu du trait, et la ligne arrêtée avant sa fin. La campagne 165, à six heures d'écart,
    /// l'avait eu fini. Personne ne choisit : c'est le minutage, et c'est le hasard qui décide de
    /// ce qu'Apple reçoit.
    ///
    /// Une photo doit montrer un écran POSÉ. Un film, lui, n'a d'intérêt que par son mouvement —
    /// d'où la distinction plutôt qu'un simple « pas d'animation en démonstration ».
    ///
    /// Figer est appliqué EN UN SEUL ENDROIT, à la racine des vues, par une `transaction` qui
    /// vide l'animation de tout ce qui passe en dessous. L'app comptait 22 appels au mouvement de l'ancien système et
    /// une cinquantaine d'animations écrites à la main : les corriger une par une aurait laissé
    /// la cinquante et unième dehors sans que rien ne le dise.
    static var animationsFigees: Bool { enCours && !filme }

    /// # L'HEURE QU'IL EST, OU L'HEURE DE LA SCÈNE
    ///
    /// En démonstration, l'app ne doit pas seulement afficher les mêmes DONNÉES d'une campagne à
    /// l'autre : elle doit les afficher au même INSTANT. Sinon la graine pose ses sorties autour
    /// d'un dimanche figé pendant que l'écran, lui, demande au calendrier réel ce que contient
    /// « cette semaine » — et un lundi, la réponse est « rien ».
    ///
    /// C'est exactement ce qu'a montré la campagne 214 : la fiche App Store affichait
    /// « 0,0 / 24 km » et « ▼ 14,2 km » alors que l'horloge de la graine était figée depuis le
    /// matin. Figer la graine sans figer l'app ne fige rien : les sorties étaient dans la semaine
    /// du 9 au 15, l'app regardait celle du 16 au 22.
    ///
    /// ## CE QUE ÇA NE FIGE PAS
    ///
    /// Seules les lectures qui décident de CE QUE LA SEMAINE COURANTE CONTIENT passent par ici —
    /// `SemaineComparable.kilometres`, `AdaptivePlanEngine.currentWeekRange`, l'index du jour. Ce
    /// qu'on ÉCRIT (la date de départ d'un programme, l'instant d'un débriefing) garde l'horloge
    /// réelle : en démonstration on n'écrit rien, et une horloge figée qui se propagerait aux
    /// écritures serait un piège pour la première fonctionnalité qui en dépendrait.
    ///
    /// ## HORS DÉMONSTRATION, C'EST `.now`
    ///
    /// Le drapeau est écrit une seule fois, au lancement, et il est faux partout ailleurs. Aucun
    /// appel ne change de comportement pour une utilisatrice.
    static var maintenant: Date { enCours ? instantFige() : .now }

    /// Le dernier dimanche 18 h révolu.
    ///
    /// `weekday: 1` EST LE DIMANCHE, et ça ne dépend pas de `firstWeekday`. Les deux se confondent
    /// facilement : `firstWeekday` dit par quel jour une SEMAINE commence — lundi ici, comme le
    /// ruban — tandis que `weekday` numérote les jours du calendrier grégorien, où 1 est toujours
    /// le dimanche. Un premier jet posait `firstWeekday = 2` juste au-dessus de cette ligne, ce
    /// qui ne changeait rien et laissait croire que 1 valait lundi.
    ///
    /// LE DERNIER, et pas celui de cette semaine : un dimanche à venir serait dans le futur, et la
    /// démonstration montrerait des sorties pas encore courues.
    ///
    /// DIX-HUIT HEURES, parce que `CaptureSeed.historique` choisit l'heure d'une sortie selon son
    /// type et que l'activité du club est bornée au matin même : une campagne lancée à 23 h et une
    /// autre à 7 h ne rendraient pas les mêmes écrans. Dix-huit heures laisse la journée derrière
    /// elle.
    static func instantFige(_ horloge: Date = .now, calendrier: Calendar = .current) -> Date {
        let dimanche = DateComponents(hour: 18, minute: 0, second: 0, weekday: 1)
        return calendrier.nextDate(after: horloge, matching: dimanche,
                                   matchingPolicy: .nextTime, direction: .backward) ?? horloge
    }

    #if DEBUG
    static func commencer() { enCours = true }
    static func filmer() { filme = true }
    static func verrouiller() { verrouille = true }

    /// REFERMER L'INTERRUPTEUR, ET POURQUOI IL LE FAUT.
    ///
    /// `enCours` était écrit une seule fois, au lancement, et jamais remis — ce qui est juste
    /// pour l'app. Mais ça rendait la scène INTESTABLE : l'invariant qui compte ici — « ce que
    /// la graine écrit, la remise à zéro du jour ne l'efface pas » — n'est vrai QUE pendant une
    /// démonstration. Un cas qui ne peut pas allumer la démonstration ne peut pas le vérifier.
    ///
    /// C'est ce qui a manqué le 16 novembre : la capture « Ta journée » est partie chez Apple à
    /// 0/3, 0 kcal, 0 pas, et rien dans le dépôt ne pouvait le dire — ni le harnais, qui ne
    /// compile pas de Swift, ni les cas, qui ne pouvaient pas entrer dans la scène.
    ///
    /// `#if DEBUG` : l'app livrée n'a pas de quoi rallumer ni éteindre quoi que ce soit.
    ///
    /// `verrouille` EST REMIS AUSSI, et ce n'est pas de la symétrie décorative : un verrou qui
    /// resterait allumé verrouillerait toutes les prises suivantes de la même campagne, et
    /// l'image de la fiche App Store partirait avec un `PlusLockCard` dessus. Un cas le vérifie.
    static func arreter() { enCours = false; filme = false; verrouille = false }
    #endif
}
