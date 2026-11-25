// Ce qu'on accepte quand quelqu'un crée la page d'une course.
//
// CE QUE CE FICHIER PROTÈGE. Une course créée par un coureur porte un champ `website` que l'app
// affiche en LIEN TAPABLE à tous ceux qui suivront cette course. Un champ libre affiché est une
// chose ; un champ libre rendu tapable au doigt de quelqu'un d'autre en est une autre. La règle
// qui décide ce qui devient tapable est donc seule dans lib/courses.js, et testée ici — pas
// dissoute au milieu d'une insertion SQL où personne ne la relira.
//
// Le deuxième défaut qu'ils empêchent : un nom qui ne se replie sur rien. L'unicité d'une course
// tient à l'index UNIQUE (name_key, race_date). Si `name_key` peut être vide, toutes les courses
// faites de ponctuation entrent en collision entre elles, et la première gagne pour toujours.
const test = require('node:test');
const assert = require('node:assert');

const {
  DISCIPLINES, SURFACES, PROFILS, STATUTS_INSCRIPTION, FORMATS_MAXIMUM,
  nettoyerCourse, codesPourPays,
} = require('../lib/courses');

// Toutes les entrées de ces tests se situent par rapport à une date fixe, passée en second
// argument : un test qui dépendrait de la vraie date d'aujourd'hui finirait par échouer tout seul.
const JOUR = '2026-10-25';
const base = { name: 'Marathon de Paris', raceDate: '2027-04-11' };

function course(extra) {
  const r = nettoyerCourse({ ...base, ...extra }, JOUR);
  assert.strictEqual(r.erreur, undefined, 'refusée alors qu\'elle devait passer : ' + r.erreur);
  return r.course;
}

function refus(extra) {
  const r = nettoyerCourse({ ...base, ...extra }, JOUR);
  assert.ok(r.erreur, 'acceptée alors qu\'elle devait être refusée');
  assert.strictEqual(r.course, undefined);
  return r.erreur;
}

// --- Le site, la raison d'être de ce fichier ----------------------------------------------------

test('UNE ADRESSE javascript: N\'EST JAMAIS RENDUE', () => {
  // Le cas qui justifie tout le reste.
  assert.strictEqual(course({ website: 'javascript:alert(1)' }).website, null);
  assert.strictEqual(course({ website: 'JavaScript:alert(1)' }).website, null);
  assert.strictEqual(course({ website: '  javascript:alert(1)  ' }).website, null);
});

test('data: et file: non plus', () => {
  assert.strictEqual(course({ website: 'data:text/html,<script>0</script>' }).website, null);
  assert.strictEqual(course({ website: 'file:///etc/passwd' }).website, null);
});

test('une adresse sans schéma est refusée plutôt que complétée', () => {
  // Compléter en `https://` serait deviner. Une adresse qu'on devine n'est pas celle qu'on
  // propose au doigt de quelqu'un.
  assert.strictEqual(course({ website: 'schneiderelectricmarathondeparis.com' }).website, null);
});

test('une vraie adresse passe, http comme https', () => {
  assert.strictEqual(
    course({ website: 'https://www.schneiderelectricmarathondeparis.com' }).website,
    'https://www.schneiderelectricmarathondeparis.com'
  );
  assert.strictEqual(course({ website: 'http://utmb.world/fr' }).website, 'http://utmb.world/fr');
});

test('UNE ADRESSE MAL COLLÉE NE BLOQUE PAS LA CRÉATION DE LA COURSE', () => {
  // Le site est facultatif. Punir quelqu'un d'une course entière pour un copier-coller raté
  // d'un champ optionnel serait disproportionné : on garde la course, on jette l'adresse.
  const c = course({ website: 'pas une adresse du tout' });
  assert.strictEqual(c.website, null);
  assert.strictEqual(c.name, 'Marathon de Paris');
});

