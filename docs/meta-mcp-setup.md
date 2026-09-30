# Meta Social Technologies MCP

Gives an MCP-capable agent (VS Code Copilot, Codex, Claude, Cursor) a
single entry point for day-to-day Meta app work: read app config,
monitor API health, check App Review, manage webhook subscriptions,
look up the changelog, search dev docs. Config is already wired in
`.vscode/mcp.json` — no secrets in the repo; auth is OAuth in your
browser. Beta: interface and tools may change, and access rolls out
gradually.

## Connect (VS Code)

1. Open this repo folder in VS Code.
2. Allow the `meta_social_technologies` server when prompted.
3. Complete Meta OAuth sign-in in the browser; grant the apps to manage.
4. Verify: ask the agent to list tools on the `meta social
   technologies` server (expect 11 `devtools_` tools), then run
   `devtools_app_list`.

## Scopes (per app, Business Integrations settings)

- **Read** — config, App Review, compliance, API health, webhook
  topics/subscriptions. Start here.
- **Manage** — adds webhook subscribe/unsubscribe/update and test
  payloads (test sends make Meta deliver a real event to the
  callback). Grant when wiring or testing webhooks, e.g. the
  `https://www.datamatrixHubsa.com/webhooks` subscription.

## Useful first prompts (this repo's context)

- "List my Meta apps and their App Review status."
- "List webhook topics and subscriptions for app <APP_ID>."
- "Is app <APP_ID> near any rate limits? Any deprecations?"
- "Send a test event to the comments field for app <APP_ID>."
  (Manage scope; confirms `webhooks/server.js` receives + validates.)

## Notes

- This CLI session itself cannot use MCP tools — the wiring lights up
  agents inside MCP-capable clients, not here.
- Re-auth is needed when the client restarts; revoke anytime at
  facebook.com → Settings → Business Integrations.
