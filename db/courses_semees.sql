-- GÉNÉRÉ PAR db/semer_courses.js — NE PAS MODIFIER À LA MAIN.
-- Relancer `node db/semer_courses.js` après avoir mis la liste à jour dans ce script.
--
-- Les 53 courses que l'app connaît d'avance, avec leurs caractéristiques relevées à la
-- source de l'organisateur le 2026-11-22 (adresse et jour de chaque relevé : dans le script). Tout le
-- reste se crée depuis l'app, par les coureurs eux-mêmes : une page de course n'a pas besoin d'un
-- catalogue mondial pour servir, elle a besoin que la course que TOI tu prépares existe.
--
-- `created_by` reste NULL : personne n'a créé ces pages, elles étaient là. `is_seeded` les fait
-- passer avant les saisies approximatives du même événement dans la recherche.
--
-- IDEMPOTENT. Une course qui existe déjà (même nom replié, même jour) n'est jamais dupliquée :
--   - si elle est SEMÉE, ses colonnes de caractéristiques sont réécrites (le statut d'inscription
--     d'aujourd'hui remplace celui de la dernière fois) ;
--   - si c'est la saisie d'un coureur, on ne complète que ce qui lui manque, jamais son statut
--     d'inscription ni sa date de vérification. Rien de ce qu'il a tapé n'est écrasé.
INSERT INTO races (name, name_key, city, race_date, distance_km, elevation_gain_m, discipline, website,
                   country, distances_km, surface, profile, start_time, registration_status,
                   registration_url, registration_opens, verified_on, created_by, is_seeded)
SELECT v.name, v.name_key, v.city, v.race_date::date, v.distance_km::numeric, v.elevation_gain_m::int,
       v.discipline, v.website, v.country, v.distances_km::numeric[], v.surface, v.profile, v.start_time,
       v.registration_status, v.registration_url, v.registration_opens::date, v.verified_on::date, NULL, true
