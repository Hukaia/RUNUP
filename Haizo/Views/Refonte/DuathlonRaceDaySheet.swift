import SwiftUI

/// Le jour J d'un duathlon : où passe le temps, où l'on mange, et le piège de la première
/// course.
///
/// Le plan répond à « que faire cette semaine ». Il ne répond pas à « comment se passe la
/// journée » — et un duathlon se perd sur ses premiers kilomètres, deux heures avant que ça se
/// voie. C'est la seule chose qu'aucune séance n'enseigne, parce qu'elle ne se joue pas aux
/// jambes mais à la tête, une fois, au départ.
///
/// Les fourchettes de ravitaillement viennent d'`UltraRaceDay` par `DuathlonRaceDay` : la
/// physiologie de l'endurance ne change pas parce qu'on change de sport. Ce qui change est la
/// FENÊTRE — ici, un vélo pris en sandwich entre deux courses.
struct DuathlonRaceDaySheet: View {
    var format: DuathlonFormat
    /// Le temps visé, en minutes. Sous trente minutes — donc quand on ne sait pas — les totaux
    /// se taisent plutôt que d'afficher des zéros qui auraient l'air d'une réponse. Même parti
    /// que les deux autres feuilles du jour J.
    var minutesVisees: Int

    private var connu: Bool { minutesVisees >= HZCourse.minutesMinimalesPourUnTotal }
    private var r: DuathlonRaceDay.Repartition {
        DuathlonRaceDay.repartition(format: format, minutesVisees: minutesVisees)
    }

    var body: some View {
        HZFeuilleModale(titre: String(localized: "Le jour J")) {
            ScrollView {
                VStack(alignment: .leading, spacing: HZEspace.entreSections) {
                    HZParagrapheDeCourse(Text("Un duathlon se décide sur ses premiers kilomètres, et la facture arrive deux heures plus tard. Ce qui suit ne se joue pas aux jambes."))

                    journee
                    premiereCourse
                    ravitaillement
                    transitions
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
                // `DuathlonFormat.km` et pas une mise en forme écrite ici : « 2.5 km » sous une
                // carte qui dit « 2,5 km » serait le même écran se contredisant.
                VStack(spacing: 0) {
                    HZLigneDeJournee(symbole: Image(systemName: "figure.run"), titre: String(localized: "Première course"),
                                     sousTitre: DuathlonFormat.km(format.premiereCourseKm),
                                     duree: TimeFormat.duree(r.premiereCourse * HZCourse.secondesParMinute))
                    HZLigneDeJournee(symbole: Image(systemName: "bicycle"), titre: String(localized: "Vélo"),
                                     sousTitre: DuathlonFormat.km(format.veloKm),
                                     duree: TimeFormat.duree(r.velo * HZCourse.secondesParMinute))
                    HZLigneDeJournee(symbole: Image(systemName: "figure.run"), titre: String(localized: "Seconde course"),
                                     sousTitre: DuathlonFormat.km(format.secondeCourseKm),
                                     duree: TimeFormat.duree(r.secondeCourse * HZCourse.secondesParMinute))
                    HZLigneDeJournee(symbole: Image(systemName: "arrow.triangle.swap"), titre: String(localized: "Transitions"),
                                     sousTitre: String(localized: "T1 et T2"),
                                     duree: TimeFormat.duree(r.transitions * HZCourse.secondesParMinute),
                                     filet: false)
                }
            }

            HZParagrapheDeCourse(Text(phraseDeLaJournee))
        }
    }

    /// Ce que la répartition dit, et qui n'est pas la même chose selon le format.
    ///
    /// Sur les deux formats courts, la seconde course est plus courte que la première : elle
    /// s'arrache. Sur les deux longs, elle est aussi longue ou bien plus, et tout ce qu'on a
    /// pris d'avance avant compte contre soi.
    private var phraseDeLaJournee: LocalizedStringKey {
        DuathlonRaceDay.secondeCourseAuMoinsAussiLongue(format)
            ? "Le vélo prend plus de la moitié de la journée, mais la seconde course est aussi longue que la première. Parfois bien plus. Tout ce que tu auras pris d'avance avant comptera contre toi là."
            : "Le vélo prend près de la moitié de la journée, et la seconde course à peine un sixième. Elle est courte : c'est ce qui donne envie de partir vite sur la première, et c'est l'erreur."
    }

    // MARK: Le piège

    private var premiereCourse: some View {
        VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
            HZTitreDeSection(titre: String(localized: "La première course"))

            HZParagrapheDeCourse(Text(phraseDuDepart))

            // Aucun chiffre, et c'est délibéré — voir `DuathlonRaceDay.lePiegeEstLaPremiereCourse`.
            // « Pars vingt secondes plus lentement » serait une fausse précision : l'écart juste
            // dépend du format, du niveau et du jour, et personne ne l'a mesuré pour cette app.
            HZParagrapheDeCourse(Text("LA FACTURE N'ARRIVE PAS TOUT DE SUITE. Elle arrive à la seconde course, et elle ne se renégocie pas : on ne rattrape pas sur la fin d'un duathlon ce qu'on a dépensé au début. Pars plus doucement que ce qui te semble juste."))

            HZParagrapheDeCourse(Text("C'est la raison d'être de la répétition générale du bloc d'affûtage : course → vélo → course, une fois, pour sentir ce que ça fait avant que ça compte."))
        }
    }

