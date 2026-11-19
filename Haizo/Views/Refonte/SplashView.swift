import SwiftUI

/// Le lancement à froid : la marque se CONSTRUIT, puis le mot apparaît à côté d'elle.
///
/// L'écran de lancement du système (`UILaunchScreen` dans `project.yml`) ne sait afficher qu'une
/// couleur fixe. Celui-ci prend le relais dès que le code tourne, posé au-dessus de
/// `ContentRouterView` le temps de s'effacer.
///
/// # CE QU'IL MONTRAIT, ET POURQUOI ÇA NE SUFFISAIT PLUS
///
/// Le mot « Haizo » qui grossit de 6 % en fondu. C'est le lancement par défaut de n'importe
/// quelle app, et c'était le seul endroit où Haizo ne ressemblait pas à Haizo : son logo — quatre
/// foulées qui montent — n'y apparaissait pas une seule fois.
///
/// Les quatre barres se tracent maintenant du bas vers le haut, en se chevauchant, et le
/// mot-symbole se dévoile par un volet qui s'ouvre DEPUIS la tuile. L'œil suit donc une seule
/// trajectoire, de gauche à droite, à l'inclinaison du logo — au lieu de deux apparitions
/// simultanées sans rapport l'une avec l'autre.
///
/// # LA DURÉE EST UN BUDGET, PAS UN CHOIX ESTHÉTIQUE
///
/// 1,15 s au total, dont 0,75 de tracé. Un lancement est vu plusieurs fois par jour par quelqu'un
/// qui veut partir courir : chaque dixième ajouté ici est un dixième pris à la personne, tous les
/// jours. La séquence tient donc dans le temps qu'il faut de toute façon pour charger l'état de
/// l'app, et elle n'ajoute rien à l'attente — elle l'occupe.
struct SplashView: View {
    var onFinished: () -> Void

    @State private var drawn: Double = 0
    @State private var tile: Double = 0
    @State private var reveal: CGFloat = 0
    @State private var opacity: Double = 1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let markSize = HZLancement.coteDeLaTuile

    var body: some View {
        ZStack {
            HZCouleur.blanc.ignoresSafeArea()
            HStack(spacing: HZLancement.ecartTuileMot) {
                AppMarkView(size: markSize, radius: markSize * HZLancement.rayonRelatif, drawn: drawn)
                    // La tuile arrive derrière les barres, pas avec elles : les traits blancs se
                    // posent sur le noir, et le dégradé de marque monte dessous une fois qu'ils
                    // sont lisibles. Dans l'autre ordre, on voit un carré rose avant de voir un logo.
                    .opacity(tile)
                    .scaleEffect(HZLancement.echelleDeDepart + HZLancement.gainDEchelle * tile)

                // L'ENCRE EST CELLE DU KIT, PAS CELLE DE L'INTERFACE. `#1A1023` est un noir
                // FROID — bleu nettement au-dessus du rouge — là où `textPrimary` est passé au
                // chaud le 12 novembre pour suivre la famille des fonds. Les deux ont la même
                // luminance à un dixième près (18,31:1 contre 18,19:1 sur blanc), donc la
                // différence ne se voit qu'à côté : un logo garde son encre, c'est tout ce qui
                // le distingue d'un mot de l'interface.
                MotDeMarque(tuile: markSize)
                    .foregroundStyle(HZLancement.encreDeMarque)
                    .fixedSize()
                    // Un volet qui s'ouvre depuis la tuile. `scaleEffect` sur un masque plutôt
                    // qu'une largeur animée : la largeur reflowerait le `HStack` à chaque image et
                    // ferait glisser la tuile pendant que le mot se dévoile.
                    .mask(alignment: .leading) {
                        Rectangle().scaleEffect(x: reveal, y: HZLancement.echellePleine, anchor: .leading)
                    }
            }
        }
        // LE FONDU PORTE L'ÉCRAN ENTIER, FOND COMPRIS — et c'était là le sursaut.
        //
        // Il ne portait que le logo. Le fond, lui, restait opaque jusqu'à ce que `onFinished`
        // retire la vue : le mot s'effaçait sur un fond plein, puis l'app apparaissait d'un
        // coup, en une image. Un fondu suivi d'une coupe.
        //
        // Posé sur le `ZStack`, le même fondu découvre progressivement `ContentRouterView`, qui
        // est déjà dessiné dessous — l'ouverture devient un fondu enchaîné et ne coûte pas une
        // milliseconde de plus.
        .opacity(opacity)
        // Rien à toucher ici, et pendant les trois dixièmes du fondu l'écran d'ouverture
        // avalait les gestes destinés à l'app qui apparaît dessous.
        .allowsHitTesting(false)
        .onAppear { jouer() }
    }

    /// LA CHORÉGRAPHIE D'OUVERTURE, EN CLAIR.
    ///
    /// Ces six nombres étaient écrits à même les appels, et personne ne les avait jamais
    /// additionnés. Le dévoilement démarrait à 0,58 s pour 0,80 s, donc il finissait à 1,38 s —
    /// quand le fondu commençait à 1,15. **29 % du mouvement d'ouverture de l'app se jouait
    /// pendant que l'écran disparaissait déjà.** Chaque valeur était raisonnable toute seule ;
    /// le défaut ne vivait que dans leur somme.
    ///
    /// Nommés ici pour deux raisons. On les lit maintenant les uns à côté des autres, ce qui rend
    /// l'addition évidente. Et `check_lancement.py` les lit aussi : il refait la somme à chaque
    /// CI, avec les durées réelles de `RUMotion`, donc raccourcir ou rallonger un jeton du
    /// système de mouvement ne peut plus désaccorder l'ouverture en silence.
    private typealias Tempo = HZLancement.Tempo

    private func jouer() {
        guard !reduceMotion else {
            drawn = 1; tile = 1; reveal = 1
            Task {
                try? await Task.sleep(for: .seconds(Tempo.replatTenue))
                withAnimation(.easeIn(duration: Tempo.replatFondu)) { opacity = 0 }
                try? await Task.sleep(for: .seconds(Tempo.replatApres))
                onFinished()
            }
            return
        }

        withAnimation(.timingCurve(HZLancement.courbe.0, HZLancement.courbe.1, HZLancement.courbe.2, HZLancement.courbe.3, duration: Tempo.traceDuree)) { drawn = 1 }
        withAnimation(HZMouvement.ressort.delay(Tempo.tuileDepart)) { tile = 1 }
        withAnimation(HZMouvement.glisse.delay(Tempo.revealDepart)) { reveal = 1 }

        Task {
            try? await Task.sleep(for: .seconds(Tempo.fondu))
            withAnimation(.easeIn(duration: Tempo.fonduDuree)) { opacity = 0 }
            try? await Task.sleep(for: .seconds(Tempo.apresFondu))
            onFinished()
        }
    }
}