test('une adresse trop longue est coupée, pas refusée', () => {
  const longue = 'https://exemple.fr/' + 'a'.repeat(500);
  assert.strictEqual(course({ website: longue }).website.length, 300);
});

test('une adresse avec un espace ou un chevron est refusée', () => {
  // L'espace et `<` sont ce par quoi on sort d'un attribut.
  assert.strictEqual(course({ website: 'https://exemple.fr/a b' }).website, null);
  assert.strictEqual(course({ website: 'https://exemple.fr/"><img' }).website, null);
});

// --- La date ------------------------------------------------------------------------------------

test('LE 31 FÉVRIER EST REFUSÉ', () => {
  // Il passe la forme AAAA-MM-JJ et n'existe pas. Postgres refuserait la ligne avec une erreur
  // 500 ; ici c'est un 400 qui dit laquelle.
  assert.strictEqual(refus({ raceDate: '2027-02-31' }), 'bad_date');
  assert.strictEqual(refus({ raceDate: '2027-13-01' }), 'bad_date');
  assert.strictEqual(refus({ raceDate: '2027-04-00' }), 'bad_date');
});

test('le 29 février d\'une année bissextile passe', () => {
  assert.strictEqual(course({ raceDate: '2028-02-29' }).raceDate, '2028-02-29');
});

test('le 29 février d\'une année non bissextile est refusé', () => {
  assert.strictEqual(refus({ raceDate: '2027-02-29' }), 'bad_date');
});

test('une date mal formée est refusée', () => {
  assert.strictEqual(refus({ raceDate: '11/04/2027' }), 'bad_date');
  assert.strictEqual(refus({ raceDate: '2027-4-11' }), 'bad_date');
  assert.strictEqual(refus({ raceDate: '' }), 'bad_date');
  assert.strictEqual(refus({ raceDate: undefined }), 'bad_date');
  assert.strictEqual(refus({ raceDate: 20270411 }), 'bad_date');
});

test('une date passée est refusée, celle du jour acceptée', () => {
  // La recherche ne rend pas les courses passées : en créer une ne ferait qu'ajouter une ligne
  // que personne ne reverrait jamais.
  assert.strictEqual(refus({ raceDate: '2026-10-23' }), 'past_date');
  assert.strictEqual(refus({ raceDate: '2025-10-25' }), 'past_date');
  assert.strictEqual(course({ raceDate: JOUR }).raceDate, JOUR);
});

test('LA VEILLE PASSE : LE FUSEAU DU TÉLÉPHONE N\'EST PAS CELUI DU SERVEUR', () => {
  // Le jour vient du sélecteur de date de l'app. « Aujourd'hui » à Los Angeles est encore hier à
  // Paris pendant huit heures : refuser au jour près ferait échouer la création d'une course du
  // jour pour tout l'ouest du monde.
  assert.strictEqual(course({ raceDate: '2026-10-24' }).raceDate, '2026-10-24');
});

test('la veille du 1er mars se calcule juste, même une année bissextile', () => {
  // `setUTCDate(0)` sur mars donne le 29 février 2028 et le 28 février 2027.
  assert.strictEqual(nettoyerCourse({ ...base, raceDate: '2028-02-29' }, '2028-03-01').erreur, undefined);
  assert.strictEqual(nettoyerCourse({ ...base, raceDate: '2028-02-28' }, '2028-03-01').erreur, 'past_date');
});

test('un horodatage complet est accepté par sa date', () => {
  // L'app envoie parfois un ISO 8601 entier.
  assert.strictEqual(course({ raceDate: '2027-04-11T08:00:00Z' }).raceDate, '2027-04-11');
});

// --- Le nom -------------------------------------------------------------------------------------

test('un nom vide ou absent est refusé', () => {
  assert.strictEqual(refus({ name: '' }), 'bad_request');
  assert.strictEqual(refus({ name: '   ' }), 'bad_request');
  assert.strictEqual(refus({ name: undefined }), 'bad_request');
  assert.strictEqual(refus({ name: 42 }), 'bad_request');
});

