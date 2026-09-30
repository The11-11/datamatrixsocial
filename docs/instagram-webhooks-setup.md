# Instagram Webhooks setup

Callback first, subscription second. Maps to the Meta Webhooks guide;
code lives in `webhooks/server.js`.

## 0. Prerequisites (yours to provide)

- Meta app with the Webhooks product, **Live** before it receives
  notifications for app users.
- `APP_SECRET` — App Dashboard → Settings → Basic.
- `TOKEN` — a verify-token string you invent (e.g. 32+ random chars).
- Public HTTPS host with a valid cert (self-signed is rejected).
  This Express app speaks HTTP — terminate TLS at the host / load
  balancer / tunnel.
- Instagram Login: Instagram professional account + User access token.
  Facebook Login: linked Facebook Page + Page access token.

## 1. Run the endpoint

```sh
cd webhooks
npm install
APP_SECRET=<app-secret> TOKEN=<verify-token> PORT=3000 npm start
```

Health: `GET /` returns `[]` until notifications arrive.
Automated local exercise: `powershell -File test-local.ps1` (challenge
echo, 403s, valid/invalid signatures, duplicate delivery, receipts).

## 2. Configure the Webhooks product (App Dashboard)

1. Open your app → Webhooks → add callback URL:
   `https://<your-host>/webhooks`, verify token = `TOKEN` value.
2. Meta sends the `GET` verification handshake
   (`hub.mode=subscribe`, `hub.challenge`, `hub.verify_token`).
   The endpoint echoes the challenge only when the token matches,
   else 403. Dashboard shows whether validation passed.

## 3. Subscribe to fields, then enable the account

1. In the dashboard, select the Instagram fields the app needs
   (comments / live_comments need Advanced Access; account must be
   public for comment/mention notifications).
2. Instagram Login — subscribe the account (comma-separated fields):

```sh
curl -i -X POST \
  "https://graph.instagram.com/v26.0/<INSTAGRAM_ACCOUNT_ID>/subscribed_apps?subscribed_fields=<WEBHOOK_FIELDS>&access_token=<INSTAGRAM_USER_ACCESS_TOKEN>"
```

Facebook Login — same call against the linked Page:

```sh
curl -i -X POST \
  "https://graph.facebook.com/v26.0/<FACEBOOK_PAGE_ID>/subscribed_apps?subscribed_fields=<WEBHOOK_FIELDS>&access_token=<FACEBOOK_PAGE_ACCESS_TOKEN>"
```

Success returns `{"success": true}`.

## 4. How notifications are handled

- Every `POST /webhooks` must carry `X-Hub-Signature-256: sha256=…`.
  The server recomputes the HMAC over the raw body with `APP_SECRET`
  and compares with `timingSafeEqual`. Mismatch → 401, no processing.
- Valid payloads get `200` immediately; field processing happens
  after the response so slow work can't time out delivery.
- Deliveries dedupe on `entry.id + time + field` (Meta retries up to
  36h). Only field *names* are logged — never values or secrets.
- `story_insights` covers the first 24h of metrics only, even on
  highlights. Payloads never include album IDs or ad IDs — query them
  from the comment ID.

## 5. mTLS (server / load-balancer level, not app code)

If you enable mTLS: trust the Meta outbound API CA
(`meta-outbound-api-ca-2025-12.pem`), verify the client cert chain,
and check the CN equals `client.webhooks.fbclientcerts.com`
(Nginx: `ssl_verify_client` + `$ssl_client_s_dn`; ALB: trust store +
`X-Amzn-Mtls-Clientcert-Subject` header).

## 6. Test delivery

1. Dashboard → Webhooks → **Test** a field → Send to My Server →
   confirm it lands in `GET /`.
2. Trigger a real event on the connected account; confirm 200s and
   no duplicate actions from retries.
3. Compare payloads against Meta's webhook examples.

## Troubleshooting

Callback unreachable → HTTPS + cert; wrong fields → dashboard
selection; nothing for a user → `/subscribed_apps` call + matching
token/login setup; missing comments → Advanced Access + public
account. Never put tokens, secrets, or credentials in logs.
