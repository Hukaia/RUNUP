// L'adhésion à un club : trois modes, au choix de son propriétaire.
//
// Deux étages. Le premier éprouve `lib/adhesionClub.js`, la règle qui dit quel est le mode d'un
// club à partir des deux colonnes qui le portent (`is_open`, que les apps déjà installées lisent
// et écrivent, et `join_mode`). Le second éprouve les points d'entrée de `api/clubs/[action].js`
// contre une base FICTIVE : pas de Postgres ici, donc un faux `sql` qui répond selon le texte de
// la requête et note tout ce qu'on lui demande d'écrire.
//
// CE QUE LE SECOND ÉTAGE PEUT DIRE, ET CE QU'IL NE PEUT PAS. Il dit quelle réponse sort pour quel
// état — 404 pour un club sur code sans code, 409 pour une demande sur un club ouvert, 403 pour
// qui n'est pas propriétaire — et si une écriture ou une notification a eu lieu. Il ne dit rien du
// SQL lui-même : une requête qui ne s'exécute pas sur Postgres passe ici.
const test = require('node:test');
const assert = require('node:assert');
const Module = require('node:module');

const {
  modeValide, modeDuClub, colonnesDuMode, normaliserLeCode, codesIdentiques, codeVisible,
  LONGUEUR_DU_CODE, MAX_DEMANDES_EN_ATTENTE,
} = require('../lib/adhesionClub');

// ─── La règle ─────────────────────────────────────────────────────────────────────────────────

test('un club ouvert est ouvert, quelle que soit la colonne join_mode', () => {
  // Ce qu'une app ancienne a écrit en rouvrant son club : is_open gagne.
  assert.strictEqual(modeDuClub({ is_open: true, join_mode: 'open' }), 'open');
  assert.strictEqual(modeDuClub({ is_open: true, join_mode: 'code' }), 'open');
  assert.strictEqual(modeDuClub({ is_open: true, join_mode: 'request' }), 'open');
});

test('un club fermé est sur code, sauf s\'il est sur demande', () => {
  assert.strictEqual(modeDuClub({ is_open: false, join_mode: 'code' }), 'code');
  assert.strictEqual(modeDuClub({ is_open: false, join_mode: 'request' }), 'request');
  // Fermé par une app ancienne sans que join_mode ait suivi : un club fermé reste fermé.
  assert.strictEqual(modeDuClub({ is_open: false, join_mode: 'open' }), 'code');
  assert.strictEqual(modeDuClub({ is_open: false, join_mode: null }), 'code');
});

test('une ligne absente ou illisible n\'ouvre rien', () => {
  assert.strictEqual(modeDuClub(null), 'code');
  assert.strictEqual(modeDuClub({}), 'code');
});

test('seuls les trois modes connus sont valides', () => {
  assert.strictEqual(modeValide('open'), 'open');
  assert.strictEqual(modeValide('request'), 'request');
  assert.strictEqual(modeValide('code'), 'code');
  for (const mauvais of ['', 'OPEN', 'invite', null, undefined, 3, {}, ['open']]) {
    assert.strictEqual(modeValide(mauvais), null);
  }
});

test('is_open reste écrit, et n\'est vrai que pour un club ouvert', () => {
  assert.deepStrictEqual(colonnesDuMode('open'), { isOpen: true, joinMode: 'open' });
  assert.deepStrictEqual(colonnesDuMode('request'), { isOpen: false, joinMode: 'request' });
  assert.deepStrictEqual(colonnesDuMode('code'), { isOpen: false, joinMode: 'code' });
  // L'aller-retour : ce qu'on écrit, on le relit.
  for (const mode of ['open', 'request', 'code']) {
    const { isOpen, joinMode } = colonnesDuMode(mode);
    assert.strictEqual(modeDuClub({ is_open: isOpen, join_mode: joinMode }), mode);
  }
});

test('un code se tape comme on veut : casse, espaces et tirets n\'y changent rien', () => {
  assert.strictEqual(normaliserLeCode(' ab3-k7 m '), 'AB3K7M');
  assert.strictEqual(normaliserLeCode(null), '');
  assert.strictEqual(normaliserLeCode(123456), '');
  assert.strictEqual(LONGUEUR_DU_CODE, 6);
});

test('la comparaison des codes ne dit oui qu\'au même code', () => {
  assert.strictEqual(codesIdentiques('AB3K7M', 'ab3 k7m'), true);
  assert.strictEqual(codesIdentiques('AB3K7M', 'AB3K7N'), false);
  assert.strictEqual(codesIdentiques('AB3K7M', 'AB3K7'), false);
  assert.strictEqual(codesIdentiques('AB3K7M', ''), false);
  assert.strictEqual(codesIdentiques('', ''), false);
  assert.strictEqual(codesIdentiques(null, 'AB3K7M'), false);
});

