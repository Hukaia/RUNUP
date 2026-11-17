// ENGENDRÉ par `ci_scripts/icones.py` depuis `design/icones.json`.
// Ne pas modifier à la main : corriger le JSON, relancer le script.
//
// Les vingt-neuf icônes du canvas de la refonte, trait pour trait. Voir l'en-tête du script
// pour la raison — et `HZIcone` pour la vue qui les dessine.

import SwiftUI

extension HZDessin {
    static let aujourdhui = HZDessin(
        boite: 24, plein: false, bout: .round, joint: .miter,
        traces: [
            .rectangle(5, 3, 14, 18, 4),
        ])

    static let barres = HZDessin(
        boite: 24, plein: false, bout: .round, joint: .miter,
        traces: [
            .depart(5, 20),
            .ligne(5, 11),
            .depart(12, 20),
            .ligne(12, 4),
            .depart(19, 20),
            .ligne(19, 14),
        ])

    static let bulle = HZDessin(
        boite: 24, plein: false, bout: .round, joint: .round,
        traces: [
            .depart(4, 5),
            .ligne(20, 5),
            .ligne(20, 16),
            .ligne(9, 16),
            .ligne(4, 20),
            .ligne(4, 5),
            .fermer,
        ])

    static let calendrier = HZDessin(
        boite: 24, plein: false, bout: .round, joint: .miter,
        traces: [
            .rectangle(3, 5, 18, 16, 3),
            .depart(3, 10),
            .ligne(21, 10),
            .depart(8, 3),
            .ligne(8, 7),
            .depart(16, 3),
            .ligne(16, 7),
        ])

    static let chevron = HZDessin(
        boite: 24, plein: false, bout: .round, joint: .miter,
        traces: [
            .depart(9, 6),
            .ligne(15, 12),
            .ligne(9, 18),
        ])

    static let cloche = HZDessin(
        boite: 24, plein: false, bout: .round, joint: .round,
        traces: [
            .depart(6, 16),
            .ligne(6, 11),
            .courbe(6, 7.686, 8.686, 5, 12, 5),
            .courbe(15.314, 5, 18, 7.686, 18, 11),
            .ligne(18, 16),
            .ligne(20, 18),
            .ligne(4, 18),
            .ligne(6, 16),
            .fermer,
            .depart(10, 21),
            .ligne(14, 21),
        ])

    static let coche = HZDessin(
        boite: 24, plein: false, bout: .round, joint: .round,
        traces: [
            .depart(5, 12),
            .ligne(10, 17),
            .ligne(19, 7),
        ])

    static let coeur = HZDessin(
        boite: 24, plein: false, bout: .round, joint: .round,
        traces: [
            .depart(12, 20),
            .courbe(12, 20, 5, 15.5, 5, 10),
            .courbe(5.059, 8.363, 6.109, 6.927, 7.652, 6.376),
            .courbe(9.195, 5.825, 10.918, 6.27, 12, 7.5),
            .courbe(13.082, 6.27, 14.805, 5.825, 16.348, 6.376),
            .courbe(17.891, 6.927, 18.941, 8.363, 19, 10),
            .courbe(19, 15.5, 12, 20, 12, 20),
            .fermer,
        ])

    static let curseurs = HZDessin(
        boite: 24, plein: false, bout: .round, joint: .miter,
        traces: [
            .depart(4, 8),
            .ligne(14, 8),
            .depart(18, 8),
            .ligne(20, 8),
            .depart(4, 16),
            .ligne(6, 16),
            .depart(10, 16),
            .ligne(20, 16),
            .ellipse(14, 6, 4, 4),
            .ellipse(6, 14, 4, 4),
        ])

    static let deplacer = HZDessin(
        boite: 24, plein: false, bout: .round, joint: .round,
        traces: [
            .depart(4, 8),
            .ligne(17, 8),
            .ligne(14, 5),
            .depart(20, 16),
            .ligne(7, 16),
            .ligne(10, 19),
        ])