test('UN NOM QUI NE SE REPLIE SUR RIEN EST REFUSÉ', () => {
  // `name_key` sert la recherche ET l'index UNIQUE. Vide, toutes ces courses-là se percuteraient
  // entre elles et la première gagnerait pour toujours.
  assert.strictEqual(refus({ name: '...' }), 'bad_request');
  assert.strictEqual(refus({ name: '---' }), 'bad_request');
});

test('le nom garde ses accents et sa casse, la clé non', () => {
  const c = course({ name: '  Grand Raid de la Réunion  ' });
  assert.strictEqual(c.name, 'Grand Raid de la Réunion');
  assert.strictEqual(c.nameKey, 'grand raid de la reunion');
});

test('un nom trop long est coupé', () => {
  assert.strictEqual(course({ name: 'A'.repeat(300) }).name.length, 120);
});

// --- Les mesures --------------------------------------------------------------------------------

test('une distance plausible est gardée, une aberrante effacée', () => {
  assert.strictEqual(course({ distanceKm: 42.195 }).distanceKm, 42.195);
  assert.strictEqual(course({ distanceKm: '42.195' }).distanceKm, 42.195);
  assert.strictEqual(course({ distanceKm: 0 }).distanceKm, null);
  assert.strictEqual(course({ distanceKm: -10 }).distanceKm, null);
  assert.strictEqual(course({ distanceKm: 99999 }).distanceKm, null);
  assert.strictEqual(course({ distanceKm: 'quarante-deux' }).distanceKm, null);
  assert.strictEqual(course({ distanceKm: undefined }).distanceKm, null);
});

test('un dénivelé non entier ou aberrant est effacé, pas arrondi', () => {
  assert.strictEqual(course({ elevationGainM: 10000 }).elevationGainM, 10000);
  assert.strictEqual(course({ elevationGainM: 0 }).elevationGainM, 0);
  assert.strictEqual(course({ elevationGainM: 1234.5 }).elevationGainM, null);
  assert.strictEqual(course({ elevationGainM: -5 }).elevationGainM, null);
  assert.strictEqual(course({ elevationGainM: 999999 }).elevationGainM, null);
});

// --- La discipline ------------------------------------------------------------------------------

test('une discipline inconnue retombe sur la course à pied', () => {
  // La colonne est NOT NULL et l'app n'a pas de pictogramme pour « quidditch ».
  assert.strictEqual(course({ discipline: 'quidditch' }).discipline, 'run');
  assert.strictEqual(course({ discipline: '' }).discipline, 'run');
  assert.strictEqual(course({ discipline: undefined }).discipline, 'run');
});

test('chacune des disciplines de l\'app est acceptée telle quelle', () => {
  for (const d of DISCIPLINES) {
    assert.strictEqual(course({ discipline: d }).discipline, d);
  }
});

// --- La ville -----------------------------------------------------------------------------------

test('la ville est facultative et nettoyée', () => {
  assert.strictEqual(course({ city: '  Paris ' }).city, 'Paris');
  assert.strictEqual(course({ city: '' }).city, null);
  assert.strictEqual(course({ city: undefined }).city, null);
  assert.strictEqual(course({ city: 'V'.repeat(200) }).city.length, 80);
});

// --- L'entrée elle-même -------------------------------------------------------------------------

test('une entrée absente ne fait pas tomber la fonction', () => {
  // Un corps de requête vide arrive pour de vrai. Il doit donner un 400, pas une exception.
  assert.strictEqual(nettoyerCourse(undefined, JOUR).erreur, 'bad_request');
  assert.strictEqual(nettoyerCourse(null, JOUR).erreur, 'bad_request');
  assert.strictEqual(nettoyerCourse({}, JOUR).erreur, 'bad_request');
});

