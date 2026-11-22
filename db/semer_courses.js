#!/usr/bin/env node
// Écrit db/courses_semees.sql et db/A_COLLER_courses_monde.sql — les grandes courses que l'app
// connaît d'avance, avec leurs caractéristiques.
//
// POURQUOI UN GÉNÉRATEUR ET PAS UN FICHIER SQL ÉCRIT À LA MAIN. Chaque course porte un `name_key`,
// le nom replié (accents, casse, traits d'union) sur lequel repose à la fois la recherche et
// l'index UNIQUE (name_key, race_date). Si la clé semée diffère d'un seul caractère de ce que
// `normaliser()` produirait, la course semée devient introuvable ET un doublon créé à la main
// pourra exister à côté d'elle. La clé n'est donc jamais tapée : elle est calculée par la même
// fonction que le serveur.
//
// CE QUI N'EST PAS SEMÉ. Seules les dates réellement annoncées par l'organisateur. Une date
// inventée serait pire qu'une course absente : les courses semées passent AVANT les autres dans
// la recherche (is_seeded DESC), donc elles ont l'air officielles — et quelqu'un construirait un
// plan d'entraînement de seize semaines dessus. UTMB 2027, Grand Raid de La Réunion 2027 et
// Marseille-Cassis 2027 n'y sont pas pour cette seule raison : au moment d'écrire, leur date
// n'était pas publiée.
//
// LA RÈGLE DES CARACTÉRISTIQUES. Pour chaque champ : la valeur PUBLIÉE par l'organisateur (ou, à
// défaut, par une source de référence), sinon rien. Jamais une estimation, jamais « à peu près »,
// jamais l'édition passée recopiée sur la suivante. Un champ absent est un champ que l'app ne
// montre pas. Chaque course porte donc, à côté de ses champs :
//   `source`  l'adresse où la valeur a été lue ;
//   `verifie` le jour où elle l'a été (AAAA-MM-JJ). Il est écrit en base (`verified_on`) : l'app
//             dit « vérifié le … » à côté du statut d'inscription, qui n'est qu'une PHOTO.
// Les distances sont une LISTE de formats (`distancesKm`), du plus court au plus long, et
// `distanceKm` n'est donné que pour une épreuve à format unique. Le dénivelé n'est donné que pour
// un format unique aussi : il n'y a pas de D+ « de l'événement ».
//
// CE QUI N'EST PAS DANS LA LISTE, FAUTE DE SOURCE AU 22 NOVEMBRE 2026 : UTMB Mont-Blanc 2027 et
// Tor des Géants 2027 (dates non publiées), Festival des Templiers 2027, Marseille-Cassis 2027,
// Melbourne 2027, Auckland 2027, Marine Corps 2027, Toronto 2027, Marathon de Mexico 2027 (aucune
// date 2027 annoncée), Ironman Hawaï 2027 (date donnée par les calendriers, pas encore confirmée par
// Ironman), Singapour 2026 (le jour du marathon n'est pas écrit sur la page), Seoul, Kigali, Tel
// Aviv, Buenos Aires, Francfort, MIUT, UTMF (une seule source, ou des sources qui se contredisent).
// Une course absente se rajoute ; une date fausse se retrouve sur un plan d'entraînement.
//
// LES COURSES DÉJÀ SEMÉES REÇOIVENT LEURS CARACTÉRISTIQUES. Le script est idempotent, et il
// distingue deux sortes de lignes quand la course existe déjà :
//   - une ligne SEMÉE (`is_seeded`) est à lui : il réécrit ses colonnes de caractéristiques, pour
//     qu'un statut d'inscription relevé aujourd'hui remplace celui de la dernière fois ;
//   - une ligne créée par un coureur (même nom replié, même jour) n'est JAMAIS écrasée : il n'y
//     remplit que les caractéristiques qu'elle n'a pas, jamais le statut d'inscription ni la date
//     de vérification, qui sont sa parole à lui et non celle du coureur.
//
// À REFAIRE CHAQUE ANNÉE. Les courses passées ne sont jamais rendues (api/races). Ce fichier est
// donc à relancer quand les éditions suivantes sont annoncées :
//   node db/semer_courses.js   puis coller db/courses_semees.sql dans la console Neon.
// Le INSERT est idempotent : le relancer deux fois ne crée rien en double. La PREMIÈRE fois, coller
// db/A_COLLER_courses_monde.sql (les colonnes, puis les courses) : `db/schema.sql` crée les colonnes
// au déploiement, mais le fichier à coller marche aussi seul dans la console Neon.
const fs = require('fs');
const path = require('path');
const { normaliser } = require('../lib/recherche');
const {
  nettoyerCourse, jourValide, DISCIPLINES, SURFACES, PROFILS, STATUTS_INSCRIPTION,
} = require('../lib/courses');

// Le jour où cette liste a été relue à ses sources. Aucune course d'avant ce jour n'y entre : l'app
// ne montre que les courses dont la date est >= aujourd'hui.
const AUJOURDHUI = '2026-11-22';

