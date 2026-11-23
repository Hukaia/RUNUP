import SwiftUI
import UniformTypeIdentifiers

/// Le fichier de sauvegarde, tel que l'app Fichiers le voit.
///
/// `FileDocument` plutôt qu'un `ShareLink` : une sauvegarde n'est pas quelque chose qu'on PARTAGE
/// — c'est quelque chose qu'on RANGE. Le sélecteur du système envoie le fichier dans iCloud
/// Drive, sur une clé, dans un dossier choisi ; une feuille de partage proposerait d'abord
/// Messages et WhatsApp, pour un fichier qui contient l'intégralité de ses données de santé.
/// `ShareLink` demande en plus que l'URL existe AVANT l'affichage du bouton, donc d'encoder toute
/// la base à chaque ouverture des réglages.
struct SauvegardeDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var contenu: Data

    init(contenu: Data) { self.contenu = contenu }

    init(configuration: ReadConfiguration) throws {
        contenu = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: contenu)
    }
}

/// « Mes données » dans Plus de réglages : écrire la sauvegarde, et la relire.
///
/// Elle rend deux LIGNES, que l'appelant range dans son groupe de réglages.
struct CarteDeSauvegarde: View {
    @Environment(AppState.self) private var appState

    @State private var document: SauvegardeDocument?
    @State private var exportOuvert = false
    @State private var nomPropose = ""
    @State private var message: String?

    var body: some View {
        VStack(spacing: 0) {
            Button(action: preparerLExport) {
                HZLigneDeReglage(
                    titre: String(localized: "Exporter mes données"),
                    precision: String(localized: "Un fichier à ranger où tu veux. Il contient tout : ton historique, ta conversation avec le coach, tes chaussures, ta série. Il ne part sur aucun serveur."),
                    filet: false) {
                    HZChevron()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // PAS DE « RESTAURER » ICI, ET C'EST VOULU. La ligne existait, et ne pouvait JAMAIS
            // réussir : une sauvegarde ne se relit que sur une app qui repart de zéro
            // (`SauvegardeService.peutRestaurer`), et cet écran n'existe qu'une fois l'inscription
            // faite. Elle ouvrait un sélecteur de fichier pour répondre « Tes données sont déjà
            // là ». La phrase dit où se fait la restauration, à la place d'un bouton qui échoue.
            Text("Pour relire ce fichier : installe Haizo sur un téléphone neuf, puis touche « J'ai déjà une sauvegarde Haizo » à l'ouverture.")
                .hzParagraphe(.c13, .medium, interligne: HZReglages.interligne)
                .foregroundStyle(HZCouleur.secondaireSurClair)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, HZEspace.entreCommandes)
        }
        .fileExporter(isPresented: $exportOuvert, document: document,
                      contentType: .json, defaultFilename: nomPropose) { resultat in
            // L'annulation n'est pas un échec : le sélecteur rend `CocoaError.userCancelled`, et
            // afficher « ça n'a pas marché » après un geste volontaire est la façon la plus sûre
            // de faire croire qu'une sauvegarde a échoué alors qu'elle n'a pas été demandée.
            switch resultat {
            case .success:
                appState.toast(String(localized: "Sauvegarde enregistrée"))
            case .failure(let erreur):
                guard (erreur as? CocoaError)?.code != .userCancelled else { return }
                message = String(localized: "Le fichier n'a pas pu être écrit.")
            }
        }
        .alert(String(localized: "Sauvegarde"), isPresented: Binding(
            get: { message != nil }, set: { if !$0 { message = nil } })
        ) {
            Button("OK") { message = nil }
        } message: {
            Text(message ?? "")
        }
    }

    private func preparerLExport() {
        // LE MÊME REFUS QUE POUR LA RESTAURATION, et il manquait ici.
        //
        // `PersistenceController` ouvre un conteneur en mémoire VIDE quand le fichier sur disque
        // refuse de s'ouvrir. Le jour où l'app annonce « Tes données n'ont pas pu être ouvertes »
        // est exactement celui où le premier réflexe est de tout sauvegarder — et sans ce
        // garde-fou, le fichier produit porterait un profil neuf, zéro course, sous un nom daté
        // parfaitement crédible. Une fausse assurance au pire moment, dans l'outil écrit pour ce
        // moment-là.
        if PersistenceController.enSecours {
            message = String(localized: "Cette session ne voit pas tes données : l'app tourne sur un espace temporaire. Une sauvegarde faite maintenant serait vide. Relance l'app, ou réinstalle Haizo.")
            return
        }
        let sauvegarde = appState.construireLaSauvegarde()
        guard let data = try? SauvegardeService.encodeur().encode(sauvegarde) else {
            message = String(localized: "La sauvegarde n'a pas pu être écrite.")
            return
        }
        document = SauvegardeDocument(contenu: data)
        nomPropose = SauvegardeService.nomSansExtension(le: sauvegarde.creeLe)
        exportOuvert = true
    }
}

/// Le bouton « j'ai une sauvegarde », avec son sélecteur de fichier et ses trois réponses.
///
/// Autonome et réutilisable parce qu'il doit exister DEUX FOIS, et que le second endroit est le
/// seul qui compte vraiment : une base vide renvoie à l'inscription, donc les réglages — où ce
/// bouton a sa place logique — sont inatteignables précisément quand on vient chercher sa
/// sauvegarde. Voir `WelcomeView`.
struct BoutonDeRestauration<Label: View>: View {
    @Environment(AppState.self) private var appState
    private let label: () -> Label

