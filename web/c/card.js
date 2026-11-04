// The web card page (web/c/index.html): reads the card from the link after
// "#", shows it like the server's web card, and offers Save contact (a
// .vcf made in the browser), Open in eBuCard (ebucard:// app link) and,
// except on iPhone/iPad, Download eBuCard for Android.
//
// Everything shown comes from whoever made the link, so the page only
// uses textContent (never innerHTML) and only links http(s), tel: and
// mailto: values (lib.js).

import {
  decodeData, initials, pickLanguage, telUri, toVCard, webUri,
} from './lib.js';

/** Where the Android app is downloaded (the latest GitHub release). */
const DOWNLOAD_URL = 'https://github.com/Etherious0712/eBuCard/releases/latest';

/** Page text, in the app's three languages. */
const STRINGS = {
  en: {
    saveContact: 'Save contact',
    saveContactHint: "Adds this card to your phone's contacts.",
    openInApp: 'Open in eBuCard',
    openInAppHint: 'If eBuCard is installed on this phone.',
    getApp: 'Exchange cards with eBuCard',
    download: 'Download eBuCard for Android',
    sharedWith: 'Shared with eBuCard',
    brokenTitle: 'This card link is incomplete',
    brokenBody: 'Part of the link may be missing. Ask for the card again.',
    oldBrowserTitle: 'Please update your browser',
    oldBrowserBody: 'This page needs a newer browser to show the card.',
    emptyTitle: 'eBuCard',
    emptyBody: 'Open a card link someone shared with you to see their card here.',
    labels: { work: 'Work', mobile: 'Mobile', home: 'Home', fax: 'Fax', other: 'Other' },
  },
  'zh-Hant': {
    saveContact: '儲存聯絡人',
    saveContactHint: '把這張名片加入手機通訊錄。',
    openInApp: '在 eBuCard 中開啟',
    openInAppHint: '適用於已安裝 eBuCard 的手機。',
    getApp: '用 eBuCard 交換名片',
    download: '下載 Android 版 eBuCard',
    sharedWith: '透過 eBuCard 分享',
    brokenTitle: '此名片連結不完整',
    brokenBody: '連結可能缺少了部分內容，請對方再次分享名片。',
    oldBrowserTitle: '請更新你的瀏覽器',
    oldBrowserBody: '此頁面需要較新的瀏覽器才能顯示名片。',
    emptyTitle: 'eBuCard',
    emptyBody: '開啟別人分享給你的名片連結，即可在這裡查看名片。',
    labels: { work: '公司', mobile: '手機', home: '住宅', fax: '傳真', other: '其他' },
  },
  'zh-Hans': {
    saveContact: '保存联系人',
    saveContactHint: '把这张名片添加到手机通讯录。',
    openInApp: '在 eBuCard 中打开',
    openInAppHint: '适用于已安装 eBuCard 的手机。',
    getApp: '用 eBuCard 交换名片',
    download: '下载 Android 版 eBuCard',
    sharedWith: '通过 eBuCard 分享',
    brokenTitle: '此名片链接不完整',
    brokenBody: '链接可能缺少了部分内容，请对方再次分享名片。',
    oldBrowserTitle: '请更新你的浏览器',
    oldBrowserBody: '此页面需要较新的浏览器才能显示名片。',
    emptyTitle: 'eBuCard',
    emptyBody: '打开别人分享给你的名片链接，即可在这里查看名片。',
    labels: { work: '工作', mobile: '手机', home: '住宅', fax: '传真', other: '其他' },
  },
};

/** Social network names (brand names stay in English). */
const NETWORKS = {
  linkedin: 'LinkedIn', wechat: 'WeChat', whatsapp: 'WhatsApp', x: 'X',
  facebook: 'Facebook', instagram: 'Instagram', line: 'LINE', telegram: 'Telegram',
  other: '',
};

/** Line icons (Lucide, ISC licence), as on the server's web card. */
const ICONS = {
  phone: ['M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z'],
  mail: ['M4 4h16a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2z', 'm22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7'],
  globe: ['M12 2a10 10 0 1 0 0 20 10 10 0 1 0 0-20', 'M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20', 'M2 12h20'],
  pin: ['M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z', 'M12 7a3 3 0 1 0 0 6 3 3 0 1 0 0-6'],
  link: ['M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71', 'M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71'],
  add: ['M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2', 'M9 3a4 4 0 1 0 0 8 4 4 0 1 0 0-8', 'M19 8v6M22 11h-6'],
};

const lang = pickLanguage(navigator.languages ?? [navigator.language]);
const t = STRINGS[lang];
document.documentElement.lang = lang;

/** An element with optional class and text. */
function el(tag, className, text) {
  const node = document.createElement(tag);
  if (className) node.className = className;
  if (text !== undefined) node.textContent = text;
  return node;
}

