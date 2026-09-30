# datamatrixsocial — system design

Marketing site architecture for the Datamatrix Instagram landing page.

## Goal

Turn Instagram traffic into project applications: hero offer (14-day
MVP), services, sharing promo, contact paths. Fast, dependency-free,
no build step, no backend.

## Non-goals

- No CMS, analytics, or tracking.
- No framework migration until the page needs dynamic content
  (see "Future" below).

## Structure

```text
datamatrixsocial/
├── index.html           # nav, hero, about, services, team, process, work, promo, FAQ, contact, footer
├── styles.css           # brand palette, Montserrat/Inter, responsive nav + grids
├── app.js               # mobile nav toggle + scroll reveal (vanilla JS)
├── assets/
│   └── hero-neon.png    # neon brand board art, hero background (~2.2 MB)
├── README.md            # overview + link inventory
└── docs/
    └── system-design.md # this file
```

## Brand system (from the brand kit)

| Token  | Value       | Use                          |
| ------ | ----------- | ---------------------------- |
| Navy   | `#060B1A`   | page background              |
| Blue   | `#008FFF`   | wordmark, primary CTA, links |
| Cyan   | `#00F0FF`   | headlines, accents, promo    |
| Orange | `#FF8A00`   | cost line, secondary accents |
| Red    | `#FF2E2E`   | sparing — alerts only        |
| Silver | `#E9F1FF`   | body text                    |

Type: Montserrat (headings/wordmark), Inter (body/UI) via Google Fonts
with system fallbacks. Palette and voice follow the brand kit sheets
(`iCloudDrive/Datamatrix social brand kit`); the offer copy mirrors the
Instagram ad creative (14-day MVP, half time / half cost, 3 developers,
share-5-times ChatGPT Plus promo at R4 788, T&Cs apply).

## Link inventory

| Label     | URL                                            |
| --------- | ---------------------------------------------- |
| Instagram | <https://instagram.com/datamatrix_applications> |
| Email     | <mailto:hello@datamatrix.io>                   |
| Website   | <https://www.datamatrix.io>                    |

The apply CTA is a `mailto:` to hello@datamatrix.io. If applications
need tracking later, point it at a form endpoint instead.

## Hosting

Any static host works (GitHub Pages, Netlify, Vercel, S3). Serve the
repo root; the entry point is `index.html`. No environment variables,
no secrets — every link is public. Before deploying, compress
`assets/hero-neon.png` (export a cropped WebP of the banner portion).

## Webhooks service (`webhooks/`)

Separate Node + Express process, not part of the static page: `GET
/webhooks` answers Meta's verification handshake, `POST /webhooks`
HMAC-validates (`X-Hub-Signature-256`, `timingSafeEqual`), acks 200
before processing, dedupes retried deliveries, and logs field names
only. Requires `APP_SECRET` + `TOKEN` env, public HTTPS (TLS at the
host), and the dashboard-first ordering: callback verified before any
`/subscribed_apps` call. Full steps in
`docs/instagram-webhooks-setup.md`.

## Attribution

Footer carries a "Powered by Meta" line.

## Future

- Migrate to the Next.js setup used by `sentinel-cloud/web` if the hub
  needs dynamic content (feed embeds, forms, i18n).
- Extract links into `links.json` + vanilla JS rendering once the list
  grows past ~5 entries.
