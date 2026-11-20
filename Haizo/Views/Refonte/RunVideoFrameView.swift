import SwiftUI

/// Une image de la vidéo d'une course.
///
/// # UNE VUE SWIFTUI, PAS UN DESSIN CORE GRAPHICS
///
/// Fabriquer les images à la main dans un `CGContext` aurait voulu dire réécrire la typographie
/// et surtout le tracé — alors que `DrawnRoute` dessine déjà exactement ça, avec sa tête et sa
/// trace fantôme, et qu'il est la seule chose à l'écran qui raconte
/// quelque chose que la personne a vraiment fait. Un second dessin aurait donné deux parcours
/// légèrement différents pour la même course.
///
/// `ImageRenderer` rasterise donc cette vue, image par image — c'est déjà ainsi que `RecapView`
/// exporte la carte de partage.
///
/// # DESSINÉE EN 360 × 640, RENDUE EN 1080 × 1920
///
/// Et c'est la même raison que la carte de partage, qui tient elle aussi dans 360 × 640 : les
/// tailles du système typographique de l'app sont en POINTS, pensées pour un écran de téléphone.
/// Composer directement en 1080 de large donnerait un titre de 18 points dans une image trois
/// fois plus large — illisible, et il faudrait un second barème de tailles qui dériverait du
/// premier. On compose donc à l'échelle de l'app et `ImageRenderer` multiplie par trois.
///
/// # DES APLATS, COMME PARTOUT
///
/// Un fond noir franc, le tracé en un trait net d'accent, des chiffres blancs en Archivo, des
/// libellés en gris opaque et en casse de phrase. Ni dégradé, ni halo, ni lueur : les deux halos
/// de couleur et le dégradé des chiffres sont partis avec la refonte, parce que le tracé est le
/// sujet et que rien ne doit lui disputer l'œil. L'accent est celui de l'app (`HZCouleur.accent`),
/// comme la tuile de la marque qui signe l'image.
struct RunVideoFrameView: View {
    var run: RunRecord
    /// Le tracé ROGNÉ, tel que `RunVideoTimeline` le rend. Cette vue ne rogne rien elle-même :
    /// elle dessine ce qu'on lui donne, et ce qu'on lui donne est déjà passé par la porte du
    /// partage.
    var route: [RunRecord.RoutePoint]
    var instant: RunVideoTimeline.Instant

    /// La taille LOGIQUE, en points. Multipliée par `echelle` à la rasterisation.
    static let taille = CGSize(width: HZJournee.largeurDeLImage, height: HZJournee.hauteurDeLImage)
    /// Trois : 1080 × 1920, le neuf-seizièmes que tous les réseaux acceptent sans recadrer.
    static let echelle: CGFloat = HZJournee.echelleDeLaVideo

    var body: some View {
        VStack(spacing: 0) {
            entete.padding(.top, HZJournee.hautDeLaVideo)
            DrawnRoute(route: route,
                       lineWidth: HZJournee.traitDuTraceDeLaVideo,
                       couleur: HZCouleur.accent,
                       targetPoints: HZJournee.pointsDuTrace,
                       showsStart: true,
                       progress: instant.fractionDuTrace)
                .frame(width: HZJournee.coteDuTraceDeLaVideo, height: HZJournee.coteDuTraceDeLaVideo)
                .padding(.vertical, HZJournee.autourDuTraceDeLaVideo)
            compteurs
            Spacer(minLength: 0)
            signature.padding(.bottom, HZJournee.basDeLaVideo)
        }
        .frame(width: Self.taille.width, height: Self.taille.height)
        // Le fond doit être OPAQUE, contrairement à la carte de partage : une vidéo n'a pas de
        // couche alpha utilisable, et un fond transparent sort noir — ou pire, non défini.
        .background(HZCouleur.noirFranc)
    }

    // MARK: Les morceaux

    private var entete: some View {
        VStack(spacing: HZJournee.entreTitreEtDate) {
            Text(verbatim: run.titreAffiche)
                .hzAffichage(.titreDEcran)
                .foregroundStyle(HZCouleur.blanc)
                .multilineTextAlignment(.center)
                .lineLimit(HZJournee.lignesDuTitreDeLaVideo)
                .padding(.horizontal, HZJournee.margeDuTitreDeLaVideo)
            Text(verbatim: Self.dateFormatee(run.date))
                .font(HZJournee.police(HZJournee.tailleDuLibelleDeLaVideo, .semi))
                .foregroundStyle(HZCouleur.secondaireSurSombre)
        }
    }

    /// Les compteurs. Le dénivelé n'apparaît QUE lorsqu'il a une valeur : afficher « 0 m D+ » sur
    /// une sortie dont on ne connaît pas le dénivelé serait un chiffre faux, et c'est précisément
    /// ce que `RunVideoTimeline` refuse de produire.
    private var compteurs: some View {
        HStack(alignment: .top, spacing: 0) {
            compteur(Text("km"), TimeFormat.distance(km: instant.metres / HZJournee.metresParKilometre))
            compteur(Text("Temps"), TimeFormat.horloge(instant.secondes))
            if let denivele = instant.denivelePositifM {
                compteur(Text("D+ (m)"), "\(Int(denivele.rounded()))")
            }
        }
        .padding(.horizontal, HZJournee.margeDesCompteurs)
    }

    /// L'étiquette arrive en `Text` et non en `String` : c'est ce qui laisse le littéral visible
    /// dans un `Text("…")`, donc attrapable par `ci_scripts/check_strings.py`. Passé en chaîne, il
    /// aurait traversé le contrôle du catalogue sans être vu, et « Temps » serait sorti en
    /// français en anglais et en espagnol.
    private func compteur(_ label: Text, _ valeur: String) -> some View {
        VStack(spacing: HZJournee.entreLibelleEtValeur) {
            label
                .font(HZJournee.police(HZJournee.tailleDuLibelleDeLaVideo, .semi))
                .foregroundStyle(HZCouleur.secondaireSurSombre)
            Text(verbatim: valeur)
                .hzAffichage(.chiffreDeProfil)
                .foregroundStyle(HZCouleur.blanc)
                .lineLimit(1)
                .minimumScaleFactor(HZJournee.reductionDuCompteur)
        }
        .frame(maxWidth: .infinity)
    }

    private var signature: some View {
        HStack(spacing: HZJournee.entreLaMarqueEtLeMot) {
            AppMarkView(size: HZJournee.coteDeLaSignature)
            MotDeMarque(tuile: HZJournee.coteDeLaSignature)
                .foregroundStyle(HZCouleur.blanc)
        }
    }

    /// « 8 octobre 2026 », dans la langue du téléphone, en casse de phrase. Un `DateFormatter`
    /// statique : en construire un par image en fabriquerait trois cent soixante pour rien, et
    /// c'est l'objet le plus coûteux à créer de tout ce fichier.
    private static let formatteur: DateFormatter = {
        let f = DateFormatter()
        f.locale = .current
        f.setLocalizedDateFormatFromTemplate("d MMMM yyyy")
        return f
    }()

    private static func dateFormatee(_ date: Date) -> String {
        formatteur.string(from: date)
    }
}
