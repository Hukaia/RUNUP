import SwiftUI
import SwiftData

/// "Mes chaussures" — gear/wear tracking, mirroring Strava's shoe mileage feature. Kilometers per
/// pair are always derived from `RunRecord.shoeID` (see `Shoe.totalKm`), never stored/incremented,
/// so deleting or reassigning a run can't leave a pair's total stale.
struct ShoesView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Shoe.createdAt, order: .reverse) private var shoes: [Shoe]
    @Query private var runs: [RunRecord]
    @State private var showAddShoe = false
    @State private var pendingRetire: Shoe?
    @State private var pendingDelete: Shoe?

    private var profile: UserProfile { appState.profile }
    private var activeShoes: [Shoe] { shoes.filter { $0.retiredAt == nil } }
    private var retiredShoes: [Shoe] { shoes.filter { $0.retiredAt != nil } }

    var body: some View {
        HZPage {
            hautDePage
        } contenu: {
            feuille
        }
        .sheet(isPresented: $showAddShoe) { AddShoeSheet().hzFeuille(detents: [.large]) }
        .alert(
            "Retirer cette paire ?",
            isPresented: Binding(get: { pendingRetire != nil }, set: { if !$0 { pendingRetire = nil } })
        ) {
            Button("Retirer") {
                if let shoe = pendingRetire {
                    shoe.retiredAt = .now
                    if profile.defaultShoeID == shoe.id {
                        // The nearest still-active pair becomes the new default so runs keep
                        // getting attributed instead of silently going unassigned again.
                        profile.defaultShoeID = activeShoes.first(where: { $0.id != shoe.id })?.id
                    }
                }
                pendingRetire = nil
            }
            Button("Annuler", role: .cancel) { pendingRetire = nil }
        } message: {
            Text("Elle reste dans ton historique, mais ne sera plus proposée par défaut sur tes prochaines courses.")
        }
        .alert(
            "Supprimer cette paire ?",
            isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } })
        ) {
            Button("Supprimer", role: .destructive) {
                if let shoe = pendingDelete {
                    if profile.defaultShoeID == shoe.id { profile.defaultShoeID = nil }
                    modelContext.delete(shoe)
                }
                pendingDelete = nil
            }
            Button("Annuler", role: .cancel) { pendingDelete = nil }
        } message: {
            Text("Les courses déjà enregistrées avec cette paire garderont leurs autres données, juste sans chaussure associée.")
        }
    }


    // MARK: - Le haut, sur le noir

    private var hautDePage: some View {
        VStack(alignment: .leading, spacing: 0) {
            HZCommandesDuHaut(retour: { appState.go(.profile) }) { EmptyView() }
            Text("Matériel")
                .hzTexte(.c15, .semi)
                .foregroundStyle(HZCouleur.secondaireSurSombre)
                .padding(.horizontal, HZEspace.margeDeTitre)
                .padding(.top, HZHub.sousLesCommandes)
            Text("Mes chaussures")
                .hzAffichage(.titreDEcran)
                .foregroundStyle(HZCouleur.blanc)
                .padding(.horizontal, HZEspace.margeDeTitre)
        }
    }

    // MARK: - La feuille

    private var feuille: some View {
        VStack(alignment: .leading, spacing: HZEspace.entreSections) {
            if shoes.isEmpty {
                HZPhrase(texte: String(localized: "Ajoute une paire pour suivre son usure — chaque course lui est attribuée automatiquement une fois que c'est ta paire par défaut."),
                         titre: String(localized: "Aucune paire"))
            } else {
                LazyVStack(spacing: HZEspace.entreTuiles) {
                    ForEach(activeShoes) { shoe in shoeRow(shoe) }
                }
                if !retiredShoes.isEmpty {
                    VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
                        HZTitreDeSection(titre: String(localized: "Retirées"))
                        LazyVStack(spacing: HZEspace.entreTuiles) {
                            ForEach(retiredShoes) { shoe in shoeRow(shoe) }
                        }
                    }
                }
            }
            HZBoutonPilule(libelle: String(localized: "Ajouter une paire"), etendu: true) { showAddShoe = true }
        }
    }

    /// Une paire : ses kilomètres en chiffres d'affichage sur une tuile noire, son nom, sa barre vers
    /// la limite. Toucher la ligne en fait la paire par défaut ; le menu retire ou supprime.
    private func shoeRow(_ shoe: Shoe) -> some View {
        let km = shoe.totalKm(runs: runs)
        let fraction = shoe.alertThresholdKm > 0 ? km / shoe.alertThresholdKm : 0
        let isDefault = profile.defaultShoeID == shoe.id
        let isRetired = shoe.retiredAt != nil
        let usee = fraction >= HZHub.seuilDUsure

        return HStack(spacing: HZEspace.groupe) {
            VStack(spacing: 0) {
                Text(verbatim: String(format: "%.0f", km))
                    .hzAffichage(.mesure)
                    .foregroundStyle(HZCouleur.blanc)
                    .lineLimit(1)
                    .minimumScaleFactor(HZHub.reductionDesKilometres)
                    .padding(.horizontal, HZEspace.entrePilules)
                Text(verbatim: "km")
                    .hzTexte(.c13, .semi)
                    .foregroundStyle(HZCouleur.secondaireSurSombre)
            }
            .frame(width: HZHub.cotePuceDeKm, height: HZHub.cotePuceDeKm)
            .background(HZCouleur.noir, in: RoundedRectangle(cornerRadius: HZRayon.mesure, style: .circular))
            VStack(alignment: .leading, spacing: HZEspace.entrePilules) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(shoe.name).hzTexte(.c16, .gras).foregroundStyle(HZCouleur.encre)
                    Text(LocalizedStringKey(isRetired ? "Retirée" : (isDefault ? "Paire par défaut" : "Appuie pour la définir par défaut")))
                        .hzParagraphe(.c13, .medium, interligne: HZBandeauDuCoach.interligne)
                        .foregroundStyle(HZCouleur.secondaireSurClair)
                        .fixedSize(horizontal: false, vertical: true)
                }
                HZJauge(fraction: fraction, couleur: usee ? HZCouleur.accent : HZCouleur.encre,
                        rail: HZCouleur.blanc, epaisseur: HZHub.hauteurDeLaProgression)
                VStack(alignment: .leading, spacing: 0) {
                    Text(verbatim: "/ \(String(format: "%.0f", shoe.alertThresholdKm)) km")
                        .hzTexte(.c13, .semi, tabulaire: true)
                        .foregroundStyle(HZCouleur.secondaireSurClair)
                    if fraction >= 1 {
                        Text("À remplacer").hzTexte(.c13, .gras).foregroundStyle(HZCouleur.encre)
                    } else if usee {
                        Text("Bientôt en fin de vie").hzTexte(.c13, .gras).foregroundStyle(HZCouleur.encre)
                    }
                }
            }
            Menu {
                if !isRetired {
                    if !isDefault {
                        Button("Définir par défaut") { profile.defaultShoeID = shoe.id }
                    }
                    Button("Retirer cette paire") { pendingRetire = shoe }
                }
                Button("Supprimer", role: .destructive) { pendingDelete = shoe }
            } label: {
                HZIcone(dessin: .options, cote: HZFil.coteDuBravo, couleur: HZCouleur.secondaireSurClair)
                    .frame(width: HZBoutonRond.zoneTactile, height: HZBoutonRond.zoneTactile)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Options de la paire")
        }
        .padding(HZEspace.tuile)
        .background(HZCouleur.surfaceClaire, in: RoundedRectangle(cornerRadius: HZRayon.groupe, style: .circular))
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isRetired, !isDefault else { return }
            profile.defaultShoeID = shoe.id
            Haptics.selection()
        }
        .opacity(isRetired ? HZHub.opaciteDesPaires : HZHub.opaciteNormale)
    }
}

