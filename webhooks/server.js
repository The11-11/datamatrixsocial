"use strict";

/*
 * Instagram Webhooks callback endpoint.
 *
 * GET  /webhooks  — verification handshake (hub.mode / hub.challenge /
 *                    hub.verify_token). Configure this URL in the App
 *                    Dashboard Webhooks product first.
 * POST /webhooks  — event notifications, HMAC-SHA256 validated against
 *                    APP_SECRET via the X-Hub-Signature-256 header.
 * GET  /healthz   — liveness probe, no data.
 * GET  /          — most recent receipts (newest first, max 50). Requires
 *                    "Authorization: Bearer <ADMIN_TOKEN>"; returns 404
 *                    when ADMIN_TOKEN is unset.
 *
 * Env: APP_SECRET (Meta app secret), TOKEN (verify token you choose),
 *      PORT (default 3000). Optional: ADMIN_TOKEN (enables GET /),
 *      DEDUPE_FILE (persist the dedupe store across restarts),
 *      DEDUPE_MAX (dedupe entry cap, default 10000). Serve behind
 *      HTTPS — Meta rejects self-signed certificates.
 */

const crypto = require("crypto");
const fs = require("fs");
const express = require("express");

const APP_SECRET = process.env.APP_SECRET;
const VERIFY_TOKEN = process.env.TOKEN;
const PORT = Number(process.env.PORT) || 3000;
const ADMIN_TOKEN = process.env.ADMIN_TOKEN || "";
const DEDUPE_FILE = process.env.DEDUPE_FILE || "";
const DEDUPE_MAX = Number(process.env.DEDUPE_MAX) || 10000;
const DEDUPE_TTL_MS = 36 * 60 * 60 * 1000; // Meta retries for up to 36h

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
const MAX_STORED = 50;

// Deduplication: key -> expiry (ms). Map keeps insertion order, so the
// oldest entries come first and pruning stops at the first live one.
const seen = new Map();

function pruneSeen(now) {
  for (const [key, expiresAt] of seen) {
    if (expiresAt > now && seen.size <= DEDUPE_MAX) {
      break;
    }
    seen.delete(key);
  }
}

function markSeen(key, now) {
  if (seen.has(key) && seen.get(key) > now) {
    return false; // duplicate delivery
  }
  seen.delete(key);
  seen.set(key, now + DEDUPE_TTL_MS);
  pruneSeen(now);
  scheduleSave();
  return true;
}

function loadSeen() {
  if (!DEDUPE_FILE) {
    return;
  }
  try {
    const entries = JSON.parse(fs.readFileSync(DEDUPE_FILE, "utf8"));
    const now = Date.now();
    for (const [key, expiresAt] of entries) {
      if (typeof key === "string" && Number(expiresAt) > now) {
        seen.set(key, Number(expiresAt));
      }
    }
    pruneSeen(now);
  } catch (err) {
    if (err.code !== "ENOENT") {
      console.error(`dedupe store not loaded: ${err.message}`);
    }
  }
}

let saveTimer = null;

function saveSeen() {
  saveTimer = null;
  const tmp = `${DEDUPE_FILE}.tmp`;
  try {
    fs.writeFileSync(tmp, JSON.stringify([...seen]));
    fs.renameSync(tmp, DEDUPE_FILE);
  } catch (err) {
    console.error(`dedupe store not saved: ${err.message}`);
  }
}

function scheduleSave() {
  if (DEDUPE_FILE && !saveTimer) {
    saveTimer = setTimeout(saveSeen, 1000);
  }
}

function isAdmin(req) {
  const header = req.headers.authorization;
  if (typeof header !== "string" || !header.startsWith("Bearer ")) {
    return false;
  }
  const theirs = crypto.createHash("sha256").update(header.slice("Bearer ".length)).digest();
  const mine = crypto.createHash("sha256").update(ADMIN_TOKEN).digest();
  return crypto.timingSafeEqual(theirs, mine);
}

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

  const now = Date.now();
  for (const entry of body.entry) {
    const changes = Array.isArray(entry.changes) ? entry.changes : [];
    for (const change of changes) {
      const key = `${entry.id}:${entry.time}:${change.field}`;
      if (!markSeen(key, now)) {
        continue; // duplicate delivery — skip
      }
      // Log names only — never values, tokens, or secrets.
      console.log(`webhook instagram entry=${entry.id} field=${change.field}`);
    }
  }

  recent.unshift({ receivedAt: new Date().toISOString(), object: body.object, entryCount: body.entry.length });
  if (recent.length > MAX_STORED) {
    recent.length = MAX_STORED;
  }
});

app.get("/healthz", (_req, res) => {
  res.json({ ok: true });
});

// Receipts listing: hidden unless ADMIN_TOKEN is configured.
app.get("/", (req, res) => {
  if (!ADMIN_TOKEN) {
    res.sendStatus(404);
    return;
  }
  if (!isAdmin(req)) {
    res.sendStatus(401);
    return;
  }
  res.json(recent);
});

loadSeen();

const server = app.listen(PORT, () => {
  console.log(`webhooks listening on port ${PORT}`);
});

function shutdown() {
  if (saveTimer) {
    clearTimeout(saveTimer);
    saveSeen();
  }
  server.close();
  process.exit(0);
}

process.on("SIGTERM", shutdown);
process.on("SIGINT", shutdown);
