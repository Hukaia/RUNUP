import SwiftUI
import StoreKit
import Foundation

/// L'écran d'abonnement, affiché à la fin de l'inscription et tant que l'abonnement n'est pas
/// actif.
///
/// # Ce que la validation App Store exige ici
///
/// Un paywall incomplet est un motif de rejet fréquent (guideline 3.1.2), et la liste est courte
/// mais stricte : le nom de l'abonnement, sa DURÉE, son prix, ce qu'il contient, un lien vers les
/// conditions d'utilisation, un lien vers la politique de confidentialité, et un bouton de
/// restauration. Tout est là, et rien n'y est décoratif — retirer un seul de ces éléments pour
/// faire plus propre, c'est un aller-retour de deux semaines avec la revue.
struct PaywallView: View {
    @Environment(AppState.self) private var appState
    var subscriptions: SubscriptionService
    var highlighted: PlusFeature?
    var onClose: (() -> Void)?

    @State private var selected: Product?

    private let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    private let privacyURL = Liens.confidentialite

    /// Trois bénéfices, pas cinq : ce qu'on achète en une ligne chacun. Le coach à la voix et le plan calé
    /// sur une course restent dans l'offre ; ils se découvrent quand on les rencontre.
    ///
    /// CHAQUE LIGNE EST VRAIE AU MOT PRÈS, parce que c'est ce qu'on lit avant de payer. Deux ne
    /// l'étaient pas. « Le coach, sans limite de messages » : le serveur plafonne à 250 demandes
    /// par jour et 40 messages par conversation (`api/coach.js`). « Allure, charge d'entraînement,
    /// records, prédictions » : l'allure et les records sont gratuits, seules la charge et les
    /// prédictions sont dans l'offre (`StatsView`).
    private var avantages: [String] {
        [String(localized: "Un programme qui s'adapte à ta forme chaque semaine"),
         String(localized: "Un coach qui connaît ton objectif et ton historique"),
         String(localized: "Ta charge d'entraînement et tes temps possibles en course")]
    }

    /// Les jours offerts de la formule CHOISIE. La pilule prenait le plus grand essai des deux
    /// formules : elle pouvait annoncer des jours que la formule sélectionnée n'offre pas.
    private var joursOfferts: Int? {
        guard let selected else { return subscriptions.joursDEssaiAnnoncables }
        return subscriptions.joursDEssai(pour: selected)
    }

