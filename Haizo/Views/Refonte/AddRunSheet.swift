import SwiftUI
import SwiftData
import UIKit

/// Manual run entry — History used to be strictly read-only (whatever the Live Run flow
/// produced), with no way to log a run that wasn't GPS-tracked or to fix a mistake. This writes a
/// real `RunRecord` via the same model everything else (`HistoryView`, `StatsView`) already
/// `@Query`s, so a manually-added run shows up everywhere automatically.
///
/// Laid out as one grouped list of icon + label + trailing-value rows (same shape
/// `MoreSettingsView` uses) rather than a stack of separate labelled cards — a single native-
/// feeling form instead of several small ones.
///
/// # ELLE N'AJOUTE PLUS SEULEMENT DES COURSES
///
/// C'est le deuxième des deux chemins par lesquels une nage entre dans l'app — l'autre étant
/// Apple Santé (voir `HealthRunImport`). Il compte autant que lui : une piscine municipale ne
/// donne pas de fichier, une montre reste au vestiaire, et « quarante minutes, 1500 m » est tout
/// ce dont on se souvient en sortant. Sans cette feuille, une nageuse sans montre n'aurait
/// aucune façon de faire exister sa séance.
///
/// Tout ce qui dépend de la discipline est lu sur `Discipline` et nulle part ici : l'unité de
/// saisie (une nage se dit en MÈTRES), le plafond, l'exemple en filigrane, la liste des types de
/// séance, le tarif en kilocalories, et le fait qu'une paire de chaussures n'a rien à voir avec
/// un bassin. Cette feuille ne sait pas ce qu'est une nage ; elle sait demander à la discipline.
struct AddRunSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(sort: \RunRecord.date) private var runs: [RunRecord]
    @Query(filter: #Predicate<Shoe> { $0.retiredAt == nil }) private var activeShoes: [Shoe]

    @State private var date = Date.now
    @State private var discipline: Discipline = .run
    @State private var title = Discipline.run.typesDeSeanceSaisis[0]
    @State private var distanceText = ""
    @State private var durationMinutesText = ""
    @State private var selectedShoeID: UUID?

    /// Le plafond de distance vit sur `Discipline` : il est dans l'unité de la saisie, et une
    /// nage ne se borne pas au même nombre qu'une sortie vélo. Celui de la durée est commun —
    /// une séance ne dure pas plus d'une journée, quelle que soit la discipline.
    private static let maxDurationMinutes: Double = HZJournee.dureeMaximaleDUneJournee

    /// `Double(_:)` accepte « 1e30 », « inf » et « nan » — pas seulement ce qu'un clavier
    /// numérique produit, mais exactement ce qu'un collage produit. Sans le test de finitude,
    /// `Int(seconds)` plus bas est un piège FATAL en Swift : convertir un flottant hors bornes en
    /// entier ne renvoie pas une valeur écrêtée, ça termine le processus.
    private var distance: Double? {
        guard let value = Double(distanceText.replacingOccurrences(of: ",", with: ".")),
              value.isFinite else { return nil }
        return value
    }
    private var durationMinutes: Double? {
        guard let value = Double(durationMinutesText.replacingOccurrences(of: ",", with: ".")),
              value.isFinite else { return nil }
        return value
    }
    private var isValid: Bool {
        guard let distance, let durationMinutes else { return false }
        return distance > 0 && distance <= discipline.distanceMaximaleSaisie
            && durationMinutes > 0 && durationMinutes <= Self.maxDurationMinutes
    }

    /// La distance en kilomètres — l'unité de `RunRecord`. `distance` est ce qu'elle a TAPÉ, dans
    /// l'unité que la discipline demande ; les deux ne sont égales que hors du bassin.
    private var distanceKm: Double? {
        distance.map { discipline.kilometres(depuisLaSaisie: $0) }
    }
    private var selectedShoeName: String {
        activeShoes.first { $0.id == selectedShoeID }?.name ?? String(localized: "Aucune")
    }

    var body: some View {
        // « Une séance » et non « une course » : cette feuille ajoute aussi des nages.
        HZFeuilleModale(titre: String(localized: "Ajouter une séance")) {
            ScrollView {
                VStack(alignment: .leading, spacing: HZEspace.entreSections) {
                    HZGroupeDeReglages(titre: String(localized: "Informations générales")) {
                        disciplineRow
                        dateRow
                        typeRow
                        numRow(label: String(localized: "Distance"), value: $distanceText,
                               unit: discipline.uniteDeSaisieLabel,
                               placeholder: discipline.exempleDeDistance)
                        numRow(label: String(localized: "Durée"), value: $durationMinutesText,
                               unit: HZJournee.uniteDeDuree, placeholder: HZJournee.exempleDeDuree,
                               derniere: true)
                    }

                    // Only shown once she's actually added a pair — no point cluttering this form
                    // with a picker for a feature she isn't using. Et jamais hors de la course à
                    // pied : une paire de chaussures ne vieillit pas dans un bassin ni sur une
                    // selle, donc la question ne se pose pas. Voir `Discipline.wearsShoes`.
                    if !activeShoes.isEmpty, discipline.wearsShoes {
                        HZGroupeDeReglages(titre: String(localized: "Chaussures")) {
                            shoeRow
                        }
                    }

                    HZBoutonPilule(libelle: String(localized: "Ajouter"), etendu: true) { save() }
                        .opacity(isValid ? HZHub.opaciteNormale : HZHub.opaciteEteinte)
                        .disabled(!isValid)
                }
                .padding(.horizontal, HZEspace.marge)
            }
        }
        .onAppear { selectedShoeID = appState.profile.defaultShoeID }
    }

    private func save() {
        // `isValid` garde déjà le bouton, mais on revérifie ici : c'est la seule barrière entre
        // une valeur saisie et une conversion en entier qui termine le processus si elle déborde.
        // Une garde en double sur ce chemin coûte une ligne.
        guard isValid, let distanceKm, let durationMinutes else { return }
        let seconds = durationMinutes * Double(HZJournee.secondesParMinute)
        // Toujours des secondes AU KILOMÈTRE, pour toutes les disciplines — c'est l'unité de
        // stockage de `avgPace`, et `TimeFormat.rythme(_:secondesParKm:)` la relit dans celle que
        // la discipline affiche : au kilomètre à pied, aux cent mètres en bassin, en km/h à vélo.
        // Convertir ici donnerait deux unités dans le même champ selon qui l'a écrit.
        let secPerKm = seconds / distanceKm
        let run = RunRecord(
            date: date,
            // Traduit à l'ÉCRITURE. Le menu affiche « Long run », et la ligne d'historique
            // relisait « Sortie longue » : `HistoryView` rend `run.title` en `Text(String)`, qui
            // ne consulte jamais le catalogue — et ne doit pas le consulter, ce champ portant
            // aussi du texte libre venu de Strava.
            title: String(localized: String.LocalizationValue(title)),
            distanceKm: distanceKm,
            durationSeconds: Int(seconds),
            avgPace: PaceModel.paceText(secPerKm),
            // 0 = "no real reading" — HistoryView hides the FC line rather than show a fake 0bpm.
            avgHeartRate: 0,
            // Une approximation plate et assumée (aucune fréquence cardiaque réelle derrière) —
            // mieux que 0 kcal après une vraie sortie. Voir `Calories` : le même tarif que la
            // course au GPS, pour que les deux ne divergent pas sur une distance identique.
            //
            // Par discipline, parce que le kilomètre ne coûte pas la même chose partout : à vélo
            // c'est le terrain qui le fausse, en bassin c'est la technique. Sans ça, 1500 m de
            // nage valaient 93 kcal — le tarif d'un kilomètre et demi de footing, pour trois
            // quarts d'heure d'effort.
            kcal: Int(Calories.estimate(discipline, distanceKm: distanceKm,
                                        durationMinutes: Int(durationMinutes.rounded())).rounded()),
            discipline: discipline
        )
        // Aucune paire attachée hors de la course à pied, même si un choix traînait dans l'état
        // de la vue : la ligne est masquée pour les autres disciplines, mais changer de
        // discipline APRÈS avoir choisi une paire laissait la sélection derrière, et la nage
        // aurait vieilli les chaussures de deux kilomètres par bassin.
        run.shoeID = discipline.wearsShoes ? selectedShoeID : nil
        modelContext.insert(run)
        // `runs` won't reflect the insert until the next @Query update cycle, so the current
        // set is computed by hand rather than read back immediately — same pattern as HistoryView's delete.
        AdaptivePlanEngine.recomputeStreak(profile: appState.profile, currentRuns: runs + [run])
        Haptics.success()
        dismiss()
    }

    private var dateRow: some View {
        HZLigneDeReglage(titre: String(localized: "Date")) {
            DatePicker("", selection: $date, in: ...Date.now, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .tint(HZCouleur.encre)
        }
    }

    /// Le choix de la discipline, en tête de formulaire — avant la date, parce qu'il commande
    /// tout ce qui suit : l'unité du champ de distance, la liste des types de séance, la présence
    /// de la ligne « chaussures ».
    ///
    /// Les quatre disciplines sont proposées, y compris celles qui se démarrent depuis le
    /// téléphone : le premier usage de cette feuille est précisément d'avoir oublié d'appuyer sur
    /// « démarrer ». Voir `Discipline.saisissables`, qui n'est pas `demarrables`.
    private var disciplineRow: some View {
        HZLigneDeReglage(titre: String(localized: "Discipline")) {
            Menu {
                ForEach(Discipline.saisissables, id: \.self) { d in
                    Button {
                        choisir(d)
                    } label: {
                        Label(d.title, systemImage: d.sfSymbol)
                    }
                }
            } label: {
                valeurDeMenu(discipline.title)
            }
        }
    }

    /// Changer de discipline remet le type de séance à zéro, et VIDE LA DISTANCE.
    ///
    /// Le type, parce qu'il n'appartient pas à la nouvelle liste : « Footing » resterait affiché
    /// sous « Natation », et serait écrit tel quel dans l'historique.
    ///
    /// La distance, parce que le nombre tapé ne veut plus rien dire : « 1500 » saisi en mètres
    /// pour une nage devient mille cinq cents KILOMÈTRES si on passe à la course sans y toucher,
    /// et « 8,2 » devient huit mètres de bassin. Le plafond de la nouvelle discipline attraperait
    /// le premier cas et bloquerait le bouton — mais pas le second, qui s'enregistrerait
    /// tranquillement. Vider est la seule réponse juste : aucune valeur ne survit à un changement
    /// d'unité.
    private func choisir(_ nouvelle: Discipline) {
        guard nouvelle != discipline else { return }
        let changeDUnite = nouvelle.uniteDeSaisie != discipline.uniteDeSaisie
        discipline = nouvelle
        title = nouvelle.typesDeSeanceSaisis[0]
        if changeDUnite { distanceText = "" }
    }

    private var typeRow: some View {
        HZLigneDeReglage(titre: String(localized: "Type de séance")) {
            Menu {
                ForEach(discipline.typesDeSeanceSaisis, id: \.self) { t in
                    // `Button(t)` avec un `String` ne passe jamais par le catalogue (seul
                    // l'initialiseur `LocalizedStringKey` le fait) : le menu restait en français
                    // alors que la ligne repliée juste en dessous, elle, se traduisait.
                    Button(LocalizedStringKey(t)) { title = t }
                }
            } label: {
                valeurDeMenu(String(localized: String.LocalizationValue(title)))
            }
        }
    }

    private var shoeRow: some View {
        HZLigneDeReglage(titre: String(localized: "Chaussures"), filet: false) {
            Menu {
                Button("Aucune") { selectedShoeID = nil }
                ForEach(activeShoes) { shoe in
                    Button(shoe.name) { selectedShoeID = shoe.id }
                }
            } label: {
                valeurDeMenu(selectedShoeName)
            }
        }
    }

    /// Ce que montre un menu replié : la valeur choisie, et les deux chevrons qui disent qu'on peut
    /// la changer.
    private func valeurDeMenu(_ valeur: String) -> some View {
        HStack(spacing: HZEspace.entrePilules) {
            Text(valeur)
                .hzTexte(.c15, .semi)
                .foregroundStyle(HZCouleur.secondaireSurClair)
                .lineLimit(1)
            Image(systemName: "chevron.up.chevron.down")
                .font(HZPolice.texte(.c12, .semi))
                .foregroundStyle(HZCouleur.secondaireSurClair)
        }
        .frame(minHeight: HZBoutonRond.zoneTactile)
        .contentShape(Rectangle())
    }

    private func numRow(label: String, value: Binding<String>, unit: String, placeholder: String,
                        derniere: Bool = false) -> some View {
        HZLigneDeReglage(titre: label, filet: !derniere) {
            HStack(spacing: HZEspace.entrePilules) {
                TextField(text: value,
                          prompt: Text(placeholder).foregroundStyle(HZCouleur.secondaireSurClair)) { EmptyView() }
                    .accessibilityLabel(label)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(HZPolice.texte(.c16, .semi))
                    .foregroundStyle(HZCouleur.encre)
                    .tint(HZCouleur.encre)
                    .frame(width: HZJournee.largeurDuChampNumerique)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Terminé") {
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }
                        }
                    }
                Text(unit)
                    .hzTexte(.c15, .semi)
                    .foregroundStyle(HZCouleur.secondaireSurClair)
                    .lineLimit(1)
            }
        }
    }
}
