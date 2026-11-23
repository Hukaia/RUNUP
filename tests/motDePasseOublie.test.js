// Les règles du mot de passe oublié. Voir `lib/motDePasseOublie.js`.
const test = require('node:test');
const assert = require('node:assert');
const {
  DUREE_DU_CODE_MINUTES, ESSAIS_PAR_CODE,
  nouveauCode, normaliserLeCode, empreinteDuCode, empreintesIdentiques, etatDeLaDemande, courrielDuCode,
} = require('../lib/motDePasseOublie');

test('un code fait toujours six chiffres, y compris quand il commence par zéro', () => {
  for (let i = 0; i < 500; i++) assert.match(nouveauCode(), /^\d{6}$/);
});

test("le code tapé tolère les espaces et les tirets, et rien d'autre", () => {
  assert.strictEqual(normaliserLeCode('123 456'), '123456');
  assert.strictEqual(normaliserLeCode(' 123-456 '), '123456');
  assert.strictEqual(normaliserLeCode(123456), '123456');
  assert.strictEqual(normaliserLeCode('12345'), null);
  assert.strictEqual(normaliserLeCode('1234567'), null);
  assert.strictEqual(normaliserLeCode('12345a'), null);
  assert.strictEqual(normaliserLeCode(null), null);
  assert.strictEqual(normaliserLeCode({}), null);
});

test("l'empreinte dépend du code, du compte et du secret", () => {
  const e = empreinteDuCode('123456', 'u1', 's');
  assert.strictEqual(e, empreinteDuCode('123456', 'u1', 's'));
  assert.notStrictEqual(e, empreinteDuCode('123457', 'u1', 's'));
  // Le même code ne vaut pas pour un autre compte.
  assert.notStrictEqual(e, empreinteDuCode('123456', 'u2', 's'));
  assert.notStrictEqual(e, empreinteDuCode('123456', 'u1', 'autre'));
  assert.ok(!e.includes('123456'), "le code ne doit pas se lire dans l'empreinte");
});

test('deux empreintes ne sont identiques que si elles le sont vraiment', () => {
  const e = empreinteDuCode('123456', 'u1', 's');
  assert.strictEqual(empreintesIdentiques(e, e), true);
  assert.strictEqual(empreintesIdentiques(e, empreinteDuCode('654321', 'u1', 's')), false);
  assert.strictEqual(empreintesIdentiques(e, e.slice(1)), false);
  assert.strictEqual(empreintesIdentiques(e, undefined), false);
});

test("une demande expirée est expirée, même s'il lui restait des essais", () => {
  const maintenant = new Date('2026-11-23T12:00:00Z');
  assert.strictEqual(etatDeLaDemande(null, maintenant), 'absente');
  assert.strictEqual(etatDeLaDemande({ expires_at: '2026-11-23T11:59:59Z', attempts: 0 }, maintenant), 'expire');
  assert.strictEqual(etatDeLaDemande({ expires_at: '2026-11-23T12:00:00Z', attempts: 0 }, maintenant), 'expire');
  assert.strictEqual(etatDeLaDemande({ expires_at: 'pas une date', attempts: 0 }, maintenant), 'expire');
});

test('le cinquième essai raté ferme le code, le quatrième non', () => {
  const maintenant = new Date('2026-11-23T12:00:00Z');
  const plusTard = '2026-11-23T12:10:00Z';
  assert.strictEqual(etatDeLaDemande({ expires_at: plusTard, attempts: ESSAIS_PAR_CODE - 1 }, maintenant), 'essayer');
  assert.strictEqual(etatDeLaDemande({ expires_at: plusTard, attempts: ESSAIS_PAR_CODE }, maintenant), 'trop_d_essais');
  assert.strictEqual(etatDeLaDemande({ expires_at: plusTard }, maintenant), 'essayer');
});

test('le courriel porte le code et sa durée, dans les trois langues, et retombe sur le français', () => {
  for (const langue of ['fr', 'en', 'es', 'xx', undefined]) {
    const c = courrielDuCode('042917', langue);
    assert.ok(c.subject.includes('042917'));
    assert.ok(c.text.includes('042917'));
    assert.ok(c.text.includes(String(DUREE_DU_CODE_MINUTES)));
    assert.ok(c.html.includes('042917'));
    assert.ok(!c.html.includes('<script'));
  }
  assert.strictEqual(courrielDuCode('042917', 'xx').subject, courrielDuCode('042917', 'fr').subject);
  assert.notStrictEqual(courrielDuCode('042917', 'en').subject, courrielDuCode('042917', 'fr').subject);
});
