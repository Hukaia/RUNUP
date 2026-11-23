// Consolidated into one dynamic route ([action] = create | join | leave | mine) instead of 4
// separate files — see api/auth/[action].js for why. /api/clubs/create, /join, /leave, /mine
// still work exactly as before.
const { sql } = require('../../lib/db');
const { requireAuth } = require('../../lib/auth');
const { withErrorHandling, isUuid } = require('../../lib/http');
const { containsObjectionableContent } = require('../../lib/moderation');
const { REJECTED, sanitizeOwnText } = require('../../lib/activityFields');
const { tamponDepuisDataURI } = require('../../lib/images');
const { put, del } = require('@vercel/blob');

// Une description de club tient en un paragraphe qu'on lit sans le déplier — l'équivalent de la
// note d'une sortie, en plus court : elle s'affiche en tête d'une page, pas dans un fil.
const MAX_CLUB_DESCRIPTION = 240;
const MAX_CLUB_CITY = 80;
const { sendPushToUsers } = require('../../lib/apns');
const { underDailyCap } = require('../../lib/rateLimit');
const { MAX_SUGGESTIONS, ligneSuggeree } = require('../../lib/clubsSuggeres');
const { heritierDuClub } = require('../../lib/proprieteClub');
const {
  LONGUEUR_DU_CODE, MAX_DEMANDES_EN_ATTENTE, MAX_ESSAIS_DE_CODE_PAR_JOUR,
  modeValide, modeDuClub, colonnesDuMode, normaliserLeCode, codesIdentiques, codeVisible,
} = require('../../lib/adhesionClub');
// Le même repli que la recherche de personnes : accents, casse, traits d'union, ligatures. Un
// club qui s'appelle « Les Côtes de Belleville » doit se trouver en tapant « cotes ».
const {
  ACCENTS_SOURCE, ACCENTS_CIBLE, normaliser, echapperPourLike,
} = require('../../lib/recherche');

module.exports = withErrorHandling(async function handler(req, res) {
  // LA PAGE PUBLIQUE D'UN CLUB EST LE SEUL POINT D'ENTRÉE SANS JETON DE TOUT LE SERVEUR, et
  // c'est tout son intérêt : un crew recrute sur Instagram et par le bouche-à-oreille, pas dans
  // un moteur de recherche interne. Un lien qu'il faut déjà avoir l'app pour ouvrir ne recrute
  // personne.
  //
  // AVANT l'authentification, donc — et volontairement avant, pas « sans la vérifier » : la
  // réponse ne contient que ce qu'un club OUVERT affiche de lui-même (son nom, sa ville, sa
  // présentation, ses prochaines séances), jamais ses membres ni rien qui désigne quelqu'un.
  if (req.query.action === 'public') {
    if (req.method !== 'GET') return res.status(405).json({ error: 'method_not_allowed' });
    return handlePublicClub(req, res);
  }

  const userId = await requireAuth(req, res);
  if (!userId) return res.status(401).json({ error: 'unauthorized' });

  switch (req.query.action) {
    case 'create':
      if (req.method !== 'POST') return res.status(405).json({ error: 'method_not_allowed' });
      return handleCreate(req, res, userId);
    case 'join':
      if (req.method !== 'POST') return res.status(405).json({ error: 'method_not_allowed' });
      return handleJoin(req, res, userId);
    case 'search':
      if (req.method !== 'GET') return res.status(405).json({ error: 'method_not_allowed' });
      return handleSearchClubs(req, res, userId);
    case 'suggested':
      if (req.method !== 'GET') return res.status(405).json({ error: 'method_not_allowed' });
      return handleSuggestedClubs(req, res, userId);
    case 'setOpen':
      if (req.method !== 'POST') return res.status(405).json({ error: 'method_not_allowed' });
      return handleSetOpen(req, res, userId);
    // L'ADHÉSION : trois modes au choix du propriétaire (ouvert, sur demande, sur code), la fiche
    // qu'on voit avant d'entrer, et les demandes. Voir `lib/adhesionClub.js`.
    case 'preview':
      if (req.method !== 'GET') return res.status(405).json({ error: 'method_not_allowed' });
      return handlePreview(req, res, userId);
    case 'byCode':
      if (req.method !== 'GET') return res.status(405).json({ error: 'method_not_allowed' });
      return handleByCode(req, res, userId);
    case 'requestJoin':
      if (req.method !== 'POST') return res.status(405).json({ error: 'method_not_allowed' });
      return handleRequestJoin(req, res, userId);
    case 'cancelRequest':
      if (req.method !== 'POST') return res.status(405).json({ error: 'method_not_allowed' });
      return handleCancelRequest(req, res, userId);
    case 'requests':
      if (req.method !== 'GET') return res.status(405).json({ error: 'method_not_allowed' });
      return handleRequests(req, res, userId);
    case 'respondRequest':
      if (req.method !== 'POST') return res.status(405).json({ error: 'method_not_allowed' });
      return handleRespondRequest(req, res, userId);
    case 'setJoinMode':
      if (req.method !== 'POST') return res.status(405).json({ error: 'method_not_allowed' });
      return handleSetJoinMode(req, res, userId);
    case 'removeMember':
      if (req.method !== 'POST') return res.status(405).end();
      return handleRemoveMember(req, res, userId);
    case 'regenerateCode':
      if (req.method !== 'POST') return res.status(405).end();
      return handleRegenerateCode(req, res, userId);
    case 'deleteClub':
      if (req.method !== 'POST') return res.status(405).end();
      return handleDeleteClub(req, res, userId);
    case 'leave':
      if (req.method !== 'POST') return res.status(405).json({ error: 'method_not_allowed' });
      return handleLeave(req, res, userId);
    case 'mine':
      if (req.method !== 'GET') return res.status(405).json({ error: 'method_not_allowed' });
      return handleMine(req, res, userId);
    case 'createChallenge':
      if (req.method !== 'POST') return res.status(405).json({ error: 'method_not_allowed' });
      return handleCreateChallenge(req, res, userId);
    case 'updateBio':
      if (req.method !== 'POST') return res.status(405).json({ error: 'method_not_allowed' });
      return handleUpdateBio(req, res, userId);
    case 'syncBadges':
      if (req.method !== 'POST') return res.status(405).json({ error: 'method_not_allowed' });
      return handleSyncBadges(req, res, userId);
    case 'syncWeeklyTarget':
      if (req.method !== 'POST') return res.status(405).json({ error: 'method_not_allowed' });
      return handleSyncWeeklyTarget(req, res, userId);
    case 'createEvent':
      if (req.method !== 'POST') return res.status(405).json({ error: 'method_not_allowed' });
      return handleCreateEvent(req, res, userId);
    case 'rsvpEvent':
      if (req.method !== 'POST') return res.status(405).json({ error: 'method_not_allowed' });
      return handleRsvpEvent(req, res, userId);
    case 'deleteEvent':
      if (req.method !== 'POST') return res.status(405).json({ error: 'method_not_allowed' });
      return handleDeleteEvent(req, res, userId);
    case 'highlights':
      if (req.method !== 'GET') return res.status(405).json({ error: 'method_not_allowed' });
      return handleHighlights(req, res, userId);
    case 'setClubProfile':
      if (req.method !== 'POST') return res.status(405).json({ error: 'method_not_allowed' });
      return handleSetClubProfile(req, res, userId);
    case 'cover':
      if (req.method !== 'POST') return res.status(405).json({ error: 'method_not_allowed' });
      return handleCover(req, res, userId);
    case 'setRole':
      if (req.method !== 'POST') return res.status(405).json({ error: 'method_not_allowed' });
      return handleSetRole(req, res, userId);
    // LE MUR DU CLUB. Mêmes trois actions que le mur d'une course, au mot près.
    case 'posts':
      if (req.method !== 'GET') return res.status(405).json({ error: 'method_not_allowed' });
      return handlePosts(req, res, userId);
    case 'post':
      if (req.method !== 'POST') return res.status(405).json({ error: 'method_not_allowed' });
      return handleCreatePost(req, res, userId);
    case 'postKudos':
      if (req.method !== 'POST') return res.status(405).json({ error: 'method_not_allowed' });
      return handlePostKudos(req, res, userId);
    case 'updateEvent':
      if (req.method !== 'POST') return res.status(405).json({ error: 'method_not_allowed' });
      return handleUpdateEvent(req, res, userId);
    case 'updatePost':
      if (req.method !== 'POST') return res.status(405).json({ error: 'method_not_allowed' });
      return handleUpdatePost(req, res, userId);
    case 'deletePost':
      if (req.method !== 'POST') return res.status(405).json({ error: 'method_not_allowed' });
      return handleDeletePost(req, res, userId);
    default:
      return res.status(404).json({ error: 'not_found' });
  }
});

// Must match `ClubBadgeCatalog.all` keys on the client — anything else is silently dropped rather
// than trusted, since a tampered client could otherwise write arbitrary junk keys here.
const KNOWN_BADGES = new Set([
  'streak3', 'interval3', 'earlyRun', 'elevation300',
  'firstRun', 'streak7', 'streak30', 'tenRuns', 'fiftyRuns',
  'distance50', 'distance250', 'distance1000',
  'halfMarathonDistance', 'marathonDistance', 'nightRun', 'weekendWarrior',
]);

function randomInviteCode() {
  // No 0/O/1/I — avoids ambiguity when a code is read aloud or typed by hand.
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = '';
  for (let i = 0; i < 6; i++) code += alphabet[Math.floor(Math.random() * alphabet.length)];
  return code;
}

// Creates a club and auto-joins the creator. v1: a user can only be in one club at a time.
async function handleCreate(req, res, userId) {
  const { rows: already } = await sql`SELECT club_id FROM club_members WHERE user_id = ${userId}`;
  if (already.length > 0) return res.status(409).json({ error: 'already_in_club' });

  const { name } = req.body || {};
  const cleanName = typeof name === 'string' ? name.trim().slice(0, 60) : '';
  if (!cleanName) return res.status(400).json({ error: 'bad_request' });
  if (containsObjectionableContent(cleanName)) return res.status(422).json({ error: 'objectionable_content' });

  // COMMENT ON ENTRERA DANS CE CLUB, au choix de qui le crée. Absent : ouvert, comme avant — une
  // app installée ne l'envoie pas. Présent mais inconnu : une faute, pas un repli silencieux sur
  // un mode que la personne n'a pas choisi.
  let mode = 'open';
  if (req.body?.joinMode !== undefined && req.body?.joinMode !== null) {
    mode = modeValide(req.body.joinMode);
    if (!mode) return res.status(400).json({ error: 'bad_request' });
  }
  const colonnes = colonnesDuMode(mode);

  let club;
  // LE CODE EST ENCORE ÉCRIT, ET PLUS JAMAIS LU.
  //
  // `clubs.invite_code` est `NOT NULL UNIQUE` : un club ne peut pas être créé sans. Plus rien ne
  // s'en sert — on rejoint un club par son nom — mais retirer la contrainte demanderait une
  // migration destructrice sur une colonne qui ne gêne personne. On continue donc d'en tirer un,
  // et on ne le rend plus à qui que ce soit.
  //
  // Retry on the astronomically rare invite_code collision instead of trusting a single attempt.
  for (let attempt = 0; attempt < 5 && !club; attempt++) {
    const code = randomInviteCode();
    try {
      const { rows } = await sql`
        INSERT INTO clubs (name, invite_code, created_by, is_open, join_mode)
        VALUES (${cleanName}, ${code}, ${userId}, ${colonnes.isOpen}, ${colonnes.joinMode})
        RETURNING id, name
      `;
      club = rows[0];
    } catch (e) {
      if (!String(e.message).includes('invite_code')) throw e;
    }
  }
  if (!club) return res.status(500).json({ error: 'could_not_create' });

  // The DB now enforces one club per user (uniq_club_members_user) — a double-submitted create
  // that raced past the pre-check above lands here instead of silently joining a second club.
  try {
    await sql`INSERT INTO club_members (club_id, user_id) VALUES (${club.id}, ${userId})`;
  } catch (e) {
    if (String(e.message).includes('uniq_club_members_user')) {
      await sql`DELETE FROM clubs WHERE id = ${club.id}`;
      return res.status(409).json({ error: 'already_in_club' });
    }
    throw e;
  }
  res.status(201).json({ id: club.id, name: club.name, joinMode: mode });
}