    /// Tout ce que l'App Store exige tient sans défilement : la formule, le prix, la durée, le
    /// renouvellement, « Restaurer », les conditions. Le défilement n'existe que pour le gros texte, où
    /// rien ne tient de toute façon.
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                entete
                avantagesList.padding(.top, HZPaywall.sousLeTitre)
                formules.padding(.top, HZPaywall.sousLesAvantages)
                achat.padding(.top, HZPaywall.sousLesFormules)
            }
            .padding(.horizontal, HZEspace.marge)
            .padding(.top, HZPaywall.hautDePage)
            .padding(.bottom, HZPaywall.basDePage)
        }
        .scrollIndicators(.hidden)
        .foregroundStyle(HZCouleur.blanc)
        .background(HZCouleur.noir.ignoresSafeArea())
        // Noir plein écran : l'heure grise de la barre d'état s'y perdrait, comme sur les pages.
        .statusBarHidden()
        .task {
            await subscriptions.start()
            if selected == nil { selected = subscriptions.products.first }
            Analytics.shared.track(.paywallShown, [
                "products": .int(subscriptions.products.count),
                "origin": .string(highlighted?.rawValue ?? (onClose == nil ? "onboarding" : "settings")),
            ])
            if subscriptions.products.isEmpty {
                Analytics.shared.track(.paywallProductsUnavailable)
            }
        }
        .onChange(of: subscriptions.products.map(\.id)) { _, _ in
            if selected == nil { selected = subscriptions.products.first }
        }
    }

    // MARK: - Le haut

    private var entete: some View {
        VStack(alignment: .leading, spacing: HZEspace.entreCommandes) {
            HStack {
                if let jours = joursOfferts {
                    HZPilule(texte: Pluriel.choisir(jours,
                                                    String(localized: "\(jours) jour offert"),
                                                    String(localized: "\(jours) jours offerts")),
                             style: .etiquetteGrasse, fond: HZCouleur.accent, couleur: HZCouleur.encreSurAccent)
                }
                Spacer(minLength: 0)
                if let onClose {
                    HZBoutonRond(dessin: .fermer, nom: String(localized: "Fermer"), diametre: .outil,
                                 fond: HZCouleur.surfaceSombre, cote: HZHub.coteDeLaCroix,
                                 trait: HZHub.traitDeLaCroix, action: onClose)
                }
            }
            .frame(minHeight: HZDiametre.outil.rawValue)
            if let highlighted {
                Text("Haizo Plus").hzTexte(.c15, .semi).foregroundStyle(HZCouleur.secondaireSurSombre)
                Text(highlighted.title)
                    .hzAffichage(.titreDeReglages)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Haizo Plus")
                    .hzAffichage(.heros)
                    .lineLimit(1)
                    .minimumScaleFactor(HZPaywall.reductionDuTitre)
            }
            Text(highlighted?.pitch ?? String(localized: "Ton programme, ton coach et tes stats. Sans rien qui manque."))
                .hzParagraphe(.c15, .medium, interligne: HZBandeauDuCoach.interligne)
                .foregroundStyle(HZCouleur.secondaireSurSombre)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Les trois bénéfices

    private var avantagesList: some View {
        VStack(alignment: .leading, spacing: HZEspace.entreCommandes) {
            ForEach(avantages, id: \.self) { texte in
                HStack(alignment: .top, spacing: HZEspace.entreTuiles) {
                    HZIcone(dessin: .coche, cote: HZPaywall.coteDeLaCoche, trait: HZHub.traitDeLIcone,
                            couleur: HZCouleur.noir)
                        .frame(width: HZPaywall.disqueDeLaCoche, height: HZPaywall.disqueDeLaCoche)
                        .background(HZCouleur.blanc, in: Circle())
                    Text(texte)
                        .hzParagraphe(.c15, .semi, interligne: HZBandeauDuCoach.interligne)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
            }
        }
    }

    // MARK: - Les deux formules

    @ViewBuilder private var formules: some View {
        if subscriptions.products.isEmpty && (subscriptions.loadFailed || subscriptions.productsUnavailable) {
            // L'ÉCHEC SE DIT. Sans réseau, ou si l'App Store ne renvoie aucune formule, l'écran
            // restait sur « Chargement des formules… » indéfiniment, avec un bouton d'achat éteint
            // et aucune explication.
            VStack(alignment: .leading, spacing: HZEspace.entreCommandes) {
                Text(subscriptions.loadFailed
                     ? String(localized: "Impossible de charger les formules pour le moment.")
                     : String(localized: "Les formules ne sont pas disponibles pour le moment."))
                    .hzTexte(.c14, .semi)
                    .foregroundStyle(HZCouleur.blanc)
                    .fixedSize(horizontal: false, vertical: true)
                HZBoutonPilule(libelle: String(localized: "Réessayer"), hauteur: .petite,
                               fond: HZCouleur.blanc, couleur: HZCouleur.noir) {
                    Task {
                        await subscriptions.loadProducts()
                        if selected == nil { selected = subscriptions.products.first }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else if subscriptions.products.isEmpty {
            HStack(spacing: HZEspace.entreCommandes) {
                ProgressView().tint(HZCouleur.blanc)
                Text("Chargement des formules…")
                    .hzTexte(.c13, .semi)
                    .foregroundStyle(HZCouleur.secondaireSurSombre)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            HStack(alignment: .top, spacing: HZEspace.entreTuiles) {
                ForEach(subscriptions.products, id: \.id) { product in
                    formule(product)
                }
            }
        }
    }

    /// Une formule : sa période, son prix en grand, ce qu'il couvre. La choisie est en blanc.
    private func formule(_ product: Product) -> some View {
        let choisie = selected?.id == product.id
        let annuelle = product.id == SubscriptionService.ProductID.yearly
        return Button(action: {
            if selected?.id != product.id {
                Analytics.shared.track(.paywallPlanSelected, ["plan": .string(annuelle ? "yearly" : "monthly")])
            }
            selected = product
        }) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: HZEspace.entrePilules) {
                    Text(annuelle ? "Annuel" : "Mensuel").hzTexte(.c14, .gras)
                    if annuelle, let economie = yearlySavingPercent {
                        HZPilule(texte: "−" + (Double(economie) / HZHub.centPourcent).formatted(.percent),
                                 style: .etiquetteGrasse, fond: HZCouleur.accent, couleur: HZCouleur.encreSurAccent)
                    }
                }
                .foregroundStyle(choisie ? HZCouleur.encre : HZCouleur.blanc)
                Text(product.displayPrice)
                    .hzAffichage(.chiffreDeTuile)
                    .foregroundStyle(choisie ? HZCouleur.encre : HZCouleur.blanc)
                    .lineLimit(1)
                    .minimumScaleFactor(HZPaywall.reductionDuPrix)
                    .padding(.top, HZEspace.entrePilules)
                Text(annuelle ? "par an" : "par mois")
                    .hzTexte(.c13, .medium)
                    .foregroundStyle(choisie ? HZCouleur.secondaireSurClair : HZCouleur.secondaireSurSombre)
                Text(annuelle ? (yearlyPerMonth.map { String(localized: "soit \($0)/mois") } ?? " ") : " ")
                    .hzTexte(.c13, .medium)
                    .foregroundStyle(choisie ? HZCouleur.secondaireSurClair : HZCouleur.secondaireSurSombre)
                    .lineLimit(1)
                    .minimumScaleFactor(HZPaywall.reductionDuPrix)
            }
            .padding(HZEspace.tuile)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(choisie ? HZCouleur.blanc : HZCouleur.surfaceSombre,
                        in: RoundedRectangle(cornerRadius: HZRayon.tuile, style: .circular))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(choisie ? [.isButton, .isSelected] : .isButton)
    }

    private var yearlySavingPercent: Int? {
        guard let year = subscriptions.products.first(where: { $0.id == SubscriptionService.ProductID.yearly }),
              let month = subscriptions.products.first(where: { $0.id == SubscriptionService.ProductID.monthly })
        else { return nil }
        let monthly = NSDecimalNumber(decimal: month.price).doubleValue
        let yearly = NSDecimalNumber(decimal: year.price).doubleValue
        let full = monthly * HZPaywall.moisParAn
        guard full > 0, yearly < full else { return nil }
        return Int(((full - yearly) / full * HZHub.centPourcent).rounded())
    }

    private var yearlyPerMonth: String? {
        guard let year = subscriptions.products.first(where: { $0.id == SubscriptionService.ProductID.yearly })
        else { return nil }
        return (year.price / Decimal(HZPaywall.moisParAnEntier)).formatted(year.priceFormatStyle)
    }

    // MARK: - L'achat, et ce que l'App Store exige à côté

    private var achat: some View {
        VStack(spacing: HZEspace.entreCommandes) {
            // DÉJÀ ABONNÉE : on ne propose pas de s'abonner. « Voir l'offre », dans les Réglages
            // d'un compte abonné, ouvrait cet écran avec « S'abonner » comme si de rien n'était.
            if subscriptions.isSubscribed == true {
                Text("Ton abonnement Haizo Plus est actif.")
                    .hzTexte(.c16, .semi)
                    .multilineTextAlignment(.center)
                Link(destination: Liens.abonnements) {
                    Text("Gérer mon abonnement")
                        .hzTexte(HZHauteurDeBouton.grande.corps, .gras)
                        .foregroundStyle(HZCouleur.noir)
                        .frame(maxWidth: .infinity)
                        .frame(height: HZHauteurDeBouton.grande.rawValue)
                        .background(HZCouleur.blanc, in: Capsule())
                        .contentShape(Capsule())
                }
            } else {
            if let line = priceLine {
                Text(line)
                    .hzTexte(.c14, .semi)
                    .multilineTextAlignment(.center)
            }
            Button(action: { Task { await buy() } }) {
                Group {
                    if subscriptions.isPurchasing {
                        ProgressView().tint(HZCouleur.noir)
                    } else {
                        Text(libelleDAchat)
                            .hzTexte(HZHauteurDeBouton.grande.corps, .gras)
                            .foregroundStyle(HZCouleur.noir)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: HZHauteurDeBouton.grande.rawValue)
                .background(HZCouleur.blanc, in: Capsule())
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(selected == nil || subscriptions.isPurchasing)

            Text("Renouvellement automatique, résiliable à tout moment.")
                .hzTexte(.c12, .medium)
                .foregroundStyle(HZCouleur.secondaireSurSombre)
            }

            HStack(spacing: HZEspace.entreTuiles) {
                Button("Restaurer mes achats") { Task { await restore() } }
                Text(verbatim: "·")
                OfferCodeButton(subscriptions: subscriptions, onOutcome: announce) {
                    Text("J'ai un code promo")
                }
            }
            .hzTexte(.c13, .semi)
            .foregroundStyle(HZCouleur.secondaireSurSombre)
            .frame(minHeight: HZBoutonRond.zoneTactile)

            HStack(spacing: HZEspace.entreTuiles) {
                Link("Conditions d'utilisation", destination: termsURL)
                Text(verbatim: "·")
                Link("Confidentialité", destination: privacyURL)
            }
            .hzTexte(.c13, .semi)
            .foregroundStyle(HZCouleur.secondaireSurSombre)
            .frame(minHeight: HZBoutonRond.zoneTactile)
        }
        .frame(maxWidth: .infinity)
    }

    private var priceLine: String? {
        guard let product = selected else { return nil }
        let isYearly = product.id == SubscriptionService.ProductID.yearly
        guard let jours = subscriptions.joursDEssai(pour: product) else {
            return isYearly
                ? String(localized: "\(product.displayPrice) par an")
                : String(localized: "\(product.displayPrice) par mois")
        }
        return isYearly
            ? String(localized: "\(jours) jours gratuits, puis \(product.displayPrice) par an")
            : String(localized: "\(jours) jours gratuits, puis \(product.displayPrice) par mois")
    }

    private var libelleDAchat: String {
        guard let product = selected, let jours = subscriptions.joursDEssai(pour: product) else {
            return String(localized: "S'abonner")
        }
        return Pluriel.choisir(jours,
                               String(localized: "Commencer le jour gratuit"),
                               String(localized: "Commencer les \(jours) jours gratuits"))
    }

    private func buy() async {
        guard let product = selected else { return }
        let plan: AnalyticsValue = .string(product.id == SubscriptionService.ProductID.yearly ? "yearly" : "monthly")
        Analytics.shared.track(.purchaseStarted, ["plan": plan])
        let issue = await subscriptions.purchase(product)
        switch issue {
        case .subscribed:
            Analytics.shared.track(.purchaseCompleted, ["plan": plan])
        // UN ACHAT ABOUTI, LUI AUSSI : Apple a signé la transaction, le droit d'accès n'a
        // simplement pas fini d'arriver. Le compter avec les échecs gonflerait un taux d'échec
        // qui pousserait à corriger du code qui marche. Il est distingué par `unlock`, pour qu'on
        // puisse mesurer combien de fois l'attente de trois secondes n'a pas suffi.
        case .purchasedAwaitingUnlock:
            Analytics.shared.track(.purchaseCompleted, ["plan": plan, "unlock": .string("deferred")])
        case .pending:
            // « En attente » n'est ni un succès ni un échec — typiquement Demander à acheter, sur
            // un compte enfant. Le ranger avec l'un des deux fausserait les deux.
            Analytics.shared.track(.purchaseFailed, ["plan": plan, "reason": .string("pending")])
        case .failed:
            Analytics.shared.track(.purchaseFailed, ["plan": plan, "reason": .string("failed")])
        case .cancelled:
            // Distinct d'un échec, et c'est tout l'intérêt : ici la machinerie a parfaitement
            // fonctionné, la personne a lu le prix et a dit non. Un taux d'annulation élevé se
            // corrige sur l'offre ; un taux d'échec élevé se corrige dans le code.
            Analytics.shared.track(.purchaseCancelled, ["plan": plan])
        }
        // Le message et la fermeture viennent de l'issue, pas d'un `if` par cas : c'est en
        // écrivant la phrase à la main dans chaque branche qu'on finit par en annoncer une fausse.
        if let message = issue.message { appState.toast(message) }
        if issue.ferme { onClose?() }
    }

    /// Le résultat d'un code promo, dit seulement quand il y a quelque chose à dire.
    private func announce(_ outcome: OfferCodeOutcome) {
        if outcome == .unlocked { Analytics.shared.track(.purchaseCompleted, ["plan": .string("offer-code")]) }
        if let message = outcome.message { appState.toast(message) }
        if outcome == .unlocked { onClose?() }
    }

    private func restore() async {
        Analytics.shared.track(.restoreTapped)
        // Le résultat est toujours annoncé, y compris quand ça marche : un bouton qui ne répond
        // rien laisse croire qu'il n'a rien fait, et fait retaper.
        appState.toast(await subscriptions.restore().message)
    }
}
