import Foundation
import SwiftUI

/// DES INTERRUPTEURS POUR TROUVER CE QUI CASSE, et rien d'autre.
///
/// Sur l'accueil et le plan refaits, le contenu d'un écran ne se remplace pas quand on en sort (la
/// barre change, le contenu reste), et la rangée des jours ne change pas de jour. Aucune ligne de
/// code ne l'explique à la lecture. Chaque interrupteur retire UNE des particularités de ces deux
/// écrans — ce qu'aucun autre écran de l'app n'a — pour que le test de capture dise laquelle est
/// en cause : `--sans-statusbar`, `--sans-fond`, `--sans-zonesure`, `--sans-recouvrement`,
/// `--sans-barre`, ou `--sans-tout`.
///
/// Hors DEBUG, tout est faux : la version publiée n'est jamais touchée. À supprimer dès que la
/// cause est trouvée.
enum DiagnosticRefonte {
    static func sans(_ nom: String) -> Bool {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        return arguments.contains("--sans-\(nom)") || (nom != "nu" && arguments.contains("--sans-tout"))
        #else
        return false
        #endif
    }

    /// UNE LIGNE DANS `/tmp/haizo-diag.log` : le simulateur partage le disque de la machine, le test
    /// de capture lit ce fichier. C'est le seul moyen de savoir ce que l'app a fait — une action
    /// est-elle partie, une vue a-t-elle été réévaluée — quand l'image ne change pas.
    static func noter(_ texte: @autoclosure () -> String) {
        #if DEBUG
        let ligne = "\(Int(Date().timeIntervalSince1970 * 1000)) \(texte())\n"
        guard let donnees = ligne.data(using: .utf8) else { return }
        let adresse = URL(fileURLWithPath: "/tmp/haizo-diag.log")
        if let fichier = try? FileHandle(forWritingTo: adresse) {
            fichier.seekToEndOfFile()
            fichier.write(donnees)
            try? fichier.close()
        } else {
            try? donnees.write(to: adresse)
        }
        #endif
    }
}

/// L'ACCUEIL, REMPLACÉ PAR LE MINIMUM : un texte et un bouton qui appelle `go(.coach)`. Si le contenu
/// se remplace avec lui, la cause est dans le sous-arbre de l'accueil refait ; sinon, dans la racine.
struct DiagnosticNuAccueil: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: HZEspace.groupe) {
            Text(verbatim: "nu-accueil")
            Button {
                appState.go(.coach)
            } label: {
                Text(verbatim: "aller-coach")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

/// LE PLAN, REMPLACÉ PAR LE MINIMUM : un compteur `@State` et un bouton qui l'incrémente.
struct DiagnosticNuPlan: View {
    @State private var n = 0

    var body: some View {
        VStack(spacing: HZEspace.groupe) {
            Text(verbatim: "n=\(n)")
            Button {
                n += 1
            } label: {
                Text(verbatim: "incrementer")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

/// UN `ScrollView`, ou un simple empilement quand `--sans-defilement` est demandé.
struct DiagnosticDefilement<Contenu: View>: View {
    @ViewBuilder var contenu: () -> Contenu

    var body: some View {
        if DiagnosticRefonte.sans("defilement") {
            VStack(spacing: 0) { contenu() }
        } else {
            ScrollView { contenu() }
        }
    }
}

/// UNE ÉCHELLE D'ÉCRANS QUI AJOUTENT UN INGRÉDIENT À LA FOIS à une sonde (un bouton et son compteur),
/// du `@State` seul jusqu'au décor de la page. Le premier échelon où le compteur cesse de suivre
/// désigne l'ingrédient qui casse le suivi des états : `--echelle=<nom>`.
struct DiagnosticEchelle: View {
    enum Niveau: String, CaseIterable {
        case etat, profil, abonnement, modele, polices, defilement, page

        /// Le niveau demandé au lancement, s'il y en a un. Hors DEBUG : jamais.
        static func demande() -> Niveau? {
            #if DEBUG
            let prefixe = "--echelle="
            guard let argument = ProcessInfo.processInfo.arguments.first(where: { $0.hasPrefix(prefixe) })
            else { return nil }
            return Niveau(rawValue: String(argument.dropFirst(prefixe.count)))
            #else
            return nil
            #endif
        }

        func atteint(_ autre: Niveau) -> Bool {
            let tous = Niveau.allCases
            return (tous.firstIndex(of: self) ?? 0) >= (tous.firstIndex(of: autre) ?? 0)
        }
    }

    let niveau: Niveau
    @Environment(AppState.self) private var appState
    @Environment(SubscriptionService.self) private var subscriptions
    @State private var compteur = 0

    var body: some View {
        let _ = DiagnosticRefonte.noter("DiagnosticEchelle.body \(niveau.rawValue) compteur=\(compteur)")
        if niveau.atteint(.defilement) {
            ScrollView { contenu }
                .modifier(Decor(actif: niveau.atteint(.page)))
        } else {
            contenu
        }
    }

    private var contenu: some View {
        VStack(alignment: .leading, spacing: HZEspace.groupe) {
            Button { compteur += 1 } label: {
                Text(verbatim: "sonde-\(compteur)").foregroundStyle(HZCouleur.noir)
            }
            if niveau.atteint(.profil) {
                Text(verbatim: "seances \(appState.profile.weekSessions.count)")
            }
            if niveau.atteint(.abonnement) {
                Text(verbatim: "ouvert \(subscriptions.unlocks(.adaptivePlan))")
            }
            if niveau.atteint(.modele) {
                Text(verbatim: "jours \(jours.count)")
            }
            if niveau.atteint(.polices) {
                Text(verbatim: "Ta semaine").hzAffichage(.titreDePage)
                Text(verbatim: "sous-titre").hzTexte(.c15, .semi)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var jours: [PlanSemaineModele.Jour] {
        PlanSemaineModele.jours(appState.profile.weekSessions,
                                aujourdHui: PlanSemaineModele.indiceDuJour(Demonstration.maintenant),
                                lundi: PlanSemaineModele.lundi(de: Demonstration.maintenant),
                                titreDuRepos: String(localized: "Jour de repos"))
    }

    private struct Decor: ViewModifier {
        let actif: Bool

        func body(content: Content) -> some View {
            if actif {
                content
                    .background {
                        VStack(spacing: 0) {
                            HZCouleur.noir
                            HZCouleur.blanc
                        }
                        .ignoresSafeArea()
                    }
                    .ignoresSafeArea(edges: .top)
                    .statusBarHidden(true)
            } else {
                content
            }
        }
    }
}
