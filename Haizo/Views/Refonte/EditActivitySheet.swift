import SwiftUI
import PhotosUI
import UIKit

/// Renommer sa sortie, lui ajouter une note, ou lui retirer son tracé — après coup.
///
/// # Pourquoi l'édition existe
///
/// La phrase que le fil affiche est FABRIQUÉE : « a couru 8,2 km · Sortie longue ». Elle dit ce
/// qui s'est passé, et c'est très bien. Elle ne dit pas que c'était le premier 10 km, qu'il
/// pleuvait, ou que le genou a tenu. Un fil où personne ne peut rien ajouter est un journal, pas
/// une conversation — et c'est exactement ce qu'on lui reprochait.
///
/// # Ce qui ne s'édite pas, et pourquoi
///
/// Ni la distance, ni la durée, ni l'allure, ni le dénivelé, ni le record. Ces mesures alimentent
/// la progression des défis de club, qui est une SOMME : les rendre modifiables offrirait à
/// n'importe qui un défi terminé en une requête. Ce qui s'édite ici est ce qui n'est compté nulle
/// part — du texte, et un tracé qu'on retire.
struct EditActivitySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    /// Construit à la demande, exactement comme `ClubView` : `ClubService` est une structure sans
    /// état, dont la seule dépendance est le jeton de session porté par `AuthService`.
    private var clubService: ClubService { ClubService(auth: appState.auth) }

    let item: FeedItem
    /// Rappelée après un enregistrement réussi, pour que le fil se recharge sans attendre.
    var onSaved: () -> Void

    @State private var title: String
    @State private var note: String
    @State private var removeRoute = false
    @State private var saving = false
    @State private var errorMessage: String?

    // La photo. `photoItem` est la sélection, `photoPreview` l'image réduite affichée tout de
    // suite, `photoDataURI` ce qui part au serveur — et `photoRetiree` le cas qu'on ne peut pas
    // déduire des trois autres : « il y en avait une, je la retire » ressemblerait sinon à
    // « je n'en ai pas choisi », c'est-à-dire à « n'y touche pas ».
    @State private var photoItem: PhotosPickerItem?
    /// Vrai le temps de décoder, réduire et encoder l'image choisie — voir `chargerLaPhoto`.
    @State private var chargementPhoto = false
    @State private var photoPreview: UIImage?
    @State private var photoDataURI: String?
    @State private var photoRetiree = false

    init(item: FeedItem, onSaved: @escaping () -> Void) {
        self.item = item
        self.onSaved = onSaved
        _title = State(initialValue: item.title ?? "")
        _note = State(initialValue: item.note ?? "")
    }

    private static let maxTitle = HZFeuillesDuFil.longueurDUnTitre
    private static let maxNote = HZFeuillesDuFil.longueurDUnTexte

    var body: some View {
        HZFeuilleModale(titre: String(localized: "Modifier ma sortie")) {
            ScrollView {
                VStack(alignment: .leading, spacing: HZEspace.entreSections) {
                    ceQuiNeBougePas
                    champs
                    photoSection
                    if item.routePreview != nil { routeSection }
                    if let errorMessage { HZAvisDeFeuille(texte: errorMessage) }
                }
                .padding(.horizontal, HZEspace.marge)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                HZBasDeFeuille {
                    HZBoutonPilule(libelle: String(localized: "Enregistrer"), etendu: true) { save() }
                        .opacity(saving ? HZHub.opaciteEteinte : HZHub.opaciteNormale)
                        .disabled(saving)
                }
            }
        }
    }

    /// Ce qui NE bouge PAS, montré en premier. Une feuille d'édition qui n'affiche que les champs
    /// modifiables laisse croire qu'elle a tout effacé.
    private var ceQuiNeBougePas: some View {
        VStack(alignment: .leading, spacing: HZEspace.entrePilules) {
            Text("Ta sortie")
                .hzTexte(.c13, .semi)
                .foregroundStyle(HZCouleur.secondaireSurClair)
            HZPlaque {
                Text(item.localizedText)
                    .hzParagraphe(.c15, .medium, interligne: HZBandeauDuCoach.interligne)
                    .foregroundStyle(HZCouleur.encre)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var champs: some View {
        VStack(alignment: .leading, spacing: HZEspace.entreCommandes) {
            HZChampDeTexte(titre: String(localized: "Titre"), invite: String(localized: "Mon premier 10 km"),
                           texte: $title)
                .onChange(of: title) { _, new in
                    if new.count > Self.maxTitle { title = String(new.prefix(Self.maxTitle)) }
                }
            HZChampDeTexte(titre: String(localized: "Note"), invite: String(localized: "Comment c'était ?"),
                           texte: $note, lignes: HZFeuillesDuFil.lignesDUneNote)
                .onChange(of: note) { _, new in
                    if new.count > Self.maxNote { note = String(new.prefix(Self.maxNote)) }
                }
        }
    }

    /// Le retrait du tracé est le seul champ qu'on peut supprimer sans supprimer la sortie, et il
    /// doit l'être : quelqu'un qui réalise après coup que le dessin de sa boucle en dit trop ne
    /// doit pas avoir à choisir entre garder ça et effacer sa course.
    private var routeSection: some View {
        VStack(alignment: .leading, spacing: HZEspace.entreCommandes) {
            HZPlaque {
                HZLigneDeReglage(
                    titre: String(localized: "Retirer le tracé"),
                    precision: String(localized: "Le dessin du parcours disparaît du fil. Le début et la fin de ta course n'y ont jamais été envoyés."),
                    filet: false) {
                    Toggle("", isOn: $removeRoute)
                        .labelsHidden()
                        .toggleStyle(HZStyleDInterrupteur())
                        .accessibilityLabel(String(localized: "Retirer le tracé"))
                }
            }
            if removeRoute {
                HZAvisDeFeuille(texte: String(localized: "C'est définitif : le tracé ne pourra pas être remis."))
            }
        }
    }

    /// LA PHOTO, APRÈS COUP ET NON AU MOMENT DE COURIR.
    ///
    /// On ne sort pas son téléphone pour choisir une image en finissant un dix kilomètres. C'est
    /// aussi ce que fait Strava : la sortie part d'abord, la photo s'ajoute ensuite — et toutes
    /// les sorties déjà publiées en deviennent candidates, ce qu'un ajout au moment de la
    /// publication n'aurait jamais permis.
    private var photoSection: some View {
        VStack(alignment: .leading, spacing: HZEspace.entrePilules) {
            Text("Photo")
                .hzTexte(.c13, .semi)
                .foregroundStyle(HZCouleur.secondaireSurClair)

            if let apercu = photoPreview {
                zoneDePhoto { Image(uiImage: apercu).resizable().scaledToFill() }
            } else if let existante = item.photoUrl, !existante.isEmpty, !photoRetiree,
                      let url = URL(string: existante) {
                zoneDePhoto {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        HZCouleur.surfaceClaire
                    }
                }
            } else {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Text("Ajouter une photo")
                        .hzTexte(HZHauteurDeBouton.moyenne.corps, .gras)
                        .foregroundStyle(HZCouleur.encre)
                        .frame(maxWidth: .infinity)
                        .frame(height: HZHauteurDeBouton.moyenne.rawValue)
                        .background(HZCouleur.surfaceClaire, in: Capsule())
                        .contentShape(Capsule())
                }
            }

            Text("Elle sera visible par ton club et par tes abonnés.")
                .hzParagraphe(.c13, .medium, interligne: HZBandeauDuCoach.interligne)
                .foregroundStyle(HZCouleur.secondaireSurClair)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onChange(of: photoItem) { _, nouveau in Task { await chargerLaPhoto(nouveau) } }
    }

    private func zoneDePhoto<Contenu: View>(@ViewBuilder _ contenu: () -> Contenu) -> some View {
        ZStack(alignment: .topTrailing) {
            contenu()
                .frame(height: HZFeuillesDuFil.hauteurDeLaPhotoDeSortie)
                .frame(maxWidth: .infinity)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: HZRayon.tuile, style: .circular))
            HZBoutonRond(dessin: .fermer, nom: String(localized: "Retirer la photo"), diametre: .outil,
                         cote: HZHub.coteDeLaCroix, trait: HZHub.traitDeLaCroix) {
                photoPreview = nil
                photoDataURI = nil
                photoItem = nil
                photoRetiree = true
            }
            .padding(HZEspace.entrePilules)
        }
    }

    /// Réduite et encodée dès la sélection : 1080 px sur le côté long, qualité 0,6 — ce qui tient
    /// sous les 500 ko que le serveur accepte tout en restant net en plein écran. Exactement la
    /// même chaîne que la photo d'un itinéraire et celle du profil : une troisième façon de
    /// préparer une image serait une troisième façon de dépasser le plafond.
    ///
    /// L'ATTENTE SE VOIT, ET L'ÉCHEC SE DIT.
    ///
    /// Le bouton affichait « Ajouter une photo » pendant tout le temps du décodage, du
    /// redimensionnement et de l'encodage — une à deux secondes sur une photo de douze
    /// mégapixels, pendant lesquelles l'écran ne bougeait pas. Le geste naturel est alors
    /// d'appuyer une seconde fois.
    ///
    /// Et les trois `guard` sortaient en silence. Une photo restée sur iCloud, un format que
    /// `UIImage` ne sait pas lire, un encodage qui échoue : dans les trois cas, rien ne se
    /// passait et rien ne le disait — exactement le défaut du chantier 2, sur un autre écran.
    private func chargerLaPhoto(_ selection: PhotosPickerItem?) async {
        guard let selection else { return }
        chargementPhoto = true
        errorMessage = nil
        defer { chargementPhoto = false }
        guard let data = try? await selection.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            errorMessage = String(localized: "Impossible de lire cette photo. Choisis-en une autre.")
            return
        }
        let reduite = image.resized(maxDimension: HZFeuillesDuFil.coteMaxDUnePhoto)
        guard let jpeg = reduite.jpegData(compressionQuality: HZFeuillesDuFil.qualiteDUnePhoto) else {
            errorMessage = String(localized: "Impossible de préparer cette photo. Choisis-en une autre.")
            return
        }
        photoPreview = reduite
        photoDataURI = "data:image/jpeg;base64," + jpeg.base64EncodedString()
        photoRetiree = false
    }

    private func save() {
        saving = true
        errorMessage = nil
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            do {
                try await clubService.updateActivity(
                    activityId: item.id,
                    title: trimmedTitle.isEmpty ? nil : trimmedTitle,
                    note: trimmedNote.isEmpty ? nil : trimmedNote,
                    removeRoute: removeRoute
                )
                // LA PHOTO PART APRÈS LE TEXTE, ET SON ÉCHEC NE REMET PAS LE RESTE EN CAUSE.
                //
                // Ce sont deux requêtes parce que ce sont deux choses : le texte passe par le
                // filtre de modération, l'image par un stockage et un plafond quotidien. Les
                // joindre ferait perdre un titre corrigé parce qu'une photo était trop lourde.
                // Même ordre et même raison que la publication d'un itinéraire.
                if let photoDataURI {
                    _ = try? await clubService.setActivityPhoto(activityId: item.id, dataURI: photoDataURI)
                } else if photoRetiree {
                    _ = try? await clubService.setActivityPhoto(activityId: item.id, dataURI: nil)
                }
                onSaved()
                dismiss()
            } catch {
                // Le message de modération mérite d'être distingué d'une panne réseau : dans un
                // cas il faut réécrire, dans l'autre réessayer. Les confondre en « une erreur est
                // survenue » laisse la personne relancer indéfiniment un texte qui ne passera pas.
                errorMessage = (error as? ClubServiceError)?.isObjectionableContent == true
                    ? String(localized: "Ce texte a été refusé par le filtre de contenu. Reformule-le.")
                    : String(localized: "Impossible d'enregistrer pour l'instant. Réessaie dans un moment.")
                saving = false
            }
        }
    }
}
