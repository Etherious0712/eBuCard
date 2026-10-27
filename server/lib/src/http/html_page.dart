// Minimal HTML pages for links opened from emails (email confirmation and
// password reset). Plain, mobile-friendly, no scripts.

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

/// An HTML page with [title] and already-escaped [bodyHtml].
Response htmlPage(
  ServerStrings strings,
  String title, {
  String bodyHtml = '',
  int status = HttpStatus.ok,
}) => Response(
  statusCode: status,
  headers: {
    'content-type': 'text/html; charset=utf-8',
    'cache-control': 'no-store',
    // No scripts, frames or outside resources are needed.
    'content-security-policy':
        "default-src 'none'; style-src 'unsafe-inline'; form-action 'self'; "
        "frame-ancestors 'none'",
    'referrer-policy': 'no-referrer',
  },
  body:
      '''

<!doctype html>
<html lang="${strings.htmlLang}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${escapeHtml(title)} · eBuCard</title>
<style>
body{font-family:system-ui,sans-serif;max-width:28rem;margin:3rem auto;padding:0 1rem;color:#1b1b21;background:#fff}
@media (prefers-color-scheme:dark){body{color:#e4e1e9;background:#131318}input{background:#1f1f25;color:inherit}}
h1{font-size:1.4rem}label{display:block;margin:1rem 0 .3rem}
input{width:100%;padding:.6rem;font-size:1rem;box-sizing:border-box;border:1px solid #888;border-radius:.4rem}
button{margin-top:1.2rem;padding:.7rem 1.2rem;font-size:1rem;border:0;border-radius:.4rem;background:#3f51b5;color:#fff}
.error{color:#b3261e}
</style>
</head>
<body>
<h1>${escapeHtml(title)}</h1>
$bodyHtml
</body>
</html>''',
);
