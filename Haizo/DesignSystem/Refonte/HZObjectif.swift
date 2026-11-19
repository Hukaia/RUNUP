import CoreGraphics

/// LES MESURES DU NOUVEL OBJECTIF ET DE LA FIN DE PROGRAMME : l'assistant « nouvel objectif », le
/// choix qui suit la récupération, et la récupération elle-même.
///
/// L'assistant parle le langage de l'inscription : une question en très grand, ses réponses en
/// grandes lignes grises (`HZReponse`), la progression en segments (`HZSegments`), une pilule noire
/// en bas. Il n'a donc presque pas de mesure à lui — celles de `HZEntree` et de `HZEspace` suffisent.
/// Ce qui est ici est ce qu'aucun jeton partagé ne dit : les bornes d'une date, le rang du chrono
/// proposé d'abord, le temps que dure la construction du plan.
enum HZObjectif {
    /// La course est proposée dans soixante jours tant que rien n'a été choisi.
    static let joursAvantLaDateParDefaut = 60
    /// La première date qu'on puisse choisir : demain.
    static let joursAvantLaPremiereDate = 1
    /// Le chrono proposé d'abord : le deuxième de la liste, celui du milieu de la fourchette.
    static let rangDuChronoParDefaut = 1
    /// Sept cases, une par jour de la semaine, lundi à zéro.
    static let joursDeLaSemaine = 7
    /// Deux jours au moins, tant qu'aucun objectif n'a été choisi.
    static let joursMinimumParDefaut = 2
    /// Les étapes : l'objectif, puis (pour une course, un triathlon, un duathlon) ses détails, puis les jours.
    static let etapeDesJours = 2
    /// Trois écrans de questions quand l'objectif a des détails, deux sinon.
    static let etapesAvecDetails = 3
    static let etapesSansDetails = 2
    /// Le temps que dure la construction, en secondes : le même que l'attente avant que le nouveau
    /// programme soit réellement prêt.
    static let dureeDeLaConstruction: Double = 2.2
    /// L'espace entre le disque, le titre et la jauge, sur l'écran de construction.
    static let ecartDeLaConstruction: CGFloat = 24
    /// Le signe (la marque, puis la coche) dans le disque noir de la construction.
    static let coteDuSigne: CGFloat = 36
    /// Sous le titre de la page de fin de programme, avant la feuille.
    static let sousLeTitre: CGFloat = 4
}
