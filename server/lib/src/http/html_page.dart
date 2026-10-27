// HTML pages the server shows people: the public web card and the pages
// opened from emails (email confirmation, password reset). They share one
// look, the eBuCard design system (docs/design-system/ebucard/MASTER.md):
// flat, professional blue, Poppins headings and Open Sans text, light and
// dark. No scripts; fonts come from this server (`public/fonts/`).

import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:ebucard_server/src/email/server_strings.dart';

/// Escapes text for HTML.
String escapeHtml(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');

/// A page from the email links: [title] as the heading, then the
/// already-escaped [bodyHtml], in a card in the middle of the screen.
Response htmlPage(
  ServerStrings strings,
  String title, {
  String bodyHtml = '',
  int status = HttpStatus.ok,
}) => pageResponse(
  strings,
  title: title,
  status: status,
  bodyHtml:
      '''
<main class="sheet">
<h1>${escapeHtml(title)}</h1>
$bodyHtml
</main>''',
);

/// A full HTML page around [bodyHtml] (already escaped). [headHtml] adds
/// tags to `<head>` (e.g. link previews). [cacheControl] defaults to
/// `no-store`, since most pages are personal.
Response pageResponse(
  ServerStrings strings, {
  required String title,
  required String bodyHtml,
  String headHtml = '',
  int status = HttpStatus.ok,
  String cacheControl = 'no-store',
}) => Response(
  statusCode: status,
  headers: {
    'content-type': 'text/html; charset=utf-8',
    'cache-control': cacheControl,
    // Only our own images and fonts; no scripts or frames.
    'content-security-policy':
        "default-src 'none'; style-src 'unsafe-inline'; img-src 'self'; "
        "font-src 'self'; form-action 'self'; frame-ancestors 'none'; "
        "base-uri 'none'",
    'referrer-policy': 'no-referrer',
    'x-content-type-options': 'nosniff',
    // Cards are personal: keep them out of search engines.
    'x-robots-tag': 'noindex, nofollow',
  },
  body:
      '''
<!doctype html>
<html lang="${strings.htmlLang}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex, nofollow">
<meta name="color-scheme" content="light dark">
<title>${escapeHtml(title)} · eBuCard</title>
$headHtml
<style>$pageCss</style>
</head>
<body>
$bodyHtml
</body>
</html>''',
);

/// Styles shared by every page. Colours are design-system tokens; text
/// on them meets WCAG AA contrast (4.5:1) in light and dark mode.
const pageCss = '''
@font-face{font-family:"Poppins";font-weight:600;font-display:swap;src:url(/fonts/Poppins-600-latin.woff2) format("woff2");unicode-range:U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,U+2000-206F,U+20AC,U+2122,U+2212}
@font-face{font-family:"Poppins";font-weight:700;font-display:swap;src:url(/fonts/Poppins-700-latin.woff2) format("woff2");unicode-range:U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,U+2000-206F,U+20AC,U+2122,U+2212}
@font-face{font-family:"Open Sans";font-weight:300 800;font-display:swap;src:url(/fonts/OpenSans-latin.woff2) format("woff2");unicode-range:U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,U+2000-206F,U+20AC,U+2122,U+2212}
:root{--primary:#2563EB;--on-primary:#fff;--accent:#047857;--on-accent:#fff;--bg:#F8FAFC;--card:#fff;--fg:#0F172A;--muted:#475569;--line:#E2E8F0;--soft:#EFF6FF;--danger:#DC2626;--ring:#2563EB;
--heading:"Poppins","PingFang TC","PingFang SC","Noto Sans TC","Noto Sans SC","Microsoft JhengHei","Microsoft YaHei",system-ui,sans-serif;
--text:"Open Sans","PingFang TC","PingFang SC","Noto Sans TC","Noto Sans SC","Microsoft JhengHei","Microsoft YaHei",system-ui,sans-serif}
@media (prefers-color-scheme:dark){:root{--primary:#60A5FA;--on-primary:#0F172A;--accent:#34D399;--on-accent:#052E16;--bg:#0B1120;--card:#162033;--fg:#F1F5F9;--muted:#A3B1C6;--line:#26334A;--soft:#1C2A44;--danger:#F87171;--ring:#93C5FD}}
*{box-sizing:border-box}
html{-webkit-text-size-adjust:100%}
body{margin:0;min-height:100vh;background:var(--bg);color:var(--fg);font:400 1rem/1.5 var(--text);padding:1.5rem 1rem 2.5rem}
h1,h2{font-family:var(--heading);font-weight:700;line-height:1.25;margin:0;text-wrap:balance}
h1{font-size:1.5rem}
p{margin:.75rem 0 0}
a{color:var(--primary)}
a:focus-visible,button:focus-visible,input:focus-visible{outline:3px solid var(--ring);outline-offset:2px}
.sheet,.card{max-width:28rem;margin:0 auto;background:var(--card);border:1px solid var(--line);border-radius:1rem;padding:1.5rem}
.error{color:var(--danger);font-weight:600}
label{display:block;margin:1rem 0 .375rem;font-weight:600}
input{width:100%;min-height:3rem;padding:.625rem .75rem;font:inherit;color:var(--fg);background:var(--bg);border:1px solid var(--muted);border-radius:.5rem}
button,.button{display:flex;align-items:center;justify-content:center;gap:.5rem;width:100%;min-height:3rem;margin-top:1.25rem;padding:.75rem 1rem;font:600 1rem/1.2 var(--heading);border:0;border-radius:.75rem;background:var(--primary);color:var(--on-primary);text-decoration:none;cursor:pointer;transition:filter .15s ease}
button:hover,.button:hover{filter:brightness(1.08)}
.button svg{flex:none;width:1.25rem;height:1.25rem}
.button.save{background:var(--accent);color:var(--on-accent)}
.button.store{background:transparent;color:var(--fg);border:1px solid var(--line);margin-top:.75rem}
.hero{display:flex;gap:1rem;align-items:center}
.avatar{flex:none;width:5rem;height:5rem;border-radius:50%;object-fit:cover;background:var(--soft);color:var(--primary);display:flex;align-items:center;justify-content:center;font:700 1.75rem var(--heading)}
img.avatar{overflow:hidden;color:transparent;font-size:.75rem}
.who{min-width:0}
.who p{margin:.25rem 0 0;color:var(--muted)}
.logo{display:block;max-height:2.5rem;max-width:8rem;margin:0 0 1rem auto;object-fit:contain}
.hint{color:var(--muted);font-size:.875rem;text-align:center}
.rows{list-style:none;margin:1.25rem 0 0;padding:0;border-top:1px solid var(--line)}
.rows li{border-bottom:1px solid var(--line)}
.row{display:flex;align-items:center;gap:.875rem;min-height:3.5rem;padding:.5rem .25rem;color:var(--fg);text-decoration:none;overflow-wrap:anywhere}
a.row:hover{background:var(--soft)}
.row svg{flex:none;width:1.25rem;height:1.25rem;color:var(--primary)}
.row small{display:block;color:var(--muted);font-size:.8125rem}
.foot{max-width:28rem;margin:1.5rem auto 0;text-align:center;color:var(--muted);font-size:.875rem}
.foot h2{font-size:1rem;color:var(--fg);margin-bottom:.25rem}
@media (prefers-reduced-motion:reduce){*{transition:none!important}}
''';