// ON REJOINT UN CLUB PAR SON IDENTIFIANT — ET, S'IL EST SUR CODE, AVEC SON CODE.
//
// Le code à six lettres supposait qu'on l'ait reçu de quelqu'un — donc qu'on sache déjà que le
// club existe, et comment il s'appelle. C'est exactement ce qu'une recherche par nom rend
// inutile. `handleSearchClubs` trouve le club, celui-ci l'ouvre.
//
// L'identifiant n'est pas un secret et ne remplace pas le mode du club : le serveur le revérifie
// ICI, pas seulement à la recherche — sans quoi un identifiant retenu avant un changement de
// mode ferait encore entrer.
//
//   · ouvert    : on entre ;
//   · sur code  : on entre avec `code`, sinon c'est la réponse d'avant, « n'existe pas » — une
//                 app installée n'envoie pas de code et se comporte comme devant un club fermé ;
//   · sur demande : on n'entre pas d'un appui, on demande (`handleRequestJoin`) : 409.
async function handleJoin(req, res, userId) {
  const { rows: already } = await sql`SELECT club_id FROM club_members WHERE user_id = ${userId}`;
  if (already.length > 0) return res.status(409).json({ error: 'already_in_club' });

  // Le plafond reste. Il ne protège plus un code devinable, mais il borne toujours ce qu'un
  // script peut faire de cette route — entrer et sortir d'un club en boucle, par exemple.
  if (!(await underDailyCap('join:' + userId, 20))) return res.status(429).json({ error: 'too_many_requests' });

  const { clubId } = req.body || {};
  if (!isUuid(clubId)) return res.status(400).json({ error: 'bad_request' });

  const { rows } = await sql`SELECT id, name, is_open, join_mode, invite_code FROM clubs WHERE id = ${clubId}`;
  const club = rows[0];
  if (!club) return res.status(404).json({ error: 'not_found' });
  const mode = modeDuClub(club);

  if (mode === 'request') return res.status(409).json({ error: 'request_required' });

  if (mode === 'code') {
    const saisi = normaliserLeCode(req.body?.code);
    // Pas de code : la même réponse que « n'existe pas ». Dire « ce club est fermé » confirmerait
    // son existence à quelqu'un qui ne peut de toute façon pas y entrer.
    if (!saisi) return res.status(404).json({ error: 'not_found' });
    // Un plafond à part pour les essais : c'est la seule valeur ici qu'on puisse chercher.
    if (!(await underDailyCap('joinCode:' + userId, MAX_ESSAIS_DE_CODE_PAR_JOUR))) {
      return res.status(429).json({ error: 'too_many_requests' });
    }
    // 400 et non 403 : le client traite un 403 comme une session refusée.
    if (!codesIdentiques(club.invite_code, saisi)) return res.status(400).json({ error: 'bad_code' });
  }

  // Same double-submit race as create — the unique index is the real guard, the pre-check above
  // just gives the common case a friendlier path.
  try {
    await sql`INSERT INTO club_members (club_id, user_id) VALUES (${club.id}, ${userId})`;
  } catch (e) {
    if (String(e.message).includes('uniq_club_members_user')) {
      return res.status(409).json({ error: 'already_in_club' });
    }
    throw e;
  }
  await retirerSesDemandes(userId);
  res.status(200).json({ id: club.id, name: club.name });
}

// Une personne qui vient d'entrer dans un club n'a plus de demande à faire : on les retire toutes.
// Isolé dans son try/catch : entrer dans le club est fait, et une table de demandes pas encore
// migrée ne doit pas transformer cette réussite en erreur.
async function retirerSesDemandes(userId) {
  try {
    await sql`DELETE FROM club_join_requests WHERE user_id = ${userId}`;
  } catch { /* table pas encore migrée : rien à retirer */ }
}

// CHERCHER UN CLUB PAR SON NOM.
//
// Ne rend que les clubs OUVERTS, et jamais celui dont l'appelante est déjà membre — proposer de
// rejoindre un club où l'on est déjà est la façon la plus sûre de faire douter de ce qu'on lit.
//
// Le nombre de membres accompagne chaque résultat, et ce n'est pas une décoration : rien
// n'empêche deux clubs de porter le même nom, et c'est la seule chose qui permette de les
// distinguer d'un coup d'œil.
// UN CLUB SANS UN SEUL MEMBRE N'EST PAS UN CLUB À REJOINDRE : ni la recherche ni les suggestions ne le
// rendent. Des clubs de test et des clubs abandonnés (tout le monde est parti) s'affichaient avec
// « 0 membre » et un bouton « Rejoindre ». Le nettoyage de ceux qui existent déjà est dans
// `db/A_COLLER_nettoyer_clubs.sql` ; cette condition évite que d'autres reviennent.
async function handleSearchClubs(req, res, userId) {
  const raw = typeof req.query.q === 'string' ? req.query.q.trim().slice(0, 60) : '';
  if (raw.length < 2) return res.status(200).json({ items: [] });

  // Même plafond et même raison que la recherche de personnes : c'est la route qui balaie la
  // table des clubs, donc celle qu'un script interrogerait préfixe par préfixe.
  if (!(await underDailyCap('clubSearch:' + userId, 300))) return res.status(429).json({ error: 'too_many_requests' });

  // `adhesion=1` : l'app sait ce qu'est un club sur demande. Sans elle, la recherche rend ce
  // qu'elle a toujours rendu — les clubs ouverts, et eux seuls : une app installée afficherait un
  // bouton « Rejoindre » sur un club qu'on ne rejoint pas d'un appui.
  // Les clubs sur code n'y sont jamais : ils ne se trouvent pas, on y entre avec le code.
  const avecDemandes = req.query.adhesion === '1';

  const besoin = echapperPourLike(normaliser(raw));
  const { rows } = await sql`
    SELECT c.id, c.name, c.city, c.is_open, c.join_mode,
           (SELECT COUNT(*)::int FROM club_members m WHERE m.club_id = c.id) AS member_count,
           EXISTS (SELECT 1 FROM club_join_requests r
                    WHERE r.club_id = c.id AND r.user_id = ${userId}) AS demande_en_cours
    FROM clubs c
    WHERE (c.is_open = true
           OR (${avecDemandes}::boolean AND c.join_mode = 'request' AND c.created_by IS NOT NULL))
      AND EXISTS (SELECT 1 FROM club_members vivant WHERE vivant.club_id = c.id)
      AND c.id NOT IN (SELECT club_id FROM club_members WHERE user_id = ${userId})
      AND translate(lower(replace(replace(replace(c.name, '-', ' '), 'œ', 'oe'), 'æ', 'ae')),
            ${ACCENTS_SOURCE}, ${ACCENTS_CIBLE}) LIKE ${'%' + besoin + '%'}
    ORDER BY
      (translate(lower(c.name), ${ACCENTS_SOURCE}, ${ACCENTS_CIBLE}) LIKE ${besoin + '%'}) DESC,
      (SELECT COUNT(*) FROM club_members m WHERE m.club_id = c.id) DESC,
      c.name ASC
    LIMIT 20
  `;
  res.status(200).json({
    // La ville avec le nom : « Les Foulées · Lyon » et « Les Foulées · Nantes » cessent d'être
    // le même résultat, et on ne rejoint plus un club à l'autre bout du pays par homonymie.
    items: rows.map((row) => ({
      id: row.id, name: row.name, city: row.city || null, memberCount: row.member_count,
      // Comment on y entre, et si on a déjà demandé : de quoi écrire le bon bouton sans ouvrir la fiche.
      joinMode: modeDuClub(row), requestPending: row.demande_en_cours === true,
    })),
  });
}

// LES CLUBS QU'ON PEUT REJOINDRE, SANS RIEN TAPER. Le pourquoi est dans `lib/clubsSuggeres.js`,
// avec la mise en forme des lignes.
//
// Ce n'est PAS un annuaire complet : cinq lignes, choisies pour qu'on arrive dans un club vivant
// plutôt que dans le plus gros. C'est l'ORDRE qui le décide — une séance à venir d'abord, puis
// un mur qui a parlé récemment, puis le nombre de membres.
//
// AUCUNE POSITION N'ENTRE ICI. Classer par proximité aurait été plus utile, et aurait demandé
// d'envoyer la ville ou les coordonnées de quelqu'un pour une liste de suggestions — une
// nouvelle collecte, à déclarer au manifeste, dans la politique et chez Apple. Pour cinq lignes,
// non.
async function handleSuggestedClubs(req, res, userId) {
  // Plafond plus bas que la recherche : cette route ne répond pas à une frappe, elle répond à
  // l'ouverture d'un écran. Cent fois par jour est déjà beaucoup.
  if (!(await underDailyCap('clubSuggest:' + userId, 100))) return res.status(429).json({ error: 'too_many_requests' });

  // Même `adhesion=1` que la recherche, pour la même raison.
  const avecDemandes = req.query.adhesion === '1';

  const { rows } = await sql`
    SELECT c.id, c.name, c.city, c.is_open, c.join_mode,
           (SELECT COUNT(*)::int FROM club_members m WHERE m.club_id = c.id) AS member_count,
           EXISTS (SELECT 1 FROM club_events e
                    WHERE e.club_id = c.id AND e.starts_at > now()) AS seance_prevue,
           (SELECT MAX(p.created_at) FROM club_posts p WHERE p.club_id = c.id) AS dernier_message,
           EXISTS (SELECT 1 FROM club_join_requests r
                    WHERE r.club_id = c.id AND r.user_id = ${userId}) AS demande_en_cours
    FROM clubs c
    WHERE (c.is_open = true
           OR (${avecDemandes}::boolean AND c.join_mode = 'request' AND c.created_by IS NOT NULL))
      AND EXISTS (SELECT 1 FROM club_members vivant WHERE vivant.club_id = c.id)
      AND c.id NOT IN (SELECT club_id FROM club_members WHERE user_id = ${userId})
    ORDER BY seance_prevue DESC,
             dernier_message DESC NULLS LAST,
             member_count DESC,
             c.name ASC
    LIMIT ${MAX_SUGGESTIONS}
  `;

  const maintenant = Date.now();
  res.status(200).json({ items: rows.map((row) => ligneSuggeree(row, maintenant)) });
}

// LE VERROU D'AVANT LES TROIS MODES, GARDÉ POUR LES APPS DÉJÀ INSTALLÉES.
//
// Une app qui ne connaît pas `join_mode` ouvre et ferme son club avec cet interrupteur, et il doit
// continuer à faire exactement cela : un club fermé disparaît des recherches et ne se rejoint
// plus — il est donc « sur code », ce qu'était un club fermé. Ses membres actuels ne sont pas
// touchés : fermer n'est pas vider.
//
// Deux cas où le mode ne se réduit pas à deux valeurs :
//   · ouvrir un club sur demande l'ouvre pour de bon, et ses demandes en attente n'ont plus de
//     sens : elles sont retirées (leurs auteurs peuvent maintenant entrer d'un appui) ;
//   · « fermer » un club déjà sur demande ne le change pas : pour une app ancienne il est déjà
//     fermé, et le faire passer sur code aurait changé ce que son propriétaire a choisi.
//
// `is_open` reste écrit à chaque fois : voir `lib/adhesionClub.js`.
async function handleSetOpen(req, res, userId) {
  const { isOpen } = req.body || {};
  if (typeof isOpen !== 'boolean') return res.status(400).json({ error: 'bad_request' });

  const clubId = await clubQueJAdministre(userId);
  if (!clubId) return res.status(403).json({ error: 'forbidden' });
  const { rows } = await sql`
    UPDATE clubs SET
      is_open = ${isOpen},
      join_mode = CASE WHEN ${isOpen}::boolean THEN 'open'
                       WHEN is_open = false AND join_mode = 'request' THEN 'request'
                       ELSE 'code' END
    WHERE id = ${clubId}
    RETURNING id, is_open
  `;
  if (rows.length === 0) return res.status(403).json({ error: 'forbidden' });
  if (isOpen) await retirerLesDemandesDuClub(clubId);
  res.status(200).json({ isOpen: rows[0].is_open });
}

async function retirerLesDemandesDuClub(clubId) {
  try {
    await sql`DELETE FROM club_join_requests WHERE club_id = ${clubId}`;
  } catch { /* table pas encore migrée : rien à retirer */ }
}

