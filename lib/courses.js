// Ce qu'on accepte quand quelqu'un crée une course.
//
// Extrait du handler pour une raison précise : `website` finit en LIEN TAPABLE sur la page de la
// course. Un champ libre qu'on affiche est une chose ; un champ libre qu'on rend tapable en est
// une autre, et `javascript:` n'est pas une adresse de site. La règle vit donc ici, seule, avec
// ses tests — plutôt qu'au milieu de quarante lignes d'insertion.
const { normaliser } = require('./recherche');

// Les familles d'épreuves qu'une course peut porter — les mêmes que les objectifs de l'app.
const DISCIPLINES = ['run', 'trail', 'hyrox', 'triathlon', 'duathlon'];

const LONGUEUR_NOM = 120;
const LONGUEUR_VILLE = 80;
const LONGUEUR_SITE = 300;

// LES CARACTÉRISTIQUES D'UNE COURSE (db/schema.sql, bloc « caractéristiques »).
//
// Des valeurs CONTRÔLÉES, jamais du texte libre : ce que la page affiche, elle l'a reconnu. Une
// valeur qu'on ne connaît pas n'est pas une erreur (la course se crée sans), même règle que
// `website` : punir une course entière pour un détail facultatif serait disproportionné.
const SURFACES = ['route', 'trail', 'piste', 'mixte'];
const PROFILS = ['plat', 'vallonne', 'montagneux'];
// 'ouverte' : on peut s'inscrire maintenant. 'tirage_au_sort' : les places sont attribuées par
// tirage au sort. 'bientot' : pas encore ouverte. 'complete' : toutes les places sont prises.
// 'fermee' : les inscriptions sont closes sans être complètes (ou le tirage est passé).
const STATUTS_INSCRIPTION = ['ouverte', 'tirage_au_sort', 'bientot', 'complete', 'fermee'];
// Au plus douze formats pour un même événement (le Marathon du Mont-Blanc en compte sept).
const FORMATS_MAXIMUM = 12;
// « HH:MM » en heure locale, de 00:00 à 23:59.
const HEURE = /^([01]\d|2[0-3]):[0-5]\d$/;