/** A decorative inline SVG icon. */
function icon(name) {
  const ns = 'http://www.w3.org/2000/svg';
  const svg = document.createElementNS(ns, 'svg');
  for (const [k, v] of Object.entries({
    viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2',
    'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'aria-hidden': 'true',
  })) svg.setAttribute(k, v);
  for (const d of ICONS[name]) {
    const path = document.createElementNS(ns, 'path');
    path.setAttribute('d', d);
    svg.append(path);
  }
  return svg;
}

/** One contact row; a link when `href` is given. */
function row(iconName, value, label, href) {
  const li = el('li');
  const box = href ? el('a', 'row') : el('div', 'row');
  if (href) {
    box.href = href;
    box.rel = 'noopener noreferrer nofollow';
  }
  const span = el('span', '', value);
  if (label) span.append(el('small', '', label));
  box.append(icon(iconName), span);
  li.append(box);
  return li;
}

/** Shows a message instead of a card. */
function showMessage(title, body) {
  document.title = `${title} · eBuCard`;
  const main = document.getElementById('card');
  main.replaceChildren(el('h1', '', title), el('p', '', body));
}

/** Shows `card`, made from the link data `data`. */
function showCard(card, data) {
  document.title = `${card.name} · eBuCard`;
  const main = document.getElementById('card');
  const subtitle = [card.title, card.company].filter(Boolean).join(' · ');

  const hero = el('div', 'hero');
  const avatar = el('div', 'avatar', initials(card.name));
  avatar.setAttribute('aria-hidden', 'true');
  const who = el('div', 'who');
  who.append(el('h1', '', card.name));
  if (subtitle) who.append(el('p', '', subtitle));
  hero.append(avatar, who);

  const save = el('a', 'button save');
  save.href = '#';
  save.append(icon('add'), document.createTextNode(t.saveContact));
  save.addEventListener('click', (event) => {
    event.preventDefault();
    const blob = new Blob([toVCard(card)], { type: 'text/vcard;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const a = el('a');
    a.href = url;
    a.download = `${card.name.replace(/[\\/:*?"<>|]/g, '_') || 'card'}.vcf`;
    document.body.append(a);
    a.click();
    a.remove();
    setTimeout(() => URL.revokeObjectURL(url), 10000);
  });

  const rows = el('ul', 'rows');
  const L = t.labels;
  for (const p of card.phones) {
    rows.append(row('phone', p.value, L[p.label], p.label === 'fax' ? null : telUri(p.value)));
  }
  for (const e of card.emails) {
    rows.append(row('mail', e.value, L[e.label], `mailto:${encodeURIComponent(e.value).replace(/%40/g, '@')}`));
  }
  for (const w of card.websites) rows.append(row('globe', w, null, webUri(w)));
  for (const a of card.addresses) {
    const text = [a.street, a.city, a.region, a.postalCode, a.country].filter(Boolean).join(', ');
    rows.append(row('pin', text, L[a.label], null));
  }
  for (const s of card.socials) {
    const shown = s.value.replace(/^https?:\/\/(www\.)?/, '');
    rows.append(row('link', shown, NETWORKS[s.network] || null, webUri(s.value, true)));
  }

  const open = el('a', 'button open', t.openInApp);
  open.href = `ebucard://card/receive/${data}`;
  const openNote = el('p', 'note', t.openInAppHint);

  main.replaceChildren(hero, save, el('p', 'hint', t.saveContactHint));
  if (rows.children.length) main.append(rows);
  if (isPhone()) main.append(open, openNote);

  const foot = document.getElementById('foot');
  foot.replaceChildren();
  if (!isApple()) {
    const download = el('a', 'button store', t.download);
    download.href = DOWNLOAD_URL;
    download.rel = 'noopener noreferrer';
    foot.append(el('h2', '', t.getApp), download);
  }
  foot.append(el('p', '', t.sharedWith));
}

/** iPhone or iPad (no App Store version yet, so no download button). */
function isApple() {
  return /iPhone|iPad|iPod/.test(navigator.userAgent) ||
    (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
}

/** A phone or tablet, where Open in eBuCard can work. */
function isPhone() {
  return isApple() || /Android/.test(navigator.userAgent);
}

/** Reads the link and shows the card or a message. */
async function main() {
  const data = location.hash.slice(1);
  if (!data) return showMessage(t.emptyTitle, t.emptyBody);
  if (typeof DecompressionStream === 'undefined') {
    return showMessage(t.oldBrowserTitle, t.oldBrowserBody);
  }
  const card = await decodeData(data);
  if (!card) return showMessage(t.brokenTitle, t.brokenBody);
  showCard(card, data);
}

window.addEventListener('hashchange', main);
main();