    static let drapeau = HZDessin(
        boite: 24, plein: false, bout: .round, joint: .round,
        traces: [
            .depart(5, 21),
            .ligne(5, 4),
            .ligne(17, 4),
            .ligne(15, 8),
            .ligne(17, 12),
            .ligne(5, 12),
        ])

    static let envoyer = HZDessin(
        boite: 24, plein: false, bout: .round, joint: .round,
        traces: [
            .depart(12, 19),
            .ligne(12, 5),
            .depart(6, 11),
            .ligne(12, 5),
            .ligne(18, 11),
        ])

    static let fermer = HZDessin(
        boite: 24, plein: false, bout: .round, joint: .miter,
        traces: [
            .depart(6, 6),
            .ligne(18, 18),
            .depart(18, 6),
            .ligne(6, 18),
        ])

    static let fil = HZDessin(
        boite: 24, plein: false, bout: .round, joint: .round,
        traces: [
            .depart(4, 6),
            .ligne(20, 6),
            .depart(4, 12),
            .ligne(20, 12),
            .depart(4, 18),
            .ligne(14, 18),
        ])

    static let groupe = HZDessin(
        boite: 24, plein: false, bout: .round, joint: .miter,
        traces: [
            .ellipse(5.5, 4.5, 7, 7),
            .ellipse(14.5, 6.5, 5, 5),
            .depart(2.5, 20),
            .courbe(2.5, 16.5, 5.5, 14, 9, 14),
            .courbe(12.5, 14, 15.5, 16.5, 15.5, 20),
        ])

    static let haltere = HZDessin(
        boite: 24, plein: false, bout: .round, joint: .miter,
        traces: [
            .depart(3, 9),
            .ligne(3, 15),
            .depart(6, 6),
            .ligne(6, 18),
            .depart(18, 6),
            .ligne(18, 18),
            .depart(21, 9),
            .ligne(21, 15),
            .depart(6, 12),
            .ligne(18, 12),
        ])

    static let itineraire = HZDessin(
        boite: 24, plein: false, bout: .round, joint: .round,
        traces: [
            .depart(4, 18),
            .courbe(8, 17, 7, 11, 11, 10),
            .courbe(15, 9, 15, 15, 20, 13),
            .ellipse(2.5, 16.5, 3, 3),
            .ellipse(18.5, 11.5, 3, 3),
        ])

    static let lecture = HZDessin(
        boite: 14, plein: true, bout: .butt, joint: .miter,
        traces: [
            .depart(3.5, 1.5),
            .ligne(3.5, 12.5),
            .ligne(12.5, 7),
            .ligne(3.5, 1.5),
            .fermer,
        ])

    static let marque = HZDessin(
        boite: 24, plein: true, bout: .butt, joint: .miter,
        traces: [
            .depart(3, 20),
            .ligne(3, 15),
            .ligne(6.5, 15),
            .ligne(6.5, 20),
            .ligne(3, 20),
            .fermer,
            .depart(8.5, 20),
            .ligne(8.5, 10),
            .ligne(12, 10),
            .ligne(12, 20),
            .ligne(8.5, 20),
            .fermer,
            .depart(14, 20),
            .ligne(14, 12),
            .ligne(17.5, 12),
            .ligne(17.5, 20),
            .ligne(14, 20),
            .fermer,
            .depart(19.5, 20),
            .ligne(19.5, 4),
            .ligne(23, 4),
            .ligne(23, 20),
            .ligne(19.5, 20),
            .fermer,
        ])

    static let micro = HZDessin(
        boite: 24, plein: false, bout: .round, joint: .miter,
        traces: [
            .rectangle(9, 3, 6, 12, 3),
            .depart(5, 11),
            .courbe(5, 14.866, 8.134, 18, 12, 18),
            .courbe(15.866, 18, 19, 14.866, 19, 11),
            .depart(12, 18),
            .ligne(12, 21),
        ])