FROM (VALUES
  ('Marathon des Alpes-Maritimes Nice-Cannes', 'marathon des alpes maritimes nice cannes', 'Nice', '2026-11-08', 42.195, NULL, 'run', 'https://www.marathon06.com', 'FR', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
  ('SaintéLyon', 'saintelyon', 'Saint-Étienne', '2026-11-28', 78, 2000, 'trail', 'https://www.saintelyon.com', 'FR', NULL, 'trail', NULL, NULL, NULL, NULL, NULL, '2026-11-22'),
  ('Semi-Marathon de Paris', 'semi marathon de paris', 'Paris', '2027-03-07', 21.0975, NULL, 'run', NULL, 'FR', '{21.0975}', 'route', NULL, NULL, 'fermee', NULL, NULL, '2026-11-22'),
  ('EcoTrail Paris', 'ecotrail paris', 'Paris', '2027-03-20', NULL, NULL, 'trail', 'https://en.ecotrailparis.com', 'FR', '{10,20,30,35,45,80,120}', 'trail', NULL, NULL, 'ouverte', NULL, NULL, '2026-11-22'),
  ('Marathon de Paris', 'marathon de paris', 'Paris', '2027-04-04', 42.195, NULL, 'run', NULL, 'FR', '{42.195}', 'route', NULL, NULL, 'fermee', NULL, NULL, '2026-11-22'),
  ('Marathon du Mont-Blanc', 'marathon du mont blanc', 'Chamonix', '2027-06-27', NULL, NULL, 'trail', 'https://www.marathonmontblanc.fr', 'FR', NULL, 'trail', 'montagneux', NULL, 'tirage_au_sort', NULL, NULL, '2026-11-22'),
  ('MaXi-Race Annecy', 'maxi race annecy', 'Annecy', '2027-05-29', NULL, NULL, 'trail', 'https://www.maxi-race.org/en/', 'FR', NULL, 'trail', 'montagneux', NULL, 'fermee', NULL, NULL, '2026-11-22'),
  ('TCS London Marathon', 'tcs london marathon', 'London', '2027-04-25', 42.195, NULL, 'run', 'https://www.tcslondonmarathon.com', 'GB', '{42.195}', 'route', NULL, NULL, 'fermee', NULL, NULL, '2026-11-22'),
  ('Edinburgh Marathon', 'edinburgh marathon', 'Edinburgh', '2027-05-30', 42.195, NULL, 'run', 'https://www.edinburghmarathon.com', 'GB', '{42.195}', 'route', NULL, NULL, 'ouverte', NULL, NULL, '2026-11-22'),
  ('Great North Run', 'great north run', 'Newcastle', '2027-09-12', 21.0975, NULL, 'run', 'https://www.greatrun.org', 'GB', '{21.0975}', 'route', NULL, NULL, 'fermee', NULL, NULL, '2026-11-22'),
  ('Generali Berlin Marathon', 'generali berlin marathon', 'Berlin', '2027-09-26', 42.195, NULL, 'run', NULL, 'DE', '{42.195}', 'route', NULL, NULL, 'tirage_au_sort', NULL, NULL, '2026-11-22'),
  ('Berlin Half Marathon', 'berlin half marathon', 'Berlin', '2027-04-04', 21.0975, NULL, 'run', 'https://www.generali-berliner-halbmarathon.de', 'DE', '{21.0975}', 'route', NULL, NULL, 'fermee', NULL, NULL, '2026-11-22'),
  ('DATEV Challenge Roth', 'datev challenge roth', 'Roth', '2027-07-04', NULL, NULL, 'triathlon', 'https://www.challenge-roth.com', 'DE', NULL, NULL, NULL, NULL, 'complete', NULL, NULL, '2026-11-22'),
  ('Rotterdam Marathon', 'rotterdam marathon', 'Rotterdam', '2027-04-11', NULL, NULL, 'run', 'https://www.nnmarathonrotterdam.nl/en/', 'NL', '{10.55,42.195}', 'route', 'plat', NULL, 'complete', NULL, NULL, '2026-11-22'),
  ('Amsterdam Marathon', 'amsterdam marathon', 'Amsterdam', '2027-10-31', NULL, NULL, 'run', 'https://www.tcsamsterdammarathon.eu', 'NL', '{7.5,21.0975,42.195}', 'route', 'plat', NULL, 'bientot', NULL, NULL, '2026-11-22'),
  ('Vienna City Marathon', 'vienna city marathon', 'Vienna', '2027-04-18', NULL, NULL, 'run', 'https://www.vienna-marathon.com', 'AT', '{21.0975,42.195}', 'route', NULL, NULL, 'ouverte', NULL, NULL, '2026-11-22'),
  ('Prague Marathon', 'prague marathon', 'Prague', '2027-05-02', 42.195, NULL, 'run', 'https://www.runczech.com', 'CZ', '{42.195}', 'route', NULL, NULL, NULL, NULL, NULL, '2026-11-22'),
  ('Copenhagen Marathon', 'copenhagen marathon', 'Copenhagen', '2027-05-09', 42.195, NULL, 'run', 'https://copenhagenmarathon.dk', 'DK', '{42.195}', 'route', NULL, NULL, 'tirage_au_sort', NULL, NULL, '2026-11-22'),
  ('Rome Marathon', 'rome marathon', 'Rome', '2027-03-14', 42.195, NULL, 'run', 'https://www.runromethemarathon.com', 'IT', '{42.195}', 'route', NULL, '08:30', 'ouverte', NULL, NULL, '2026-11-22'),
  ('Florence Marathon', 'florence marathon', 'Florence', '2026-11-29', 42.195, NULL, 'run', 'https://www.firenzemarathon.it/en/', 'IT', '{42.195}', 'route', NULL, '08:30', 'complete', NULL, NULL, '2026-11-22'),
  ('Barcelona Marathon', 'barcelona marathon', 'Barcelona', '2027-03-14', 42.195, NULL, 'run', 'https://www.zurichmaratobarcelona.es/en', 'ES', '{42.195}', 'route', 'plat', NULL, 'complete', NULL, NULL, '2026-11-22'),
  ('Valencia Marathon', 'valencia marathon', 'Valencia', '2026-12-06', 42.195, NULL, 'run', 'https://www.valenciaciudaddelrunning.com/en/marathon/', 'ES', '{42.195}', 'route', 'plat', NULL, NULL, NULL, NULL, '2026-11-22'),
  ('Seville Marathon', 'seville marathon', 'Seville', '2027-02-21', 42.195, NULL, 'run', NULL, 'ES', '{42.195}', 'route', NULL, NULL, NULL, NULL, NULL, '2026-11-22'),
  ('Madrid Marathon', 'madrid marathon', 'Madrid', '2027-04-25', NULL, NULL, 'run', 'https://rocknrollmadridrun.com', 'ES', '{21.0975,42.195}', 'route', NULL, NULL, NULL, NULL, NULL, '2026-11-22'),
  ('Lavaredo Ultra Trail', 'lavaredo ultra trail', 'Cortina d''Ampezzo', '2027-06-25', NULL, NULL, 'trail', 'https://lavaredo.utmb.world', 'IT', '{10,20,50,80,120}', 'trail', 'montagneux', NULL, 'tirage_au_sort', 'https://lavaredo.utmb.world/registration', NULL, '2026-11-22'),
  ('Zegama-Aizkorri', 'zegama aizkorri', 'Zegama', '2027-06-06', 42, NULL, 'trail', 'https://www.zegama-aizkorri.com/en/', 'ES', '{42}', 'trail', 'montagneux', NULL, 'bientot', NULL, '2027-01-11', '2026-11-22'),
  ('Sierre-Zinal', 'sierre zinal', 'Sierre', '2027-08-07', 31, 2200, 'trail', 'https://www.sierre-zinal.com', 'CH', '{31}', 'trail', 'montagneux', NULL, NULL, NULL, NULL, '2026-11-22'),
  ('Grand Raid de La Réunion', 'grand raid de la reunion', 'Saint-Pierre', '2027-10-14', NULL, NULL, 'trail', 'https://www.grandraid-reunion.com', 'RE', NULL, 'trail', NULL, NULL, NULL, NULL, NULL, '2026-11-22'),
  ('Transvulcania', 'transvulcania', 'Fuencaliente (La Palma)', '2027-05-08', 73, NULL, 'trail', 'https://transvulcania.com/en/', 'ES', '{73}', 'trail', NULL, NULL, 'ouverte', NULL, NULL, '2026-11-22'),
  ('TCS New York City Marathon', 'tcs new york city marathon', 'New York', '2027-11-07', 42.195, NULL, 'run', 'https://www.nyrr.org', 'US', '{42.195}', 'route', NULL, NULL, NULL, NULL, NULL, '2026-11-22'),
  ('Boston Marathon', 'boston marathon', 'Boston', '2027-04-19', 42.195, NULL, 'run', 'https://www.baa.org/races/boston-marathon', 'US', '{42.195}', 'route', NULL, NULL, 'fermee', NULL, NULL, '2026-11-22'),
  ('Chicago Marathon', 'chicago marathon', 'Chicago', '2027-10-10', 42.195, NULL, 'run', 'https://www.chicagomarathon.com', 'US', '{42.195}', 'route', NULL, NULL, 'fermee', NULL, NULL, '2026-11-22'),
  ('Los Angeles Marathon', 'los angeles marathon', 'Los Angeles', '2027-03-07', 42.195, NULL, 'run', NULL, 'US', '{42.195}', 'route', NULL, NULL, 'ouverte', 'https://www.mccourtfoundation.org/event/los-angeles-marathon/register', NULL, '2026-11-22'),
  ('Houston Marathon', 'houston marathon', 'Houston', '2027-01-17', NULL, NULL, 'run', 'https://www.chevronhoustonmarathon.com', 'US', '{21.0975,42.195}', 'route', NULL, NULL, 'complete', NULL, NULL, '2026-11-22'),
  ('Honolulu Marathon', 'honolulu marathon', 'Honolulu', '2026-12-13', 42.195, NULL, 'run', 'https://www.honolulumarathon.org', 'US', '{42.195}', 'route', NULL, '05:00', 'ouverte', NULL, NULL, '2026-11-22'),
  ('Western States 100', 'western states 100', 'Olympic Valley', '2027-06-26', 161.3, NULL, 'trail', 'https://www.wser.org', 'US', '{161.3}', 'trail', 'montagneux', NULL, 'tirage_au_sort', NULL, NULL, '2026-11-22'),
  ('IRONMAN 70.3 World Championship', 'ironman 70 3 world championship', 'Chattanooga', '2027-08-28', NULL, NULL, 'triathlon', NULL, 'US', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-11-22'),
  ('Santiago Marathon', 'santiago marathon', 'Santiago', '2027-05-16', NULL, NULL, 'run', 'https://www.maratondesantiago.cl', 'CL', '{10,21.0975,42.195}', 'route', NULL, NULL, 'ouverte', NULL, NULL, '2026-11-22'),
  ('Sao Paulo Marathon', 'sao paulo marathon', 'São Paulo', '2027-04-04', 42.195, NULL, 'run', NULL, 'BR', '{42.195}', 'route', NULL, NULL, NULL, NULL, NULL, '2026-11-22'),
  ('Corrida de São Silvestre', 'corrida de sao silvestre', 'São Paulo', '2026-12-31', 15, NULL, 'run', 'https://www.saosilvestre.com.br', 'BR', '{15}', 'route', NULL, NULL, NULL, NULL, NULL, '2026-11-22'),
  ('Tokyo Marathon', 'tokyo marathon', 'Tokyo', '2027-03-07', 42.195, NULL, 'run', 'https://www.marathon.tokyo/en/', 'JP', '{42.195}', 'route', NULL, NULL, 'fermee', NULL, NULL, '2026-11-22'),
  ('Osaka Marathon', 'osaka marathon', 'Osaka', '2027-02-28', 42.195, NULL, 'run', 'https://www.osaka-marathon.com', 'JP', '{42.195}', 'route', NULL, NULL, 'fermee', NULL, NULL, '2026-11-22'),
  ('Hong Kong Marathon', 'hong kong marathon', 'Hong Kong', '2027-01-17', NULL, NULL, 'run', 'https://www.hkmarathon.com', 'HK', '{10,21.0975,42.195}', 'route', NULL, NULL, 'fermee', NULL, NULL, '2026-11-22'),
  ('Tata Mumbai Marathon', 'tata mumbai marathon', 'Mumbai', '2027-01-17', NULL, NULL, 'run', 'https://tatamumbaimarathon.procam.in', 'IN', '{10,21.0975,42.195}', 'route', NULL, NULL, 'fermee', NULL, NULL, '2026-11-22'),
  ('Dubai Marathon', 'dubai marathon', 'Dubai', '2027-01-17', NULL, NULL, 'run', 'https://www.dubaimarathon.org', 'AE', '{4,10,42.195}', 'route', NULL, NULL, 'ouverte', NULL, NULL, '2026-11-22'),
  ('Great Wall Marathon', 'great wall marathon', 'Huangyaguan (Tianjin)', '2027-05-15', NULL, NULL, 'run', 'https://great-wall-marathon.com', 'CN', '{8.5,21.0975,42.195}', NULL, NULL, NULL, NULL, NULL, NULL, '2026-11-22'),
  ('HYROX World Championships', 'hyrox world championships', 'Hong Kong', '2027-06-10', NULL, NULL, 'hyrox', 'https://hyrox.com/event/puma-hyrox-world-championships-hong-kong/', 'HK', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-11-22'),
  ('Comrades Marathon', 'comrades marathon', 'Pietermaritzburg', '2027-06-13', NULL, NULL, 'run', 'https://www.comrades.com', 'ZA', NULL, 'route', NULL, NULL, 'complete', NULL, NULL, '2026-11-22'),
  ('Two Oceans Marathon', 'two oceans marathon', 'Cape Town', '2027-04-04', NULL, NULL, 'run', 'https://www.twooceansmarathon.org.za', 'ZA', '{21.1,56}', 'route', NULL, NULL, 'fermee', NULL, NULL, '2026-11-22'),
  ('Cape Town Marathon', 'cape town marathon', 'Cape Town', '2027-05-23', 42.195, NULL, 'run', 'https://capetownmarathon.com', 'ZA', '{42.195}', 'route', NULL, NULL, 'fermee', NULL, NULL, '2026-11-22'),
  ('Marrakech Marathon', 'marrakech marathon', 'Marrakech', '2027-01-31', NULL, NULL, 'run', 'https://marathonmarrakech.ma', 'MA', '{21.0975,42.195}', 'route', NULL, NULL, NULL, NULL, NULL, '2026-11-22'),
  ('Sydney Marathon', 'sydney marathon', 'Sydney', '2027-08-29', 42.195, NULL, 'run', 'https://www.tcssydneymarathon.com', 'AU', '{42.195}', 'route', NULL, NULL, 'fermee', NULL, NULL, '2026-11-22'),
  ('Gold Coast Marathon', 'gold coast marathon', 'Gold Coast', '2027-07-04', NULL, NULL, 'run', 'https://goldcoastmarathon.com.au', 'AU', '{5,10,21.0975,42.195}', 'route', NULL, NULL, NULL, NULL, NULL, '2026-11-22')
) AS v (name, name_key, city, race_date, distance_km, elevation_gain_m, discipline, website,
        country, distances_km, surface, profile, start_time, registration_status,
        registration_url, registration_opens, verified_on)
ON CONFLICT (name_key, race_date) DO UPDATE SET
  country = CASE WHEN races.is_seeded THEN EXCLUDED.country ELSE COALESCE(races.country, EXCLUDED.country) END,
  distances_km = CASE WHEN races.is_seeded THEN EXCLUDED.distances_km ELSE COALESCE(races.distances_km, EXCLUDED.distances_km) END,
  surface = CASE WHEN races.is_seeded THEN EXCLUDED.surface ELSE COALESCE(races.surface, EXCLUDED.surface) END,
  profile = CASE WHEN races.is_seeded THEN EXCLUDED.profile ELSE COALESCE(races.profile, EXCLUDED.profile) END,
  start_time = CASE WHEN races.is_seeded THEN EXCLUDED.start_time ELSE COALESCE(races.start_time, EXCLUDED.start_time) END,
  registration_status = CASE WHEN races.is_seeded THEN EXCLUDED.registration_status ELSE races.registration_status END,
  registration_url = CASE WHEN races.is_seeded THEN EXCLUDED.registration_url ELSE races.registration_url END,
  registration_opens = CASE WHEN races.is_seeded THEN EXCLUDED.registration_opens ELSE races.registration_opens END,
  verified_on = CASE WHEN races.is_seeded THEN EXCLUDED.verified_on ELSE races.verified_on END,
  website = COALESCE(races.website, EXCLUDED.website);
