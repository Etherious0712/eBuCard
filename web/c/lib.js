// The web card's logic, without the page: read an offline card link,
// turn the card into a vCard, and pick the language. Kept free of the
// DOM so Node tests can run it (web/test/). The format is the one in
// packages/ebucard_models/lib/src/offline_link.dart (DESIGN.md §4.5);
// both sides are tested with packages/ebucard_models/test/fixtures/
// offline_links.json.

/** Format version: the first character of the link data. */
export const VERSION = '1';

/** Longest link data accepted, in characters (real cards are a few hundred). */
export const MAX_DATA_LENGTH = 8000;

/** Largest decompressed card accepted, in bytes ("zip bomb" guard). */
export const MAX_JSON_BYTES = 32 * 1024;

const LABELS = ['work', 'mobile', 'home', 'fax', 'other'];
const NETWORKS = [
  'linkedin', 'wechat', 'whatsapp', 'x', 'facebook',
  'instagram', 'line', 'telegram', 'other',
];

/**
 * The card in version-prefixed link `data` (the part after `#`), as
 * {name, title, company, phones, emails, websites, addresses, socials},
 * or null if it can't be read or has no name.
 */
export async function decodeData(data) {
  if (typeof data !== 'string' || data.length < 2) return null;
  if (data.length > MAX_DATA_LENGTH || data[0] !== VERSION) return null;
  try {
    const packed = base64UrlToBytes(data.slice(1));
    const bytes = await inflateRaw(packed, MAX_JSON_BYTES);
    if (!bytes) return null;
    return normalize(JSON.parse(new TextDecoder().decode(bytes)));
  } catch {
    return null;
  }
}

/** Bytes from base64url text without padding; throws on bad input. */
export function base64UrlToBytes(text) {
  if (!/^[A-Za-z0-9_-]*$/.test(text)) throw new Error('not base64url');
  const b64 = text.replace(/-/g, '+').replace(/_/g, '/');
  const binary = atob(b64.padEnd(Math.ceil(b64.length / 4) * 4, '='));
  return Uint8Array.from(binary, (c) => c.charCodeAt(0));
}

/** Raw-deflate decompression, stopping (null) past `limit` bytes. */
async function inflateRaw(bytes, limit) {
  const stream = new Blob([bytes])
    .stream()
    .pipeThrough(new DecompressionStream('deflate-raw'));
  const reader = stream.getReader();
  const chunks = [];
  let size = 0;
  for (;;) {
    const { done, value } = await reader.read();
    if (done) break;
    size += value.length;
    if (size > limit) {
      await reader.cancel();
      return null;
    }
    chunks.push(value);
  }
  const out = new Uint8Array(size);
  let at = 0;
  for (const c of chunks) {
    out.set(c, at);
    at += c.length;
  }
  return out;
}

/**
 * The card from compact JSON (keys n, t, o, p, e, w, a, s). Unknown labels
 * become "other"; malformed parts are skipped, as in the Dart reader.
 */
export function normalize(json) {
  if (!json || typeof json !== 'object' || Array.isArray(json)) return null;
  const text = (v) => (typeof v === 'string' ? v.trim() : '');
  const rows = (v) =>
    Array.isArray(v)
      ? v.filter(Array.isArray).map((r) => r.map(text))
      : [];
  const label = (l) => (LABELS.includes(l) ? l : 'other');
  const at = (r, i) => (i < r.length ? r[i] : '');
  const name = text(json.n);
  if (!name) return null;
  return {
    name,
    title: text(json.t),
    company: text(json.o),
    phones: rows(json.p)
      .filter((r) => at(r, 1))
      .map((r) => ({ label: label(at(r, 0)), value: at(r, 1) })),
    emails: rows(json.e)
      .filter((r) => at(r, 1))
      .map((r) => ({ label: label(at(r, 0)), value: at(r, 1) })),
    websites: Array.isArray(json.w) ? json.w.map(text).filter(Boolean) : [],
    addresses: rows(json.a)
      .filter((r) => r.slice(1).some(Boolean))
      .map((r) => ({
        label: label(at(r, 0)),
        street: at(r, 1),
        city: at(r, 2),
        region: at(r, 3),
        postalCode: at(r, 4),
        country: at(r, 5),
      })),
    socials: rows(json.s)
      .filter((r) => at(r, 1))
      .map((r) => ({
        network: NETWORKS.includes(at(r, 0)) ? at(r, 0) : 'other',
        value: at(r, 1),
      })),
  };
}