// `distanceKm` et `elevationGainM` restent absents pour les événements à plusieurs formats
// (EcoTrail, Marathon du Mont-Blanc) : annoncer une distance quand il y en a six serait faux pour
// cinq personnes sur six, et l'app sait afficher une course sans distance. Les formats vont dans
// `distancesKm` quand l'organisateur les publie.
//
// `website` aussi est souvent absent, et pour une raison plus sérieuse : l'app en fait un LIEN
// TAPABLE. Un lien officiel vaut mieux qu'une recherche ; un lien deviné vaut moins que rien. Le
// Marathon de Paris change d'organisateur en 2027 et Berlin change de partenaire-titre — leurs
// adresses actuelles peuvent cesser d'être les bonnes. Dans le doute, pas de lien. Un site qui
// figure ici est une adresse d'organisateur LUE le jour de `verifie`.
//
// Les noms sont ceux de l'événement SANS son partenaire-titre quand il change (Chicago, Boston,
// Tokyo…) : la clé de recherche est le nom replié, et « Marathon de Chicago » ne doit pas dépendre
// d'une banque. Les courses déjà semées gardent le leur (la clé de l'index UNIQUE ne change pas).
//
// Les `registrationStatus` sont des PHOTOS du 22 novembre 2026 :
//   ouverte        on peut s'inscrire maintenant ;
//   tirage_au_sort les places sont attribuées par tirage au sort (ouvert ou à venir) ;
//   bientot        pas encore ouverte (avec `registrationOpens` quand le jour est annoncé) ;
//   complete       toutes les places sont prises ;
//   fermee         inscriptions closes, ou tirage déjà passé.
const COURSES = [
  // =============================================== Europe : France ===============================================
  {
    name: 'Marathon des Alpes-Maritimes Nice-Cannes',
    city: 'Nice', country: 'FR', raceDate: '2026-11-08', distanceKm: 42.195, discipline: 'run',
    website: 'https://www.marathon06.com',
  },
  {
    name: 'SaintéLyon',
    // La nuit du 28 au 29 novembre : le départ de Saint-Étienne est donné le 28 au soir.
    city: 'Saint-Étienne', country: 'FR', raceDate: '2026-11-28', distanceKm: 78, elevationGainM: 2000,
    discipline: 'trail', surface: 'trail', website: 'https://www.saintelyon.com',
    source: 'https://www.saintelyon.com/en', verifie: '2026-11-22',
  },
  {
    name: 'Semi-Marathon de Paris',
    city: 'Paris', country: 'FR', raceDate: '2027-03-07', distanceKm: 21.0975, distancesKm: [21.0975],
    discipline: 'run', surface: 'route',
    // Inscriptions par tirage au sort du 8 au 30 septembre 2026, résultats à partir du 1er octobre.
    registrationStatus: 'fermee',
    source: 'https://reference-trail.fr/semi-marathon-de-paris-2027-inscriptions-des-le-8-septembre-et-nouvelle-loterie/',
    verifie: '2026-11-22',
  },
  {
    name: 'EcoTrail Paris',
    // Sept formats, du 10 km au 120 km, départ Rambouillet pour le plus long, arrivée à la tour Eiffel.
    // Le 80 km et le 120 km le 20 mars 2027 (pages officielles de chaque format).
    city: 'Paris', country: 'FR', raceDate: '2027-03-20', distancesKm: [10, 20, 30, 35, 45, 80, 120],
    discipline: 'trail', surface: 'trail', registrationStatus: 'ouverte',
    website: 'https://en.ecotrailparis.com',
    source: 'https://en.ecotrailparis.com/course/trail-80-km', verifie: '2026-11-22',
  },
  {
    name: 'Marathon de Paris',
    // 50e édition, nouvel organisateur (Cadence), tirage au sort du 8 au 30 septembre 2026.
    city: 'Paris', country: 'FR', raceDate: '2027-04-04', distanceKm: 42.195, distancesKm: [42.195],
    discipline: 'run', surface: 'route', registrationStatus: 'fermee',
    source: 'https://stadion-actu.fr/marathon-de-paris-2027-date-tirage-au-sort-inscriptions-comment-decrocher-son-dossard-pour-le-4-avril/',
    verifie: '2026-11-22',
  },
  {
    name: 'Marathon du Mont-Blanc',
    // L'événement court du 24 au 27 juin ; le marathon lui-même est le dimanche. Sept formats, dont
    // les distances réelles bougent d'une édition à l'autre (43,6 km annoncés pour le marathon) :
    // ni distance ni dénivelé tant que l'organisateur ne les fige pas.
    city: 'Chamonix', country: 'FR', raceDate: '2027-06-27', discipline: 'trail', surface: 'trail',
    profile: 'montagneux', website: 'https://www.marathonmontblanc.fr',
    // Dossards train et bus le 20 novembre, tirage au sort du 23 au 30 novembre.
    registrationStatus: 'tirage_au_sort',
    source: 'https://reference-trail.fr/inscriptions-au-marathon-du-mont-blanc-2027-calendrier-prix-et-programme-du-24-au-27-juin/',
    verifie: '2026-11-22',
  },
  {
    name: 'MaXi-Race Annecy',
    // Du 28 au 30 mai ; le Tour du Lac en solo est le samedi 29. L'organisateur publie des FOURCHETTES
    // (100 à 103 km, 5 300 à 5 500 m de D+) parce que le tracé n'est pas figé : pas de distance.
    city: 'Annecy', country: 'FR', raceDate: '2027-05-29', discipline: 'trail', surface: 'trail',
    profile: 'montagneux', registrationStatus: 'fermee', website: 'https://www.maxi-race.org/en/',
    source: 'https://www.maxi-race.org/en/', verifie: '2026-11-22',
  },
  // =============================================== Europe : Royaume-Uni ===============================================
  {
    name: 'TCS London Marathon',
    // Édition en deux jours, une seule fois : samedi 24 et dimanche 25 avril. Le dimanche est le
    // jour historique de la course. Tirage au sort du 24 avril au 1er mai 2026, il ne rouvrira pas.
    city: 'London', country: 'GB', raceDate: '2027-04-25', distanceKm: 42.195, distancesKm: [42.195],
    discipline: 'run', surface: 'route', registrationStatus: 'fermee',
    website: 'https://www.tcslondonmarathon.com',
    source: 'https://www.londonmarathonevents.co.uk/london-marathon', verifie: '2026-11-22',
  },
  {
    name: 'Edinburgh Marathon',
    // Le week-end du 29 et 30 mai ; le marathon est le dimanche 30.
    city: 'Edinburgh', country: 'GB', raceDate: '2027-05-30', distancesKm: [42.195], discipline: 'run',
    surface: 'route', registrationStatus: 'ouverte', website: 'https://www.edinburghmarathon.com',
    source: 'https://www.bhf.org.uk/edinburghmarathon', verifie: '2026-11-22',
  },
  {
    name: 'Great North Run',
    // Le semi-marathon de Newcastle à South Shields. Tirage de septembre 2026 passé ; un second
    // tirage en janvier, dates non annoncées.
    city: 'Newcastle', country: 'GB', raceDate: '2027-09-12', distancesKm: [21.0975], discipline: 'run',
    surface: 'route', registrationStatus: 'fermee', website: 'https://www.greatrun.org',
    source: 'https://www.ageuk.org.uk/northumberland/get-involved/great-north-run-2027/', verifie: '2026-11-22',
  },
  // =============================================== Europe : Allemagne, Pays-Bas, Autriche, Italie, Espagne... ===============================================
  {
    name: 'Generali Berlin Marathon',
    // Generali remplace BMW comme partenaire-titre à partir de 2027. Tirage au sort ouvert.
    city: 'Berlin', country: 'DE', raceDate: '2027-09-26', distanceKm: 42.195, distancesKm: [42.195],
    discipline: 'run', surface: 'route', registrationStatus: 'tirage_au_sort',
    source: 'https://www.bmw-berlin-marathon.com/en/', verifie: '2026-11-22',
  },
  {
    name: 'Berlin Half Marathon',
    city: 'Berlin', country: 'DE', raceDate: '2027-04-04', distancesKm: [21.0975], discipline: 'run',
    surface: 'route', registrationStatus: 'fermee', website: 'https://www.generali-berliner-halbmarathon.de',
    source: 'https://www.generali-berliner-halbmarathon.de/en/preparation/event-faq', verifie: '2026-11-22',
  },
  {
    name: 'DATEV Challenge Roth',
    // Triathlon longue distance. Les places en ligne sont parties en juillet 2026 ; le tirage de
    // rattrapage existe. Les trois distances (3,8 / 180 / 42,2 km) ne sont pas une liste de formats.
    city: 'Roth', country: 'DE', raceDate: '2027-07-04', discipline: 'triathlon',
    registrationStatus: 'complete', website: 'https://www.challenge-roth.com',
    source: 'https://www.challenge-roth.com/en/news-area/der-termin-fur-den-datev-challenge-roth-2027-steht-fest-kopie.html',
    verifie: '2026-11-22',
  },
  {
    name: 'Rotterdam Marathon',
    // « Due to the flat course, one of the fastest marathons in the world » (l'organisateur). Le
    // quart de marathon fait 10,55 km. Marathon et quart complets.
    city: 'Rotterdam', country: 'NL', raceDate: '2027-04-11', distancesKm: [10.55, 42.195],
    discipline: 'run', surface: 'route', profile: 'plat', registrationStatus: 'complete',
    website: 'https://www.nnmarathonrotterdam.nl/en/',
    source: 'https://www.nnmarathonrotterdam.nl/en/', verifie: '2026-11-22',
  },
  {
    name: 'Amsterdam Marathon',
    // « Edition 2027 : samedi 30 et dimanche 31 octobre » (l'organisateur) ; le marathon est le dimanche.
    city: 'Amsterdam', country: 'NL', raceDate: '2027-10-31', distancesKm: [7.5, 21.0975, 42.195],
    discipline: 'run', surface: 'route', profile: 'plat', registrationStatus: 'bientot',
    website: 'https://www.tcsamsterdammarathon.eu',
    source: 'https://www.tcsamsterdammarathon.eu/', verifie: '2026-11-22',
  },
  {
    name: 'Vienna City Marathon',
    city: 'Vienna', country: 'AT', raceDate: '2027-04-18', distancesKm: [21.0975, 42.195],
    discipline: 'run', surface: 'route', registrationStatus: 'ouverte', website: 'https://www.vienna-marathon.com',
    source: 'https://www.vienna-marathon.com/', verifie: '2026-11-22',
  },
  {
    name: 'Prague Marathon',
    city: 'Prague', country: 'CZ', raceDate: '2027-05-02', distancesKm: [42.195], discipline: 'run',
    surface: 'route', website: 'https://www.runczech.com',
    source: 'https://www.finishers.com/en/course/marathon-de-prague', verifie: '2026-11-22',
  },
  {
    name: 'Copenhagen Marathon',
    // Les dossards passent au tirage au sort à partir de cette édition.
    city: 'Copenhagen', country: 'DK', raceDate: '2027-05-09', distancesKm: [42.195], discipline: 'run',
    surface: 'route', registrationStatus: 'tirage_au_sort', website: 'https://copenhagenmarathon.dk',
    source: 'https://copenhagenmarathon.dk/en/entries-for-copenhagen-marathon-2027-will-be-allocated-through-a-lottery/',
    verifie: '2026-11-22',
  },
  {
    name: 'Rome Marathon',
    // Départ « vers 8 h 30 » selon le règlement officiel.
    city: 'Rome', country: 'IT', raceDate: '2027-03-14', distancesKm: [42.195], discipline: 'run',
    surface: 'route', startTime: '08:30', registrationStatus: 'ouverte',
    website: 'https://www.runromethemarathon.com',
    source: 'https://www.runromethemarathon.com/wp-content/uploads/2026/04/RRTM27-regolamento-inglese-23-4-2026.pdf',
    verifie: '2026-11-22',
  },
  {
    name: 'Florence Marathon',
    // 42e Estra Firenze Marathon, départ à 8 h 30 piazza del Duomo.
    city: 'Florence', country: 'IT', raceDate: '2026-11-29', distancesKm: [42.195], discipline: 'run',
    surface: 'route', startTime: '08:30', registrationStatus: 'complete',
    website: 'https://www.firenzemarathon.it/en/',
    source: 'https://www.firenzemarathon.it/en/', verifie: '2026-11-22',
  },
  {
    name: 'Barcelona Marathon',
    city: 'Barcelona', country: 'ES', raceDate: '2027-03-14', distancesKm: [42.195], discipline: 'run',
    surface: 'route', profile: 'plat', registrationStatus: 'complete',
    website: 'https://www.zurichmaratobarcelona.es/en',
    source: 'https://www.zurichmaratobarcelona.es/en', verifie: '2026-11-22',
  },
  {
    name: 'Valencia Marathon',
    // « The world's fastest and flattest circuit » (l'organisateur).
    city: 'Valencia', country: 'ES', raceDate: '2026-12-06', distancesKm: [42.195], discipline: 'run',
    surface: 'route', profile: 'plat',
    website: 'https://www.valenciaciudaddelrunning.com/en/marathon/',
    source: 'https://www.valenciaciudaddelrunning.com/en/marathon/', verifie: '2026-11-22',
  },
  {
    name: 'Seville Marathon',
    // Pas de site d'organisateur lu : date de Finishers (« événement validé par l'organisateur »)
    // et de la presse locale, qui s'accordent.
    city: 'Seville', country: 'ES', raceDate: '2027-02-21', distancesKm: [42.195], discipline: 'run',
    surface: 'route', source: 'https://www.finishers.com/es/evento/maraton-de-sevilla', verifie: '2026-11-22',
  },
  {
    name: 'Madrid Marathon',
    // À partir de 2027 il n'y a plus de 10 km : marathon et semi seulement (règlement officiel).
    city: 'Madrid', country: 'ES', raceDate: '2027-04-25', distancesKm: [21.0975, 42.195], discipline: 'run',
    surface: 'route', website: 'https://rocknrollmadridrun.com',
    source: 'https://rocknrollmadridrun.com/official-rules/?lang=en', verifie: '2026-11-22',
  },
  // =============================================== Europe : trail ===============================================
  {
    name: 'Lavaredo Ultra Trail',
    // Du 23 au 27 juin ; le 120K est le vendredi 25 (site officiel). Cinq formats. Tirage au sort
    // pour les quatre plus longs (résultats publiés), le 10K en premier arrivé, premier servi.
    city: "Cortina d'Ampezzo", country: 'IT', raceDate: '2027-06-25', distancesKm: [10, 20, 50, 80, 120],
    discipline: 'trail', surface: 'trail', profile: 'montagneux', registrationStatus: 'tirage_au_sort',
    website: 'https://lavaredo.utmb.world', registrationUrl: 'https://lavaredo.utmb.world/registration',
    source: 'https://lavaredo.utmb.world/registration', verifie: '2026-11-22',
  },
  {
    name: 'Zegama-Aizkorri',
    // 26e édition le 6 juin. La pré-inscription ouvre le 11 janvier (annonce de l'organisateur,
    // l'année n'y est pas écrite : c'est le 11 janvier qui suit), tirage des dossards ensuite.
    city: 'Zegama', country: 'ES', raceDate: '2027-06-06', distancesKm: [42], discipline: 'trail',
    surface: 'trail', profile: 'montagneux', registrationStatus: 'bientot', registrationOpens: '2027-01-11',
    website: 'https://www.zegama-aizkorri.com/en/',
    source: 'https://www.zegama-aizkorri.com/en/', verifie: '2026-11-22',
  },
  {
    name: 'Sierre-Zinal',
    // « Samedi 7 août » 2027 sur le site officiel ; 31 km, 2 200 m de montée et 1 100 m de descente.
    city: 'Sierre', country: 'CH', raceDate: '2027-08-07', distanceKm: 31, distancesKm: [31],
    elevationGainM: 2200, discipline: 'trail', surface: 'trail', profile: 'montagneux',
    website: 'https://www.sierre-zinal.com',
    source: 'https://www.myswitzerland.com/en/experiences/events/sierre-zinal/', verifie: '2026-11-22',
  },
  {
    name: 'Grand Raid de La Réunion',
    // Du jeudi 14 au dimanche 17 octobre 2027 (annonce de l'organisateur). Ni distances, ni D+, ni
    // ouverture des inscriptions publiés au 22 novembre : on ne met que la date.
    city: 'Saint-Pierre', country: 'RE', raceDate: '2027-10-14', discipline: 'trail', surface: 'trail',
    website: 'https://www.grandraid-reunion.com',
    source: 'https://www.grandraid-reunion.com/', verifie: '2026-11-22',
  },
  {
    name: 'Transvulcania',
    // Du 6 au 8 mai ; l'ultra de 73 km (phare de Fuencaliente aux Llanos de Aridane) est le samedi 8.
    city: 'Fuencaliente (La Palma)', country: 'ES', raceDate: '2027-05-08', distancesKm: [73],
    discipline: 'trail', surface: 'trail', registrationStatus: 'ouverte', website: 'https://transvulcania.com/en/',
    source: 'https://transvulcania.com/en/transvulcania-adidas-2027-opens-registration-following-a-historic-event-that-set-eight-records/',
    verifie: '2026-11-22',
  },
  // =============================================== Amérique du Nord ===============================================
  {
    name: 'TCS New York City Marathon',
    // Toujours le premier dimanche de novembre.
    city: 'New York', country: 'US', raceDate: '2027-11-07', distanceKm: 42.195, distancesKm: [42.195],
    discipline: 'run', surface: 'route', website: 'https://www.nyrr.org',
    source: 'https://www.nyrr.org', verifie: '2026-11-22',
  },
  {
    name: 'Boston Marathon',
    // Le lundi 19 avril 2027 (Patriots' Day), de Hopkinton à Boston. Inscription sur qualification :
    // la fenêtre de septembre 2026 est passée.
    city: 'Boston', country: 'US', raceDate: '2027-04-19', distancesKm: [42.195], discipline: 'run',
    surface: 'route', registrationStatus: 'fermee', website: 'https://www.baa.org/races/boston-marathon',
    source: 'https://www.baa.org/races/boston-marathon', verifie: '2026-11-22',
  },
  {
    name: 'Chicago Marathon',
    city: 'Chicago', country: 'US', raceDate: '2027-10-10', distancesKm: [42.195], discipline: 'run',
    surface: 'route', registrationStatus: 'fermee', website: 'https://www.chicagomarathon.com',
    source: 'https://www.chicagomarathon.com/', verifie: '2026-11-22',
  },
  {
    name: 'Los Angeles Marathon',
    // Inscription générale ouverte sur la page de l'organisateur ; elle se remplit vite.
    city: 'Los Angeles', country: 'US', raceDate: '2027-03-07', distancesKm: [42.195], discipline: 'run',
    surface: 'route', registrationStatus: 'ouverte',
    registrationUrl: 'https://www.mccourtfoundation.org/event/los-angeles-marathon/register',
    source: 'https://www.mccourtfoundation.org/event/los-angeles-marathon/register', verifie: '2026-11-22',
  },
  {
    name: 'Houston Marathon',
    city: 'Houston', country: 'US', raceDate: '2027-01-17', distancesKm: [21.0975, 42.195],
    discipline: 'run', surface: 'route', registrationStatus: 'complete',
    website: 'https://www.chevronhoustonmarathon.com',
    source: 'https://www.chevronhoustonmarathon.com/registration/', verifie: '2026-11-22',
  },
  {
    name: 'Honolulu Marathon',
    // Départ à 5 h, sans temps limite (page officielle des épreuves).
    city: 'Honolulu', country: 'US', raceDate: '2026-12-13', distancesKm: [42.195], discipline: 'run',
    surface: 'route', startTime: '05:00', registrationStatus: 'ouverte', website: 'https://www.honolulumarathon.org',
    source: 'https://www.honolulumarathon.org/our-events', verifie: '2026-11-22',
  },
  {
    name: 'Western States 100',
    // 100,2 miles (161,3 km) d'Olympic Valley à Auburn, du 26 au 27 juin. Tirage au sort : demande
    // du 1er au 21 novembre 2026, tirage le 5 décembre. « Plus de 18 000 pieds » de montée est une
    // borne basse, pas un dénivelé : pas de D+.
    city: 'Olympic Valley', country: 'US', raceDate: '2027-06-26', distancesKm: [161.3], discipline: 'trail',
    surface: 'trail', profile: 'montagneux', registrationStatus: 'tirage_au_sort', website: 'https://www.wser.org',
    source: 'https://www.wser.org/', verifie: '2026-11-22',
  },
  {
    name: 'IRONMAN 70.3 World Championship',
    // Les 28 et 29 août 2027, à Chattanooga (communiqué d'Ironman). Pas d'adresse de la page de la
    // course lue : pas de lien.
    city: 'Chattanooga', country: 'US', raceDate: '2027-08-28', discipline: 'triathlon',
    source: 'https://www.slowtwitch.com/triathlon/its-back-to-chattanooga-2027-ironman-70-3-world-championship-host-announced/',
    verifie: '2026-11-22',
  },
  // =============================================== Amérique du Sud ===============================================
  {
    name: 'Santiago Marathon',
    // Le dimanche 16 mai ; vente générale ouverte depuis le 15 octobre (10K et 21K épuisés début
    // novembre, 42K encore disponible).
    city: 'Santiago', country: 'CL', raceDate: '2027-05-16', distancesKm: [10, 21.0975, 42.195],
    discipline: 'run', surface: 'route', registrationStatus: 'ouverte', website: 'https://www.maratondesantiago.cl',
    source: 'https://www.radioagricultura.cl/noticias/dato-practico/maraton-de-santiago-2027-abre-inscripciones-revisa-precios-distancias-y-como-participar_20261015/',
    verifie: '2026-11-22',
  },
  {
    name: 'Sao Paulo Marathon',
    // 31e édition, le 4 avril (règlement officiel).
    city: 'São Paulo', country: 'BR', raceDate: '2027-04-04', distancesKm: [42.195], discipline: 'run',
    surface: 'route',
    source: 'https://www.yescom.com.br/maratonasp/2027/img/Regulamento-ING_31aMaratonaSP2027_atualizadoem25-06-2026.pdf',
    verifie: '2026-11-22',
  },
  {
    name: 'Corrida de São Silvestre',
    // 101e édition, 15 km sur l'avenue Paulista, le 31 décembre 2026.
    city: 'São Paulo', country: 'BR', raceDate: '2026-12-31', distancesKm: [15], discipline: 'run',
    surface: 'route', website: 'https://www.saosilvestre.com.br',
    source: 'https://www.saosilvestre.com.br', verifie: '2026-11-22',
  },
  // =============================================== Asie ===============================================
  {
    name: 'Tokyo Marathon',
    // Le dimanche 7 mars 2027. Tirage au sort général passé (résultats le 11 septembre 2026).
    city: 'Tokyo', country: 'JP', raceDate: '2027-03-07', distancesKm: [42.195], discipline: 'run',
    surface: 'route', registrationStatus: 'fermee', website: 'https://www.marathon.tokyo/en/',
    source: 'https://www.marathon.tokyo/en/about/', verifie: '2026-11-22',
  },
  {
    name: 'Osaka Marathon',
    city: 'Osaka', country: 'JP', raceDate: '2027-02-28', distancesKm: [42.195], discipline: 'run',
    surface: 'route', registrationStatus: 'fermee', website: 'https://www.osaka-marathon.com',
    source: 'https://www.osaka-marathon.com/2027/en/info/gist', verifie: '2026-11-22',
  },
  {
    name: 'Hong Kong Marathon',
    // Dimanche 17 janvier 2027 ; inscription du 11 au 20 septembre 2026.
    city: 'Hong Kong', country: 'HK', raceDate: '2027-01-17', distancesKm: [10, 21.0975, 42.195],
    discipline: 'run', surface: 'route', registrationStatus: 'fermee', website: 'https://www.hkmarathon.com',
    source: 'https://www.hkmarathon.com/race-information', verifie: '2026-11-22',
  },
  {
    name: 'Tata Mumbai Marathon',
    city: 'Mumbai', country: 'IN', raceDate: '2027-01-17', distancesKm: [10, 21.0975, 42.195],
    discipline: 'run', surface: 'route', registrationStatus: 'fermee',
    website: 'https://tatamumbaimarathon.procam.in',
    source: 'https://tatamumbaimarathon.procam.in/race-categories/marathon/faqs', verifie: '2026-11-22',
  },
  {
    name: 'Dubai Marathon',
    // 26e édition, dimanche 17 janvier 2027. L'organisateur : inscription ouverte.
    city: 'Dubai', country: 'AE', raceDate: '2027-01-17', distancesKm: [4, 10, 42.195], discipline: 'run',
    surface: 'route', registrationStatus: 'ouverte', website: 'https://www.dubaimarathon.org',
    source: 'https://www.dubaimarathon.org/', verifie: '2026-11-22',
  },
  {
    name: 'Great Wall Marathon',
    // Départ de la vieille forteresse de Huangyaguan, le samedi 15 mai 2027 (site de l'organisateur).
    // Statut d'inscription : la page d'accueil et celle des épreuves se contredisent, donc aucun.
    city: 'Huangyaguan (Tianjin)', country: 'CN', raceDate: '2027-05-15', distancesKm: [8.5, 21.0975, 42.195],
    discipline: 'run', website: 'https://great-wall-marathon.com',
    source: 'https://great-wall-marathon.com/', verifie: '2026-11-22',
  },
  {
    name: 'HYROX World Championships',
    // PUMA HYROX World Championships, du 10 au 13 juin 2027 à AsiaWorld-Expo : la première fois en Asie-Pacifique.
    city: 'Hong Kong', country: 'HK', raceDate: '2027-06-10', discipline: 'hyrox',
    website: 'https://hyrox.com/event/puma-hyrox-world-championships-hong-kong/',
    source: 'https://hyrox.com/event/puma-hyrox-world-championships-hong-kong/', verifie: '2026-11-22',
  },
  // =============================================== Afrique ===============================================
  {
    name: 'Comrades Marathon',
    // 100e édition, la « Down Run » de Pietermaritzburg à Durban, dimanche 13 juin 2027. La distance
    // officielle n'est fixée qu'après la mesure du parcours (travaux en cours) : pas de distance.
    // Plus de places : tirage général passé (42 802 demandes pour 14 519 places).
    city: 'Pietermaritzburg', country: 'ZA', raceDate: '2027-06-13', discipline: 'run', surface: 'route',
    registrationStatus: 'complete', website: 'https://www.comrades.com',
    source: 'https://www.comrades.com/', verifie: '2026-11-22',
  },
  {
    name: 'Two Oceans Marathon',
    // Le semi (21,1 km) le samedi 3 avril, l'ultra (56 km) le dimanche 4. Fenêtres d'inscription closes.
    city: 'Cape Town', country: 'ZA', raceDate: '2027-04-04', distancesKm: [21.1, 56], discipline: 'run',
    surface: 'route', registrationStatus: 'fermee', website: 'https://www.twooceansmarathon.org.za',
    source: 'https://www.twooceansmarathon.org.za/?p=9246', verifie: '2026-11-22',
  },
  {
    name: 'Cape Town Marathon',
    // Huitième des World Marathon Majors : sa première édition « Major » est celle-ci.
    city: 'Cape Town', country: 'ZA', raceDate: '2027-05-23', distancesKm: [42.195], discipline: 'run',
    surface: 'route', registrationStatus: 'fermee', website: 'https://capetownmarathon.com',
    source: 'https://capetownmarathon.com/FAQ/', verifie: '2026-11-22',
  },
  {
    name: 'Marrakech Marathon',
    // 37e édition, le dimanche 31 janvier 2027 (le titre du site de l'organisateur ; son programme
    // écrit aussi « 30 » à un endroit, le 31 est la date des horaires d'inscription).
    city: 'Marrakech', country: 'MA', raceDate: '2027-01-31', distancesKm: [21.0975, 42.195],
    discipline: 'run', surface: 'route', website: 'https://marathonmarrakech.ma',
    source: 'https://marathonmarrakech.ma/?lang=en', verifie: '2026-11-22',
  },
  // =============================================== Océanie ===============================================
  {
    name: 'Sydney Marathon',
    // Le dimanche 29 août 2027. Tirage au sort clos ; résultats envoyés le 3 novembre.
    city: 'Sydney', country: 'AU', raceDate: '2027-08-29', distancesKm: [42.195], discipline: 'run',
    surface: 'route', registrationStatus: 'fermee', website: 'https://www.tcssydneymarathon.com',
    source: 'https://www.tcssydneymarathon.com/ballot-information', verifie: '2026-11-22',
  },
  {
    name: 'Gold Coast Marathon',
    // Le week-end des 3 et 4 juillet ; le marathon est le dimanche 4, le semi et les 5 et 10 km le samedi.
    city: 'Gold Coast', country: 'AU', raceDate: '2027-07-04', distancesKm: [5, 10, 21.0975, 42.195],
    discipline: 'run', surface: 'route', website: 'https://goldcoastmarathon.com.au',
    source: 'https://goldcoastmarathon.com.au/?p=431', verifie: '2026-11-22',
  },
];