    // MARK: Le vélo est la seule fenêtre

    private var ravitaillement: some View {
        VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
            HZTitreDeSection(titre: String(localized: "Le vélo est la seule fenêtre"))

            HZParagrapheDeCourse(Text("Rien avant : la première course se fait à vide, et c'est sans conséquence, elle est courte. Rien après non plus : à pied, sur un estomac déjà secoué, presque tout est refusé."))

            if connu {
                HZChiffresDeCourse(chiffres: [
                    (glucides, String(localized: "g de glucides sur le vélo")),
                    (eau, String(localized: "ml à embarquer"))
                ])
            }

            HZParagrapheDeCourse(Text("Tout ce dont la seconde course aura besoin se prend sur la selle. Pas idéalement : c'est la règle. Et ça se teste à l'entraînement, sur les enchaînements, jamais le jour J."))
        }
    }

    private var glucides: String {
        let g = DuathlonRaceDay.glucidesSurLeVelo(r)
        return "\(g.min)–\(g.max)"
    }

    private var eau: String {
        let e = DuathlonRaceDay.eauSurLeVelo(r)
        return "\(e.min)–\(e.max)"
    }

    // MARK: Les transitions

    private var transitions: some View {
        VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
            HZTitreDeSection(titre: String(localized: "Les transitions"))

            // Pas de « c'est là que ça se gagne » : sur un duathlon, les transitions pèsent
            // entre 1,6 et 3,6 % selon le format — jamais le levier principal. Le dire
            // autrement serait envoyer quelqu'un travailler ce qui ne changera pas sa journée.
            HZParagrapheDeCourse(Text("Deux transitions, et aucune combinaison à retirer : elles sont plus courtes qu'en triathlon, et elles ne sont jamais là que ta journée se joue. Deux ou trois pour cent du total, pas davantage."))

            HZParagrapheDeCourse(Text(phraseDeT1))
        }
    }

    /// Deux phrases qui parlent À quelqu'un, donc qui s'accordent. Écrites dans les deux
    /// formes et choisies à l'affichage : un homme qui lit « tu seras fraîche » n'a pas affaire
    /// à une voix, il a affaire à une app qui ne l'a pas écouté. Voir `Accord`.
    private var phraseDuDepart: LocalizedStringKey {
        LocalizedStringKey(Accord.selon(
            f: String(localized: "Tu seras fraîche, en groupe, et cinq ou dix kilomètres ne font pas peur quand c'est ta distance d'entraînement. C'est exactement pour ça que presque tout le monde part trop vite."),
            m: String(localized: "Tu seras frais, en groupe, et cinq ou dix kilomètres ne font pas peur quand c'est ta distance d'entraînement. C'est exactement pour ça que presque tout le monde part trop vite.")))
    }

    private var phraseDeT1: LocalizedStringKey {
        LocalizedStringKey(Accord.selon(
            f: String(localized: "Elles méritent quand même d'être répétées une fois, non pour le chrono, mais pour ne pas découvrir en pleine course qu'on a oublié quelque chose. T1 surtout : on y arrive déjà essoufflée, et c'est là qu'on enfile un casque à l'envers."),
            m: String(localized: "Elles méritent quand même d'être répétées une fois, non pour le chrono, mais pour ne pas découvrir en pleine course qu'on a oublié quelque chose. T1 surtout : on y arrive déjà essoufflé, et c'est là qu'on enfile un casque à l'envers.")))
    }
}