// QUITTER SON CLUB, Y COMPRIS QUAND ON L'A CRÉÉ.
//
// La créatrice qui partait laissait un club sans personne pour le tenir (voir
// `lib/proprieteClub.js`). Elle le TRANSMET maintenant en partant : à l'organisateur le plus
// ancien, à défaut au membre le plus ancien. Seule dans son club, elle le supprime en le quittant.
// La réponse dit ce qui s'est passé, pour que l'app puisse le dire aussi.
async function handleLeave(req, res, userId) {
  const { rows: possedes } = await sql`
    SELECT c.id, c.cover_url
      FROM clubs c
      JOIN club_members m ON m.club_id = c.id AND m.user_id = ${userId}
     WHERE c.created_by = ${userId}
  `;
  const club = possedes[0];
  if (!club) {
    await sql`DELETE FROM club_members WHERE user_id = ${userId}`;
    return res.status(200).json({ ok: true });
  }

  const { rows: membres } = await sql`
    SELECT user_id, role, joined_at FROM club_members WHERE club_id = ${club.id}
  `;
  const heritier = heritierDuClub(
    membres.map((m) => ({ userId: m.user_id, role: m.role, joinedAt: m.joined_at })), userId);

  if (!heritier) {
    await supprimerLeClub(club);
    return res.status(200).json({ ok: true, clubDeleted: true });
  }
  // La propriété D'ABORD, l'adhésion ensuite : dans l'autre ordre, un échec entre les deux
  // laisserait exactement le club orphelin que cette route existe pour empêcher.
  await sql`UPDATE clubs SET created_by = ${heritier} WHERE id = ${club.id}`;
  await sql`DELETE FROM club_members WHERE user_id = ${userId}`;
  res.status(200).json({ ok: true, newOwnerId: heritier });
}

// Supprime un club et ce qui en dépend. Les membres, les défis, les sorties, les messages et les
// demandes partent avec lui (clés étrangères en cascade) ; les activités restent chez leurs
// autrices, détachées du club (`ON DELETE SET NULL`). L'image de couverture est retirée du
// stockage, sans quoi elle y resterait, facturée et sans plus rien pour la référencer.
async function supprimerLeClub(club) {
  await sql`DELETE FROM clubs WHERE id = ${club.id}`;
  if (club.cover_url) del(club.cover_url).catch(() => {});
}

// ─── CE QUE SEULE LA CRÉATRICE PEUT FAIRE ────────────────────────────────────────────────────
//
// Elle pouvait nommer un organisateur et changer le mode d'entrée, et rien de plus : ni retirer
// quelqu'un, ni changer un code qui avait circulé, ni fermer son club. Trois gestes sans lesquels
// « tenir un club » ne veut pas dire grand-chose.

// Retire UN membre. Jamais soi-même (c'est `leave`, qui transmet le club), et jamais quelqu'un
// d'un autre club : la suppression est bornée au club que l'appelante possède.
//
// Ce n'est PAS une exclusion définitive : dans un club ouvert, la personne peut revenir. Pour
// l'en empêcher, la créatrice passe le club sur demande ou sur code.
async function handleRemoveMember(req, res, userId) {
  const { memberId } = req.body || {};
  if (!isUuid(memberId) || memberId === userId) return res.status(400).json({ error: 'bad_request' });
  const club = await clubQueJePossede(userId);
  if (!club) return res.status(403).json({ error: 'not_owner' });
  const { rows } = await sql`
    DELETE FROM club_members WHERE club_id = ${club.id} AND user_id = ${memberId}
    RETURNING user_id
  `;
  if (rows.length === 0) return res.status(404).json({ error: 'not_found' });
  res.status(200).json({ ok: true, memberId });
}

// Tire un nouveau code. L'ancien cesse de marcher à l'instant : c'est tout l'objet du geste,
// quand un code a circulé plus loin que prévu.
async function handleRegenerateCode(req, res, userId) {
  const club = await clubQueJePossede(userId);
  if (!club) return res.status(403).json({ error: 'not_owner' });
  for (let attempt = 0; attempt < 5; attempt++) {
    const code = randomInviteCode();
    try {
      await sql`UPDATE clubs SET invite_code = ${code} WHERE id = ${club.id}`;
      return res.status(200).json({ inviteCode: codeVisible(modeDuClub(club), true, code) });
    } catch (e) {
      // La même collision, rarissime, que `create` rejoue : un code déjà porté par un autre club.
      if (!String(e.message).includes('invite_code')) throw e;
    }
  }
  res.status(500).json({ error: 'could_not_regenerate' });
}

// Supprime le club. Seule la créatrice, et seulement tant qu'elle en est membre.
async function handleDeleteClub(req, res, userId) {
  const { rows } = await sql`
    SELECT c.id, c.cover_url
      FROM clubs c
      JOIN club_members m ON m.club_id = c.id AND m.user_id = ${userId}
     WHERE c.created_by = ${userId}
  `;
  if (!rows[0]) return res.status(403).json({ error: 'not_owner' });
  await supprimerLeClub(rows[0]);
  res.status(200).json({ ok: true });
}

// Any member can set the club's active challenge — replaces the one before it (a club has at
// most one active challenge at a time, kept simple rather than juggling several in parallel).
async function handleCreateChallenge(req, res, userId) {
  const { rows: memberRows } = await sql`SELECT club_id FROM club_members WHERE user_id = ${userId}`;
  const clubId = memberRows[0]?.club_id;
  if (!clubId) return res.status(409).json({ error: 'not_in_club' });

  const { title, targetKm, endDate } = req.body || {};
  const cleanTitle = typeof title === 'string' ? title.trim().slice(0, 100) : '';
  const target = Number(targetKm);
  // endDate must be a real, parseable YYYY-MM-DD that isn't already past — an arbitrary string
  // used to reach Postgres as a cast error (a 500), and a target with no upper bound let a
  // tampered client store absurd values the whole club then sees.
  const validDate = typeof endDate === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(endDate) && !Number.isNaN(Date.parse(endDate));
  if (!cleanTitle || !Number.isFinite(target) || target <= 0 || target > 10000 || !validDate) {
    return res.status(400).json({ error: 'bad_request' });
  }
  if (containsObjectionableContent(cleanTitle)) return res.status(422).json({ error: 'objectionable_content' });

  // Idempotent on the client-generated clientId, same pattern as activities.client_id — a
  // request that timed out client-side after the server already processed it (then retried by
  // the user re-tapping) must not insert a second challenge and re-notify... well, this endpoint
  // doesn't push, but it would otherwise silently create an orphaned duplicate row. clientId is
  // optional (older clients / callers that don't send one just skip the dedup, same as before).
  const { clientId } = req.body || {};
  const cleanClientId = isUuid(clientId) ? clientId : null;

  const { rows: inserted } = await sql`
    INSERT INTO challenges (club_id, created_by, title, target_km, end_date, client_id)
    VALUES (${clubId}, ${userId}, ${cleanTitle}, ${target}, ${endDate}, ${cleanClientId})
    ON CONFLICT (client_id) DO NOTHING
    RETURNING id, title, target_km, end_date, created_at
  `;

  let challenge = inserted[0];
  let progressKm = 0;
  if (!challenge && cleanClientId) {
    // A retried request that already landed — return the existing row (with its real progress)
    // instead of erroring or silently creating a duplicate.
    const { rows: existing } = await sql`
      SELECT c.id, c.title, c.target_km, c.end_date,
             COALESCE((
               SELECT SUM(a.distance_km) FROM activities a
               WHERE a.club_id = ${clubId} AND a.type = 'run' AND a.distance_km IS NOT NULL
                 AND a.created_at >= c.created_at
             ), 0) AS progress_km
      FROM challenges c
      WHERE c.client_id = ${cleanClientId}
    `;
    challenge = existing[0];
    progressKm = Number(challenge?.progress_km ?? 0);
  }
  if (!challenge) return res.status(500).json({ error: 'could_not_create' });

  res.status(201).json({
    id: challenge.id,
    title: challenge.title,
    targetKm: Number(challenge.target_km),
    progressKm,
    endDate: challenge.end_date,
  });
}