test('le code n\'est visible que du propriétaire, et seulement sur un club sur code', () => {
  assert.strictEqual(codeVisible('code', true, 'AB3K7M'), 'AB3K7M');
  assert.strictEqual(codeVisible('code', false, 'AB3K7M'), null);
  assert.strictEqual(codeVisible('open', true, 'AB3K7M'), null);
  assert.strictEqual(codeVisible('request', true, 'AB3K7M'), null);
  assert.strictEqual(codeVisible('code', true, null), null);
});

// ─── Les points d'entrée, contre une base fictive ─────────────────────────────────────────────

const MOI = '11111111-1111-4111-8111-111111111111';
const PROPRIO = '22222222-2222-4222-8222-222222222222';
const AUTRE = '33333333-3333-4333-8333-333333333333';
const CLUB = '44444444-4444-4444-8444-444444444444';

let journal;   // chaque requête SQL vue : { texte, valeurs }
let scenario;  // des règles { quand: RegExp, rows | (valeurs) => rows }, la première qui colle gagne
let pushs;     // chaque notification demandée : { destinataires, notification }
let utilisateur;

function faitSql(strings, ...valeurs) {
  const texte = strings.join('?').replace(/\s+/g, ' ').trim();
  journal.push({ texte, valeurs });
  for (const regle of scenario) {
    if (regle.quand.test(texte)) {
      const rows = typeof regle.rows === 'function' ? regle.rows(valeurs) : regle.rows;
      return Promise.resolve({ rows });
    }
  }
  return Promise.resolve({ rows: [] });
}

// Les dépendances qui ne se chargent pas sans réseau ni base : remplacées AVANT d'exiger le point
// d'entrée. `Module._load` pour `@vercel/blob`, que ce dépôt n'installe pas pour les tests ; le
// cache de `require` pour les modules du dépôt.
const chargeur = Module._load;
Module._load = function (demande, ...reste) {
  if (demande === '@vercel/blob') return { put: async () => ({}), del: async () => {} };
  return chargeur.call(this, demande, ...reste);
};
function remplace(chemin, exports) {
  const resolu = require.resolve(chemin);
  require.cache[resolu] = { id: resolu, filename: resolu, loaded: true, exports };
}
remplace('../lib/db', { sql: faitSql });
remplace('../lib/auth', { requireAuth: async () => utilisateur });
remplace('../lib/apns', {
  sendPushToUsers: async (_sql, destinataires, notification) => { pushs.push({ destinataires, notification }); },
  sendPushToUser: async () => {},
});
const handler = require('../api/clubs/[action]');

function reponse() {
  return {
    statusCode: null, body: null, headersSent: false,
    status(code) { this.statusCode = code; return this; },
    json(corps) { this.body = corps; this.headersSent = true; return this; },
    setHeader() {},
  };
}

async function appelle(action, { method = 'POST', body = {}, query = {}, moi = MOI } = {}) {
  utilisateur = moi;
  const res = reponse();
  await handler({ method, body, query: { action, ...query }, headers: {} }, res);
  return res;
}

const ecritures = (re) => journal.filter((l) => re.test(l.texte));

function club(extra = {}) {
  return {
    id: CLUB, name: 'Les Foulées du Canal', is_open: true, join_mode: 'open',
    invite_code: 'AB3K7M', created_by: PROPRIO, city: 'Lyon', description: null, cover_url: null,
    ...extra,
  };
}

// Le scénario de base : je ne suis dans aucun club, le plafond n'est jamais atteint.
function depart(regles = []) {
  journal = [];
  pushs = [];
  scenario = [
    ...regles,
    { quand: /INSERT INTO coach_usage/, rows: [{ count: 1 }] },
    { quand: /SELECT club_id FROM club_members WHERE user_id/, rows: [] },
  ];
}

// ── rejoindre ──

test('join : un club ouvert se rejoint d\'un appui, comme avant', async () => {
  depart([{ quand: /FROM clubs WHERE id/, rows: [club()] }]);
  const res = await appelle('join', { body: { clubId: CLUB } });
  assert.strictEqual(res.statusCode, 200);
  assert.strictEqual(ecritures(/INSERT INTO club_members/).length, 1);
  // Entrer dans un club solde les demandes qu'on avait faites ailleurs.
  assert.strictEqual(ecritures(/DELETE FROM club_join_requests WHERE user_id/).length, 1);
});

