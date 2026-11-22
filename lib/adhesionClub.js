// COMMENT ON ENTRE DANS UN CLUB : LES TROIS MODES, ET CE QUI SE CALCULE SANS BASE DE DONNÉES.
//
// Un club avait un seul réglage, `clubs.is_open` : ouvert (on le trouve et on le rejoint d'un
// appui) ou fermé (on ne le trouve pas et on ne le rejoint plus). Le propriétaire choisit
// maintenant entre trois façons, et le choix est SIENNE, pas celle de l'app :
//
//   · `open`    n'importe qui rejoint d'un appui ;
//   · `request` on demande depuis la fiche du club, le propriétaire accepte ou refuse ;
//   · `code`    seule une personne qui a le code d'invitation rejoint.
//
// LES CLUBS QUI EXISTAIENT GARDENT EXACTEMENT LEUR COMPORTEMENT : ouvert devient `open`, fermé
// devient `code` (un club fermé ne se trouve dans aucune recherche, et c'est aussi ce que fait
// un club sur code).
//
// # POURQUOI `is_open` RESTE, ET QUI EST LA SOURCE DE VÉRITÉ
//
// Une app déjà installée ne connaît pas `join_mode`. Elle lit `isOpen` et écrit `setOpen`.
// `is_open` reste donc écrit à chaque changement de mode (vrai pour `open` seulement), et la
// lecture d'un club passe par `modeDuClub` plutôt que par la seule colonne `join_mode` :
//
//   · `is_open = true`  ⇒ `open`, quelle que soit `join_mode`. C'est ce qu'une app ancienne a
//     écrit en rouvrant le club, et c'est ce que sa propriétaire a voulu.
//   · `is_open = false` ⇒ `request` si `join_mode` le dit, sinon `code`. Un club fermé par une
//     app ancienne (ou par la migration, avant le déploiement du code qui lit `join_mode`) est
//     donc un club sur code, jamais un club ouvert par accident.
//
// Si les deux colonnes se contredisent un instant (une app ancienne écrit pendant que le code
// neuf n'est pas encore déployé), c'est `is_open` qui l'emporte, et la contradiction se résorbe
// à la prochaine écriture du mode.

const { timingSafeEqual } = require('crypto');

const MODES = ['open', 'request', 'code'];

/// Le code d'invitation fait six signes : c'est `randomInviteCode` de `api/clubs/[action].js`,
/// qui n'emploie ni 0, ni O, ni 1, ni I.
const LONGUEUR_DU_CODE = 6;

/// Combien de demandes en attente une personne peut avoir à la fois. Une demande notifie un
/// propriétaire : sans borne, une personne pourrait les déranger tous, un à un.
const MAX_DEMANDES_EN_ATTENTE = 5;

/// Combien d'essais de code par jour. Le code a un milliard de combinaisons ; ce plafond n'est
/// pas là pour la probabilité mais pour qu'un script ne puisse pas essayer.
const MAX_ESSAIS_DE_CODE_PAR_JOUR = 15;

function modeValide(valeur) {
  return typeof valeur === 'string' && MODES.includes(valeur) ? valeur : null;
}

/// Le mode d'une ligne de `clubs`. Voir le commentaire de tête pour la règle.
function modeDuClub(ligne) {
  if (!ligne) return 'code';
  if (ligne.is_open === true) return 'open';
  return ligne.join_mode === 'request' ? 'request' : 'code';
}

/// Les deux colonnes à écrire pour un mode. `is_open` n'est vrai que pour `open`.
function colonnesDuMode(mode) {
  return { isOpen: mode === 'open', joinMode: mode };
}

/// Un code tel qu'une personne le tape : espaces, tirets et minuscules n'y changent rien. Rend
/// une chaîne vide pour tout ce qui n'est pas du texte.
function normaliserLeCode(brut) {
  if (typeof brut !== 'string') return '';
  return brut.replace(/[\s-]+/g, '').toUpperCase().slice(0, 32);
}

/// Deux codes sont-ils les mêmes ? Une comparaison en temps constant, parce que c'est la seule
/// valeur du serveur qu'on peut deviner caractère par caractère à partir de sa seule réponse.
function codesIdentiques(attendu, saisi) {
  const a = normaliserLeCode(attendu);
  const b = normaliserLeCode(saisi);
  if (!a || a.length !== b.length) return false;
  // `timingSafeEqual` lève si les longueurs diffèrent : elles sont égales, vérifié au-dessus.
  return timingSafeEqual(Buffer.from(a), Buffer.from(b));
}

/// Le code, tel que seule la personne qui a créé le club doit le voir : jamais pour un club
/// qui n'est pas sur code, jamais pour quelqu'un d'autre.
function codeVisible(mode, estProprietaire, codeDuClub) {
  return mode === 'code' && estProprietaire === true && codeDuClub ? codeDuClub : null;
}

module.exports = {
  MODES,
  LONGUEUR_DU_CODE,
  MAX_DEMANDES_EN_ATTENTE,
  MAX_ESSAIS_DE_CODE_PAR_JOUR,
  modeValide,
  modeDuClub,
  colonnesDuMode,
  normaliserLeCode,
  codesIdentiques,
  codeVisible,
};