/**
 * vCard 3.0 for `card`, identical to the app's VCardEncoder (full form,
 * no images): same fields, escaping and 75-octet line folding.
 */
export function toVCard(card) {
  const esc = (v) =>
    v.replace(/\\/g, '\\\\').replace(/\n/g, '\\n').replace(/,/g, '\\,')
      .replace(/;/g, '\\;');
  const labelType = (l) =>
    ({ work: 'WORK', home: 'HOME', mobile: 'CELL', fax: 'FAX' })[l] ?? 'OTHER';
  const telType = (l) =>
    l === 'mobile' ? 'CELL' : l === 'fax' ? 'FAX' : labelType(l);
  const parts = card.name.trim().split(/\s+/);
  const structured = parts.length < 2
    ? `${esc(card.name.trim())};;;;`
    : `${esc(parts[parts.length - 1])};${esc(parts.slice(0, -1).join(' '))};;;`;
  const lines = [
    'BEGIN:VCARD',
    'VERSION:3.0',
    `FN:${esc(card.name)}`,
    `N:${structured}`,
  ];
  if (card.company) lines.push(`ORG:${esc(card.company)}`);
  if (card.title) lines.push(`TITLE:${esc(card.title)}`);
  for (const p of card.phones) lines.push(`TEL;TYPE=${telType(p.label)}:${esc(p.value)}`);
  for (const e of card.emails) {
    lines.push(`EMAIL;TYPE=INTERNET,${labelType(e.label)}:${esc(e.value)}`);
  }
  for (const w of card.websites) lines.push(`URL:${esc(w)}`);
  for (const a of card.addresses) {
    const adr = ['', '', a.street, a.city, a.region, a.postalCode, a.country]
      .map(esc)
      .join(';');
    lines.push(`ADR;TYPE=${labelType(a.label)}:${adr}`);
  }
  for (const s of card.socials) {
    lines.push(`X-SOCIALPROFILE;TYPE=${s.network}:${esc(s.value)}`);
  }
  lines.push('END:VCARD');
  return `${lines.map(fold).join('\r\n')}\r\n`;
}

/** Folds a line at 75 UTF-8 octets without splitting a character. */
function fold(line) {
  let out = '';
  let octets = 0;
  for (const ch of line) {
    const cp = ch.codePointAt(0);
    const size = cp < 0x80 ? 1 : cp < 0x800 ? 2 : cp < 0x10000 ? 3 : 4;
    if (octets + size > 75) {
      out += '\r\n ';
      octets = 1;
    }
    out += ch;
    octets += size;
  }
  return out;
}

/**
 * The page language for the browser's preferred `languages`, with the
 * app's rules: Chinese with Hant or a TW/HK/MO region is Traditional,
 * other Chinese is Simplified, everything else English.
 */
export function pickLanguage(languages) {
  for (const tag of languages ?? []) {
    const parts = String(tag).toLowerCase().replace(/_/g, '-').split('-');
    if (parts[0] === 'en') return 'en';
    if (parts[0] !== 'zh') continue;
    if (parts.includes('hant') || parts.some((p) => ['tw', 'hk', 'mo'].includes(p))) {
      return 'zh-Hant';
    }
    return 'zh-Hans';
  }
  return 'en';
}

/** Up to two initials, as in the app and the server's web card. */
export function initials(name) {
  const words = name.trim().split(/\s+/).filter(Boolean);
  if (words.length === 0) return '?';
  const first = [...words[0]][0];
  if (words.length === 1) return first.toUpperCase();
  return (first + [...words[words.length - 1]][0]).toUpperCase();
}

/** `tel:` link with only digits and +, or null. */
export function telUri(number) {
  const digits = number.replace(/[^0-9+]/g, '');
  return digits.replace(/\+/g, '') ? `tel:${digits}` : null;
}

/**
 * An http(s) link for `text`, or null. A bare domain gets https:// unless
 * `requireScheme`; any other scheme (javascript:, data:, ...) is refused.
 */
export function webUri(text, requireScheme = false) {
  const value = text.trim();
  const scheme = /^([a-z][a-z0-9+.-]*):/i.exec(value)?.[1]?.toLowerCase();
  if (scheme === 'http' || scheme === 'https') {
    try {
      return new URL(value).host ? value : null;
    } catch {
      return null;
    }
  }
  if (requireScheme || scheme || /\s/.test(value)) return null;
  try {
    return new URL(`https://${value}`).host.includes('.')
      ? `https://${value}`
      : null;
  } catch {
    return null;
  }
}