/// La feuille « Nouvelle paire » : un nom, et les kilomètres déjà faits si elle n'est pas neuve.
private struct AddShoeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query private var shoes: [Shoe]

    @State private var name = ""
    @State private var startKmText = ""

    private var profile: UserProfile { appState.profile }
    private var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        HZFeuilleModale(titre: String(localized: "Nouvelle paire")) {
            ScrollView {
                VStack(alignment: .leading, spacing: HZEspace.entreSections) {
                    HZChampDeTexte(titre: String(localized: "Nom de la paire"),
                                   invite: String(localized: "Ex. Pegasus 41"), texte: $name)
                    VStack(alignment: .leading, spacing: HZEspace.entrePilules) {
                        HZChampDeTexte(titre: String(localized: "Déjà parcourus (facultatif)"),
                                       invite: String(localized: "0"),
                                       texte: $startKmText, clavier: .decimalPad)
                        Text("Si cette paire n'est pas neuve, indique les km déjà dessus.")
                            .hzTexte(.c13, .medium)
                            .foregroundStyle(HZCouleur.secondaireSurClair)
                    }
                    HZBoutonPilule(libelle: String(localized: "Ajouter"), etendu: true) { save() }
                        .opacity(isValid ? HZHub.opaciteNormale : HZHub.opaciteEteinte)
                        .disabled(!isValid)
                }
                .padding(.horizontal, HZEspace.marge)
            }
        }
    }

    private func save() {
        // `shoes` won't reflect the insert below until the next @Query update cycle, so whether
        // this is the first pair ever is captured before it, not after (same reasoning as
        // HistoryView's delete-time streak recompute).
        let isFirstShoe = shoes.isEmpty
        let startKm = Double(startKmText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let shoe = Shoe(name: name.trimmingCharacters(in: .whitespaces), startDistanceKm: max(0, startKm))
        modelContext.insert(shoe)
        // The first pair ever added becomes the default automatically — without this, every run
        // would go unattributed until she opens this screen a second time just to set it.
        if isFirstShoe { profile.defaultShoeID = shoe.id }
        Haptics.success()
        dismiss()
    }
}