test('join : un club fermé sans code répond comme un club qui n\'existe pas', async () => {
  // Le comportement exact d'une app installée devant un club fermé.
  depart([{ quand: /FROM clubs WHERE id/, rows: [club({ is_open: false, join_mode: 'code' })] }]);
  const res = await appelle('join', { body: { clubId: CLUB } });
  assert.strictEqual(res.statusCode, 404);
  assert.deepStrictEqual(res.body, { error: 'not_found' });
  assert.strictEqual(ecritures(/INSERT INTO club_members/).length, 0);
});

test('join : un club fermé par une app ancienne, join_mode pas encore à jour, reste fermé', async () => {
  depart([{ quand: /FROM clubs WHERE id/, rows: [club({ is_open: false, join_mode: 'open' })] }]);
  const res = await appelle('join', { body: { clubId: CLUB } });
  assert.strictEqual(res.statusCode, 404);
  assert.strictEqual(ecritures(/INSERT INTO club_members/).length, 0);
});

test('join : un mauvais code ne fait pas entrer', async () => {
  depart([{ quand: /FROM clubs WHERE id/, rows: [club({ is_open: false, join_mode: 'code' })] }]);
  const res = await appelle('join', { body: { clubId: CLUB, code: 'ZZZZZZ' } });
  // 400 et non 403 : le client lit un 403 comme une session refusée.
  assert.strictEqual(res.statusCode, 400);
  assert.deepStrictEqual(res.body, { error: 'bad_code' });
  assert.strictEqual(ecritures(/INSERT INTO club_members/).length, 0);
});

test('join : le bon code fait entrer, tapé comme on veut', async () => {
  depart([{ quand: /FROM clubs WHERE id/, rows: [club({ is_open: false, join_mode: 'code' })] }]);
  const res = await appelle('join', { body: { clubId: CLUB, code: ' ab3-k7m ' } });
  assert.strictEqual(res.statusCode, 200);
  assert.strictEqual(ecritures(/INSERT INTO club_members/).length, 1);
});

test('join : le plafond des essais de code est celui du serveur', async () => {
  depart([
    { quand: /FROM clubs WHERE id/, rows: [club({ is_open: false, join_mode: 'code' })] },
    // Le compteur de l'essai de code dépasse le plafond ; celui de `join` reste sous le sien.
    { quand: /INSERT INTO coach_usage/, rows: (v) => [{ count: String(v[0]).startsWith('joinCode:') ? 999 : 1 }] },
  ]);
  const res = await appelle('join', { body: { clubId: CLUB, code: 'ZZZZZZ' } });
  assert.strictEqual(res.statusCode, 429);
});

test('join : un club sur demande ne se rejoint pas d\'un appui', async () => {
  depart([{ quand: /FROM clubs WHERE id/, rows: [club({ is_open: false, join_mode: 'request' })] }]);
  const res = await appelle('join', { body: { clubId: CLUB } });
  assert.strictEqual(res.statusCode, 409);
  assert.deepStrictEqual(res.body, { error: 'request_required' });
  assert.strictEqual(ecritures(/INSERT INTO club_members/).length, 0);
});

test('join : quelqu\'un qui est déjà dans un club n\'en rejoint pas un second', async () => {
  depart([
    { quand: /SELECT club_id FROM club_members WHERE user_id/, rows: [{ club_id: AUTRE }] },
    { quand: /FROM clubs WHERE id/, rows: [club()] },
  ]);
  const res = await appelle('join', { body: { clubId: CLUB } });
  assert.strictEqual(res.statusCode, 409);
  assert.deepStrictEqual(res.body, { error: 'already_in_club' });
});

// ── demander ──

test('requestJoin : une demande sur un club sur demande notifie le propriétaire', async () => {
  depart([
    { quand: /SELECT id, name, is_open, join_mode, created_by FROM clubs/, rows: [club({ is_open: false, join_mode: 'request' })] },
    { quand: /INSERT INTO club_join_requests/, rows: [{ id: 'r1' }] },
    { quand: /SELECT COUNT\(\*\)::int AS n FROM club_join_requests/, rows: [{ n: 0 }] },
    { quand: /SELECT name FROM users/, rows: [{ name: 'Camille' }] },
  ]);
  const res = await appelle('requestJoin', { body: { clubId: CLUB } });
  assert.strictEqual(res.statusCode, 201);
  assert.deepStrictEqual(res.body, { requestPending: true });
  assert.strictEqual(pushs.length, 1);
  assert.deepStrictEqual(pushs[0].destinataires, [PROPRIO]);
  assert.match(pushs[0].notification.body, /Camille/);
  assert.match(pushs[0].notification.body, /Les Foulées du Canal/);
});