// The user's club (if any) plus a real, computed leaderboard — ranked by each member's actual
// xp_total, not a fixed/mocked position. Returns { club: null } if the user hasn't joined or
// created a club yet.
async function handleMine(req, res, userId) {
  const { rows: memberRows } = await sql`SELECT club_id FROM club_members WHERE user_id = ${userId}`;
  if (memberRows.length === 0) return res.status(200).json({ club: null, leaderboard: [] });

  const clubId = memberRows[0].club_id;
  const { rows: clubRows } = await sql`SELECT id, name, is_open, join_mode, invite_code, created_by, description, city, cover_url FROM clubs WHERE id = ${clubId}`;
  const club = clubRows[0];
  const mode = modeDuClub(club);
  const estProprietaire = club.created_by === userId;
  // Les demandes en attente, comptées pour le seul propriétaire : de quoi lui dire qu'il y a
  // quelque chose à traiter sans qu'il ouvre la gestion. Isolé dans son try/catch — c'est une
  // mention EN PLUS, et une table pas encore migrée ne doit pas coûter l'écran du club entier.
  let demandesEnAttente = 0;
  if (estProprietaire && mode === 'request') {
    try {
      const { rows } = await sql`
        SELECT COUNT(*)::int AS n FROM club_join_requests r
         WHERE r.club_id = ${clubId}
           AND r.user_id NOT IN (SELECT blocked_id FROM blocks WHERE blocker_id = ${userId})
           AND r.user_id NOT IN (SELECT blocker_id FROM blocks WHERE blocked_id = ${userId})
      `;
      demandesEnAttente = rows[0]?.n ?? 0;
    } catch { /* table pas encore migrée */ }
  }

  // Rank is computed over every member first (a subquery), then blocked users are filtered out
  // of the outer result — so someone you've blocked disappears from your view, but everyone
  // else's rank number still reflects their true position rather than shifting to fill the gap.
  // bio/joined_at/activities_count/badge_keys power the real club-profile screen — real per-member
  // data (join date already tracked, activity count a plain COUNT scoped to this club, badges a
  // real array_agg over `user_badges`) instead of anything computed only from this device's own
  // local history.
  const { rows: leaderboard } = await sql`
    SELECT id, name, last_name, xp_total, rank, bio, avatar_data, avatar_url, joined_at, activities_count, badge_keys, role FROM (
      SELECT u.id, u.name, u.last_name, u.xp_total, u.bio, u.avatar_data, u.avatar_url, cm.joined_at,
             -- Qui tient le club. La créatrice est organisatrice par construction, sans ligne
             -- de rôle à elle : c'est clubs.created_by qui le dit, et le calculer ici évite à
             -- l'app de porter la règle une deuxième fois.
             --
             -- (Pas d'accent grave dans ce commentaire : il est À L'INTÉRIEUR d'un gabarit
             -- JavaScript délimité par des accents graves, et le premier refermerait la chaîne.)
             CASE WHEN u.id = ${club.created_by} THEN 'owner' ELSE cm.role END AS role,
             RANK() OVER (ORDER BY u.xp_total DESC) AS rank,
             (SELECT COUNT(*)::int FROM activities a WHERE a.user_id = u.id AND a.club_id = cm.club_id) AS activities_count,
             COALESCE((SELECT array_agg(ub.badge_key) FROM user_badges ub WHERE ub.user_id = u.id), ARRAY[]::text[]) AS badge_keys
      FROM club_members cm
      JOIN users u ON u.id = cm.user_id
      WHERE cm.club_id = ${clubId}
    ) ranked
    WHERE id NOT IN (SELECT blocked_id FROM blocks WHERE blocker_id = ${userId})
    AND id NOT IN (SELECT blocker_id FROM blocks WHERE blocked_id = ${userId})
    ORDER BY xp_total DESC
    LIMIT 100
  `;

  const { rows: countRows } = await sql`SELECT COUNT(*)::int AS count FROM club_members WHERE club_id = ${clubId}`;

  // The most recent still-active challenge (if any), with real collective progress: every
  // 'run' activity logged to this club since the challenge was created, summed — not a running
  // counter that could drift from what actually got posted.
  const { rows: challengeRows } = await sql`
    SELECT c.id, c.title, c.target_km, c.end_date,
           COALESCE((
             SELECT SUM(a.distance_km) FROM activities a
             WHERE a.club_id = ${clubId} AND a.type = 'run' AND a.distance_km IS NOT NULL
               AND a.created_at >= c.created_at
           ), 0) AS progress_km
    FROM challenges c
    WHERE c.club_id = ${clubId} AND c.end_date >= CURRENT_DATE
    ORDER BY c.created_at DESC
    LIMIT 1
  `;
  const challenge = challengeRows[0];

  // Weekly leaderboard: real km actually run THIS week (date_trunc('week') is ISO/Monday-start,
  // same convention as the app's plan engine) — a fresh race every Monday, next to the all-time
  // XP board which a newcomer could otherwise never climb. `weekly_target_km` (each member's own
  // client-computed plan for this week, see `handleSyncWeeklyTarget`) rides along so the client
  // can offer a "% objectif" ranking mode alongside the raw-km one — still ordered by km here,
  // the client re-sorts client-side when that mode is selected.
  const { rows: weekly } = await sql`
    SELECT u.id, u.name, u.last_name, u.avatar_data, u.avatar_url, u.weekly_target_km, COALESCE(SUM(a.distance_km), 0) AS week_km
    FROM club_members cm
    JOIN users u ON u.id = cm.user_id
    LEFT JOIN activities a ON a.user_id = u.id AND a.club_id = cm.club_id
      AND a.type = 'run' AND a.distance_km IS NOT NULL
      AND a.created_at >= date_trunc('week', now())
    WHERE cm.club_id = ${clubId}
      AND u.id NOT IN (SELECT blocked_id FROM blocks WHERE blocker_id = ${userId})
      AND u.id NOT IN (SELECT blocker_id FROM blocks WHERE blocked_id = ${userId})
    GROUP BY u.id, u.name, u.last_name, u.avatar_data, u.avatar_url, u.weekly_target_km
    ORDER BY week_km DESC, u.name ASC
    LIMIT 100
  `;

  // Upcoming sorties de groupe — includes ones started in the last 3h (a 9h meetup should still
  // show mid-morning), capped at the next 10. Isolated in its own try/catch: club_events/
  // event_rsvps are the newest tables, added after everything else here — if the Neon migration
  // that creates them hasn't run yet on a given deploy, a "relation does not exist" error must
  // only cost the sorties section, not 500 the entire Club tab (club info, both leaderboards,
  // the challenge) for every member.
  let events = [];
  try {
    // LA SÉANCE QUI REVIENT S'AVANCE TOUTE SEULE.
    //
    // Une séance hebdomadaire est UNE ligne qui pointe toujours vers la prochaine fois — pas une
    // ligne par occurrence, qui ferait cinquante-deux lignes par an dont on ne regarde que la
    // première. Quand sa date est passée de plus de trois heures, on l'avance d'autant de
    // semaines qu'il faut (`ceil` : un club en sommeil trois semaines retrouve la bonne date du
    // premier coup, pas trois lectures plus tard).
    //
    // Une seule instruction, donc atomique : deux membres qui ouvrent le Club à la même seconde
    // ne peuvent pas l'avancer deux fois.
    const { rows: avancees } = await sql`
      UPDATE club_events
         SET starts_at = starts_at + (
               ceil(extract(epoch FROM (now() - starts_at)) / 604800.0) * interval '7 days')
       WHERE club_id = ${clubId}
         AND repeats_weekly = true
         AND starts_at < now() - interval '3 hours'
      RETURNING id, title, starts_at,
                starts_at - (ceil(extract(epoch FROM (now() - starts_at)) / 604800.0) * interval '7 days') AS tenue_le,
                (SELECT COUNT(*)::int FROM event_rsvps r WHERE r.event_id = club_events.id) AS presents
    `;

    // ON GARDE CE QUI VIENT D'AVOIR LIEU, AVANT DE L'EFFACER.
    //
    // La séance s'avance d'une semaine et vide ses présences : sans cette ligne, « on était 28
    // mardi dernier » disparaîtrait au profit de mardi prochain, chaque semaine, pour toujours.
    // C'est pourtant la phrase dont un crew est fier, et la preuve qu'un club vit.
    //
    // `ON CONFLICT DO NOTHING` sur (club, date, titre) : l'avance est atomique, mais une
    // migration rejouée ne doit pas doubler un mardi.
    const tenues = avancees.filter((e) => e.presents > 0);
    if (tenues.length > 0) {
      await sql`
        INSERT INTO club_session_history (club_id, event_id, title, held_at, attendees)
        SELECT ${clubId}, x.event_id::uuid, x.title, x.held_at::timestamptz, x.attendees::int
          FROM jsonb_to_recordset(${JSON.stringify(tenues.map((e) => ({
            event_id: e.id, title: e.title, held_at: e.tenue_le, attendees: e.presents,
          })))}::jsonb)
            AS x(event_id text, title text, held_at text, attendees int)
        ON CONFLICT DO NOTHING
      `;
    }
    // Les présences appartiennent à l'occurrence, pas à la série : « qui vient » se redemande
    // chaque semaine. Sans ce vide, la séance de mardi prochain s'ouvrirait avec les présents de
    // mardi dernier déjà cochés.
    if (avancees.length > 0) {
      // `= ANY(…::uuid[])` ET NON `IN (…)` : le pilote passe un tableau JS comme UN paramètre,
      // donc `IN ($1)` comparerait un uuid à un tableau entier et échouerait. Le transtypage est
      // nécessaire parce que le tableau arrive en `text[]`.
      const ids = avancees.map((r) => r.id);
      await sql`DELETE FROM event_rsvps WHERE event_id = ANY(${ids}::uuid[])`;
    }

    const { rows } = await sql`
      SELECT e.id, e.title, e.location, e.starts_at, e.created_by,
             e.repeats_weekly, e.pace_groups,
             (SELECT COUNT(*)::int FROM event_rsvps r WHERE r.event_id = e.id) AS going,
             EXISTS(SELECT 1 FROM event_rsvps r WHERE r.event_id = e.id AND r.user_id = ${userId}) AS going_by_me,
             (SELECT r.pace_group FROM event_rsvps r WHERE r.event_id = e.id AND r.user_id = ${userId}) AS my_pace_group,
             -- Combien de personnes dans chaque groupe d'allure : c'est la seule information
             -- dont l'organisateur a besoin, et celle qui dit à chacun s'il courra accompagné.
             (SELECT COALESCE(json_object_agg(g.pace_group, g.n), '{}'::json) FROM (
                SELECT r.pace_group, COUNT(*)::int AS n
                  FROM event_rsvps r
                 WHERE r.event_id = e.id AND r.pace_group IS NOT NULL
                 GROUP BY r.pace_group) g) AS pace_counts
      FROM club_events e
      WHERE e.club_id = ${clubId} AND e.starts_at >= now() - interval '3 hours'
      ORDER BY e.starts_at ASC
      LIMIT 10
    `;
    events = rows;
  } catch { /* table not migrated yet on this deploy — degrade to no events, not a 500 */ }

  const weeklyMapped = weekly.map((r, i) => {
    const weekKm = Number(r.week_km);
    const targetKm = r.weekly_target_km != null ? Number(r.weekly_target_km) : null;
    return {
      id: r.id, name: r.name, lastName: r.last_name || null,
      avatarBase64: r.avatar_data || null, avatarUrl: r.avatar_url || null,
      weekKm, rank: i + 1, isMe: r.id === userId,
      targetKm,
      // null (not 0) when this member has no target on record yet — the client falls back to
      // km-only display for that one row instead of showing a misleading "0%".
      pctOfTarget: targetKm && targetKm > 0 ? Math.round((weekKm / targetKm) * 100) : null,
    };
  });

  res.status(200).json({
    club: {
      id: club.id, name: club.name, memberCount: countRows[0].count,
      // Le verrou, et à qui il appartient. Le client n'affiche l'interrupteur qu'à la personne
      // qui a créé le club — le serveur le revérifie de toute façon (`handleSetOpen`).
      isOpen: club.is_open, isOwner: estProprietaire,
      // Comment on entre dans ce club (`open`, `request`, `code`). Le code d'invitation n'est
      // rendu qu'à la personne qui a créé le club, et seulement quand le club est sur code : il
      // n'a aucune raison d'atterrir sur l'écran d'un membre.
      joinMode: mode,
      inviteCode: codeVisible(mode, estProprietaire, club.invite_code),
      pendingRequests: estProprietaire && mode === 'request' ? demandesEnAttente : null,
      // Ce qui fait d'un club un LIEU et plus un nom : ce qu'il est, et où il court.
      description: club.description || null,
      city: club.city || null,
      coverUrl: club.cover_url || null,
    },
    leaderboard: leaderboard.map((r) => ({
      id: r.id, name: r.name, lastName: r.last_name || null, xp: r.xp_total, rank: Number(r.rank), isMe: r.id === userId,
      bio: r.bio || null,
      avatarBase64: r.avatar_data || null,
      avatarUrl: r.avatar_url || null,
      joinedAt: r.joined_at,
      activitiesCount: r.activities_count,
      badgeKeys: r.badge_keys || [],
      role: r.role || 'member',
    })),
    weekly: weeklyMapped,
    weekStats: {
      totalKm: weeklyMapped.reduce((sum, r) => sum + r.weekKm, 0),
      activeMembers: weeklyMapped.filter((r) => r.weekKm > 0).length,
    },
    events: events.map((e) => ({
      id: e.id,
      title: e.title,
      location: e.location || null,
      startsAt: e.starts_at,
      going: e.going,
      goingByMe: e.going_by_me,
      isMine: e.created_by === userId,
      repeatsWeekly: e.repeats_weekly === true,
      paceGroups: Array.isArray(e.pace_groups) ? e.pace_groups : [],
      myPaceGroup: e.my_pace_group || null,
      paceCounts: e.pace_counts || {},
    })),
    challenge: challenge ? {
      id: challenge.id,
      title: challenge.title,
      targetKm: Number(challenge.target_km),
      progressKm: Number(challenge.progress_km),
      endDate: challenge.end_date,
    } : null,
  });
}

// A member proposes a real group run — title + optional meeting point + date/time. The creator
// is auto-RSVP'd (proposing a sortie means going), and every other member gets a push.
// Les groupes d'allure d'une séance, écrits par qui la propose. Une liste libre : un club
// décide de ses groupes, et aucune échelle imposée ne conviendrait à la fois à un crew de
// débutants et à un club d'élite. Huit au plus — au-delà ce n'est plus un départ groupé.
function nettoyerLesGroupes(valeur) {
  if (!Array.isArray(valeur) || valeur.length === 0) return null;
  const propres = valeur
    .filter((g) => typeof g === 'string')
    .map((g) => g.trim().slice(0, 24))
    .filter(Boolean)
    .slice(0, 8);
  if (propres.length === 0) return null;
  // Les libellés s'affichent chez tous les membres : même filtre que le titre.
  if (propres.some((g) => containsObjectionableContent(g))) return 'rejete';
  return propres;
}

async function handleCreateEvent(req, res, userId) {
  const { title, location, startsAt } = req.body || {};
  const cleanTitle = typeof title === 'string' ? title.trim().slice(0, 80) : '';
  const cleanLocation = typeof location === 'string' ? location.trim().slice(0, 80) : '';
  if (!cleanTitle || !startsAt) return res.status(400).json({ error: 'bad_request' });
  if (containsObjectionableContent(cleanTitle) || containsObjectionableContent(cleanLocation)) {
    return res.status(422).json({ error: 'objectionable_content' });
  }
  const when = new Date(startsAt);
  if (Number.isNaN(when.getTime())) return res.status(400).json({ error: 'bad_request' });
  const oneYear = 365 * 24 * 3600 * 1000;
  if (when.getTime() < Date.now() - 3600 * 1000 || when.getTime() > Date.now() + oneYear) {
    return res.status(400).json({ error: 'bad_date' });
  }

  const { rows: memberRows } = await sql`SELECT club_id FROM club_members WHERE user_id = ${userId}`;
  const clubId = memberRows[0]?.club_id;
  if (!clubId) return res.status(409).json({ error: 'not_in_club' });

  // Every other member gets a real push per call — without a cap this is an easy way to flood
  // the whole club's lock screens. 20/day is far beyond any real day of group-run proposals.
  if (!(await underDailyCap('event:' + userId, 20))) return res.status(429).json({ error: 'too_many_requests' });

  // Idempotent on the client-generated clientId, same pattern as activities.client_id — without
  // it, a request that timed out client-side after the server already processed it (then retried
  // by the user re-tapping "Proposer" after seeing a spinner hang) inserted a second near-
  // identical event and re-pushed the whole club a second time. clientId is optional (older
  // clients just skip the dedup, same as before).
  const { clientId } = req.body || {};
  const cleanClientId = isUuid(clientId) ? clientId : null;

  const repeats = req.body?.repeatsWeekly === true;
  const groupes = nettoyerLesGroupes(req.body?.paceGroups);
  if (groupes === 'rejete') return res.status(422).json({ error: 'objectionable_content' });

  const { rows: inserted } = await sql`
    INSERT INTO club_events (club_id, created_by, title, location, starts_at, client_id,
                             repeats_weekly, pace_groups)
    VALUES (${clubId}, ${userId}, ${cleanTitle}, ${cleanLocation || null}, ${when.toISOString()}, ${cleanClientId},
            ${repeats}, ${groupes ? JSON.stringify(groupes) : null}::jsonb)
    ON CONFLICT (client_id) DO NOTHING
    RETURNING id, title, location, starts_at
  `;

  if (inserted.length === 0 && cleanClientId) {
    // Already created by an earlier attempt of this same request — return it as-is, RSVP'd and
    // pushed already, rather than doing either a second time.
    const { rows: existing } = await sql`SELECT id, title, location, starts_at FROM club_events WHERE client_id = ${cleanClientId}`;
    const event = existing[0];
    if (!event) return res.status(500).json({ error: 'could_not_create' });
    return res.status(201).json({ id: event.id, title: event.title, location: event.location || null, startsAt: event.starts_at, going: 1, goingByMe: true, isMine: true });
  }

  const event = inserted[0];
  await sql`INSERT INTO event_rsvps (event_id, user_id) VALUES (${event.id}, ${userId}) ON CONFLICT DO NOTHING`;

  // Push before the response — Vercel may freeze the function once the response is sent.
  const { rows: me } = await sql`SELECT name FROM users WHERE id = ${userId}`;
  const { rows: recipients } = await sql`
    SELECT user_id FROM club_members
    WHERE club_id = ${clubId} AND user_id != ${userId}
      AND user_id NOT IN (SELECT blocker_id FROM blocks WHERE blocked_id = ${userId})
  `;
  await sendPushToUsers(sql, recipients.map((r) => r.user_id), {
    title: 'Sortie de groupe',
    body: `${me[0]?.name || 'Un membre'} propose : ${cleanTitle}`,
  });

  res.status(201).json({
    id: event.id,
    title: event.title,
    location: event.location || null,
    startsAt: event.starts_at,
    going: 1,
    goingByMe: true,
    isMine: true,
  });
}

