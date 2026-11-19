import SwiftUI

/// Le jour J d'un triathlon : où passe le temps, où l'on mange, ce qui se perd en transition.
///
/// Le plan répond à « que faire cette semaine ». Il ne répond pas à « comment se passe la
/// journée », et un triathlon se perd au ventre et en transition bien plus souvent qu'aux
/// jambes. Les trois sections de cet écran sont les trois choses qu'aucune séance n'enseigne.
///
/// Les fourchettes viennent d'`UltraRaceDay` par `TriathlonRaceDay` : la physiologie de
/// l'endurance ne change pas parce qu'on change de sport. Ce qui change est la RÉPARTITION, et
/// c'est tout l'objet de cet écran — la même somme horaire, concentrée sur une fenêtre qui
/// exclut la natation et se referme dès le début de la course.
struct TriathlonRaceDaySheet: View {
    var format: TriathlonFormat
    /// Le temps visé, en minutes. Zéro — donc quand on ne sait pas — fait taire les totaux
    /// plutôt que d'afficher des zéros qui auraient l'air d'une réponse. Même parti que
    /// `UltraRaceDaySheet`.
    var minutesVisees: Int

    private var connu: Bool { minutesVisees >= HZCourse.minutesMinimalesPourUnTotal }
    private var r: TriathlonRaceDay.Repartition {
        TriathlonRaceDay.repartition(format: format, minutesVisees: minutesVisees)
    }

    var body: some View {
        HZFeuilleModale(titre: String(localized: "Le jour J")) {
            ScrollView {
                VStack(alignment: .leading, spacing: HZEspace.entreSections) {
                    HZParagrapheDeCourse(Text("Trois choses décident d'un triathlon, et aucune n'est ton entraînement. Elles se préparent, et elles se testent à l'entraînement, jamais le jour J."))

                    journee
                    ravitaillement
                    transitions
                    combinaison
                }
                .padding(.horizontal, HZEspace.marge)
            }
        }
    }

    // MARK: Où passe le temps

    private var journee: some View {
        VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
            HZTitreDeSection(titre: String(localized: "Où passe la journée"))

            if connu {
                VStack(spacing: 0) {
                    HZLigneDeJournee(symbole: Image(systemName: "figure.pool.swim"), titre: String(localized: "Natation"),
                                     sousTitre: "\(format.nageMetres) " + String(localized: "m"),
                                     duree: TimeFormat.duree(r.nage * HZCourse.secondesParMinute))
                    HZLigneDeJournee(symbole: Image(systemName: "bicycle"), titre: String(localized: "Vélo"),
                                     sousTitre: "\(Int(format.veloKm.rounded())) " + String(localized: "km"),
                                     duree: TimeFormat.duree(r.velo * HZCourse.secondesParMinute))
                    HZLigneDeJournee(symbole: Image(systemName: "figure.run"), titre: String(localized: "Course"),
                                     sousTitre: "\(Int(format.courseKm.rounded())) " + String(localized: "km"),
                                     duree: TimeFormat.duree(r.course * HZCourse.secondesParMinute))
                    HZLigneDeJournee(symbole: Image(systemName: "arrow.triangle.swap"), titre: String(localized: "Transitions"),
                                     sousTitre: String(localized: "T1 et T2"),
                                     duree: TimeFormat.duree(r.transitions * HZCourse.secondesParMinute),
                                     filet: false)
                }
            }

            HZParagrapheDeCourse(Text("Le vélo prend à peu près la moitié de la journée — plus que les deux autres réunies sur un format long. C'est lui qui décide de ce que tu auras dans les jambes en descendant de selle."))
        }
    }

    // MARK: On ne mange pas dans l'eau

    private var ravitaillement: some View {
        VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
            HZTitreDeSection(titre: String(localized: "On ne mange pas dans l'eau"))

            HZParagrapheDeCourse(Text("La natation ne permet aucun ravitaillement, et la combinaison comprime l'estomac. Ta nutrition commence à la sortie de l'eau, alors qu'une partie de l'effort est déjà faite."))

            if connu {
                HZChiffresDeCourse(chiffres: [
                    (glucides, String(localized: "g de glucides sur le vélo")),
                    (eau, String(localized: "ml à embarquer"))
                ])
            }

            HZParagrapheDeCourse(Text("TOUT CE QUI SERA NÉCESSAIRE POUR LA COURSE SE PREND SUR LE VÉLO. Pas idéalement : c'est la règle. À pied, après des heures de selle, l'estomac refuse presque tout, et c'est pour ça qu'on peut bien nager, bien rouler, et s'arrêter de courir."))
        }
    }

    private var glucides: String {
        let g = TriathlonRaceDay.glucidesSurLeVelo(r)
        return "\(g.min)–\(g.max)"
    }

    private var eau: String {
        let e = TriathlonRaceDay.eauSurLeVelo(r)
        return "\(e.min)–\(e.max)"
    }

    // MARK: Les transitions

    private var transitions: some View {
        VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
            HZTitreDeSection(titre: String(localized: "Les transitions"))

            HZParagrapheDeCourse(Text(phraseDesTransitions))

            HZParagrapheDeCourse(Text("Deux minutes gagnées là, c'est deux minutes de chrono sans un battement de cœur de plus. Pose ton matériel dans l'ordre où tu le prendras, répète-le une fois, et tu ne chercheras rien le jour J."))
        }
    }

    /// La phrase change avec le format, parce que le conseil n'est pas le même.
    ///
    /// Les transitions pèsent sept pour cent d'un sprint et moins de deux d'une longue distance.
    /// Dire « un triathlon se gagne en transition » à quelqu'un qui prépare un Ironman serait
    /// l'envoyer travailler la seule chose qui ne changera rien à sa journée.
    private var phraseDesTransitions: LocalizedStringKey {
        TriathlonRaceDay.transitionsDecisives(format)
            ? "Sur un format court, les transitions pèsent près d'un dixième de la journée. C'est là que ce format se gagne, et c'est la seule partie qui ne coûte aucune condition physique."
            : LocalizedStringKey(Accord.selon(
                f: String(localized: "Sur un format long, les transitions pèsent peu : le temps est ailleurs. Elles méritent quand même d'être répétées une fois — non pour le chrono, mais pour ne pas découvrir fatiguée qu'on a oublié quelque chose."),
                m: String(localized: "Sur un format long, les transitions pèsent peu : le temps est ailleurs. Elles méritent quand même d'être répétées une fois — non pour le chrono, mais pour ne pas découvrir fatigué qu'on a oublié quelque chose.")))
    }

    // MARK: La combinaison

    private var combinaison: some View {
        VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
            HZTitreDeSection(titre: String(localized: "La combinaison"))

            HZParagrapheDeCourse(Text("Elle est obligatoire en dessous d'une certaine température d'eau, et INTERDITE au-dessus d'une autre. Les deux seuils dépendent de la fédération, du format et de l'année : ils se lisent au briefing, et nulle part ailleurs."))

            // Aucun chiffre, et c'est délibéré — voir
            // `TriathlonRaceDay.combinaisonEstUneRegleDeCourse`. Un seuil faux ici n'est pas une
            // approximation : c'est quelqu'un qui arrive au départ avec une combinaison qu'on va
            // lui refuser, ou sans celle qu'on va lui réclamer.
            HZParagrapheDeCourse(Text("Ce qui se prépare, en revanche : nager dedans avant le jour J. Elle serre, elle gêne la respiration, et elle change la position dans l'eau. Et l'enlever vite s'apprend — c'est la moitié de T1."))
        }
    }
}