test('requestJoin : une demande déjà faite ne notifie pas une seconde fois', async () => {
  depart([
    { quand: /SELECT id, name, is_open, join_mode, created_by FROM clubs/, rows: [club({ is_open: false, join_mode: 'request' })] },
    { quand: /SELECT COUNT\(\*\)::int AS n FROM club_join_requests/, rows: [{ n: 1 }] },
    // ON CONFLICT DO NOTHING : rien n'est rendu.
    { quand: /INSERT INTO club_join_requests/, rows: [] },
  ]);
  const res = await appelle('requestJoin', { body: { clubId: CLUB } });
  assert.strictEqual(res.statusCode, 200);
  assert.deepStrictEqual(res.body, { requestPending: true });
  assert.strictEqual(pushs.length, 0);
});

test('requestJoin : un club ouvert se rejoint, il ne se demande pas', async () => {
  depart([{ quand: /SELECT id, name, is_open, join_mode, created_by FROM clubs/, rows: [club()] }]);
  const res = await appelle('requestJoin', { body: { clubId: CLUB } });
  assert.strictEqual(res.statusCode, 409);
  assert.deepStrictEqual(res.body, { error: 'use_join' });
  assert.strictEqual(ecritures(/INSERT INTO club_join_requests/).length, 0);
});

test('requestJoin : un club sur code n\'existe pas pour qui le demande', async () => {
  depart([{ quand: /SELECT id, name, is_open, join_mode, created_by FROM clubs/, rows: [club({ is_open: false, join_mode: 'code' })] }]);
  const res = await appelle('requestJoin', { body: { clubId: CLUB } });
  assert.strictEqual(res.statusCode, 404);
});

test('requestJoin : un club dont le propriétaire est parti ne reçoit pas de demande', async () => {
  depart([{ quand: /SELECT id, name, is_open, join_mode, created_by FROM clubs/, rows: [club({ is_open: false, join_mode: 'request', created_by: null })] }]);
  const res = await appelle('requestJoin', { body: { clubId: CLUB } });
  assert.strictEqual(res.statusCode, 404);
});

test('requestJoin : un blocage dans un sens ou dans l\'autre répond « n\'existe pas »', async () => {
  depart([
    { quand: /SELECT id, name, is_open, join_mode, created_by FROM clubs/, rows: [club({ is_open: false, join_mode: 'request' })] },
    { quand: /FROM blocks/, rows: [{ '?column?': 1 }] },
  ]);
  const res = await appelle('requestJoin', { body: { clubId: CLUB } });
  assert.strictEqual(res.statusCode, 404);
  assert.strictEqual(ecritures(/INSERT INTO club_join_requests/).length, 0);
  assert.strictEqual(pushs.length, 0);
});

test('requestJoin : au plafond de demandes en attente, on n\'en fait pas une de plus', async () => {
  depart([
    { quand: /SELECT id, name, is_open, join_mode, created_by FROM clubs/, rows: [club({ is_open: false, join_mode: 'request' })] },
    { quand: /SELECT COUNT\(\*\)::int AS n FROM club_join_requests/, rows: [{ n: MAX_DEMANDES_EN_ATTENTE }] },
  ]);
  const res = await appelle('requestJoin', { body: { clubId: CLUB } });
  assert.strictEqual(res.statusCode, 409);
  assert.deepStrictEqual(res.body, { error: 'too_many_pending_requests' });
});

test('requestJoin : déjà dans un club, on ne demande pas', async () => {
  depart([{ quand: /SELECT club_id FROM club_members WHERE user_id/, rows: [{ club_id: AUTRE }] }]);
  const res = await appelle('requestJoin', { body: { clubId: CLUB } });
  assert.strictEqual(res.statusCode, 409);
  assert.deepStrictEqual(res.body, { error: 'already_in_club' });
});

test('cancelRequest : retirer sa demande est idempotent', async () => {
  depart();
  const res = await appelle('cancelRequest', { body: { clubId: CLUB } });
  assert.strictEqual(res.statusCode, 200);
  assert.deepStrictEqual(res.body, { ok: true, requestPending: false });
  const suppression = ecritures(/DELETE FROM club_join_requests/)[0];
  // Seulement la sienne : le club ET la personne qui appelle.
  assert.deepStrictEqual(suppression.valeurs, [CLUB, MOI]);
});

test('cancelRequest : un identifiant qui n\'en est pas un est une faute', async () => {
  depart();
  const res = await appelle('cancelRequest', { body: { clubId: 'abc' } });
  assert.strictEqual(res.statusCode, 400);
});

