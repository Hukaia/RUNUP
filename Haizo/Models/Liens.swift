import Foundation

/// Les pages publiées de Haizo, déclarées une fois.
///
/// # NEUF COPIES, ET UN RENOMMAGE QUI LES A TOUTES CASSÉES
///
/// L'adresse de la politique de confidentialité était écrite en dur à neuf endroits : la fiche App
/// Store dans ses trois langues, le script qui l'envoie à Apple, la page d'assistance, la page de
/// club, le paywall de l'app. Le dépôt a changé de propriétaire, GitHub Pages a suivi — et les neuf
/// copies pointaient toujours vers l'ancien domaine, qui répond 404.
///
/// Conséquences, aucune bruyante : la fiche App Store annonçait une politique de confidentialité
/// introuvable, ce qu'Apple exige de fournir ; et le lien du paywall, dans l'app livrée, ouvrait
/// une page d'erreur au moment précis où quelqu'un s'apprête à payer.
///
/// Un renommage est maintenant UNE ligne ici, plus une dans `ci_scripts/liens.py`, et
/// `check_liens.py` exige que tous les porteurs s'accordent — y compris le HTML et le Markdown, qui
/// ne peuvent pas importer une constante mais peuvent être relus.
enum Liens {
    /// La racine des pages publiées. Elle suit le PROPRIÉTAIRE du dépôt, pas son nom : un
    /// changement de compte la déplace, et c'est exactement ce qui est arrivé.
    static let base = "https://hukaia.github.io/RUNUP"

    static let confidentialite = URL(string: "\(base)/privacy.html")!
    static let assistance = URL(string: "\(base)/support.html")!

    /// La page d'Apple où l'on gère, donc où l'on résilie, un abonnement.
    static let abonnements = URL(string: "https://apps.apple.com/account/subscriptions")!

    /// La fiche App Store de Haizo : le même identifiant que `public/club.html`.
    static let appStore = URL(string: "https://apps.apple.com/app/id6790719663")!

    /// Ce qu'on partage pour faire entrer quelqu'un dans SON club : le lien du club, que l'app
    /// ouvre quand elle est installée et que la page web accueille sinon (`public/club.html`).
    /// Déclaré une fois : la carte « seule dans son club » et le bouton « Inviter » du fil disent
    /// la même chose.
    static func invitationAuClub(nom: String, id: String) -> String {
        String(localized: "Rejoins mon club \(nom) sur Haizo : https://runup-nu.vercel.app/club/\(id)")
    }

    /// Ce que « Inviter un ami » partage. Le texte portait `runup-nu.vercel.app`, la racine du
    /// serveur, qui ne sert aucune page et répond 404 : l'invitation menait à une erreur. Qui
    /// reçoit ce message n'a pas l'app, donc la fiche App Store est la seule destination utile.
    static var invitation: String {
        String(localized: "Rejoins-moi sur Haizo, mon appli de coaching running : \(appStore.absoluteString)")
    }
}
