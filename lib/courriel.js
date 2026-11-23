// L'ENVOI D'UN COURRIEL, par Resend.
//
// Le serveur n'envoyait aucun courriel. Le mot de passe oublié en a besoin d'un, et un seul.
// Pas de dépendance : l'API de Resend est un POST JSON, et `fetch` est dans Node.
//
// DEUX VARIABLES D'ENVIRONNEMENT, posées sur Vercel :
//   · RESEND_API_KEY : la clé. Absente, rien ne part, et `courrielDisponible()` le dit pour que
//     la route réponde « pas disponible » au lieu de faire croire à un envoi.
//   · RESEND_FROM : l'expéditeur, sur un domaine VÉRIFIÉ chez Resend. Sans elle, l'adresse par
//     défaut ci-dessous, qui suppose que hukaia.com est vérifié.
const EXPEDITEUR_PAR_DEFAUT = 'Haizo <contact@hukaia.com>';

function courrielDisponible() {
  return Boolean(process.env.RESEND_API_KEY);
}

/// Envoie un courriel. Rend true si Resend l'a accepté. Ne lève jamais : un envoi raté ne doit
/// pas transformer une demande en erreur 500, et l'appelant décide quoi dire.
async function envoyerUnCourriel({ to, subject, text, html }) {
  if (!courrielDisponible()) return false;
  try {
    const reponse = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        authorization: `Bearer ${process.env.RESEND_API_KEY}`,
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        from: process.env.RESEND_FROM || EXPEDITEUR_PAR_DEFAUT,
        to: [to], subject, text, html,
      }),
      signal: AbortSignal.timeout(8000),
    });
    if (!reponse.ok) console.error('courriel refusé par Resend', reponse.status);
    return reponse.ok;
  } catch (e) {
    console.error('courriel non envoyé', e && e.message);
    return false;
  }
}

module.exports = { courrielDisponible, envoyerUnCourriel };