// ── décider : le propriétaire seulement ──

const proprietaire = { quand: /JOIN club_members m ON m.club_id = c.id AND m.user_id/,
  rows: [{ id: CLUB, name: 'Les Foulées du Canal', is_open: false, join_mode: 'request', invite_code: 'AB3K7M' }] };
const pasProprietaire = { quand: /JOIN club_members m ON m.club_id = c.id AND m.user_id/, rows: [] };

test('requests : seul le propriétaire lit les demandes', async () => {
  depart([pasProprietaire]);
  const res = await appelle('requests', { method: 'GET' });
  assert.strictEqual(res.statusCode, 403);
});

test('requests : le propriétaire les lit, sans les personnes bloquées', async () => {
  depart([
    proprietaire,
    { quand: /FROM club_join_requests r JOIN users u/, rows: [
      { id: 'r1', user_id: AUTRE, name: 'Camille', last_name: null, avatar_data: null, avatar_url: null, created_at: '2026-11-22T08:00:00.000Z' },
    ] },
  ]);
  const res = await appelle('requests', { method: 'GET', moi: PROPRIO });
  assert.strictEqual(res.statusCode, 200);
  assert.strictEqual(res.body.items.length, 1);
  assert.strictEqual(res.body.items[0].userId, AUTRE);
  assert.strictEqual(res.body.items[0].lastName, null);
  // Le filtre de blocage est dans la requête, dans les deux sens.
  const requete = ecritures(/FROM club_join_requests r JOIN users u/)[0].texte;
  assert.match(requete, /blocker_id = \? AND|blocked_id FROM blocks WHERE blocker_id/);
  assert.match(requete, /blocker_id FROM blocks WHERE blocked_id/);
});

test('respondRequest : qui n\'est pas propriétaire ne décide rien', async () => {
  depart([pasProprietaire]);
  const res = await appelle('respondRequest', { body: { userId: AUTRE, accept: true } });
  assert.strictEqual(res.statusCode, 403);
  assert.strictEqual(ecritures(/INSERT INTO club_members/).length, 0);
});

test('respondRequest : accepter fait entrer la personne, solde ses demandes et la notifie', async () => {
  depart([
    proprietaire,
    { quand: /SELECT id FROM club_join_requests WHERE club_id/, rows: [{ id: 'r1' }] },
  ]);
  const res = await appelle('respondRequest', { body: { userId: AUTRE, accept: true }, moi: PROPRIO });
  assert.strictEqual(res.statusCode, 200);
  assert.deepStrictEqual(res.body, { ok: true, accepted: true });
  assert.deepStrictEqual(ecritures(/INSERT INTO club_members/)[0].valeurs, [CLUB, AUTRE]);
  assert.strictEqual(ecritures(/DELETE FROM club_join_requests WHERE user_id/).length, 1);
  assert.strictEqual(pushs.length, 1);
  assert.deepStrictEqual(pushs[0].destinataires, [AUTRE]);
});

test('respondRequest : refuser retire la demande et ne dit rien à personne', async () => {
  depart([
    proprietaire,
    { quand: /SELECT id FROM club_join_requests WHERE club_id/, rows: [{ id: 'r1' }] },
  ]);
  const res = await appelle('respondRequest', { body: { userId: AUTRE, accept: false }, moi: PROPRIO });
  assert.strictEqual(res.statusCode, 200);
  assert.deepStrictEqual(res.body, { ok: true, accepted: false });
  assert.strictEqual(ecritures(/INSERT INTO club_members/).length, 0);
  assert.strictEqual(ecritures(/DELETE FROM club_join_requests WHERE club_id/).length, 1);
  assert.strictEqual(pushs.length, 0);
});

test('respondRequest : une demande déjà retirée n\'est plus là', async () => {
  depart([proprietaire]);
  const res = await appelle('respondRequest', { body: { userId: AUTRE, accept: true }, moi: PROPRIO });
  assert.strictEqual(res.statusCode, 404);
  assert.strictEqual(ecritures(/INSERT INTO club_members/).length, 0);
});

test('respondRequest : accepter quelqu\'un entré entre-temps dans un autre club n\'ajoute personne', async () => {
  depart([
    proprietaire,
    { quand: /SELECT id FROM club_join_requests WHERE club_id/, rows: [{ id: 'r1' }] },
    // Les deux lectures « club de la personne » : la mienne (propriétaire) n'est pas celle-ci.
    { quand: /SELECT club_id FROM club_members WHERE user_id/, rows: (v) => (v[0] === AUTRE ? [{ club_id: 'ailleurs' }] : []) },
  ]);
  const res = await appelle('respondRequest', { body: { userId: AUTRE, accept: true }, moi: PROPRIO });
  assert.strictEqual(res.statusCode, 409);
  assert.strictEqual(ecritures(/INSERT INTO club_members/).length, 0);
  assert.strictEqual(pushs.length, 0);
});

