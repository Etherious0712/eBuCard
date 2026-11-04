// Tests for the web card's logic (web/c/lib.js), with the same test
// vectors as the Dart offline-link reader. Run: node --test web/test
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { deflateRawSync } from 'node:zlib';
import { test } from 'node:test';

import {
  decodeData, initials, pickLanguage, telUri, toVCard, webUri,
} from '../c/lib.js';

const vectors = JSON.parse(
  readFileSync(
    new URL('../../packages/ebucard_models/test/fixtures/offline_links.json', import.meta.url),
  ),
);

/** Link data for compact JSON `json`, as the app makes it. */
const encode = (json) =>
  '1' + deflateRawSync(Buffer.from(JSON.stringify(json))).toString('base64url');

test('reads every link the app makes, and Save contact matches the app', async () => {
  for (const v of vectors) {
    const card = await decodeData(v.data);
    assert.equal(card.name, v.card.n);
    assert.equal(toVCard(card), v.vcard);
  }
});

test('broken, foreign and oversized links are not cards', async () => {
  assert.equal(await decodeData(''), null);
  assert.equal(await decodeData('2' + vectors[0].data.slice(1)), null);
  assert.equal(await decodeData('1!!!'), null);
  assert.equal(await decodeData('1' + vectors[0].data.slice(1, 20)), null);
  assert.equal(await decodeData('1' + 'A'.repeat(9000)), null);
  assert.equal(await decodeData(encode({ t: 'no name' })), null);
  // A tiny link that inflates to far more than any card.
  const bomb = '1' + deflateRawSync(Buffer.alloc(200000, 32)).toString('base64url');
  assert.ok(bomb.length < 8000);
  assert.equal(await decodeData(bomb), null);
});

test('unknown labels become other; malformed rows are skipped', async () => {
  const card = await decodeData(encode({
    n: 'A',
    p: [['satellite', '123'], 'x', ['mobile']],
    s: [['myspace', 'a']],
    w: ['ok.example', 5],
  }));
  assert.deepEqual(card.phones, [{ label: 'other', value: '123' }]);
  assert.deepEqual(card.socials, [{ network: 'other', value: 'a' }]);
  assert.deepEqual(card.websites, ['ok.example']);
});

test('language follows the browser like the app', () => {
  assert.equal(pickLanguage(['zh-HK', 'en']), 'zh-Hant');
  assert.equal(pickLanguage(['zh-Hant-TW']), 'zh-Hant');
  assert.equal(pickLanguage(['zh-CN']), 'zh-Hans');
  assert.equal(pickLanguage(['fr-FR', 'zh']), 'zh-Hans');
  assert.equal(pickLanguage(['fr-FR']), 'en');
  assert.equal(pickLanguage([]), 'en');
});

test('only safe links are made from card text', () => {
  assert.equal(telUri('+852 9123 4567'), 'tel:+85291234567');
  assert.equal(telUri('ext. only'), null);
  assert.equal(webUri('acme.example'), 'https://acme.example');
  assert.equal(webUri('https://x.example/a'), 'https://x.example/a');
  assert.equal(webUri('javascript:alert(1)'), null);
  assert.equal(webUri('data:text/html,hi'), null);
  assert.equal(webUri('jane_chan', true), null);
  assert.equal(webUri('not a site'), null);
  assert.equal(initials('Jane Chan'), 'JC');
  assert.equal(initials('陳大文'), '陳');
});