// Toggles the caller's "J'y serai" on one sortie — scoped to their own club.
async function handleRsvpEvent(req, res, userId) {
  const { eventId } = req.body || {};
  if (!isUuid(eventId)) return res.status(400).json({ error: 'bad_request' });

  const { rows: memberRows } = await sql`SELECT club_id FROM club_members WHERE user_id = ${userId}`;
  const clubId = memberRows[0]?.club_id;
  const { rows: eventRows } = await sql`SELECT club_id, pace_groups FROM club_events WHERE id = ${eventId}`;
  if (!clubId || eventRows[0]?.club_id !== clubId) return res.status(404).json({ error: 'not_found' });

  // LE GROUPE D'ALLURE DOIT ÊTRE UN DE CEUX DE LA SÉANCE. Du texte libre venu du client
  // atterrirait à côté des libellés de l'organisateur et ferait, à l'affichage, un quatrième
  // groupe que personne n'a prévu.
  const proposes = Array.isArray(eventRows[0].pace_groups) ? eventRows[0].pace_groups : [];
  const demande = typeof req.body?.paceGroup === 'string' ? req.body.paceGroup : null;
  const groupe = demande && proposes.includes(demande) ? demande : null;

  const { rows: existing } = await sql`SELECT pace_group FROM event_rsvps WHERE event_id = ${eventId} AND user_id = ${userId}`;
  if (existing.length > 0) {
    // Déjà présente, mais sur un AUTRE groupe : elle change de groupe, elle ne se décommande
    // pas. Sans ce cas, taper « 5:15 » quand on était sur « 4:30 » effaçait la présence.
    if (groupe && existing[0].pace_group !== groupe) {
      await sql`UPDATE event_rsvps SET pace_group = ${groupe} WHERE event_id = ${eventId} AND user_id = ${userId}`;
      const { rows: apres } = await sql`SELECT COUNT(*)::int AS count FROM event_rsvps WHERE event_id = ${eventId}`;
      return res.status(200).json({ going: true, count: apres[0].count, paceGroup: groupe });
    }
    await sql`DELETE FROM event_rsvps WHERE event_id = ${eventId} AND user_id = ${userId}`;
  } else {
    await sql`
      INSERT INTO event_rsvps (event_id, user_id, pace_group) VALUES (${eventId}, ${userId}, ${groupe})
      ON CONFLICT DO NOTHING
    `;
  }
  const { rows: countRows } = await sql`SELECT COUNT(*)::int AS count FROM event_rsvps WHERE event_id = ${eventId}`;
  res.status(200).json({
    going: existing.length === 0,
    count: countRows[0].count,
    paceGroup: existing.length === 0 ? groupe : null,
  });
}

// Only the sortie's creator can cancel it.
// MODIFIER UNE SORTIE DE GROUPE DÉJÀ PROPOSÉE.
//
// Les mêmes contrôles que `createEvent` — modération du titre et du lieu, date dans la fenêtre
// d'un an, groupes d'allure nettoyés — parce qu'une modification est une CRÉATION différée : ce
// qui n'avait pas le droit d'entrer à la création n'a pas le droit d'entrer ici non plus. Les
// recopier plutôt que les appeler est délibéré : les deux points d'entrée ne partagent ni leur
// idempotence, ni leur plafond quotidien, ni leur notification.
//
// Pas de plafond quotidien, lui : modifier ne pousse aucune notification, donc rien à limiter.
// Et pas de `clientId` : on modifie une ligne qui existe, l'identifiant EST l'idempotence.
//
// MÊME RÈGLE D'AUTORISATION QUE LA SUPPRESSION : son auteur, ou un organisateur du club. Une
// séance laissée par quelqu'un qui est parti doit rester corrigeable.
async function handleUpdateEvent(req, res, userId) {
  const { eventId, title, location, startsAt } = req.body || {};
  if (!isUuid(eventId)) return res.status(400).json({ error: 'bad_request' });

  const cleanTitle = typeof title === 'string' ? title.trim().slice(0, 80) : '';
  const cleanLocation = typeof location === 'string' ? location.trim().slice(0, 80) : '';
  if (!cleanTitle || !startsAt) return res.status(400).json({ error: 'bad_request' });
  if (containsObjectionableContent(cleanTitle) || containsObjectionableContent(cleanLocation)) {
    return res.status(422).json({ error: 'objectionable_content' });
  }
  const when = new Date(startsAt);
  if (Number.isNaN(when.getTime())) return res.status(400).json({ error: 'bad_request' });
  const oneYear = 365 * 24 * 3600 * 1000;
  if (when.getTime() < Date.now() - 3600 * 1000 || when.getTime() > Date.now() + oneYear) {
    return res.status(400).json({ error: 'bad_date' });
  }
  const repeats = req.body?.repeatsWeekly === true;
  const groupes = nettoyerLesGroupes(req.body?.paceGroups);
  if (groupes === 'rejete') return res.status(422).json({ error: 'objectionable_content' });

  const administre = await clubQueJAdministre(userId);
  const { rows } = await sql`
    UPDATE club_events
       SET title = ${cleanTitle},
           location = ${cleanLocation || null},
           starts_at = ${when.toISOString()},
           repeats_weekly = ${repeats},
           pace_groups = ${groupes ? JSON.stringify(groupes) : null}::jsonb
     WHERE id = ${eventId}
       AND (created_by = ${userId} OR (${administre}::uuid IS NOT NULL AND club_id = ${administre}::uuid))
    RETURNING 1
  `;
  if (rows.length === 0) return res.status(404).json({ error: 'not_found' });
  res.status(200).json({ ok: true });
}

async function handleDeleteEvent(req, res, userId) {
  const { eventId } = req.body || {};
  if (!isUuid(eventId)) return res.status(400).json({ error: 'bad_request' });
  // SON AUTEUR, OU UN ORGANISATEUR. Une séance qu'un membre parti a laissée derrière lui
  // resterait sinon affichée pour toujours, sans personne pour l'annuler.
  const administre = await clubQueJAdministre(userId);
  const { rows } = await sql`
    DELETE FROM club_events
     WHERE id = ${eventId}
       AND (created_by = ${userId} OR (${administre}::uuid IS NOT NULL AND club_id = ${administre}::uuid))
    RETURNING id
  `;
  if (rows.length === 0) return res.status(404).json({ error: 'not_found' });
  res.status(200).json({ ok: true });
}

// A short, optional, self-authored status shown on the caller's own club profile — only ever the
// caller's own row (there's no targetId; the token is the identity), same moderation as club
// names and challenge titles.
async function handleUpdateBio(req, res, userId) {
  const { bio } = req.body || {};
  const trimmed = (bio || '').trim().slice(0, 140);
  if (trimmed && containsObjectionableContent(trimmed)) return res.status(422).json({ error: 'objectionable_content' });
  await sql`UPDATE users SET bio = ${trimmed || null} WHERE id = ${userId}`;
  res.status(200).json({ ok: true, bio: trimmed || null });
}

// Upserts real, permanent achievements from keys the client computed locally (streak, run
// history, elevation — data only the client has). Never deletes: once earned, a badge stays
// earned even if the underlying streak later resets, same as any other achievement system.
// Unknown keys are silently dropped rather than trusted, since a tampered client could otherwise
// write arbitrary junk here.
async function handleSyncBadges(req, res, userId) {
  const { badgeKeys } = req.body || {};
  if (!Array.isArray(badgeKeys)) return res.status(400).json({ error: 'bad_request' });
  const valid = [...new Set(badgeKeys)].filter((k) => KNOWN_BADGES.has(k));
  await Promise.all(
    valid.map((key) => sql`
      INSERT INTO user_badges (user_id, badge_key) VALUES (${userId}, ${key})
      ON CONFLICT DO NOTHING
    `)
  );
  res.status(200).json({ ok: true });
}

// Pushes up the client's own computed `plannedWeeklyKm` (see `UserProfile.plannedWeeklyKm`) —
// this device is the only place that can compute it (real program/session data), same reasoning
// as `handleSyncBadges`. Clamped to a sane range rather than trusted outright: a tampered or
// corrupted value here would skew the "% objectif" leaderboard mode for the whole club, not just
// this one member's own view of it.
async function handleSyncWeeklyTarget(req, res, userId) {
  const { targetKm } = req.body || {};
  if (typeof targetKm !== 'number' || !Number.isFinite(targetKm) || targetKm < 0 || targetKm > 500) {
    return res.status(400).json({ error: 'bad_request' });
  }
  await sql`UPDATE users SET weekly_target_km = ${targetKm} WHERE id = ${userId}`;
  res.status(200).json({ ok: true });
}

// LE CLASSEMENT MONDIAL EST PARTI.
//
// Un club de course est LOCAL. Se comparer aux kilomètres de quelqu'un qu'on ne croisera jamais,
// dans une ville qu'on ne connaît pas, ne fait pas courir — ça ne fait même pas un classement,
// ça fait un palmarès où personne ne se reconnaît.
//
// C'était aussi, et de loin, la requête la plus lourde du serveur : une agrégation sur TOUS les
// comptes inscrits et toutes leurs activités de la semaine, pour un écran que presque personne
// n'ouvrait. La colonne `users.global_leaderboard_opt_in` reste en base : la retirer serait une
// migration destructrice pour rien.

