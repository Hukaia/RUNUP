// À QUI REVIENT UN CLUB QUAND SA CRÉATRICE LE QUITTE.
//
// `leave` retirait l'adhésion et rien d'autre. La créatrice qui quittait son club le laissait donc
// avec un `created_by` qui n'en était plus membre : personne pour accepter une demande d'adhésion,
// changer le mode d'entrée ou nommer un organisateur, et aucun moyen pour elle d'y revenir si le
// club était sur demande ou sur code. Un club vivant, et que plus personne ne pouvait tenir.
//
// La règle, écrite une fois et éprouvée dans `tests/proprieteClub.test.js` :
//
//   · le club passe à l'organisateur le plus ANCIEN ; à défaut, au membre le plus ancien.
//     L'ancienneté, et non l'activité ou les points : c'est le seul critère que tout le monde peut
//     vérifier en regardant la liste des membres, et qui ne change pas d'une semaine à l'autre ;
//   · s'il ne reste personne, il n'y a pas d'héritier, et l'appelant supprime le club. Un club sans
//     membre ne se trouve dans aucune liste et ne sert à personne.
//
// Une fonction pure, sans base : le choix est une décision de produit, pas une requête.

/**
 * @param {Array<{userId: string, role?: string, joinedAt: string|Date}>} membres tous les membres
 * @param {string} partant celle ou celui qui quitte le club
 * @returns {string|null} l'identifiant de l'héritier, ou null s'il ne reste personne
 */
function heritierDuClub(membres, partant) {
  const restants = (Array.isArray(membres) ? membres : []).filter((m) => m && m.userId && m.userId !== partant);
  if (restants.length === 0) return null;
  const depuis = (m) => {
    const t = new Date(m.joinedAt).getTime();
    // Une date illisible range le membre en dernier plutôt que de faire planter le tri.
    return Number.isFinite(t) ? t : Number.MAX_SAFE_INTEGER;
  };
  const rang = (m) => (m.role === 'organiser' ? 0 : 1);
  const tries = [...restants].sort((a, b) =>
    rang(a) - rang(b) || depuis(a) - depuis(b) || String(a.userId).localeCompare(String(b.userId)));
  return tries[0].userId;
}

module.exports = { heritierDuClub };