test('sans jour donné, la fonction prend aujourd\'hui sans se plaindre', () => {
  // Le serveur l'appelle sans second argument.
  const dansDixAns = new Date(Date.now() + 10 * 365 * 86400000).toISOString().slice(0, 10);
  assert.strictEqual(nettoyerCourse({ ...base, raceDate: dansDixAns }).erreur, undefined);
  assert.strictEqual(nettoyerCourse({ ...base, raceDate: '2000-01-01' }).erreur, 'past_date');
});

// --- Les caractéristiques : où, quoi, comment, et comment s'y inscrire ---------------------------
//
// Même règle que `website` : des valeurs CONTRÔLÉES. Une valeur qu'on ne reconnaît pas est effacée,
// jamais corrigée, jamais devinée, et ne bloque pas la création de la course.

test('LE PAYS EST UN CODE ISO EN CAPITALES, SINON RIEN', () => {
  assert.strictEqual(course({ country: 'fr' }).country, 'FR');
  assert.strictEqual(course({ country: ' jp ' }).country, 'JP');
  assert.strictEqual(course({ country: 'RE' }).country, 'RE');
  // Pas un nom de pays : ce serait deviner le code.
  assert.strictEqual(course({ country: 'France' }).country, null);
  assert.strictEqual(course({ country: 'F' }).country, null);
  assert.strictEqual(course({ country: 'FRA' }).country, null);
  assert.strictEqual(course({ country: 42 }).country, null);
  assert.strictEqual(course({ country: undefined }).country, null);
  // Deux lettres de la bonne forme qui ne sont pas un pays.
  assert.strictEqual(course({ country: 'ZZ' }).country, null);
  assert.strictEqual(course({ country: 'UK' }).country, null);
  assert.strictEqual(course({ country: 'DD' }).country, null);
});

test('la recherche par pays comprend les trois langues de l\'app', () => {
  assert.deepStrictEqual(codesPourPays('japon'), ['JP']);
  assert.deepStrictEqual(codesPourPays('japan'), ['JP']);
  assert.deepStrictEqual(codesPourPays('japón'.normalize('NFC').replace('ó', 'o')), ['JP']);
  assert.ok(codesPourPays('allemagne').includes('DE'));
  assert.ok(codesPourPays('germany').includes('DE'));
  assert.ok(codesPourPays('alemania').includes('DE'));
  assert.ok(codesPourPays('etats').includes('US'));
  // « united » : trois pays, et pas l'Union européenne ni les Nations unies.
  assert.deepStrictEqual(codesPourPays('united'), ['AE', 'GB', 'US']);
});

test('on ne cherche pas un pays avec deux lettres', () => {
  // « fr » est le début d'un nom de course, pas une recherche de pays.
  assert.deepStrictEqual(codesPourPays('fr'), []);
  assert.deepStrictEqual(codesPourPays(''), []);
  assert.deepStrictEqual(codesPourPays(undefined), []);
  assert.deepStrictEqual(codesPourPays('zzzzzz'), []);
});

test('plusieurs distances : triées, sans doublon, bornées', () => {
  assert.deepStrictEqual(course({ distancesKm: [42.195, 10, 21.0975, 10] }).distancesKm, [10, 21.0975, 42.195]);
  assert.deepStrictEqual(course({ distancesKm: ['10', 5] }).distancesKm, [5, 10]);
  // Le garbage est ignoré, le reste est gardé.
  assert.deepStrictEqual(course({ distancesKm: [0, -3, 'x', null, 99999, 21] }).distancesKm, [21]);
  const trop = Array.from({ length: 40 }, (_, i) => i + 1);
  assert.strictEqual(course({ distancesKm: trop }).distancesKm.length, FORMATS_MAXIMUM);
});

test('aucune distance valable donne null, pas une liste vide', () => {
  assert.strictEqual(course({ distancesKm: [] }).distancesKm, null);
  assert.strictEqual(course({ distancesKm: [0, 'x'] }).distancesKm, null);
  assert.strictEqual(course({ distancesKm: 'dix' }).distancesKm, null);
  assert.strictEqual(course({ distancesKm: undefined }).distancesKm, null);
});