test('respondRequest : accept doit être un booléen', async () => {
  depart([proprietaire]);
  const res = await appelle('respondRequest', { body: { userId: AUTRE, accept: 'oui' }, moi: PROPRIO });
  assert.strictEqual(res.statusCode, 400);
});

// ── changer le mode ──

test('setJoinMode : qui n\'est pas propriétaire ne change rien', async () => {
  depart([pasProprietaire]);
  const res = await appelle('setJoinMode', { body: { joinMode: 'open' } });
  assert.strictEqual(res.statusCode, 403);
  assert.strictEqual(ecritures(/UPDATE clubs/).length, 0);
});

test('setJoinMode : un mode inconnu est une faute', async () => {
  depart([proprietaire]);
  const res = await appelle('setJoinMode', { body: { joinMode: 'invite' }, moi: PROPRIO });
  assert.strictEqual(res.statusCode, 400);
});

test('setJoinMode : sur code rend le code, au propriétaire, et retire les demandes', async () => {
  depart([proprietaire]);
  const res = await appelle('setJoinMode', { body: { joinMode: 'code' }, moi: PROPRIO });
  assert.strictEqual(res.statusCode, 200);
  assert.deepStrictEqual(res.body, { joinMode: 'code', isOpen: false, inviteCode: 'AB3K7M' });
  assert.deepStrictEqual(ecritures(/UPDATE clubs SET is_open/)[0].valeurs, [false, 'code', CLUB]);
  assert.strictEqual(ecritures(/DELETE FROM club_join_requests WHERE club_id/).length, 1);
});

test('setJoinMode : ouvert écrit is_open, et ne rend pas de code', async () => {
  depart([proprietaire]);
  const res = await appelle('setJoinMode', { body: { joinMode: 'open' }, moi: PROPRIO });
  assert.deepStrictEqual(res.body, { joinMode: 'open', isOpen: true, inviteCode: null });
  assert.deepStrictEqual(ecritures(/UPDATE clubs SET is_open/)[0].valeurs, [true, 'open', CLUB]);
});

test('setJoinMode : sur demande garde les demandes en attente', async () => {
  depart([proprietaire]);
  const res = await appelle('setJoinMode', { body: { joinMode: 'request' }, moi: PROPRIO });
  assert.deepStrictEqual(res.body, { joinMode: 'request', isOpen: false, inviteCode: null });
  assert.strictEqual(ecritures(/DELETE FROM club_join_requests/).length, 0);
});

test('setOpen : l\'interrupteur d\'avant ne change pas de sens', async () => {
  // Une app ancienne ferme son club : il devient sur code ; elle l'ouvre : il est ouvert.
  depart([{ quand: /SELECT c.id FROM clubs c JOIN club_members m/, rows: [{ id: CLUB }] },
          { quand: /UPDATE clubs SET is_open/, rows: [{ id: CLUB, is_open: false }] }]);
  let res = await appelle('setOpen', { body: { isOpen: false }, moi: PROPRIO });
  assert.strictEqual(res.statusCode, 200);
  assert.deepStrictEqual(res.body, { isOpen: false });
  const maj = ecritures(/UPDATE clubs SET is_open/)[0];
  assert.match(maj.texte, /WHEN is_open = false AND join_mode = 'request' THEN 'request' ELSE 'code'/);
  assert.strictEqual(ecritures(/DELETE FROM club_join_requests/).length, 0);

  depart([{ quand: /SELECT c.id FROM clubs c JOIN club_members m/, rows: [{ id: CLUB }] },
          { quand: /UPDATE clubs SET is_open/, rows: [{ id: CLUB, is_open: true }] }]);
  res = await appelle('setOpen', { body: { isOpen: true }, moi: PROPRIO });
  assert.deepStrictEqual(res.body, { isOpen: true });
  // Ouvrir un club sur demande solde ses demandes.
  assert.strictEqual(ecritures(/DELETE FROM club_join_requests WHERE club_id/).length, 1);
});

// ── la fiche ──

test('preview : un club sur code n\'a pas de fiche par identifiant', async () => {
  depart([{ quand: /FROM clubs WHERE id/, rows: [club({ is_open: false, join_mode: 'code' })] }]);
  const res = await appelle('preview', { method: 'GET', query: { id: CLUB } });
  assert.strictEqual(res.statusCode, 404);
});

