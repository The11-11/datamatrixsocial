"use strict";

/*
 * Instagram Webhooks callback endpoint.
 *
 * GET  /webhooks  — verification handshake (hub.mode / hub.challenge /
 *                    hub.verify_token). Configure this URL in the App
 *                    Dashboard Webhooks product first.
 * POST /webhooks  — event notifications, HMAC-SHA256 validated against
 *                    APP_SECRET via the X-Hub-Signature-256 header.
 * GET  /          — most recent notifications (newest first, max 50).
 *
 * Env: APP_SECRET (Meta app secret), TOKEN (verify token you choose),
 *      PORT (default 3000). Serve behind HTTPS — Meta rejects
 *      self-signed certificates.
 */

const crypto = require("crypto");
const express = require("express");

const APP_SECRET = process.env.APP_SECRET;
const VERIFY_TOKEN = process.env.TOKEN;
const PORT = Number(process.env.PORT) || 3000;

if (!APP_SECRET || !VERIFY_TOKEN) {
  console.error("Missing required env: set APP_SECRET and TOKEN.");
  process.exit(1);
}

const app = express();

// Keep the raw body: the HMAC must be computed over the exact bytes Meta sent.
app.use(
  "/webhooks",
  express.json({
    verify: (req, _res, buf) => {
      req.rawBody = buf;
    },
  })
);

const recent = []; // newest first, capped below
const seen = new Set(); // deduplication (Meta retries for up to 36h)
const MAX_STORED = 50;

function isValidSignature(req) {
  const header = req.headers["x-hub-signature-256"];
  if (typeof header !== "string" || !header.startsWith("sha256=")) {
    return false;
  }
  const theirs = Buffer.from(header.slice("sha256=".length), "hex");
  const mine = crypto.createHmac("sha256", APP_SECRET).update(req.rawBody).digest();
  return theirs.length === mine.length && crypto.timingSafeEqual(theirs, mine);
}

// --- verification handshake ---
app.get("/webhooks", (req, res) => {
  const mode = req.query["hub.mode"];
  const token = req.query["hub.verify_token"];
  const challenge = req.query["hub.challenge"];

  if (mode === "subscribe" && token === VERIFY_TOKEN && typeof challenge === "string") {
    res.status(200).send(challenge);
  } else {
    res.sendStatus(403);
  }
});

// --- event notifications ---
app.post("/webhooks", (req, res) => {
  if (!isValidSignature(req)) {
    res.sendStatus(401);
    return;
  }

  // Acknowledge first; do slow work after responding.
  res.sendStatus(200);

  const body = req.body;
  if (!body || body.object !== "instagram" || !Array.isArray(body.entry)) {
    return;
  }

  for (const entry of body.entry) {
    const changes = Array.isArray(entry.changes) ? entry.changes : [];
    for (const change of changes) {
      const key = `${entry.id}:${entry.time}:${change.field}`;
      if (seen.has(key)) {
        continue; // duplicate delivery — skip
      }
      seen.add(key);
      // Log names only — never values, tokens, or secrets.
      console.log(`webhook instagram entry=${entry.id} field=${change.field}`);
    }
  }

  recent.unshift({ receivedAt: new Date().toISOString(), object: body.object, entryCount: body.entry.length });
  if (recent.length > MAX_STORED) {
    recent.length = MAX_STORED;
  }
});

app.get("/", (_req, res) => {
  res.json(recent);
});

app.listen(PORT, () => {
  console.log(`webhooks listening on port ${PORT}`);
});
