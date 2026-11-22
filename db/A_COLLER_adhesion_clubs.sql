-- À COLLER DANS LA CONSOLE NEON (SQL Editor), EN UNE FOIS, AVANT DE FUSIONNER LE CODE.
--
-- L'adhésion à un club : trois modes (ouvert, sur demande, sur code) au choix de son propriétaire,
-- et la table des demandes en attente. Tout est idempotent — `IF NOT EXISTS`, et un UPDATE qui ne
-- réécrit que ce qui ne l'est pas déjà — donc le relancer ne crée rien en double et ne change aucun
-- club qui a déjà choisi.
--
-- ORDRE : à coller AVANT le déploiement du serveur. Le code neuf lit `clubs.join_mode` dans ses
-- requêtes de base (rejoindre, tableau de bord du club) : Postgres refuserait la requête entière
-- tant que la colonne n'existe pas. (Le script de construction `ci_scripts/appliquer_schema.js`
-- applique aussi `db/schema.sql` avant chaque déploiement ; coller ce fichier à la main reste utile
-- pour que la base soit prête dès maintenant.)
--
-- Les clubs existants ne changent PAS de comportement : ouvert reste ouvert, fermé devient « sur
-- code » (ce qu'un club fermé était déjà : introuvable, et rejoint seulement par qui a le code).
-- Aucune donnée personnelle n'est ajoutée : une demande est un couple (club, personne) et une date.

-- COMMENT ON ENTRE DANS UN CLUB : TROIS MODES, AU CHOIX DE SON PROPRIÉTAIRE.
--
-- Un club n'avait qu'un réglage, `is_open` : ouvert (trouvable, rejoint d'un appui) ou fermé (ni
-- trouvable, ni joignable). L'adhésion n'est pas automatique pour tous les clubs, et ce n'est pas
-- à l'app de le décider : 'open' (on rejoint d'un appui), 'request' (on demande depuis la fiche, le
-- propriétaire accepte ou refuse) ou 'code' (on rejoint avec le code d'invitation).
--
-- LES CLUBS EXISTANTS GARDENT EXACTEMENT LEUR COMPORTEMENT : ouvert reste 'open' (c'est le défaut,
-- donc aucune ligne n'est réécrite), fermé devient 'code'. `invite_code` existe déjà sur chaque
-- club (`NOT NULL UNIQUE`, écrit à la création depuis toujours) : un club sur code l'emploie tel
-- quel, sans migration de données.
--
-- `is_open` RESTE, ET RESTE ÉCRIT (vrai pour 'open' seulement) : une app installée ne connaît pas
-- `join_mode`, elle lit `isOpen` et écrit `setOpen`. `lib/adhesionClub.js` (`modeDuClub`) dit quelle
-- colonne l'emporte quand elles se contredisent un instant : `is_open = true` veut toujours dire
-- 'open'.
--
-- L'UPDATE ne touche que les clubs fermés encore marqués 'open' : un club déjà passé sur demande
-- n'est pas réécrit quand ce fichier est rejoué, et un club fermé par une app ancienne après la
-- migration devient 'code' au prochain rejeu, comme le dit `modeDuClub` dès la lecture.
ALTER TABLE clubs ADD COLUMN IF NOT EXISTS join_mode TEXT NOT NULL DEFAULT 'open';
UPDATE clubs SET join_mode = 'code' WHERE is_open = false AND join_mode = 'open';

-- LES DEMANDES POUR REJOINDRE UN CLUB SUR DEMANDE.
--
-- Une ligne par demande EN ATTENTE, et rien d'autre : annulée, refusée ou acceptée, la ligne
-- disparaît. Garder les refus aurait fait du fichier un registre de personnes écartées, que
-- personne n'a demandé et que personne n'aurait à lire ; le recours contre quelqu'un qui insiste
-- est le blocage (`blocks`), que la demande respecte, et les plafonds quotidiens.
--
-- Pas de message libre : rien d'écrit par la personne, donc rien à modérer ni à afficher.
--
-- Une demande par couple (club, personne) ; plusieurs clubs à la fois sont permis, bornés à cinq
-- par `MAX_DEMANDES_EN_ATTENTE`. `ON DELETE CASCADE` des deux côtés : un club supprimé ou un compte
-- supprimé emporte ses demandes, sans ligne orpheline.
CREATE TABLE IF NOT EXISTS club_join_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (club_id, user_id)
);

-- Les deux questions qu'on pose à cette table : « qui demande à entrer dans mon club » (par club,
-- la plus ancienne d'abord) et « quelles demandes ai-je en attente » (par personne).
CREATE INDEX IF NOT EXISTS idx_club_join_requests_club ON club_join_requests (club_id, created_at);
CREATE INDEX IF NOT EXISTS idx_club_join_requests_user ON club_join_requests (user_id);
