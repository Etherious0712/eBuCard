# eBuCard web card (GitHub Pages)

Static pages, no server: `c/` shows the card inside an offline card link
(`https://etherious0712.github.io/eBuCard/c/#1<data>`, DESIGN.md §4.5).
The card is after `#`, so it never reaches GitHub; `c/card.js` decodes it in
the browser.

| File | What |
|---|---|
| `c/index.html`, `c/card.js` | The page: card, Save contact (.vcf made in the browser), Open in eBuCard (`ebucard://`), Download for Android |
| `c/lib.js` | Decoding, vCard, language and safe-link rules; no DOM, tested in Node |
| `c/card.css` | Styles, copied from the server's web card (`server/lib/src/http/html_page.dart`); keep in step |
| `fonts/` | Poppins and Open Sans (Latin, OFL) |
| `index.html` | Home page |
| `test/` | `node --test web/test/*.test.mjs`, using the app's test vectors (`packages/ebucard_models/test/fixtures/offline_links.json`) |

Local preview: `cd web && python3 -m http.server 8000`, then open
`http://localhost:8000/c/#<data>` (copy a link from the app's QR screen).

**Publishing:** `.github/workflows/pages.yml` tests and publishes on every
change to `main`. One-time setup: repository **Settings → Pages → Build and
deployment → Source: GitHub Actions**.