test('preview : un club ouvert dit sa prochaine séance, et si je suis déjà dans un club', async () => {
  depart([
    { quand: /FROM clubs WHERE id/, rows: [club()] },
    { quand: /SELECT COUNT\(\*\)::int AS n FROM club_members/, rows: [{ n: 18 }] },
    { quand: /FROM club_events/, rows: [{ title: 'Fractionné', location: 'Stade', starts_at: '2026-11-24T18:30:00.000Z', repeats_weekly: true }] },
    { quand: /SELECT club_id FROM club_members WHERE user_id/, rows: [{ club_id: AUTRE }] },
  ]);
  const res = await appelle('preview', { method: 'GET', query: { id: CLUB } });
  assert.strictEqual(res.statusCode, 200);
  assert.strictEqual(res.body.joinMode, 'open');
  assert.strictEqual(res.body.memberCount, 18);
  assert.strictEqual(res.body.alreadyInClub, true);
  assert.deepStrictEqual(res.body.nextSession,
    { title: 'Fractionné', location: 'Stade', startsAt: '2026-11-24T18:30:00.000Z', repeatsWeekly: true });
});

test('preview : un club sur demande ne montre pas ses séances à qui n\'est pas entré', async () => {
  depart([
    { quand: /FROM clubs WHERE id/, rows: [club({ is_open: false, join_mode: 'request' })] },
    { quand: /SELECT COUNT\(\*\)::int AS n FROM club_members/, rows: [{ n: 9 }] },
    { quand: /FROM club_join_requests WHERE club_id/, rows: [{ '?column?': 1 }] },
    { quand: /FROM club_events/, rows: [{ title: 'Privée', location: null, starts_at: '2026-11-24T18:30:00.000Z', repeats_weekly: false }] },
  ]);
  const res = await appelle('preview', { method: 'GET', query: { id: CLUB } });
  assert.strictEqual(res.statusCode, 200);
  assert.strictEqual(res.body.joinMode, 'request');
  assert.strictEqual(res.body.requestPending, true);
  assert.strictEqual(res.body.alreadyInClub, false);
  assert.strictEqual(res.body.nextSession, null);
  assert.strictEqual(ecritures(/FROM club_events/).length, 0);
});

test('byCode : le code d\'un club sur code ouvre sa fiche', async () => {
  depart([
    { quand: /FROM clubs WHERE invite_code/, rows: [club({ is_open: false, join_mode: 'code' })] },
    { quand: /SELECT COUNT\(\*\)::int AS n FROM club_members/, rows: [{ n: 4 }] },
  ]);
  const res = await appelle('byCode', { method: 'GET', query: { code: 'ab3 k7m' } });
  assert.strictEqual(res.statusCode, 200);
  assert.strictEqual(res.body.joinMode, 'code');
  assert.strictEqual(res.body.nextSession, null);
  // Le code lui-même ne ressort jamais d'une fiche.
  assert.ok(!JSON.stringify(res.body).includes('AB3K7M'));
  assert.deepStrictEqual(ecritures(/FROM clubs WHERE invite_code/)[0].valeurs, ['AB3K7M']);
});

test('byCode : le code d\'un club ouvert ne désigne rien', async () => {
  depart([{ quand: /FROM clubs WHERE invite_code/, rows: [club()] }]);
  const res = await appelle('byCode', { method: 'GET', query: { code: 'AB3K7M' } });
  assert.strictEqual(res.statusCode, 404);
});

test('byCode : un code qui n\'a pas six signes est une faute, sans requête', async () => {
  depart();
  const res = await appelle('byCode', { method: 'GET', query: { code: 'AB3' } });
  assert.strictEqual(res.statusCode, 400);
  assert.strictEqual(ecritures(/FROM clubs/).length, 0);
});

// ── la recherche et les suggestions ──

const avecDemandesVu = () => ecritures(/FROM clubs c/)[0].valeurs.find((v) => typeof v === 'boolean');

test('search : sans adhesion=1, la recherche ne rend que ce qu\'elle a toujours rendu', async () => {
  depart([{ quand: /FROM clubs c/, rows: [] }]);
  await appelle('search', { method: 'GET', query: { q: 'foulees' } });
  assert.strictEqual(avecDemandesVu(), false);
});

