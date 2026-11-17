// Rend le BALISAGE d'un artboard du canvas en PNG (390 px de large, échelle 3).
// Aucun code du canvas n'est exécuté : ses <script> sont écartés, les trous sont remplis depuis
// un fichier de valeurs transcrit à la main, et la page tourne JavaScript désactivé, réseau coupé.
const fs = require('fs'), path = require('path');
const { chromium } = require('playwright');
const [, , dossier, sortie, police, fichierValeurs, suffixe, ...noms] = process.argv;
const vals = JSON.parse(fs.readFileSync(fichierValeurs, 'utf8'));
const chercher = (o, c) => c.split('.').reduce((x, k) => (x == null ? undefined : x[k]), o);
const remplir = (g, p) => g.replace(/\{\{([\w.]+)\}\}/g, (t, c) => { const v = chercher(p, c); return v == null ? '' : String(v); });
function developper(html) {
  html = html.replace(/ on[A-Z]\w+="\{\{[\w.]+\}\}"/g, '');
  html = html.replace(/<sc-for list="\{\{(\w+)\}\}" as="(\w+)"[^>]*>([\s\S]*?)<\/sc-for>/g,
    (_, liste, nom, corps) => (vals[liste] || []).map(e => remplir(corps, { [nom]: e })).join(''));
  return remplir(html, vals);
}
(async () => {
  const navigateur = await chromium.launch();
  const contexte = await navigateur.newContext({ javaScriptEnabled: false, deviceScaleFactor: 3, viewport: { width: 390, height: 844 } });
  await contexte.route('**/*', r => (r.request().url().startsWith('file://') ? r.continue() : r.abort()));
  for (const nom of noms) {
    const source = fs.readFileSync(path.join(dossier, nom + '.dc.html'), 'utf8').replace(/<script[\s\S]*?<\/script>/g, '');
    const corps = source.match(/<x-dc>([\s\S]*?)<\/x-dc>/)[1];
    const style = (corps.match(/<style>([\s\S]*?)<\/style>/) || [, ''])[1];
    const hauteur = Number(corps.match(/width: 390px; height: (\d+)px/)[1]);
    const page = await contexte.newPage();
    await page.setViewportSize({ width: 390, height: hauteur });
    const html = `<!doctype html><html><head><meta charset="utf-8"><style>
      @font-face { font-family: 'Archivo'; src: url('file://${police}'); font-weight: 500; font-stretch: 100%; }
      @font-face { font-family: 'Archivo'; src: url('file://${police}'); font-weight: 600; font-stretch: 100%; }
      @font-face { font-family: 'Archivo'; src: url('file://${police}'); font-weight: 700; font-stretch: 100%; }
      @font-face { font-family: 'Archivo'; src: url('file://${police}'); font-weight: 800; font-stretch: 125%; }
      ${style}</style></head><body>${developper(corps.replace(/<helmet>[\s\S]*?<\/helmet>/, ''))}</body></html>`;
    const tmp = path.join(sortie, '_' + nom + '.html');
    fs.writeFileSync(tmp, html);
    await page.goto('file://' + tmp);
    await page.waitForTimeout(700);
    await page.screenshot({ path: path.join(sortie, nom + suffixe + '.png') });
    await page.close(); fs.unlinkSync(tmp);
    console.log(nom + suffixe, hauteur);
  }
  await navigateur.close();
})();
