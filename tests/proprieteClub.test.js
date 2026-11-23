// À qui revient un club quand sa créatrice le quitte. Voir `lib/proprieteClub.js`.
const test = require('node:test');
const assert = require('node:assert');
const { heritierDuClub } = require('../lib/proprieteClub');

const m = (userId, joinedAt, role = 'member') => ({ userId, role, joinedAt });

test("l'organisateur le plus ancien hérite, même arrivé après un simple membre", () => {
  const membres = [
    m('creatrice', '2026-01-01'),
    m('membre-ancien', '2026-01-02'),
    m('orga-recent', '2026-03-01', 'organiser'),
    m('orga-ancien', '2026-02-01', 'organiser'),
  ];
  assert.strictEqual(heritierDuClub(membres, 'creatrice'), 'orga-ancien');
});

test("sans organisateur, le membre le plus ancien hérite", () => {
  const membres = [m('creatrice', '2026-01-01'), m('b', '2026-02-10'), m('a', '2026-02-01')];
  assert.strictEqual(heritierDuClub(membres, 'creatrice'), 'a');
});

test("seule dans son club : pas d'héritier, l'appelant supprime le club", () => {
  assert.strictEqual(heritierDuClub([m('creatrice', '2026-01-01')], 'creatrice'), null);
  assert.strictEqual(heritierDuClub([], 'creatrice'), null);
  assert.strictEqual(heritierDuClub(undefined, 'creatrice'), null);
});

test("la partante n'hérite jamais d'elle-même, même organisatrice et la plus ancienne", () => {
  const membres = [m('creatrice', '2025-01-01', 'organiser'), m('b', '2026-02-10')];
  assert.strictEqual(heritierDuClub(membres, 'creatrice'), 'b');
});

test("à ancienneté égale, le choix est stable d'un appel à l'autre", () => {
  const membres = [m('creatrice', '2026-01-01'), m('z', '2026-02-01'), m('k', '2026-02-01')];
  assert.strictEqual(heritierDuClub(membres, 'creatrice'), 'k');
  assert.strictEqual(heritierDuClub([...membres].reverse(), 'creatrice'), 'k');
});

test("une date illisible range le membre en dernier au lieu de faire échouer le choix", () => {
  const membres = [m('creatrice', '2026-01-01'), m('sans-date', 'pas une date'), m('b', '2026-02-10')];
  assert.strictEqual(heritierDuClub(membres, 'creatrice'), 'b');
});