test('UN SEUL FORMAT EST AUSSI LA DISTANCE, PLUSIEURS NE LA CHOISISSENT PAS', () => {
  // Compatibilité : une app d'avant les formats multiples ne lit que `distanceKm`.
  assert.strictEqual(course({ distancesKm: [42.195] }).distanceKm, 42.195);
  // Plusieurs formats : on n'en annonce pas un seul à la place de l'organisateur.
  assert.strictEqual(course({ distancesKm: [10, 21.0975, 42.195] }).distanceKm, null);
  // Une distance donnée explicitement reste ce qu'elle est.
  assert.strictEqual(course({ distanceKm: 21, distancesKm: [10, 21] }).distanceKm, 21);
});

test('la surface et le profil viennent d\'une liste fermée', () => {
  for (const v of SURFACES) assert.strictEqual(course({ surface: v }).surface, v);
  for (const v of PROFILS) assert.strictEqual(course({ profile: v }).profile, v);
  assert.strictEqual(course({ surface: 'sable' }).surface, null);
  assert.strictEqual(course({ surface: 'ROUTE' }).surface, null);
  assert.strictEqual(course({ profile: 'extrême' }).profile, null);
  assert.strictEqual(course({ surface: undefined }).surface, null);
  assert.strictEqual(course({ profile: {} }).profile, null);
});

test('l\'heure de départ est HH:MM, de 00:00 à 23:59', () => {
  assert.strictEqual(course({ startTime: '08:30' }).startTime, '08:30');
  assert.strictEqual(course({ startTime: ' 05:00 ' }).startTime, '05:00');
  assert.strictEqual(course({ startTime: '23:59' }).startTime, '23:59');
  assert.strictEqual(course({ startTime: '24:00' }).startTime, null);
  assert.strictEqual(course({ startTime: '8:30' }).startTime, null);
  assert.strictEqual(course({ startTime: '08:60' }).startTime, null);
  assert.strictEqual(course({ startTime: '8h30' }).startTime, null);
  assert.strictEqual(course({ startTime: 830 }).startTime, null);
});

test('le statut d\'inscription vient d\'une liste fermée', () => {
  for (const v of STATUTS_INSCRIPTION) assert.strictEqual(course({ registrationStatus: v }).registrationStatus, v);
  assert.strictEqual(course({ registrationStatus: 'open' }).registrationStatus, null);
  assert.strictEqual(course({ registrationStatus: 'Ouverte' }).registrationStatus, null);
  assert.strictEqual(course({ registrationStatus: undefined }).registrationStatus, null);
});

test('L\'ADRESSE D\'INSCRIPTION SUIT LA RÈGLE DU SITE : JAMAIS javascript:', () => {
  assert.strictEqual(course({ registrationUrl: 'javascript:alert(1)' }).registrationUrl, null);
  assert.strictEqual(course({ registrationUrl: 'data:text/html,<script>0</script>' }).registrationUrl, null);
  assert.strictEqual(course({ registrationUrl: 'exemple.fr/inscription' }).registrationUrl, null);
  assert.strictEqual(course({ registrationUrl: 'https://exemple.fr/a b' }).registrationUrl, null);
  assert.strictEqual(course({ registrationUrl: 'https://exemple.fr/inscription' }).registrationUrl,
    'https://exemple.fr/inscription');
  // Trop longue : coupée, comme le site, pas refusée.
  assert.strictEqual(course({ registrationUrl: 'https://exemple.fr/' + 'a'.repeat(500) }).registrationUrl.length, 300);
});

test('le jour d\'ouverture est une vraie date, ou rien', () => {
  assert.strictEqual(course({ registrationOpens: '2027-01-11' }).registrationOpens, '2027-01-11');
  assert.strictEqual(course({ registrationOpens: '2027-01-11T10:00:00Z' }).registrationOpens, '2027-01-11');
  assert.strictEqual(course({ registrationOpens: '2027-02-31' }).registrationOpens, null);
  assert.strictEqual(course({ registrationOpens: '11/01/2027' }).registrationOpens, null);
  assert.strictEqual(course({ registrationOpens: undefined }).registrationOpens, null);
});