    @State private var selecteurOuvert = false
    @State private var message: String?

    init(@ViewBuilder label: @escaping () -> Label) {
        self.label = label
    }

    var body: some View {
        Button { ouvrir() } label: { label() }
            .buttonStyle(.plain)
            .fileImporter(isPresented: $selecteurOuvert,
                          allowedContentTypes: [.json], allowsMultipleSelection: false) { resultat in
                guard case .success(let urls) = resultat, let url = urls.first else { return }
                switch appState.restaurer(depuis: url) {
                case .faite(let courses, let messages, let chaussures):
                    message = String(localized: "Sauvegarde restaurée : \(courses) courses, \(messages) messages, \(chaussures) paires de chaussures.")
                case .fichierIllisible:
                    message = String(localized: "Ce fichier n'est pas une sauvegarde Haizo, ou il est abîmé.")
                case .enregistrementImpossible:
                    message = String(localized: "Ta sauvegarde a bien été lue, mais rien n'a pu être écrit. Il n'y a sans doute plus de place sur ton téléphone. Fais de la place et recommence : le fichier est intact.")
                case .baseNonVide:
                    message = String(localized: "Tes données sont déjà là. Une restauration ne s'applique qu'à une app qui repart de zéro : elle ne sait pas fusionner deux historiques sans risquer d'en perdre.")
                }
            }
            .alert(String(localized: "Restaurer"), isPresented: Binding(
                get: { message != nil }, set: { if !$0 { message = nil } })
            ) {
                Button("OK") { message = nil }
            } message: {
                Text(message ?? "")
            }
    }

    private func ouvrir() {
        // LE MAGASIN DE SECOURS. `PersistenceController` ouvre un conteneur en mémoire jetable
        // quand le fichier sur disque refuse de s'ouvrir — donc exactement le jour où l'on vient
        // chercher sa sauvegarde. Y restaurer « marcherait » : les 212 courses apparaîtraient, et
        // disparaîtraient à la fermeture de l'app, en laissant croire que le fichier a servi.
        // Le dire ici est la seule façon d'éviter cette perte-là.
        if PersistenceController.enSecours {
            message = String(localized: "L'app tourne sur un espace temporaire : rien de ce qui est écrit maintenant ne serait gardé. Réinstalle Haizo, puis restaure ta sauvegarde.")
            return
        }
        selecteurOuvert = true
    }
}
