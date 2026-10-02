# datamatrixsocial

Instagram landing page + marketing hub for Datamatrix. Static, no build
step — open `index.html` or serve the folder with any static host.

## Layout

- `index.html` — nav, hero offer, about, services, team, process, work, promo, FAQ, contact, footer
- `styles.css` — brand palette + Montserrat/Inter type, responsive nav + grids
- `app.js` — mobile nav toggle, scroll reveal (vanilla JS, no dependencies)
- `webhooks/` — Instagram Webhooks callback (Node + Express, needs Node ≥18);
  see `docs/instagram-webhooks-setup.md`
- `socialcolabz/` — Instagram posting: draft, approve, publish (PowerShell);
  see `docs/socialcolabz.md`
- `ads/` — Marketing API fill-in scripts (create, pause/delete, insights);
  see `docs/meta-ads-runbook.md`
- `.vscode/mcp.json` — Meta Social Technologies MCP wiring (OAuth, no secrets);
  see `docs/meta-mcp-setup.md`
- `assets/hero-neon.png` — neon brand board art (hero background)
- `docs/system-design.md` — architecture, link inventory, hosting, future

## Brand source

`iCloudDrive/Datamatrix social brand kit` (logo sheets, neon board,
Instagram ad creative, Hawk Eye Trade + Sentinel reference work).
`assets/hero-neon.png` is a copy of the neon board — compress to WebP
before deploying (currently ~2.2 MB).

## Links

- Instagram: [@datamatrix_applications](https://instagram.com/datamatrix_applications)
- Email: [hello@datamatrix.io](mailto:hello@datamatrix.io)
- Site: [www.datamatrix.io](https://www.datamatrix.io)