// Seulement http(s). Tout le reste — `javascript:`, `data:`, `file:` — est refusé plutôt que
// nettoyé : une adresse qu'on ne reconnaît pas n'a aucune raison d'être proposée au doigt de
// quelqu'un.
const SITE = /^https?:\/\/[^\s<>"]+$/i;
const DATE_ISO = /^\d{4}-\d{2}-\d{2}$/;

// Les dates se comparent comme des chaînes : en ISO, l'ordre alphabétique EST l'ordre
// chronologique. Pas de fuseau, pas de `Date` locale, pas de course qui disparaît à minuit selon
// l'endroit d'où on la crée.
function aujourdhuiUTC() {
  return new Date().toISOString().slice(0, 10);
}

function veille(jour) {
  const d = new Date(jour + 'T00:00:00Z');
  d.setUTCDate(d.getUTCDate() - 1);
  return d.toISOString().slice(0, 10);
}

function texte(valeur, longueur) {
  return typeof valeur === 'string' && valeur.trim() ? valeur.trim().slice(0, longueur) : null;
}

function jourValide(valeur) {
  if (typeof valeur !== 'string') return null;
  const jour = valeur.slice(0, 10);
  if (!DATE_ISO.test(jour)) return null;
  const d = new Date(jour + 'T00:00:00Z');
  return !Number.isNaN(d.getTime()) && d.toISOString().slice(0, 10) === jour ? jour : null;
}

// Les 249 codes ISO 3166-1 alpha-2 attribués (plus XK, que les sources courantes emploient pour le
// Kosovo). `Intl` en connaît d'autres : réservations exceptionnelles (UK, EU, UN…) et pays qui
// n'existent plus (DD, YU, SU) : « Allemagne de l'Est » ne doit pas répondre à « allemagne ». Une
// course n'est pas organisée à « l'Union européenne ».
const CODES_ISO = new Set((
  'AD AE AF AG AI AL AM AO AQ AR AS AT AU AW AX AZ BA BB BD BE BF BG BH BI BJ BL BM BN BO ' +
  'BQ BR BS BT BV BW BY BZ CA CC CD CF CG CH CI CK CL CM CN CO CR CU CV CW CX CY CZ DE DJ ' +
  'DK DM DO DZ EC EE EG EH ER ES ET FI FJ FK FM FO FR GA GB GD GE GF GG GH GI GL GM GN GP ' +
  'GQ GR GS GT GU GW GY HK HM HN HR HT HU ID IE IL IM IN IO IQ IR IS IT JE JM JO JP KE KG ' +
  'KH KI KM KN KP KR KW KY KZ LA LB LC LI LK LR LS LT LU LV LY MA MC MD ME MF MG MH MK ML ' +
  'MM MN MO MP MQ MR MS MT MU MV MW MX MY MZ NA NC NE NF NG NI NL NO NP NR NU NZ OM PA PE ' +
  'PF PG PH PK PL PM PN PR PS PT PW PY QA RE RO RS RU RW SA SB SC SD SE SG SH SI SJ SK SL ' +
  'SM SN SO SR SS ST SV SX SY SZ TC TD TF TG TH TJ TK TL TM TN TO TR TT TV TW TZ UA UG UM ' +
  'US UY UZ VA VC VE VG VI VN VU WF WS YE YT ZA ZM ZW XK '
).trim().split(/\s+/));

// Les noms de pays, dans les trois langues de l'app, repliés comme la recherche les replie.
// Calculé UNE fois : 249 codes, trois langues, à peine une milliseconde. `Intl` rend le
// code lui-même pour une région qu'il ne connaît pas, et « Unknown Region » pour `ZZ` : ni l'un ni
// l'autre n'est un pays.
const PAYS = (() => {
  const noms = new Map();
  try {
    const langues = ['fr', 'en', 'es'].map((l) => new Intl.DisplayNames([l], { type: 'region' }));
    for (let a = 65; a <= 90; a += 1) {
      for (let b = 65; b <= 90; b += 1) {
        const code = String.fromCharCode(a, b);
        if (!CODES_ISO.has(code)) continue;
        const lus = langues.map((l) => {
          try { return l.of(code); } catch { return null; }
        });
        if (!lus[1] || lus[1] === code || /unknown/i.test(lus[1])) continue;
        noms.set(code, lus.filter(Boolean).map((n) => normaliser(n)));
      }
    }
  } catch {
    // Un moteur sans `Intl.DisplayNames` : la table reste vide, `pays()` se rabat sur la forme.
  }
  return noms;
})();

// « jp » → « JP ». Deux lettres connues d'ISO 3166-1, sinon null. Sans table (moteur sans Intl),
// la forme seule décide : mieux vaut un code plausible qu'une page sans pays.
function pays(valeur) {
  if (typeof valeur !== 'string') return null;
  const code = valeur.trim().toUpperCase();
  if (!/^[A-Z]{2}$/.test(code)) return null;
  return PAYS.size === 0 || PAYS.has(code) ? code : null;
}

// Les codes dont un des noms (français, anglais, espagnol) COMMENCE par ce qui est tapé :
// « japon » → JP, « united » → GB et US. `besoin` est déjà replié. En dessous de trois lettres on
// ne cherche pas : « fr » n'est pas une recherche de pays, c'est le début d'un nom de course.
function codesPourPays(besoin) {
  if (typeof besoin !== 'string' || besoin.length < 3) return [];
  const trouves = [];
  for (const [code, noms] of PAYS) {
    if (noms.some((n) => n.startsWith(besoin))) trouves.push(code);
  }
  return trouves;
}

// Les formats d'un événement : des nombres plausibles, sans doublon, du plus court au plus long.
// Rend null plutôt qu'une liste vide : « aucun format connu » et « une liste vide » ne sont pas la
// même chose pour l'app, qui n'affiche pas la ligne dans le premier cas.
function formats(valeur) {
  if (!Array.isArray(valeur)) return null;
  const vus = new Set();
  for (const brut of valeur.slice(0, FORMATS_MAXIMUM * 2)) {
    const km = Number(brut);
    if (!Number.isFinite(km) || km <= 0 || km > 1000) continue;
    vus.add(Math.round(km * 10000) / 10000);
  }
  const liste = [...vus].sort((a, b) => a - b).slice(0, FORMATS_MAXIMUM);
  return liste.length > 0 ? liste : null;
}

// Rend `{ erreur }` ou `{ course }`. Ne touche à aucune base : c'est de la validation pure, et
// c'est ce qui la rend vérifiable sans serveur.
function nettoyerCourse(entree, aujourdhui) {
  const brut = entree || {};
  const jour = typeof aujourdhui === 'string' && DATE_ISO.test(aujourdhui) ? aujourdhui : aujourdhuiUTC();

  const name = texte(brut.name, LONGUEUR_NOM);
  if (!name) return { erreur: 'bad_request' };

  const nameKey = normaliser(name);
  // Un nom qui ne contient que de la ponctuation se replie en chaîne vide : il ne pourrait ni
  // se chercher, ni se dédoublonner.
  if (!nameKey) return { erreur: 'bad_request' };

  const raceDate = typeof brut.raceDate === 'string' ? brut.raceDate.slice(0, 10) : '';
  if (!DATE_ISO.test(raceDate)) return { erreur: 'bad_date' };
  // Une date que `Date` refuse — le 31 février, par exemple — passe la forme mais n'existe pas.
  const verif = new Date(raceDate + 'T00:00:00Z');
  if (Number.isNaN(verif.getTime()) || verif.toISOString().slice(0, 10) !== raceDate) {
    return { erreur: 'bad_date' };
  }
  // Et dans le futur. Une page de course passée n'a plus personne à réunir : la recherche ne la
  // rendrait pas, donc la créer ne ferait qu'ajouter une ligne que personne ne reverrait jamais.
  //
  // LA VEILLE EST ACCEPTÉE, ET C'EST VOLONTAIRE. Le jour vient du sélecteur de date de l'app,
  // donc du fuseau du téléphone ; « aujourd'hui » à Los Angeles est encore hier à Paris pendant
  // huit heures. Refuser au jour près ferait échouer la création d'une course du jour pour tout
  // l'ouest du monde, sans rien dire d'utile. Un jour de marge ferme la question.
  if (raceDate < veille(jour)) return { erreur: 'past_date' };

  const km = Number(brut.distanceKm);
  // 1000 km : au-delà, c'est une faute de frappe, pas une course. Le record du monde des 24 h
  // tourne autour de 300.
  let distanceKm = Number.isFinite(km) && km > 0 && km <= 1000 ? km : null;
  const distancesKm = formats(brut.distancesKm);
  // Un seul format : c'est aussi LA distance, que les versions de l'app d'avant les formats
  // multiples lisent encore. Plusieurs formats : `distanceKm` reste ce qu'on a donné, ou null, et
  // n'est jamais choisi à la place de l'organisateur.
  if (distanceKm === null && distancesKm && distancesKm.length === 1) distanceKm = distancesKm[0];

  const d = brut.elevationGainM;
  const elevationGainM = Number.isInteger(d) && d >= 0 && d <= 30000 ? d : null;

  const discipline = DISCIPLINES.includes(brut.discipline) ? brut.discipline : 'run';

  const siteBrut = texte(brut.website, LONGUEUR_SITE);
  // Une adresse refusée n'est pas une erreur : la course se crée sans. Bloquer la création d'une
  // course pour un champ facultatif mal collé serait la punir pour un détail.
  const website = siteBrut && SITE.test(siteBrut) ? siteBrut : null;

  // L'adresse d'inscription suit la règle du site, mot pour mot : elle finit, elle aussi, en lien
  // tapable sous le doigt de quelqu'un d'autre.
  const inscriptionBrute = texte(brut.registrationUrl, LONGUEUR_SITE);
  const registrationUrl = inscriptionBrute && SITE.test(inscriptionBrute) ? inscriptionBrute : null;

  return {
    course: {
      name,
      nameKey,
      city: texte(brut.city, LONGUEUR_VILLE),
      raceDate,
      distanceKm,
      elevationGainM,
      discipline,
      website,
      country: pays(brut.country),
      distancesKm,
      surface: SURFACES.includes(brut.surface) ? brut.surface : null,
      profile: PROFILS.includes(brut.profile) ? brut.profile : null,
      startTime: typeof brut.startTime === 'string' && HEURE.test(brut.startTime.trim())
        ? brut.startTime.trim() : null,
      registrationStatus: STATUTS_INSCRIPTION.includes(brut.registrationStatus)
        ? brut.registrationStatus : null,
      registrationUrl,
      registrationOpens: jourValide(brut.registrationOpens),
    },
  };
}

// LES DISTANCES QU'ON CHERCHE (filtre « 5 km », « 10 km »… de l'app).
//
// Une course entre dans une catégorie si L'UN de ses formats y tombe : un événement qui propose un
// 10 km et un semi répond aux deux. Les bornes laissent la marge des parcours réels (un 10 km
// mesuré à 10,1 km, un semi annoncé « 21,1 ») sans avaler les distances voisines : le quart de
// marathon de Rotterdam (10,55 km) n'est pas un 10 km, il est rangé dans « autres ».
// Les mêmes bornes vivent dans l'app (Haizo/Models/RaceEvent.swift, `FiltreDeDistance`) ;
// `ci_scripts/check_bandes_distance.py` refuse qu'elles divergent.
const BANDES_DE_DISTANCE = {
  '5k': [4.8, 5.2],
  '10k': [9.7, 10.3],
  semi: [20.9, 21.3],
  marathon: [41.9, 42.5],
};
// Au-delà de la borne haute du marathon : ultra.
const ULTRA_AU_DELA_DE = BANDES_DE_DISTANCE.marathon[1];
const FILTRES_DE_DISTANCE = ['5k', '10k', 'semi', 'marathon', 'ultra', 'autres'];

/// La catégorie d'UN format, en kilomètres. null pour une valeur qui n'est pas une distance.
function categorieDeDistance(km) {
  const d = Number(km);
  if (!Number.isFinite(d) || d <= 0) return null;
  for (const [cle, [bas, haut]] of Object.entries(BANDES_DE_DISTANCE)) {
    if (d >= bas && d <= haut) return cle;
  }
  return d > ULTRA_AU_DELA_DE ? 'ultra' : 'autres';
}

/// Le filtre demandé, s'il est connu ; null sinon (un filtre inconnu est ignoré, jamais une liste vide).
function filtreDeDistance(valeur) {
  return FILTRES_DE_DISTANCE.includes(valeur) ? valeur : null;
}

module.exports = {
  DISCIPLINES, SURFACES, PROFILS, STATUTS_INSCRIPTION, FORMATS_MAXIMUM,
  nettoyerCourse, codesPourPays, jourValide, pays,
  BANDES_DE_DISTANCE, ULTRA_AU_DELA_DE, FILTRES_DE_DISTANCE, categorieDeDistance, filtreDeDistance,
  LONGUEUR_NOM, LONGUEUR_VILLE, LONGUEUR_SITE,
};
