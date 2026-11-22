-- À COLLER DANS LA CONSOLE NEON (SQL Editor), EN DEUX TEMPS.
--
-- Supprime les clubs qui n'ont AUCUN membre : des clubs de test (« Debug Test Club ») et des clubs
-- abandonnés (« Ebury », « Malakoff », créés puis quittés par tout le monde). Ils s'affichaient avec
-- « 0 membre » et un bouton « Rejoindre » dans l'écran « Rejoins un club ».
--
-- ============================================================
-- TEMPS 1 : REGARDE d'abord ce qui va partir. Ne supprime rien.
-- ============================================================
-- Si un club de cette liste est un vrai club, ne passe PAS au temps 2 et dis-le.

SELECT c.id, c.name, c.city, c.created_at,
       (SELECT COUNT(*) FROM club_posts p WHERE p.club_id = c.id)  AS messages,
       (SELECT COUNT(*) FROM club_events e WHERE e.club_id = c.id) AS sorties_prevues
FROM clubs c
WHERE NOT EXISTS (SELECT 1 FROM club_members m WHERE m.club_id = c.id)
ORDER BY c.created_at;

-- ============================================================
-- TEMPS 2 : SUPPRIME-les, une fois la liste du temps 1 relue.
-- ============================================================
-- Les messages, sorties, demandes et autres lignes rattachées à ces clubs partent avec eux
-- (ON DELETE CASCADE) : pour un club sans membre, il n'y a personne à qui ils serviraient.
-- Rien ne touche un club qui a au moins un membre.
--
-- Décommente les trois lignes ci-dessous pour l'exécuter.

-- DELETE FROM clubs c
-- WHERE NOT EXISTS (SELECT 1 FROM club_members m WHERE m.club_id = c.id)
-- RETURNING c.id, c.name;