// CE QU'UN CLUB A ET QU'UN CLASSEMENT N'A PAS.
//
// Un classement hebdomadaire dit qui court le plus. Il ne dit pas ce que le club PRÉPARE, ni ce
// qu'il a déjà fait de mieux. Deux choses qu'aucune des deux autres listes ne porte, et qui ne
// demandent aucune colonne nouvelle : elles sont dans les courses suivies et dans les sorties
// publiées, elles n'avaient simplement jamais été regardées ensemble.
//
// Un point d'entrée à part du tableau de bord : le tableau est demandé à chaque ouverture du
// Club, celui-ci seulement quand l'aperçu s'affiche. Les deux requêtes partent ensemble.
async function handleHighlights(req, res, userId) {
  const { rows: memberRows } = await sql`SELECT club_id FROM club_members WHERE user_id = ${userId}`;
  const clubId = memberRows[0]?.club_id;
  // Pas de club : pas d'erreur, des listes vides. L'écran qui appelle ne sait pas toujours encore
  // s'il y en a un, et un 404 l'obligerait à distinguer « pas de club » de « panne ».
  if (!clubId) return res.status(200).json({ races: [], records: [] });

  const [courses, records, semaine, seances] = await Promise.all([
    // LES COURSES QUE LE CLUB PRÉPARE, la plus proche d'abord. Une course par ligne, avec qui
    // s'y est inscrit : c'est le « qui vient ? » d'une sortie de groupe, à l'échelle d'une année.
    sql`
      SELECT r.id, r.name, r.city, to_char(r.race_date, 'YYYY-MM-DD') AS race_date,
             r.distance_km, r.discipline,
             COUNT(*)::int AS members,
             json_agg(json_build_object(
               'id', u.id, 'name', u.name, 'lastName', u.last_name,
               'avatarUrl', u.avatar_url, 'avatarBase64', u.avatar_data
             ) ORDER BY u.name) AS runners
        FROM race_followers f
        JOIN races r ON r.id = f.race_id
        JOIN club_members cm ON cm.user_id = f.user_id AND cm.club_id = ${clubId}
        JOIN users u ON u.id = f.user_id
       WHERE r.race_date >= CURRENT_DATE
         AND f.user_id NOT IN (SELECT blocked_id FROM blocks WHERE blocker_id = ${userId})
         AND f.user_id NOT IN (SELECT blocker_id FROM blocks WHERE blocked_id = ${userId})
       GROUP BY r.id, r.name, r.city, r.race_date, r.distance_km, r.discipline
       ORDER BY r.race_date ASC
       LIMIT 8
    `,
    // LES RECORDS DU CLUB. Trois, et pas un palmarès : la plus longue sortie, la meilleure
    // allure, le plus gros dénivelé. Chacun est une vraie sortie publiée, avec qui l'a courue.
    //
    // L'ALLURE SE CALCULE, ELLE NE SE TRIE PAS. `avg_pace` est du texte (« 5:38 ») : trié comme
    // tel, « 10:12 » passerait avant « 9:30 ». Les secondes au kilomètre viennent donc de la
    // durée et de la distance, et seulement au-delà de 5 km — en dessous, un sprint de 800 m
    // gagnerait tous les classements d'allure d'un club pour toujours.
    sql`
      WITH sorties AS (
        SELECT a.id, a.user_id, u.name, u.last_name, u.avatar_url, u.avatar_data, a.created_at,
               a.distance_km, a.duration_seconds, a.elevation_gain_m,
               CASE WHEN a.distance_km > 0 AND a.duration_seconds > 0
                    THEN a.duration_seconds / a.distance_km END AS sec_par_km
          FROM activities a
          JOIN users u ON u.id = a.user_id
          JOIN club_members cm ON cm.user_id = a.user_id AND cm.club_id = ${clubId}
         WHERE a.type = 'run'
           AND a.user_id NOT IN (SELECT blocked_id FROM blocks WHERE blocker_id = ${userId})
           AND a.user_id NOT IN (SELECT blocker_id FROM blocks WHERE blocked_id = ${userId})
      )
      (SELECT 'distance' AS genre, id, user_id, name, last_name, avatar_url, avatar_data, created_at,
              distance_km, duration_seconds, elevation_gain_m, sec_par_km
         FROM sorties WHERE distance_km IS NOT NULL ORDER BY distance_km DESC LIMIT 1)
      UNION ALL
      (SELECT 'allure', id, user_id, name, last_name, avatar_url, avatar_data, created_at,
              distance_km, duration_seconds, elevation_gain_m, sec_par_km
         FROM sorties WHERE sec_par_km IS NOT NULL AND distance_km >= 5
        ORDER BY sec_par_km ASC LIMIT 1)
      UNION ALL
      (SELECT 'denivele', id, user_id, name, last_name, avatar_url, avatar_data, created_at,
              distance_km, duration_seconds, elevation_gain_m, sec_par_km
         FROM sorties WHERE elevation_gain_m > 0 ORDER BY elevation_gain_m DESC LIMIT 1)
    `,
    // LA PLUS GROSSE SEMAINE DU CLUB — le seul record qui n'appartienne à personne.
    //
    // Les trois ci-dessus nomment quelqu'un ; celui-ci dit ce que le club a fait ENSEMBLE, et
    // c'est une phrase qu'aucun classement individuel ne produira jamais.
    //
    // La semaine EN COURS est exclue : elle n'est pas finie, et la comparer à des semaines
    // entières ferait dire « record » à une semaine qui vient de commencer. `date_trunc('week')`
    // démarre un lundi en Postgres — le même lundi que le classement hebdomadaire de l'app.
    //
    // Pas de filtre de blocage ici, contrairement aux trois records : un total collectif qui
    // changerait selon qui le regarde ne serait plus un fait du club.
    sql`
      SELECT date_trunc('week', a.created_at) AS debut, SUM(a.distance_km)::float AS km,
             COUNT(DISTINCT a.user_id)::int AS coureurs
        FROM activities a
        JOIN club_members cm ON cm.user_id = a.user_id AND cm.club_id = ${clubId}
       WHERE a.type = 'run' AND a.distance_km IS NOT NULL
         AND date_trunc('week', a.created_at) < date_trunc('week', now())
       GROUP BY 1
       ORDER BY km DESC
       LIMIT 1
    `,
    // LES SÉANCES TENUES. « On était 28 mardi dernier » est la phrase dont un crew est fier, et
    // la seule preuve qu'un club VIT — un classement dit qui court, pas si on se retrouve.
    //
    // Les cinq dernières, et les deux chiffres qui les résument : combien de séances, et combien
    // de personnes en moyenne. La moyenne compte plus que le total : vingt séances à trois
    // personnes et vingt séances à trente ne sont pas le même club.
    sql`
      SELECT title, held_at, attendees,
             (SELECT COUNT(*)::int FROM club_session_history WHERE club_id = ${clubId}) AS total,
             (SELECT ROUND(AVG(attendees))::int FROM club_session_history WHERE club_id = ${clubId}) AS moyenne
        FROM club_session_history
       WHERE club_id = ${clubId}
       ORDER BY held_at DESC
       LIMIT 5
    `,
  ]);

  res.status(200).json({
    races: courses.rows.map((r) => ({
      // La course est IMBRIQUÉE, sous la même forme que partout ailleurs : l'app la décode avec
      // son `RaceEvent`, qui sait déjà écrire « 4 avril 2027 » et compter les jours restants —
      // deux calculs qui ont coûté deux bugs de fuseau et qu'on ne réécrit pas ici.
      race: {
        id: r.id,
        name: r.name,
        city: r.city || null,
        raceDate: r.race_date,
        distanceKm: r.distance_km === null ? null : Number(r.distance_km),
        discipline: r.discipline,
      },
      members: r.members,
      // Six visages au plus : au-delà, la pile déborde de la ligne et le compte dit le reste.
      runners: (r.runners || []).slice(0, 6).map((u) => ({
        id: u.id, name: u.name, lastName: u.lastName || null,
        avatarUrl: u.avatarUrl || null, avatarBase64: u.avatarBase64 || null,
      })),
    })),
    records: records.rows.map((r) => ({
      genre: r.genre,
      activityId: r.id,
      userId: r.user_id,
      name: r.name,
      lastName: r.last_name || null,
      avatarUrl: r.avatar_url || null,
      avatarBase64: r.avatar_data || null,
      createdAt: r.created_at,
      distanceKm: r.distance_km === null ? null : Number(r.distance_km),
      durationSeconds: r.duration_seconds,
      elevationGainM: r.elevation_gain_m,
      secPerKm: r.sec_par_km === null ? null : Number(r.sec_par_km),
    })),
    sessionHistory: {
      total: seances.rows[0]?.total ?? 0,
      averageAttendees: seances.rows[0]?.moyenne ?? 0,
      recent: seances.rows.map((r) => ({
        title: r.title,
        heldAt: r.held_at,
        attendees: r.attendees,
      })),
    },
    bestWeek: semaine.rows[0] ? {
      startsAt: semaine.rows[0].debut,
      km: Number(semaine.rows[0].km),
      runners: semaine.rows[0].coureurs,
    } : null,
  });
}

// LA DESCRIPTION ET LA VILLE DU CLUB, écrites par qui l'a créé.
//
// Modérées comme tout ce que quelqu'un écrit et que d'autres liront : c'est la règle 1.2 de
// l'App Store, et ces deux champs s'affichent en tête d'une page vue par tous les membres ET
// dans les résultats de recherche de gens qui ne sont pas encore entrés.
//
// Le serveur revérifie la propriété. Le client cache déjà le formulaire à qui n'est pas le
// créateur ; cacher un bouton n'a jamais empêché personne d'appeler l'adresse qu'il ouvrait.
async function handleSetClubProfile(req, res, userId) {
  const clubId = await clubQueJAdministre(userId);
  if (!clubId) return res.status(403).json({ error: 'not_owner' });

  const description = sanitizeOwnText(req.body?.description, MAX_CLUB_DESCRIPTION);
  const city = sanitizeOwnText(req.body?.city, MAX_CLUB_CITY);
  if (description === REJECTED || city === REJECTED) {
    return res.status(422).json({ error: 'objectionable_content' });
  }

  await sql`UPDATE clubs SET description = ${description}, city = ${city} WHERE id = ${clubId}`;
  res.status(200).json({ ok: true, description, city });
}


// LA PHOTO DE COUVERTURE DU CLUB.
//
// Mot pour mot la mécanique de la photo de profil et de celle d'une sortie, et c'est délibéré :
// mêmes octets magiques vérifiés, même plafond quotidien, même chemin stable dans le stockage,
// même ménage de l'ancienne image. Une seconde façon de déposer une image serait une seconde
// façon de se tromper.
//
// Plus généreuse que l'avatar (500 ko contre 200), comme la photo d'une sortie : une bannière
// large porte nettement plus d'information qu'une pastille de 88 points, et c'est tout l'intérêt.
//
// Réservée à qui a créé le club, et le serveur le revérifie : cette image s'affiche en tête
// d'une page vue par tous les membres.
const MAX_COVER_LENGTH = 500000;

async function handleCover(req, res, userId) {
  const administre = await clubQueJAdministre(userId);
  if (!administre) return res.status(403).json({ error: 'not_owner' });
  const { rows: clubRows } = await sql`SELECT id, cover_url FROM clubs WHERE id = ${administre}`;
  const club = clubRows[0];
  if (!club) return res.status(403).json({ error: 'not_owner' });

  if (!(await underDailyCap('clubCover:' + userId, 20))) {
    return res.status(429).json({ error: 'too_many_uploads' });
  }

  const brut = req.body?.coverDataURI;
  // `null` efface. Distinguer « rien envoyé » de « envoyé mais illisible » compte : le premier
  // est une demande de retrait, le second une erreur qu'il faut dire.
  if (brut === null || brut === undefined) {
    await sql`UPDATE clubs SET cover_url = NULL WHERE id = ${club.id}`;
    if (club.cover_url) del(club.cover_url).catch(() => {});
    return res.status(200).json({ ok: true, coverUrl: null });
  }

  const image = tamponDepuisDataURI(brut, MAX_COVER_LENGTH);
  if (!image) return res.status(400).json({ error: 'not_an_image' });

  const blob = await put(`clubs/${club.id}.jpg`, image, {
    access: 'public',
    contentType: 'image/jpeg',
    // Un chemin stable par club : un remplacement écrase le même objet au lieu d'accumuler une
    // image par changement.
    addRandomSuffix: false,
    // L'adresse ne change pas d'un envoi à l'autre : sans ce cache court, l'ancienne image
    // continuerait de s'afficher jusqu'à l'expiration du cache de chaque appareil.
    cacheControlMaxAge: 3600,
  });

  await sql`UPDATE clubs SET cover_url = ${blob.url} WHERE id = ${club.id}`;
  if (club.cover_url && club.cover_url !== blob.url) del(club.cover_url).catch(() => {});
  res.status(200).json({ ok: true, coverUrl: blob.url });
}

// LE MUR DU CLUB : ce qu'on se dit entre deux sorties.
//
// Un club pouvait publier des courses, applaudir et commenter. Il ne pouvait pas PARLER. « Qui a
// un dossard en trop pour dimanche ? », « la berge est fermée jusqu'au 12 », « bienvenue à
// Sarah » : rien de tout cela n'est une sortie, rien n'est un commentaire sous la sortie de
// quelqu'un, et il n'existait aucun endroit pour l'écrire.
//
// Deux niveaux, comme le mur d'une course : un message, ses réponses. Une réponse de réponse
// n'existe pas — au-delà de deux niveaux, personne ne sait plus à qui l'on parle.
const LONGUEUR_MESSAGE_CLUB = 500;

// QUI PEUT ADMINISTRER CE CLUB.
//
// La personne qui l'a créé, et celles qu'elle a nommées organisatrices. Écrit une seule fois :
// quatre points d'entrée posaient chacun leur propre `created_by = userId`, et c'est ainsi
// qu'une règle finit par être vraie à trois endroits sur quatre.
//
// Rend l'identifiant du club quand c'est le cas, `null` sinon — les appelants en ont besoin
// juste après, et une deuxième requête pour le relire serait un aller-retour de plus.
async function clubQueJAdministre(userId) {
  const { rows } = await sql`
    SELECT c.id FROM clubs c
      JOIN club_members m ON m.club_id = c.id AND m.user_id = ${userId}
     WHERE c.created_by = ${userId} OR m.role = 'organiser'
  `;
  return rows[0]?.id || null;
}

