import SwiftUI

/// Ce qu'on voit à la place d'une fonctionnalité Plus quand on n'est pas abonnée.
///
/// # Montrer, pas masquer
///
/// Un verrou qui cache est un cul-de-sac : on tombe sur un vide, on ne sait pas ce qu'on rate, on
/// s'en va. Celui-ci nomme la fonctionnalité et dit ce qu'elle apporte — pas ce qu'elle fait. La
/// personne qui le lit vient d'essayer d'ouvrir cette porte précise ; c'est le seul instant où
/// elle est vraiment disposée à entendre ce qu'il y a derrière, et le pire moment pour lui servir
/// un argumentaire générique sur l'abonnement.
///
/// Il ne se présente jamais seul : chaque appelant le pose SOUS un aperçu réel de la
/// fonctionnalité — un vrai graphique estompé, une vraie réponse du coach tronquée. Voir ce qu'on
/// n'a pas vaut tous les arguments.
struct PlusLockCard: View {
    @Environment(AppState.self) private var appState
    let feature: PlusFeature
    /// Version courte, pour une section verrouillée au milieu d'un écran qui, lui, fonctionne.
    /// La version longue est pour un écran entier.
    var compact = false
    /// La ligne qui nomme ce qui reste gratuit.
    ///
    /// Elle vaut son encombrement là où l'écran ne montre RIEN d'autre que le verrou — l'assistant
    /// de nouvel objectif, le coach — parce que la personne qui vient de buter sur une porte ne
    /// sait pas, à cet instant, ce qui lui reste ouvert.
    ///
    /// Elle ne le vaut pas là où l'écran EST déjà la version gratuite en train de fonctionner.
    /// L'accueil montre au-dessus la carte pour partir courir, les anneaux du jour et la série :
    /// la phrase y décrit ce qu'on a sous les yeux, et rallonge un écran qu'on ouvre pour partir.
    var showsFreeReminder = true

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? HZCompte.ecartDuVerrouCompact : HZCompte.ecartDuVerrou) {
            Text("Haizo Plus")
                .hzTexte(.c13, .semi)
                .foregroundStyle(HZCouleur.secondaireSurSombre)

            titre

            Text(feature.pitch)
                .hzParagraphe(.c14, .medium, interligne: HZBandeauDuCoach.interligne)
                .foregroundStyle(HZCouleur.secondaireSurSombre)
                .fixedSize(horizontal: false, vertical: true)

            HZBoutonPilule(libelle: String(localized: "Découvrir Haizo Plus"),
                           hauteur: compact ? .petite : .reponse,
                           fond: HZCouleur.blanc, couleur: HZCouleur.noir) {
                appState.plusPrompt = feature
            }
            .padding(.top, HZCompte.avantLeBoutonDuVerrou)

            if showsFreeReminder {
                Text("Le suivi de tes courses, ton historique et le Club restent gratuits.")
                    .hzParagraphe(.c12, .medium, interligne: HZBandeauDuCoach.interligne)
                    .foregroundStyle(HZCouleur.secondaireSurSombre)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(compact ? HZEspace.groupe : HZEspace.marge)
        .background(HZCouleur.noir,
                    in: RoundedRectangle(cornerRadius: HZRayon.offre, style: .circular))
    }

    /// Le nom de la fonctionnalité : en grand sur un écran entier, plus bas dans une section.
    @ViewBuilder private var titre: some View {
        if compact {
            Text(feature.title)
                .hzAffichage(.section)
                .foregroundStyle(HZCouleur.blanc)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Text(feature.title)
                .hzAffichage(.titreDEcran)
                .foregroundStyle(HZCouleur.blanc)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// `buttonStyle` veut un type concret, et les deux branches d'un ternaire doivent avoir le même —
/// or deux styles de bouton sont deux types distincts. Cette boîte les ramène à un seul,
/// sans dupliquer tout le bouton dans un `if`.
struct AnyButtonStyleBox: ButtonStyle {
    private let render: (Configuration) -> AnyView
    init<S: ButtonStyle>(_ style: S) {
        render = { AnyView(style.makeBody(configuration: $0)) }
    }
    func makeBody(configuration: Configuration) -> some View { render(configuration) }
}

extension View {
    /// Estompe et neutralise un aperçu réel placé au-dessus d'un `PlusLockCard`.
    ///
    /// Le contenu reste à l'écran — c'est tout l'intérêt — mais il ne doit plus être lisible en
    /// entier ni utilisable : sinon le verrou n'en est pas un. `allowsHitTesting(false)` coupe
    /// l'interaction, `accessibilityHidden` évite que VoiceOver lise à voix haute ce que l'écran
    /// est justement en train de ne pas donner.
    @ViewBuilder
    func plusTeaser(_ locked: Bool) -> some View {
        if locked {
            self.blur(radius: HZCompte.flouDApercu)
                .opacity(HZCompte.opaciteDApercu)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        } else {
            self
        }
    }
}

/// Une section d'écran réservée à Haizo Plus.
///
/// Elle rend son contenu tel quel à une abonnée, et sinon un aperçu estompé surmontant le verrou.
/// L'aperçu est bridé en hauteur : il doit donner le goût, pas livrer la moitié du plat — et une
/// carte d'analyse de six cents points de haut, floutée, occuperait tout l'écran pour ne rien
/// apprendre.
struct PlusSection<Content: View>: View {
    @Environment(SubscriptionService.self) private var subscriptions
    let feature: PlusFeature
    /// Hauteur de l'aperçu estompé. Assez pour reconnaître un graphique, pas assez pour le lire.
    var teaserHeight: CGFloat = HZCompte.hauteurDApercu
    @ViewBuilder var content: () -> Content

    var body: some View {
        if subscriptions.unlocks(feature) {
            content()
        } else {
            VStack(spacing: HZEspace.entreCommandes) {
                content()
                    .plusTeaser(true)
                    .frame(maxHeight: teaserHeight, alignment: .top)
                    .clipped()
                // Une section verrouillée au milieu d'un écran qui fonctionne : le reste de la
                // page dit déjà ce qui est gratuit, mieux qu'une phrase.
                PlusLockCard(feature: feature, compact: true, showsFreeReminder: false)
            }
        }
    }
}
