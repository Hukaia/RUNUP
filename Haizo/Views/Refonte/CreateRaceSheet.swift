import SwiftUI
import UIKit

/// Ajouter une course que l'app ne connaît pas encore.
///
/// CE QUI N'EST PAS DEMANDÉ. Le minimum est un nom et une date, rien de plus — c'est la limite du
/// serveur, et c'est voulu. Quelqu'un qui vient d'échouer à trouver sa course est à un formulaire
/// de distance de renoncer : la distance, le dénivelé, la ville et le site sont tous facultatifs,
/// et n'importe qui pourra les compléter plus tard sur la même page.
///
/// LE DOUBLON NE REMONTE PAS COMME UNE ERREUR. Si la course existe déjà — même nom replié, même
/// date — le serveur rend l'existante au lieu de refuser, et cet écran ouvre sa page comme si elle
/// venait d'être créée. C'est exactement ce qu'on veut qu'il vive : deux personnes qui préparent la
/// même course doivent atterrir sur la MÊME page, et celle qui tape un nom déjà pris n'a aucune
/// raison d'apprendre qu'elle a failli créer un doublon.
struct CreateRaceSheet: View {
    /// Pré-rempli avec ce qui vient d'être cherché en vain : ne pas le retaper est la moitié de
    /// l'intérêt d'arriver ici depuis une recherche vide.
    var nomPropose: String
    var onCreated: (RaceEvent) -> Void

    @Environment(AppState.self) private var appState

    @State private var nom = ""
    @State private var ville = ""
    @State private var date = Date().addingTimeInterval(HZCourse.delaiParDefaut)
    @State private var distance = ""
    @State private var denivele = ""
    @State private var discipline = "run"
    @State private var site = ""
    @State private var enCours = false
    @State private var erreur: String?

    private static let disciplines = ["run", "trail", "hyrox", "triathlon"]

    private var nomPropre: String { nom.trimmingCharacters(in: .whitespaces) }

    /// Le format du serveur, et le JOUR CHOISI : le fuseau courant est volontaire ici — on veut le
    /// jour tel qu'il a été tapé sur le sélecteur, pas sa traduction en UTC, qui en reculerait
    /// d'un pour tout l'hémisphère est.
    private static let jourServeur: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    var body: some View {
        HZFeuilleModale(titre: String(localized: "Ajouter une course")) {
            ScrollView {
                VStack(alignment: .leading, spacing: HZEspace.groupe) {
                    champ(titre: String(localized: "Nom de la course"), texte: $nom,
                          exemple: String(localized: "Marathon de Paris"))

                    choixDeLaDate
                    choixDuType

                    champ(titre: String(localized: "Ville"), texte: $ville,
                          exemple: String(localized: "Paris"), facultatif: true)

                    // L'un sous l'autre et pas côte à côte : « Distance (km) · facultatif » ne tient
                    // pas dans une demi-largeur à 390 points.
                    champ(titre: String(localized: "Distance (km)"), texte: $distance,
                          exemple: "42,2", facultatif: true, clavier: .decimalPad)
                    champ(titre: String(localized: "D+ (m)"), texte: $denivele,
                          exemple: "1200", facultatif: true, clavier: .numberPad)

                    champ(titre: String(localized: "Site officiel"), texte: $site,
                          exemple: "https://…", facultatif: true, clavier: .URL)

                    if let erreur {
                        HZPhrase(texte: erreur)
                    }

                    HZPhrase(texte: String(localized: "Tout le monde pourra la trouver et la suivre. Les champs laissés vides se complètent plus tard."))
                }
                .padding(.horizontal, HZEspace.marge)
            }
        }
        // Le geste pour lequel cette feuille est ouverte, épinglé en bas : l'appelant pose
        // `gereSonBas: true`.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HZActionEpinglee(libelle: enCours ? String(localized: "Création…") : String(localized: "Créer la page"),
                             eteinte: nomPropre.isEmpty || enCours) { Task { await creer() } }
        }
        .onAppear { if nom.isEmpty { nom = nomPropose } }
    }

    private var choixDeLaDate: some View {
        VStack(alignment: .leading, spacing: HZEspace.entrePilules) {
            etiquette(String(localized: "Date"))
            DatePicker("", selection: $date, in: Date()..., displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .tint(HZCouleur.accent)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var choixDuType: some View {
        VStack(alignment: .leading, spacing: HZEspace.entrePilules) {
            etiquette(String(localized: "Type d'épreuve"))
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: HZEspace.entrePilules) {
                    ForEach(Self.disciplines, id: \.self) { clef in
                        HZFiltre(libelle: Self.libelleDuTypeDEpreuve(clef), actif: discipline == clef, fond: .clair) {
                            discipline = clef
                        }
                    }
                }
            }
        }
    }

    private static func libelleDuTypeDEpreuve(_ clef: String) -> String {
        switch clef {
        case "trail": return String(localized: "Trail")
        case "hyrox": return String(localized: "Hyrox")
        case "triathlon": return String(localized: "Triathlon")
        default: return String(localized: "Route")
        }
    }

    private func etiquette(_ texte: String) -> some View {
        Text(texte)
            .hzTexte(.c13, .semi)
            .foregroundStyle(HZCouleur.secondaireSurClair)
    }

    private func champ(titre: String, texte: Binding<String>, exemple: String,
                       facultatif: Bool = false, clavier: UIKeyboardType = .default) -> some View {
        HZChampDeTexte(titre: facultatif ? String(localized: "\(titre) · facultatif") : titre,
                       invite: exemple, texte: texte, clavier: clavier,
                       majuscules: clavier == .URL ? .never : .sentences)
    }

    private func creer() async {
        guard !nomPropre.isEmpty else { return }
        enCours = true
        erreur = nil
        // La virgule décimale est ce que donne le clavier français. `Double("42,2")` rend nil.
        let km = Double(distance.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces))
        let dplus = Int(denivele.trimmingCharacters(in: .whitespaces))
        do {
            let course = try await ClubService(auth: appState.auth).createRace(
                name: nomPropre,
                city: ville.trimmingCharacters(in: .whitespaces),
                raceDate: Self.jourServeur.string(from: date),
                distanceKm: km,
                elevationGainM: dplus,
                discipline: discipline,
                website: site.trimmingCharacters(in: .whitespaces)
            )
            Haptics.impact(.light)
            // Pas de `dismiss()` ici : c'est l'écran appelant qui referme cette feuille, puis
            // ouvre la page de la course. Les deux à la fois feraient refermer deux fois.
            onCreated(course)
        } catch ClubServiceError.badResponse(let code, _) where code == HZHub.refuse {
            erreur = String(localized: "Ce nom ne passe pas. Mets le nom officiel de la course.")
        } catch ClubServiceError.badResponse(let code, _) where code == HZCourse.tropDeRequetes {
            erreur = String(localized: "Trop de courses créées aujourd'hui. Réessaie demain.")
        } catch {
            erreur = String(localized: "Impossible de créer la course — \(PanneReseau.motif(pour: error)).")
        }
        enCours = false
    }
}