// Le club de qui appelle, ou rien. Toutes les actions du mur passent par là : on n'écrit pas sur
// le mur d'un club dont on n'est pas membre, et on ne le lit pas non plus.
async function monClub(userId) {
  const { rows } = await sql`SELECT club_id FROM club_members WHERE user_id = ${userId}`;
  return rows[0]?.club_id || null;
}

async function handlePosts(req, res, userId) {
  const clubId = await monClub(userId);
  if (!clubId) return res.status(200).json({ posts: [] });

  const { rows } = await sql`
    SELECT p.id, p.parent_id, p.text, p.created_at, p.user_id,
           u.name, u.last_name, u.username, u.avatar_data, u.avatar_url,
           (SELECT COUNT(*)::int FROM club_post_kudos k WHERE k.post_id = p.id) AS kudos,
           EXISTS(SELECT 1 FROM club_post_kudos k WHERE k.post_id = p.id AND k.user_id = ${userId}) AS kudoed_by_me
      FROM club_posts p
      JOIN users u ON u.id = p.user_id
     WHERE p.club_id = ${clubId}
       AND p.user_id NOT IN (SELECT blocked_id FROM blocks WHERE blocker_id = ${userId})
       AND p.user_id NOT IN (SELECT blocker_id FROM blocks WHERE blocked_id = ${userId})
     ORDER BY p.created_at DESC
     LIMIT 100
  `;

  res.status(200).json({
    posts: rows.map((r) => ({
      id: r.id,
      parentId: r.parent_id || null,
      text: r.text,
      createdAt: r.created_at,
      kudos: r.kudos,
      kudoedByMe: r.kudoed_by_me === true,
      isMine: r.user_id === userId,
      author: {
        id: r.user_id,
        name: r.name,
        lastName: r.last_name || null,
        username: r.username || null,
        avatarBase64: r.avatar_data || null,
        avatarUrl: r.avatar_url || null,
        isPrivate: false,
      },
    })),
  });
}

async function handleCreatePost(req, res, userId) {
  if (!(await underDailyCap('clubPost:' + userId, 60))) {
    return res.status(429).json({ error: 'too_many_requests' });
  }
  const clubId = await monClub(userId);
  if (!clubId) return res.status(404).json({ error: 'not_found' });

  const propre = typeof req.body?.text === 'string' ? req.body.text.trim().slice(0, LONGUEUR_MESSAGE_CLUB) : '';
  if (!propre) return res.status(400).json({ error: 'bad_request' });
  // Même filtre que les noms de clubs, les commentaires et les messages d'une course : ce texte
  // atterrit chez tous les membres.
  if (containsObjectionableContent(propre)) return res.status(422).json({ error: 'objectionable_content' });

  const parentId = req.body?.parentId;
  let parent = null;
  if (parentId !== undefined && parentId !== null) {
    if (!isUuid(parentId)) return res.status(400).json({ error: 'bad_request' });
    const { rows } = await sql`
      SELECT id FROM club_posts WHERE id = ${parentId} AND club_id = ${clubId} AND parent_id IS NULL
    `;
    if (rows.length === 0) return res.status(404).json({ error: 'not_found' });
    parent = parentId;
  }

  const { rows } = await sql`
    INSERT INTO club_posts (club_id, user_id, parent_id, text)
    VALUES (${clubId}, ${userId}, ${parent}, ${propre})
    RETURNING id, created_at
  `;
  res.status(201).json({ id: rows[0].id, createdAt: rows[0].created_at });
}

async function handlePostKudos(req, res, userId) {
  const { postId } = req.body || {};
  if (!isUuid(postId)) return res.status(400).json({ error: 'bad_request' });
  if (!(await underDailyCap('clubPostKudos:' + userId, 300))) {
    return res.status(429).json({ error: 'too_many_requests' });
  }
  const clubId = await monClub(userId);
  if (!clubId) return res.status(404).json({ error: 'not_found' });

  // Le message doit appartenir à MON club : détenir un identifiant ne donne pas le droit
  // d'applaudir sur le mur d'un club où l'on n'est pas.
  const { rows: post } = await sql`SELECT id FROM club_posts WHERE id = ${postId} AND club_id = ${clubId}`;
  if (post.length === 0) return res.status(404).json({ error: 'not_found' });

  const { rows: existe } = await sql`
    SELECT 1 FROM club_post_kudos WHERE post_id = ${postId} AND user_id = ${userId}
  `;
  if (existe.length > 0) {
    await sql`DELETE FROM club_post_kudos WHERE post_id = ${postId} AND user_id = ${userId}`;
    return res.status(200).json({ kudoed: false });
  }
  await sql`
    INSERT INTO club_post_kudos (post_id, user_id) VALUES (${postId}, ${userId})
    ON CONFLICT DO NOTHING
  `;
  res.status(200).json({ kudoed: true });
}

// Son propre message, et rien d'autre. Les réponses partent avec lui (ON DELETE CASCADE) : une
// réponse sous un message effacé serait un message sans contexte.
// MODIFIER UN MESSAGE DU MUR. Son auteur seulement — contrairement à une sortie de groupe, un
// message est une PAROLE : un organisateur peut la supprimer, jamais la réécrire au nom de
// quelqu'un d'autre.
//
// `RETURNING 1` et non `rowCount` : `lib/db.js` enveloppe le pilote Neon et ne rend que
// `{ rows }`. Voir la note de `handleDeletePost` juste en dessous — le même piège a déjà coûté
// un bug dans api/activities.
async function handleUpdatePost(req, res, userId) {
  const { postId, text } = req.body || {};
  if (!isUuid(postId)) return res.status(400).json({ error: 'bad_request' });
  const propre = typeof text === 'string' ? text.trim().slice(0, 500) : '';
  if (!propre) return res.status(400).json({ error: 'bad_request' });
  if (containsObjectionableContent(propre)) return res.status(422).json({ error: 'objectionable_content' });
  const { rows } = await sql`
    UPDATE club_posts SET text = ${propre}
     WHERE id = ${postId} AND user_id = ${userId}
    RETURNING 1
  `;
  if (rows.length === 0) return res.status(404).json({ error: 'not_found' });
  res.status(200).json({ ok: true });
}

async function handleDeletePost(req, res, userId) {
  const { postId } = req.body || {};
  if (!isUuid(postId)) return res.status(400).json({ error: 'bad_request' });
  // `RETURNING 1` ET NON `rowCount` : `lib/db.js` enveloppe le pilote Neon et ne rend QUE
  // `{ rows }`. `rowCount` y vaut `undefined`, donc ce point d'entrée aurait répondu 404 à
  // chaque suppression RÉUSSIE. Le même piège a déjà coûté un bug dans api/activities.
  const { rows } = await sql`
    DELETE FROM club_posts WHERE id = ${postId} AND user_id = ${userId} RETURNING 1
  `;
  if (rows.length === 0) return res.status(404).json({ error: 'not_found' });
  res.status(200).json({ ok: true });
}


// LA PAGE PUBLIQUE D'UN CLUB : ce qu'il montre de lui à quelqu'un qui n'est pas encore entré.
//
// SEULEMENT LES CLUBS OUVERTS. Un club fermé n'apparaît dans aucune recherche et ne se rejoint
// pas ; lui donner une page publique contredirait le seul réglage de confidentialité qu'un club
// possède. Il répond 404, comme un club qui n'existe pas — dire « il existe mais il est fermé »
// serait déjà une information sur lui.
//
// AUCUN NOM DE MEMBRE. Un compte de membres, des séances, et rien d'autre : la page est publique
// au sens le plus fort du terme — indexable, partageable, lisible par n'importe qui — et
// personne n'a consenti à y figurer en rejoignant un club.
async function handlePublicClub(req, res) {
  const id = typeof req.query.id === 'string' ? req.query.id : '';
  if (!isUuid(id)) return res.status(400).json({ error: 'bad_request' });

  const { rows } = await sql`
    SELECT c.id, c.name, c.city, c.description, c.cover_url,
           (SELECT COUNT(*)::int FROM club_members m WHERE m.club_id = c.id) AS member_count
      FROM clubs c
     WHERE c.id = ${id} AND c.is_open = true
  `;
  const club = rows[0];
  if (!club) return res.status(404).json({ error: 'not_found' });

  let seances = [];
  try {
    const { rows: evenements } = await sql`
      SELECT title, location, starts_at, repeats_weekly,
             (SELECT COUNT(*)::int FROM event_rsvps r WHERE r.event_id = e.id) AS going
        FROM club_events e
       WHERE e.club_id = ${club.id} AND e.starts_at >= now() - interval '3 hours'
       ORDER BY e.starts_at ASC
       LIMIT 5
    `;
    seances = evenements;
  } catch { /* table pas encore migrée : une page sans séances vaut mieux qu'une page en panne */ }

  // Une minute de cache au bord, cinq de plus en arrière-plan : cette page peut être partagée à
  // des centaines de personnes d'un coup depuis une story, et rien dedans ne change à la seconde.
  res.setHeader('Cache-Control', 'public, max-age=60, stale-while-revalidate=300');
  res.status(200).json({
    id: club.id,
    name: club.name,
    city: club.city || null,
    description: club.description || null,
    coverUrl: club.cover_url || null,
    memberCount: club.member_count,
    sessions: seances.map((e) => ({
      title: e.title,
      location: e.location || null,
      startsAt: e.starts_at,
      repeatsWeekly: e.repeats_weekly === true,
      going: e.going,
    })),
  });
}

// NOMMER UN ORGANISATEUR, OU LUI RETIRER LE RÔLE.
//
// RÉSERVÉ À LA PERSONNE QUI A CRÉÉ LE CLUB, et pas aux organisateurs eux-mêmes. Un organisateur
// qui pourrait en nommer d'autres pourrait aussi destituer la fondatrice, et un club se
// prendrait en otage en deux gestes. C'est le seul endroit du serveur où `created_by` reste la
// règle plutôt que `clubQueJAdministre`, et c'est volontaire.
async function handleSetRole(req, res, userId) {
  const { memberId, role } = req.body || {};
  if (!isUuid(memberId) || (role !== 'organiser' && role !== 'member')) {
    return res.status(400).json({ error: 'bad_request' });
  }

  const { rows: clubRows } = await sql`SELECT id FROM clubs WHERE created_by = ${userId}`;
  const clubId = clubRows[0]?.id;
  if (!clubId) return res.status(403).json({ error: 'not_owner' });

  // Se nommer soi-même n'a pas de sens : la créatrice administre déjà par construction, et se
  // « retirer » le rôle ne lui retirerait rien. Mieux vaut refuser que faire semblant.
  if (memberId === userId) return res.status(400).json({ error: 'bad_request' });

  const { rows } = await sql`
    UPDATE club_members SET role = ${role}
     WHERE club_id = ${clubId} AND user_id = ${memberId}
    RETURNING user_id
  `;
  if (rows.length === 0) return res.status(404).json({ error: 'not_found' });
  res.status(200).json({ ok: true, memberId, role });
}


// ─── L'ADHÉSION : LA FICHE, LES DEMANDES, LE MODE ────────────────────────────────────────────────
//
// Voir `lib/adhesionClub.js` pour les trois modes et la règle qui dit quelle colonne l'emporte.
// Tout ce qui suit est RÉSERVÉ à la personne qui a créé le club quand il s'agit de décider (voir
// `clubQueJePossede`), et ouvert à tout compte connecté quand il s'agit de demander.

// LE CLUB QUE JE POSSÈDE ET DONT JE SUIS MEMBRE, ou rien.
//
// Pas `clubQueJAdministre` : celui-là inclut les organisateurs, et décider qui entre dans un club
// est une décision de propriétaire. Pas non plus `SELECT … WHERE created_by = …` seul : quelqu'un
// qui a quitté son club puis en a rejoint un autre possède encore l'ancien, sans y être — le
// propriétaire qui décide est celui du club où il est.
async function clubQueJePossede(userId) {
  const { rows } = await sql`
    SELECT c.id, c.name, c.is_open, c.join_mode, c.invite_code
      FROM clubs c
      JOIN club_members m ON m.club_id = c.id AND m.user_id = ${userId}
     WHERE c.created_by = ${userId}
  `;
  return rows[0] || null;
}