// Ce qui sort en SQL, dans l'ordre des colonnes de l'INSERT.
function litteral(valeur) {
  if (valeur === null || valeur === undefined) return 'NULL';
  if (typeof valeur === 'number') return String(valeur);
  // Une seule façon d'échapper une chaîne SQL, et elle s'applique aussi aux apostrophes des noms
  // de ville. Ce fichier est généré, pas concaténé depuis une entrée d'utilisateur.
  return "'" + valeur.replace(/'/g, "''") + "'";
}

function litteralDeListe(liste) {
  if (!liste) return 'NULL';
  return "'{" + liste.map((n) => String(n)).join(',') + "}'";
}

// Les champs qui, s'ils sont donnés et que la validation du serveur les refuse, doivent faire
// ÉCHOUER le script : une valeur qui disparaît en silence est une donnée perdue sans que personne le
// sache. Le serveur, lui, les efface sans bruit — c'est sa règle, pas celle de ce fichier.
const CHAMPS_CONTROLES = [
  'country', 'distancesKm', 'surface', 'profile', 'startTime', 'registrationStatus',
  'registrationUrl', 'registrationOpens', 'website',
];

const vues = new Set();
const lignes = [];
for (const brute of COURSES) {
  // Même porte que le serveur : si une entrée de cette liste ne passerait pas `create`, elle ne
  // doit pas entrer par la porte de service.
  const { erreur, course } = nettoyerCourse(brute, '1970-01-01');
  if (erreur) throw new Error(`« ${brute.name} » refusée : ${erreur}`);
  if (course.nameKey !== normaliser(brute.name)) throw new Error('clé incohérente');
  if (!DISCIPLINES.includes(course.discipline)) throw new Error('discipline inconnue');
  for (const champ of CHAMPS_CONTROLES) {
    const donne = brute[champ];
    const vide = donne === undefined || donne === null;
    if (!vide && course[champ] === null) throw new Error(`« ${brute.name} » : ${champ} refusé`);
  }
  if (brute.surface && !SURFACES.includes(brute.surface)) throw new Error(`surface inconnue : ${brute.name}`);
  if (brute.profile && !PROFILS.includes(brute.profile)) throw new Error(`profil inconnu : ${brute.name}`);
  if (brute.registrationStatus && !STATUTS_INSCRIPTION.includes(brute.registrationStatus)) {
    throw new Error(`statut inconnu : ${brute.name}`);
  }

  // Les courses déjà passées ne sont pas rendues par l'app : y en avoir une serait une ligne morte.
  // La seule dont la date est antérieure est une course semée AVANT cette liste (Nice-Cannes), que
  // l'index UNIQUE garde.
  if (course.raceDate < AUJOURDHUI && brute.name !== 'Marathon des Alpes-Maritimes Nice-Cannes') {
    throw new Error(`« ${brute.name} » est passée : ${course.raceDate}`);
  }
  const doublon = `${course.nameKey}|${course.raceDate}`;
  if (vues.has(doublon)) throw new Error(`doublon dans la liste : ${brute.name}`);
  vues.add(doublon);

  // Une caractéristique sans source n'a pas sa place : `source` et `verifie` vont ensemble, et dès
  // qu'une course porte autre chose que son nom, sa date, sa ville et son pays, il lui faut les deux.
  const verifie = jourValide(brute.verifie);
  if (brute.verifie && !verifie) throw new Error(`date de vérification invalide : ${brute.name}`);
  if (verifie && !/^https?:\/\/[^\s]+$/.test(brute.source || '')) {
    throw new Error(`« ${brute.name} » : une vérification sans adresse de source`);
  }
  if (verifie && verifie > AUJOURDHUI) throw new Error(`« ${brute.name} » vérifiée dans le futur`);
  const porteDesCaracteristiques = ['distancesKm', 'surface', 'profile', 'startTime', 'registrationStatus',
    'registrationUrl', 'registrationOpens'].some((c) => course[c] !== null);
  if (porteDesCaracteristiques && !verifie) throw new Error(`« ${brute.name} » : caractéristiques sans source`);
  // Une ouverture d'inscription annoncée n'a de sens que pour une inscription pas encore ouverte.
  if (course.registrationOpens && course.registrationStatus !== 'bientot') {
    throw new Error(`« ${brute.name} » : registrationOpens sans statut « bientot »`);
  }

  lignes.push('  (' + [
    litteral(course.name), litteral(course.nameKey), litteral(course.city),
    litteral(course.raceDate), litteral(course.distanceKm), litteral(course.elevationGainM),
    litteral(course.discipline), litteral(course.website),
    litteral(course.country), litteralDeListe(course.distancesKm), litteral(course.surface),
    litteral(course.profile), litteral(course.startTime), litteral(course.registrationStatus),
    litteral(course.registrationUrl), litteral(course.registrationOpens), litteral(verifie),
  ].join(', ') + ')');
}

// Comment une ligne qui existe DÉJÀ reçoit ses caractéristiques. `races.is_seeded` : la ligne est à
// ce script, qui réécrit ; sinon c'est celle d'un coureur, dont on ne complète que le vide.
const STABLES = ['country', 'distances_km', 'surface', 'profile', 'start_time'];
const INSTANTANES = ['registration_status', 'registration_url', 'registration_opens', 'verified_on'];
const miseAJour = [
  ...STABLES.map((c) => `  ${c} = CASE WHEN races.is_seeded THEN EXCLUDED.${c} ELSE COALESCE(races.${c}, EXCLUDED.${c}) END`),
  ...INSTANTANES.map((c) => `  ${c} = CASE WHEN races.is_seeded THEN EXCLUDED.${c} ELSE races.${c} END`),
  // Le site d'une course semée n'est jamais effacé ni remplacé ; il est seulement complété s'il manque.
  '  website = COALESCE(races.website, EXCLUDED.website)',
].join(',\n');

const COLONNES = 'name, name_key, city, race_date, distance_km, elevation_gain_m, discipline, website,\n'
  + '                   country, distances_km, surface, profile, start_time, registration_status,\n'
  + '                   registration_url, registration_opens, verified_on, created_by, is_seeded';

const instruction = `INSERT INTO races (${COLONNES})
SELECT v.name, v.name_key, v.city, v.race_date::date, v.distance_km::numeric, v.elevation_gain_m::int,
       v.discipline, v.website, v.country, v.distances_km::numeric[], v.surface, v.profile, v.start_time,
       v.registration_status, v.registration_url, v.registration_opens::date, v.verified_on::date, NULL, true
FROM (VALUES
${lignes.join(',\n')}
) AS v (name, name_key, city, race_date, distance_km, elevation_gain_m, discipline, website,
        country, distances_km, surface, profile, start_time, registration_status,
        registration_url, registration_opens, verified_on)
ON CONFLICT (name_key, race_date) DO UPDATE SET
${miseAJour};
`;

const corps = `-- GÉNÉRÉ PAR db/semer_courses.js — NE PAS MODIFIER À LA MAIN.
-- Relancer \`node db/semer_courses.js\` après avoir mis la liste à jour dans ce script.
--
-- Les ${COURSES.length} courses que l'app connaît d'avance, avec leurs caractéristiques relevées à la
-- source de l'organisateur le ${AUJOURDHUI} (adresse et jour de chaque relevé : dans le script). Tout le
-- reste se crée depuis l'app, par les coureurs eux-mêmes : une page de course n'a pas besoin d'un
-- catalogue mondial pour servir, elle a besoin que la course que TOI tu prépares existe.
--
-- \`created_by\` reste NULL : personne n'a créé ces pages, elles étaient là. \`is_seeded\` les fait
-- passer avant les saisies approximatives du même événement dans la recherche.
--
-- IDEMPOTENT. Une course qui existe déjà (même nom replié, même jour) n'est jamais dupliquée :
--   - si elle est SEMÉE, ses colonnes de caractéristiques sont réécrites (le statut d'inscription
--     d'aujourd'hui remplace celui de la dernière fois) ;
--   - si c'est la saisie d'un coureur, on ne complète que ce qui lui manque, jamais son statut
--     d'inscription ni sa date de vérification. Rien de ce qu'il a tapé n'est écrasé.
${instruction}`;

// Le fichier à coller d'un seul bloc dans la console Neon : les colonnes (les mêmes que
// db/schema.sql, idempotentes), puis les courses.
const colonnes = `-- À COLLER DANS LA CONSOLE NEON (SQL Editor), EN UNE FOIS.
-- GÉNÉRÉ PAR db/semer_courses.js — NE PAS MODIFIER À LA MAIN.
--
-- Deux temps : les colonnes des caractéristiques d'une course (pays, formats, surface, profil,
-- heure de départ, statut d'inscription), puis les ${COURSES.length} courses que l'app connaît d'avance.
-- Tout est idempotent — \`ADD COLUMN IF NOT EXISTS\`, \`ON CONFLICT … DO UPDATE\` limité aux colonnes
-- nouvelles — donc le relancer ne crée rien en double, n'efface rien, et ne touche à aucune valeur
-- qu'un coureur a saisie.
--
-- Il suppose que la table \`races\` existe (db/A_COLLER_courses.sql, ou db/schema.sql). Les colonnes
-- sont aussi dans db/schema.sql, que le déploiement applique : coller ce fichier avant ou après
-- revient au même.

-- ===== 1. LES COLONNES =====

ALTER TABLE races ADD COLUMN IF NOT EXISTS country TEXT;
ALTER TABLE races ADD COLUMN IF NOT EXISTS distances_km NUMERIC[];
ALTER TABLE races ADD COLUMN IF NOT EXISTS surface TEXT;
ALTER TABLE races ADD COLUMN IF NOT EXISTS profile TEXT;
ALTER TABLE races ADD COLUMN IF NOT EXISTS start_time TEXT;
ALTER TABLE races ADD COLUMN IF NOT EXISTS registration_status TEXT;
ALTER TABLE races ADD COLUMN IF NOT EXISTS registration_url TEXT;
ALTER TABLE races ADD COLUMN IF NOT EXISTS registration_opens DATE;
ALTER TABLE races ADD COLUMN IF NOT EXISTS verified_on DATE;
CREATE INDEX IF NOT EXISTS idx_races_country ON races (country);

-- ===== 2. LES COURSES =====

${instruction}
-- ===== 3. VÉRIFICATION (facultatif) =====
-- Devrait rendre ${COURSES.length} lignes, de la plus proche à la plus lointaine.
SELECT name, city, country, race_date, distances_km, registration_status, verified_on
FROM races
WHERE is_seeded
ORDER BY race_date;
`;

const cible = path.join(__dirname, 'courses_semees.sql');
const aColler = path.join(__dirname, 'A_COLLER_courses_monde.sql');
fs.writeFileSync(cible, corps, 'utf8');
fs.writeFileSync(aColler, colonnes, 'utf8');

const parPays = {};
for (const c of COURSES) parPays[c.country] = (parPays[c.country] || 0) + 1;
process.stdout.write(`${COURSES.length} courses écrites dans ${cible}\n`);
process.stdout.write(`et dans ${aColler}\n`);
process.stdout.write(`${Object.keys(parPays).length} pays : ${Object.entries(parPays).map(([k, v]) => `${k} ${v}`).join(', ')}\n`);