    static let options = HZDessin(
        boite: 24, plein: true, bout: .butt, joint: .miter,
        traces: [
            .ellipse(3, 10, 4, 4),
            .ellipse(10, 10, 4, 4),
            .ellipse(17, 10, 4, 4),
        ])

    static let partager = HZDessin(
        boite: 24, plein: false, bout: .round, joint: .round,
        traces: [
            .depart(12, 15),
            .ligne(12, 4),
            .depart(8, 8),
            .ligne(12, 4),
            .ligne(16, 8),
            .depart(5, 14),
            .ligne(5, 19),
            .ligne(19, 19),
            .ligne(19, 14),
        ])

    static let recentrer = HZDessin(
        boite: 24, plein: false, bout: .round, joint: .round,
        traces: [
            .depart(20, 4),
            .ligne(4, 11),
            .ligne(11, 13),
            .ligne(13, 20),
            .ligne(20, 4),
            .fermer,
        ])

    static let recherche = HZDessin(
        boite: 24, plein: false, bout: .round, joint: .miter,
        traces: [
            .ellipse(4, 4, 14, 14),
            .depart(20, 20),
            .ligne(16, 16),
        ])

    static let reduire = HZDessin(
        boite: 24, plein: false, bout: .round, joint: .miter,
        traces: [
            .depart(6, 9),
            .ligne(12, 15),
            .ligne(18, 9),
        ])

    static let relief = HZDessin(
        boite: 24, plein: false, bout: .round, joint: .round,
        traces: [
            .depart(2, 20),
            .ligne(9, 8),
            .ligne(13, 14),
            .ligne(16, 10),
            .ligne(22, 20),
            .ligne(2, 20),
            .fermer,
        ])

    static let retour = HZDessin(
        boite: 24, plein: false, bout: .round, joint: .round,
        traces: [
            .depart(15, 5),
            .ligne(8, 12),
            .ligne(15, 19),
        ])

    static let route = HZDessin(
        boite: 24, plein: false, bout: .round, joint: .miter,
        traces: [
            .depart(9, 3),
            .ligne(5, 21),
            .depart(15, 3),
            .ligne(19, 21),
            .depart(12, 5),
            .ligne(12, 8),
            .depart(12, 11),
            .ligne(12, 14),
            .depart(12, 17),
            .ligne(12, 20),
        ])

    static let trophee = HZDessin(
        boite: 24, plein: false, bout: .round, joint: .round,
        traces: [
            .depart(7, 4),
            .ligne(17, 4),
            .ligne(17, 9),
            .courbe(17, 11.761, 14.761, 14, 12, 14),
            .courbe(9.239, 14, 7, 11.761, 7, 9),
            .ligne(7, 4),
            .fermer,
            .depart(12, 14),
            .ligne(12, 18),
            .depart(8, 20),
            .ligne(16, 20),
        ])

    /// Toutes, dans l'ordre alphabétique — pour la planche, qui les montre d'un coup.
    static let toutes: [(nom: String, dessin: HZDessin)] = [
        ("aujourdhui", .aujourdhui),
        ("barres", .barres),
        ("bulle", .bulle),
        ("calendrier", .calendrier),
        ("chevron", .chevron),
        ("cloche", .cloche),
        ("coche", .coche),
        ("coeur", .coeur),
        ("curseurs", .curseurs),
        ("deplacer", .deplacer),
        ("drapeau", .drapeau),
        ("envoyer", .envoyer),
        ("fermer", .fermer),
        ("fil", .fil),
        ("groupe", .groupe),
        ("haltere", .haltere),
        ("itineraire", .itineraire),
        ("lecture", .lecture),
        ("marque", .marque),
        ("micro", .micro),
        ("options", .options),
        ("partager", .partager),
        ("recentrer", .recentrer),
        ("recherche", .recherche),
        ("reduire", .reduire),
        ("relief", .relief),
        ("retour", .retour),
        ("route", .route),
        ("trophee", .trophee),
    ]
}