// LA FICHE D'UN CLUB, telle qu'on la voit avant d'y entrer.
//
// Le nom, la ville, la présentation, la bannière, le nombre de membres : ce que le club montre
// déjà dans la recherche et dans sa page publique. Aucun nom de membre.
//
// LA PROCHAINE SÉANCE N'EST DITE QUE D'UN CLUB OUVERT, comme sa page publique. Pour un club sur
// demande ou sur code, les séances sont ce que les membres se disent entre eux : les montrer à
// quelqu'un qui n'est pas entré serait plus que ce que le propriétaire a choisi de montrer.
async function ficheDuClub(club, userId, mode) {
  const { rows: compte } = await sql`SELECT COUNT(*)::int AS n FROM club_members WHERE club_id = ${club.id}`;
  const dejaMembre = await monClub(userId);
  let demandeEnCours = false;
  try {
    const { rows } = await sql`
      SELECT 1 FROM club_join_requests WHERE club_id = ${club.id} AND user_id = ${userId}
    `;
    demandeEnCours = rows.length > 0;
  } catch { /* table pas encore migrée : pas de demande */ }

  let prochaineSeance = null;
  if (mode === 'open') {
    try {
      const { rows } = await sql`
        SELECT title, location, starts_at, repeats_weekly
          FROM club_events
         WHERE club_id = ${club.id} AND starts_at >= now() - interval '3 hours'
         ORDER BY starts_at ASC
         LIMIT 1
      `;
      if (rows[0]) {
        prochaineSeance = {
          title: rows[0].title,
          location: rows[0].location || null,
          startsAt: rows[0].starts_at,
          repeatsWeekly: rows[0].repeats_weekly === true,
        };
      }
    } catch { /* table pas encore migrée : une fiche sans séance vaut mieux qu'une fiche en panne */ }
  }

  return {
    id: club.id,
    name: club.name,
    city: club.city || null,
    description: club.description || null,
    coverUrl: club.cover_url || null,
    memberCount: compte[0].n,
    joinMode: mode,
    requestPending: demandeEnCours,
    alreadyInClub: Boolean(dejaMembre),
    nextSession: prochaineSeance,
  };
}

// LA FICHE PAR IDENTIFIANT : un club ouvert, ou sur demande. Un club sur code répond « n'existe
// pas », comme dans la recherche — on le trouve par son code (`handleByCode`), pas autrement.
async function handlePreview(req, res, userId) {
  const id = typeof req.query.id === 'string' ? req.query.id : '';
  if (!isUuid(id)) return res.status(400).json({ error: 'bad_request' });
  if (!(await underDailyCap('clubPreview:' + userId, 200))) return res.status(429).json({ error: 'too_many_requests' });

  const { rows } = await sql`
    SELECT id, name, city, description, cover_url, is_open, join_mode, created_by
      FROM clubs WHERE id = ${id}
  `;
  const club = rows[0];
  const mode = club ? modeDuClub(club) : null;
  if (!club || mode === 'code' || (mode === 'request' && !club.created_by)) {
    return res.status(404).json({ error: 'not_found' });
  }
  res.status(200).json(await ficheDuClub(club, userId, mode));
}

// LA FICHE PAR CODE : la seule façon de tomber sur un club sur code. Le plafond est celui d'un
// essai de code, pas d'une lecture : c'est la route qu'un script interrogerait pour deviner.
async function handleByCode(req, res, userId) {
  const code = normaliserLeCode(req.query.code);
  if (code.length !== LONGUEUR_DU_CODE) return res.status(400).json({ error: 'bad_request' });
  if (!(await underDailyCap('joinCode:' + userId, MAX_ESSAIS_DE_CODE_PAR_JOUR))) {
    return res.status(429).json({ error: 'too_many_requests' });
  }

  const { rows } = await sql`
    SELECT id, name, city, description, cover_url, is_open, join_mode, created_by, invite_code
      FROM clubs WHERE invite_code = ${code}
  `;
  const club = rows[0];
  // Le code d'un club qui n'est pas sur code ne désigne rien : il existe en base pour chaque
  // club depuis toujours, et ne doit pas faire retrouver un club ouvert ou sur demande.
  if (!club || modeDuClub(club) !== 'code') return res.status(404).json({ error: 'not_found' });
  res.status(200).json(await ficheDuClub(club, userId, 'code'));
}

// DEMANDER À REJOINDRE UN CLUB SUR DEMANDE. Le propriétaire reçoit une notification.
//
// Les gardes, dans l'ordre où elles coûtent : déjà dans un club (409, comme `join`), plafond
// quotidien, puis le club. Un club qui n'est pas sur demande ne se demande pas : ouvert, c'est
// `join` (409 `use_join`, pour que l'app se rafraîchisse) ; sur code, il « n'existe pas ».
async function handleRequestJoin(req, res, userId) {
  const { rows: already } = await sql`SELECT club_id FROM club_members WHERE user_id = ${userId}`;
  if (already.length > 0) return res.status(409).json({ error: 'already_in_club' });

  if (!(await underDailyCap('joinRequest:' + userId, 10))) return res.status(429).json({ error: 'too_many_requests' });

  const { clubId } = req.body || {};
  if (!isUuid(clubId)) return res.status(400).json({ error: 'bad_request' });

  const { rows } = await sql`SELECT id, name, is_open, join_mode, created_by FROM clubs WHERE id = ${clubId}`;
  const club = rows[0];
  if (!club) return res.status(404).json({ error: 'not_found' });
  const mode = modeDuClub(club);
  if (mode === 'open') return res.status(409).json({ error: 'use_join' });
  // Sans propriétaire (son compte a été supprimé), personne ne répondrait jamais.
  if (mode !== 'request' || !club.created_by) return res.status(404).json({ error: 'not_found' });

  // Un blocage dans un sens ou dans l'autre : la même réponse que « n'existe pas », comme partout
  // ailleurs où un blocage cache quelqu'un. C'est aussi le recours d'un propriétaire contre
  // quelqu'un qui insiste.
  const { rows: bloque } = await sql`
    SELECT 1 FROM blocks
     WHERE (blocker_id = ${club.created_by} AND blocked_id = ${userId})
        OR (blocker_id = ${userId} AND blocked_id = ${club.created_by})
     LIMIT 1
  `;
  if (bloque.length > 0) return res.status(404).json({ error: 'not_found' });

  const { rows: enAttente } = await sql`
    SELECT COUNT(*)::int AS n FROM club_join_requests WHERE user_id = ${userId}
  `;
  if (enAttente[0].n >= MAX_DEMANDES_EN_ATTENTE) {
    return res.status(409).json({ error: 'too_many_pending_requests' });
  }

  const { rows: inseree } = await sql`
    INSERT INTO club_join_requests (club_id, user_id) VALUES (${club.id}, ${userId})
    ON CONFLICT (club_id, user_id) DO NOTHING
    RETURNING id
  `;
  // Déjà demandée : le même résultat, sans second message au propriétaire.
  if (inseree.length === 0) return res.status(200).json({ requestPending: true });

  // Push avant la réponse — Vercel peut figer la fonction une fois la réponse envoyée.
  const { rows: moi } = await sql`SELECT name FROM users WHERE id = ${userId}`;
  await sendPushToUsers(sql, [club.created_by], {
    title: 'Demande pour rejoindre le club',
    body: `${moi[0]?.name || 'Quelqu\'un'} demande à rejoindre ${club.name}`,
  });
  res.status(201).json({ requestPending: true });
}

// RETIRER SA DEMANDE. Idempotent : retirer une demande qui n'existe plus (déjà acceptée, déjà
// retirée depuis un autre appareil) est un succès, pas une erreur — le résultat voulu est atteint.
async function handleCancelRequest(req, res, userId) {
  const { clubId } = req.body || {};
  if (!isUuid(clubId)) return res.status(400).json({ error: 'bad_request' });
  await sql`DELETE FROM club_join_requests WHERE club_id = ${clubId} AND user_id = ${userId}`;
  res.status(200).json({ ok: true, requestPending: false });
}

// LES DEMANDES EN ATTENTE DE MON CLUB, la plus ancienne d'abord. Le propriétaire seulement.
//
// Les gens qu'on a bloqués, ou qui nous ont bloqué, n'y figurent pas : même règle que les
// classements et le mur.
async function handleRequests(req, res, userId) {
  const club = await clubQueJePossede(userId);
  if (!club) return res.status(403).json({ error: 'forbidden' });

  const { rows } = await sql`
    SELECT r.id, r.created_at, u.id AS user_id, u.name, u.last_name, u.avatar_data, u.avatar_url
      FROM club_join_requests r
      JOIN users u ON u.id = r.user_id
     WHERE r.club_id = ${club.id}
       AND u.id NOT IN (SELECT blocked_id FROM blocks WHERE blocker_id = ${userId})
       AND u.id NOT IN (SELECT blocker_id FROM blocks WHERE blocked_id = ${userId})
     ORDER BY r.created_at ASC
     LIMIT 50
  `;
  res.status(200).json({
    items: rows.map((r) => ({
      id: r.id,
      userId: r.user_id,
      name: r.name,
      lastName: r.last_name || null,
      avatarUrl: r.avatar_url || null,
      avatarBase64: r.avatar_data || null,
      createdAt: r.created_at,
    })),
  });
}

// ACCEPTER OU REFUSER UNE DEMANDE. Le propriétaire seulement.
//
// Accepter fait entrer la personne ET RETIRE TOUTES SES DEMANDES : elle n'est plus qu'à un club,
// et les autres propriétaires n'ont plus rien à traiter. Elle est notifiée. Refuser retire la
// demande sans rien dire à personne — une notification de refus n'est demandée à personne, et
// faire savoir à quelqu'un qu'on l'a écarté n'est pas la même chose que ne pas l'avoir accepté.
async function handleRespondRequest(req, res, userId) {
  const { userId: demandeurId, accept } = req.body || {};
  if (!isUuid(demandeurId) || typeof accept !== 'boolean') return res.status(400).json({ error: 'bad_request' });

  const club = await clubQueJePossede(userId);
  if (!club) return res.status(403).json({ error: 'forbidden' });

  const { rows: demande } = await sql`
    SELECT id FROM club_join_requests WHERE club_id = ${club.id} AND user_id = ${demandeurId}
  `;
  // Déjà retirée par son auteur, ou déjà traitée depuis un autre appareil.
  if (demande.length === 0) return res.status(404).json({ error: 'not_found' });

  if (!accept) {
    await sql`DELETE FROM club_join_requests WHERE club_id = ${club.id} AND user_id = ${demandeurId}`;
    return res.status(200).json({ ok: true, accepted: false });
  }

  // Elle a pu entrer dans un autre club depuis sa demande. Sa demande ici n'a plus d'objet.
  if (await monClub(demandeurId)) {
    await retirerSesDemandes(demandeurId);
    return res.status(409).json({ error: 'already_in_club' });
  }
  try {
    await sql`INSERT INTO club_members (club_id, user_id) VALUES (${club.id}, ${demandeurId})`;
  } catch (e) {
    if (String(e.message).includes('uniq_club_members_user')) {
      await retirerSesDemandes(demandeurId);
      return res.status(409).json({ error: 'already_in_club' });
    }
    throw e;
  }
  await retirerSesDemandes(demandeurId);

  // Push avant la réponse, pour la même raison que partout ailleurs dans ce fichier.
  await sendPushToUsers(sql, [demandeurId], {
    title: 'Demande acceptée',
    body: `Tu fais maintenant partie de ${club.name}`,
  });
  res.status(200).json({ ok: true, accepted: true });
}

// CHANGER LE MODE D'ADHÉSION DE SON CLUB. Le propriétaire seulement — pas les organisateurs :
// décider qui peut entrer est ce qui définit le club, et un organisateur qui pourrait le faire
// pourrait aussi le rendre ouvert à tous malgré sa fondatrice.
//
// Les membres actuels ne sont jamais touchés : changer de mode ne vide rien. Quitter le mode
// « sur demande » retire les demandes en attente : leurs auteurs peuvent maintenant entrer d'un
// appui, ou doivent avoir le code, et une demande qui ne mène plus nulle part ne doit pas rester
// affichée « envoyée ».
async function handleSetJoinMode(req, res, userId) {
  const mode = modeValide(req.body?.joinMode);
  if (!mode) return res.status(400).json({ error: 'bad_request' });

  const club = await clubQueJePossede(userId);
  if (!club) return res.status(403).json({ error: 'forbidden' });

  const colonnes = colonnesDuMode(mode);
  await sql`
    UPDATE clubs SET is_open = ${colonnes.isOpen}, join_mode = ${colonnes.joinMode}
     WHERE id = ${club.id}
  `;
  if (mode !== 'request') await retirerLesDemandesDuClub(club.id);

  res.status(200).json({
    joinMode: mode,
    isOpen: colonnes.isOpen,
    inviteCode: codeVisible(mode, true, club.invite_code),
  });
}