test('UNE VALEUR MAL FORMÉE NE BLOQUE PAS LA CRÉATION', () => {
  const c = course({
    country: 'Narnia', distancesKm: 'beaucoup', surface: 'lave', profile: 'raide', startTime: 'à l\'aube',
    registrationStatus: 'peut-être', registrationUrl: 'bientôt', registrationOpens: 'demain',
  });
  assert.strictEqual(c.name, 'Marathon de Paris');
  for (const champ of ['country', 'distancesKm', 'surface', 'profile', 'startTime',
    'registrationStatus', 'registrationUrl', 'registrationOpens']) {
    assert.strictEqual(c[champ], null, champ);
  }
});

test('une course sans caractéristique les rend toutes null', () => {
  // Compatibilité dans l'autre sens : un client d'avant ces champs crée toujours une course.
  const c = course({});
  for (const champ of ['country', 'distancesKm', 'surface', 'profile', 'startTime',
    'registrationStatus', 'registrationUrl', 'registrationOpens']) {
    assert.strictEqual(c[champ], null, champ);
  }
});

test('verifiedOn n\'entre jamais par la porte de création', () => {
  // La date de vérification est la parole du générateur de courses semées, pas celle d'un coureur.
  assert.strictEqual(course({ verifiedOn: '2026-11-22' }).verifiedOn, undefined);
});

// --- Les catégories de distance (filtre « 5 km », « 10 km »… de l'app) ------------------------------
const { categorieDeDistance, filtreDeDistance, FILTRES_DE_DISTANCE, BANDES_DE_DISTANCE } = require('../lib/courses');

test('les distances officielles tombent dans leur catégorie', () => {
  assert.strictEqual(categorieDeDistance(5), '5k');
  assert.strictEqual(categorieDeDistance(10), '10k');
  assert.strictEqual(categorieDeDistance(21.0975), 'semi');
  assert.strictEqual(categorieDeDistance(21.1), 'semi');
  assert.strictEqual(categorieDeDistance(42.195), 'marathon');
});

test('un parcours mesuré un peu long reste dans sa catégorie, une distance voisine non', () => {
  assert.strictEqual(categorieDeDistance(10.1), '10k');
  // Le quart de marathon de Rotterdam n'est pas un 10 km.
  assert.strictEqual(categorieDeDistance(10.55), 'autres');
  assert.strictEqual(categorieDeDistance(16.0934), 'autres'); // 10 miles
  assert.strictEqual(categorieDeDistance(20), 'autres');
  assert.strictEqual(categorieDeDistance(8), 'autres');
});

test('au-delà du marathon, c\'est un ultra', () => {
  assert.strictEqual(categorieDeDistance(43.6), 'ultra');
  assert.strictEqual(categorieDeDistance(78), 'ultra');
  assert.strictEqual(categorieDeDistance(42.5), 'marathon');
});

test('une valeur qui n\'est pas une distance n\'a pas de catégorie', () => {
  for (const v of [0, -5, NaN, null, undefined, 'abc']) assert.strictEqual(categorieDeDistance(v), null);
});

test('un filtre inconnu est ignoré, pas transformé en liste vide', () => {
  for (const f of FILTRES_DE_DISTANCE) assert.strictEqual(filtreDeDistance(f), f);
  for (const f of ['', '42k', 'SEMI', undefined, ['5k']]) assert.strictEqual(filtreDeDistance(f), null);
});

test('les bandes ne se chevauchent pas et vont croissant', () => {
  const bandes = Object.values(BANDES_DE_DISTANCE);
  for (let i = 0; i < bandes.length; i += 1) {
    assert.ok(bandes[i][0] < bandes[i][1]);
    if (i > 0) assert.ok(bandes[i - 1][1] < bandes[i][0]);
  }
});
