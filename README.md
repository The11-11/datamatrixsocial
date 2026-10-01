# datamatrixsocial

Instagram landing page + marketing hub for Datamatrix. Static, no build
step — open `index.html` or serve the folder with any static host.

## Layout

- `index.html` — nav, hero offer, about, services, team, process, work, promo, FAQ, contact, footer
- `styles.css` — brand palette + Montserrat/Inter type, responsive nav + grids
- `app.js` — mobile nav toggle, scroll reveal (vanilla JS, no dependencies)
- `webhooks/` — Instagram Webhooks callback (Node + Express, needs Node ≥18);
  see `docs/instagram-webhooks-setup.md`
- `ads/` — Marketing API fill-in scripts (create, pause/delete, insights);
  see `docs/meta-ads-runbook.md`
- `.vscode/mcp.json` — Meta Social Technologies MCP wiring (OAuth, no secrets);
  see `docs/meta-mcp-setup.md`
- `assets/hero-banner.webp` — hero background (banner crop of the neon
  board, ~90 KB), with `assets/hero-banner.png` as the fallback
- `assets/hero-neon.png` — full neon brand board (source, not served)
- `docs/system-design.md` — architecture, link inventory, hosting, future

## Brand source

`iCloudDrive/Datamatrix social brand kit` (logo sheets, neon board,
Instagram ad creative, Hawk Eye Trade + Sentinel reference work).
`assets/hero-neon.png` is a copy of the neon board. The hero uses the
banner strip cropped from it (`hero-banner.webp` / `.png`).

## Links

- Instagram: [@datamatrix_applications](https://instagram.com/datamatrix_applications)
- Email: [hello@datamatrix.io](mailto:hello@datamatrix.io)
- Site: [www.datamatrix.io](https://www.datamatrix.io)