test('search : avec adhesion=1, les clubs sur demande en font partie, et chaque ligne dit son mode', async () => {
  depart([{ quand: /FROM clubs c/, rows: [
    { id: CLUB, name: 'Les Foulées', city: null, is_open: false, join_mode: 'request', member_count: 7, demande_en_cours: true },
  ] }]);
  const res = await appelle('search', { method: 'GET', query: { q: 'foulees', adhesion: '1' } });
  assert.strictEqual(avecDemandesVu(), true);
  assert.deepStrictEqual(res.body.items, [
    { id: CLUB, name: 'Les Foulées', city: null, memberCount: 7, joinMode: 'request', requestPending: true },
  ]);
});

test('suggested : même règle, même garde', async () => {
  depart([{ quand: /FROM clubs c/, rows: [] }]);
  await appelle('suggested', { method: 'GET' });
  assert.strictEqual(avecDemandesVu(), false);
  depart([{ quand: /FROM clubs c/, rows: [] }]);
  await appelle('suggested', { method: 'GET', query: { adhesion: '1' } });
  assert.strictEqual(avecDemandesVu(), true);
});

// ── créer ──

test('create : sans mode, le club est ouvert comme avant ; avec un mode, c\'est celui-là', async () => {
  depart([{ quand: /INSERT INTO clubs/, rows: [{ id: CLUB, name: 'Nouveau' }] }]);
  let res = await appelle('create', { body: { name: 'Nouveau' } });
  assert.strictEqual(res.statusCode, 201);
  assert.strictEqual(res.body.joinMode, 'open');
  assert.deepStrictEqual(ecritures(/INSERT INTO clubs/)[0].valeurs.slice(-2), [true, 'open']);

  depart([{ quand: /INSERT INTO clubs/, rows: [{ id: CLUB, name: 'Nouveau' }] }]);
  res = await appelle('create', { body: { name: 'Nouveau', joinMode: 'request' } });
  assert.strictEqual(res.body.joinMode, 'request');
  assert.deepStrictEqual(ecritures(/INSERT INTO clubs/)[0].valeurs.slice(-2), [false, 'request']);
});

test('create : un mode inconnu est refusé, pas remplacé par un autre', async () => {
  depart();
  const res = await appelle('create', { body: { name: 'Nouveau', joinMode: 'secret' } });
  assert.strictEqual(res.statusCode, 400);
  assert.strictEqual(ecritures(/INSERT INTO clubs/).length, 0);
});

// ── le tableau de bord ──

function tableau(extra) {
  return [
    { quand: /SELECT club_id FROM club_members WHERE user_id/, rows: [{ club_id: CLUB }] },
    { quand: /SELECT id, name, is_open, join_mode, invite_code, created_by/, rows: [club(extra)] },
    { quand: /SELECT COUNT\(\*\)::int AS n FROM club_join_requests/, rows: [{ n: 3 }] },
    { quand: /SELECT COUNT\(\*\)::int AS count FROM club_members/, rows: [{ count: 12 }] },
  ];
}

test('mine : le propriétaire d\'un club sur code voit le code ; un membre non', async () => {
  depart(tableau({ is_open: false, join_mode: 'code' }));
  let res = await appelle('mine', { method: 'GET', moi: PROPRIO });
  assert.strictEqual(res.statusCode, 200);
  assert.strictEqual(res.body.club.joinMode, 'code');
  assert.strictEqual(res.body.club.inviteCode, 'AB3K7M');
  assert.strictEqual(res.body.club.isOpen, false);
  assert.strictEqual(res.body.club.pendingRequests, null);

  depart(tableau({ is_open: false, join_mode: 'code' }));
  res = await appelle('mine', { method: 'GET', moi: MOI });
  assert.strictEqual(res.body.club.joinMode, 'code');
  assert.strictEqual(res.body.club.inviteCode, null);
});

test('mine : le propriétaire d\'un club sur demande compte ses demandes ; un membre non', async () => {
  depart(tableau({ is_open: false, join_mode: 'request' }));
  let res = await appelle('mine', { method: 'GET', moi: PROPRIO });
  assert.strictEqual(res.body.club.joinMode, 'request');
  assert.strictEqual(res.body.club.pendingRequests, 3);
  assert.strictEqual(res.body.club.inviteCode, null);

  depart(tableau({ is_open: false, join_mode: 'request' }));
  res = await appelle('mine', { method: 'GET', moi: MOI });
  assert.strictEqual(res.body.club.pendingRequests, null);
});

test('mine : un club ouvert n\'expose ni code ni demandes', async () => {
  depart(tableau());
  const res = await appelle('mine', { method: 'GET', moi: PROPRIO });
  assert.strictEqual(res.body.club.joinMode, 'open');
  assert.strictEqual(res.body.club.isOpen, true);
  assert.strictEqual(res.body.club.inviteCode, null);
  assert.strictEqual(res.body.club.pendingRequests, null);
});
