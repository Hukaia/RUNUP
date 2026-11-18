import SwiftUI

/// UNE TUILE DE « CE QU'IL REGARDE » : trois, côte à côte, sous le titre du Coach.
///
/// Un libellé en haut, une valeur en bas, sur une carte de 104 points. La première (la forme) est
/// à l'accent, les deux autres sur le noir doux — c'est `Coach.dc.html`, à la lettre. La valeur est
/// toujours blanche ; seul le libellé change de teinte, pour rester lisible sur l'accent.
struct HZTuileDuCoach: View {
    let libelle: String
    let valeur: String
    var style: HZAffichage = .chiffre
    var fond: Color = HZCouleur.surfaceSombre
    var encreDuLibelle: Color = HZCouleur.secondaireSurSombre
    var graisseDuLibelle: HZGraisse = .semi

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(libelle)
                .hzTexte(.c13, graisseDuLibelle)
                .foregroundStyle(encreDuLibelle)
                .lineLimit(1)
            Spacer(minLength: 0)
            Text(valeur)
                .hzAffichage(style)
                .foregroundStyle(HZCouleur.blanc)
                // Un nom de séance de plus de deux mots remplit le tiers de la largeur : il
                // rétrécit plutôt que de se couper — un nom tronqué est un nom faux.
                .minimumScaleFactor(HZCoach.retraitDUneValeur)
        }
        .padding(.vertical, HZCoach.margeVerticaleDeTuile)
        .padding(.horizontal, HZEspace.tuile)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: HZCoach.hauteurDeTuile)
        .background(fond, in: RoundedRectangle(cornerRadius: HZRayon.groupe, style: .circular))
        .accessibilityElement(children: .combine)
    }
}

/// QUI PARLE, dans une bulle.
enum HZAuteurDeBulle {
    case coach
    case coureuse
}

/// UNE BULLE DU FIL. Celle du coach est claire, alignée à gauche, son coin bas-gauche est vif ;
/// celle de la coureuse est noire, alignée à droite, son coin bas-droit est vif.
///
/// Le contenu est libre : un texte, ou un texte et un bouton (la réponse qui dit ce qui manque à
/// qui n'a pas souscrit). Il se met en page lui-même ; la bulle ne fait que l'envelopper.
struct HZBulle<Contenu: View>: View {
    let auteur: HZAuteurDeBulle
    @ViewBuilder var contenu: () -> Contenu

    var body: some View {
        HStack(spacing: 0) {
            if auteur == .coureuse { Spacer(minLength: 0) }
            contenu()
                .padding(.horizontal, HZCoach.margeHorizontaleDeBulle)
                .padding(.vertical, auteur == .coach ? HZCoach.margeVerticaleDeBulleDuCoach
                                                     : HZCoach.margeVerticaleDeBulleDeLaCoureuse)
                .background(fond, in: forme)
                .frame(maxWidth: HZCoach.largeurMaxDeBulle,
                       alignment: auteur == .coach ? .leading : .trailing)
            if auteur == .coach { Spacer(minLength: 0) }
        }
        .frame(maxWidth: .infinity)
    }

    private var fond: Color {
        auteur == .coach ? HZCouleur.surfaceClaire : HZCouleur.encre
    }

    private var forme: UnevenRoundedRectangle {
        let coin = HZRayon.groupe
        let vif = HZRayon.coinDeBulle
        return UnevenRoundedRectangle(topLeadingRadius: coin,
                                      bottomLeadingRadius: auteur == .coach ? vif : coin,
                                      bottomTrailingRadius: auteur == .coach ? coin : vif,
                                      topTrailingRadius: coin,
                                      style: .circular)
    }
}

extension HZBulle where Contenu == Text {
    /// Une bulle qui ne porte qu'une phrase.
    init(_ texte: String, auteur: HZAuteurDeBulle) {
        self.auteur = auteur
        self.contenu = {
            Text(texte)
        }
    }
}

/// LE TEXTE D'UNE BULLE : 15 points, interligne 1,4 ; blanc sur la bulle noire, encre sur la claire.
struct HZTexteDeBulle: View {
    let texte: String
    let auteur: HZAuteurDeBulle

    var body: some View {
        Text(texte)
            .hzParagraphe(.c15, .medium, interligne: HZCoach.interligne)
            .foregroundStyle(auteur == .coach ? HZCouleur.encre : HZCouleur.blanc)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// LA SAISIE : une capsule claire de 54 points, le champ à gauche, le bouton d'envoi noir à droite.
struct HZSaisie: View {
    @Binding var texte: String
    let invite: String
    let nomDuBouton: String
    let peutEnvoyer: Bool
    let envoyer: () -> Void

    var body: some View {
        HStack(spacing: HZEspace.entreCommandes) {
            TextField("", text: $texte,
                      prompt: Text(invite).foregroundStyle(HZCouleur.secondaireSurClair))
                .hzTexte(.c15, .medium)
                .foregroundStyle(HZCouleur.encre)
                // En conversation, « retour » veut dire « envoyer », comme dans toute messagerie.
                .submitLabel(.send)
                .onSubmit(envoyer)
            Button(action: envoyer) {
                HZIcone(dessin: .envoyer, cote: HZCoach.coteDeLEnvoi, trait: HZCoach.traitDeLEnvoi,
                        couleur: HZCouleur.blanc)
                    .frame(width: HZDiametre.outil.rawValue, height: HZDiametre.outil.rawValue)
                    .background(HZCouleur.encre, in: Circle())
                    .opacity(peutEnvoyer ? HZPlan.pleine : HZCoach.envoiEteint)
            }
            .buttonStyle(.plain)
            .disabled(!peutEnvoyer)
            .accessibilityLabel(nomDuBouton)
        }
        .padding(.leading, HZCoach.margeGaucheDeSaisie)
        .padding(.trailing, HZCoach.margeDroiteDeSaisie)
        .frame(height: HZCoach.hauteurDeSaisie)
        .background(HZCouleur.surfaceClaire, in: Capsule())
    }
}
