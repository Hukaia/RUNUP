// MOT DE PASSE OUBLIÉ : les règles, sans base ni réseau.
//
// Un compte créé avec une adresse et un mot de passe n'avait aucune issue quand le mot de passe
// était perdu : pas de lien, pas de code, pas de route. Compte perdu, avec son historique côté
// club. Ce module porte ce qui se décide : le code, sa durée de vie, le nombre d'essais, et le
// texte du courriel. Les routes (`api/auth/[action].js`) n'y ajoutent que la base et l'envoi.
//
// UN CODE À SIX CHIFFRES, ET NON UN LIEN. Un lien demande une page web qui reçoit le jeton et un
// lien universel pour rouvrir l'app ; un code se lit dans le courriel et se tape dans l'app, sur le
// même téléphone ou un autre. Six chiffres ne résistent pas à la force brute, donc ce n'est pas le
// code qui protège : ce sont les CINQ ESSAIS et le QUART D'HEURE. Cinq essais sur un million, puis
// il faut un nouveau code, lui-même plafonné par jour.
const crypto = require('crypto');

const DUREE_DU_CODE_MINUTES = 15;
const ESSAIS_PAR_CODE = 5;
const DEMANDES_PAR_ADRESSE_ET_PAR_JOUR = 5;
const DEMANDES_PAR_IP_ET_PAR_JOUR = 20;
const ESSAIS_PAR_IP_ET_PAR_JOUR = 40;

/// Six chiffres tirés par le générateur cryptographique. `Math.random` suffit pour un code de
/// club qu'on lit à voix haute, pas pour ce qui ouvre un compte.
function nouveauCode() {
  return String(crypto.randomInt(0, 1000000)).padStart(6, '0');
}

/// Ce qu'on a tapé, ramené à six chiffres, ou null. Les espaces et les tirets qu'un clavier ou
/// un copier-coller ajoute ne doivent pas faire échouer un bon code.
function normaliserLeCode(saisi) {
  if (typeof saisi !== 'string' && typeof saisi !== 'number') return null;
  const chiffres = String(saisi).replace(/[\s-]/g, '');
  return /^\d{6}$/.test(chiffres) ? chiffres : null;
}

/// L'empreinte gardée en base à la place du code : une fuite de la table ne donne pas les codes
/// en clair. Liée au compte, pour qu'un code ne vaille que pour celui qui l'a demandé, et au
/// secret du serveur quand il existe.
function empreinteDuCode(code, userId, secret) {
  return crypto.createHmac('sha256', String(secret || 'haizo')).update(`${userId}:${code}`).digest('hex');
}

/// Comparaison à temps constant de deux empreintes.
function empreintesIdentiques(a, b) {
  if (typeof a !== 'string' || typeof b !== 'string' || a.length !== b.length) return false;
  return crypto.timingSafeEqual(Buffer.from(a), Buffer.from(b));
}

/// Ce qu'on fait d'une demande en cours AVANT de comparer le code : 'expire', 'trop_d_essais',
/// ou 'essayer'. L'ordre compte : un code expiré est expiré, même s'il lui restait des essais.
function etatDeLaDemande(ligne, maintenant = new Date()) {
  if (!ligne) return 'absente';
  const fin = new Date(ligne.expires_at).getTime();
  if (!Number.isFinite(fin) || fin <= maintenant.getTime()) return 'expire';
  if ((ligne.attempts || 0) >= ESSAIS_PAR_CODE) return 'trop_d_essais';
  return 'essayer';
}

const TEXTES = {
  fr: {
    sujet: (code) => `Ton code Haizo : ${code}`,
    corps: (code) => [
      `Voici ton code pour choisir un nouveau mot de passe sur Haizo : ${code}`,
      '',
      `Il est valable ${DUREE_DU_CODE_MINUTES} minutes. Tape-le dans l'app, à l'écran « Mot de passe oublié ».`,
      '',
      "Si tu n'as rien demandé, ignore ce message : ton mot de passe ne change pas.",
    ],
  },
  en: {
    sujet: (code) => `Your Haizo code: ${code}`,
    corps: (code) => [
      `Here is your code to choose a new Haizo password: ${code}`,
      '',
      `It is valid for ${DUREE_DU_CODE_MINUTES} minutes. Type it in the app, on the "Forgot password" screen.`,
      '',
      "If you didn't ask for this, ignore this message: your password stays the same.",
    ],
  },
  es: {
    sujet: (code) => `Tu código de Haizo: ${code}`,
    corps: (code) => [
      `Este es tu código para elegir una nueva contraseña en Haizo: ${code}`,
      '',
      `Es válido durante ${DUREE_DU_CODE_MINUTES} minutos. Escríbelo en la app, en la pantalla «Contraseña olvidada».`,
      '',
      'Si no has pedido nada, ignora este mensaje: tu contraseña no cambia.',
    ],
  },
};

/// Le courriel, dans la langue de l'app. Une langue inconnue retombe sur le français, qui est la
/// langue de l'app, plutôt que d'envoyer un message vide.
function courrielDuCode(code, langue) {
  const t = TEXTES[langue] || TEXTES.fr;
  const lignes = t.corps(code);
  const echappe = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  return {
    subject: t.sujet(code),
    text: lignes.join('\n'),
    html: lignes.map((l) => (l ? `<p>${echappe(l)}</p>` : '')).join(''),
  };
}

module.exports = {
  DUREE_DU_CODE_MINUTES, ESSAIS_PAR_CODE,
  DEMANDES_PAR_ADRESSE_ET_PAR_JOUR, DEMANDES_PAR_IP_ET_PAR_JOUR, ESSAIS_PAR_IP_ET_PAR_JOUR,
  nouveauCode, normaliserLeCode, empreinteDuCode, empreintesIdentiques, etatDeLaDemande, courrielDuCode,
};
