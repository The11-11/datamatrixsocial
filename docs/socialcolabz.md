# SocialColabz — Instagram posting

Draft → you approve → publish. Scripts live in `socialcolabz/`; each post
is one JSON file in `socialcolabz/posts/` that records its own state
(`draft`, `approved`, `published`), so git history doubles as a post log.
Uses the Instagram API with Instagram Login (`graph.instagram.com`).

## 0. One-time setup (yours to do, in the App Dashboard)

App: **Datamatrix_HubSA** (`2139588153438351`). It can stay in
Development mode: posting to an account that has a role on the app
needs no App Review.

1. developers.facebook.com → your app → **Add use case** → the
   Instagram one ("Manage messaging & content on Instagram"), API setup
   with **Instagram business login**.
2. **App roles → Roles → Add people → Instagram Tester**, enter
   `datamatrix_applications`. Accept the invite in Instagram:
   Settings → Website permissions → Apps and websites → Tester invites.
   The account must be a Business or Creator (professional) account.
3. Back in the Instagram use case → **Generate access tokens** → add the
   account and sign in. Permissions needed:
   `instagram_business_basic`, `instagram_business_content_publish`.
4. Copy the token into an environment variable, never into the repo or
   chat:

   ```powershell
   [Environment]::SetEnvironmentVariable("IG_ACCESS_TOKEN", "<TOKEN>", "User")
   ```

   Open a new terminal afterwards. The token lasts 60 days; run
   `refresh-token.ps1` before then and store the new one the same way.

## 1. Draft

```powershell
cd socialcolabz
powershell -File new-post.ps1 -Name '2026-10-launch' -ImageUrl 'https://<host>/post.jpg' -CaptionFile caption.txt -AltText '<describe the image>'
```

The image must be a **JPEG at a public https URL** when you publish
(Meta downloads it then). Captions: 2,200 characters, 30 hashtags max.

## 2. Approve

```powershell
powershell -File approve-post.ps1 -Post posts\2026-10-launch.json
```

Shows the post and asks you to type `APPROVE`. Changing the image URL,
caption or alt text afterwards voids the approval; approve again.

## 3. Publish

```powershell
powershell -File publish-post.ps1 -Post posts\2026-10-launch.json
```

Refuses anything not approved or already published. Checks the 24-hour
publishing quota, creates the media container, waits for it to finish,
publishes, then writes `media_id` and `permalink` into the post file.
Commit the file so the repo shows what went out.

## Limits and errors

- Single-image feed posts only for now (no carousels, reels or stories).
- 50 API-published posts per account per 24 hours (the script checks).
- Error code 190: token expired or wrong → regenerate (step 0.3).
- Container `ERROR`: usually the image is not a reachable JPEG.
- If the connected Facebook Page needs Page Publishing Authorization,
  complete it in Facebook before publishing.

## Ready to go

`posts/2026-10-launch-14-day-mvp.json` holds the launch post from
`docs/instagram-launch-post.md`. Its image is
`assets/posts/2026-10-launch-14-day-mvp.jpg`, served from a raw GitHub
URL pinned to the commit that added it (the repo is public), so the
approved image can't change underneath the post. Approve, then publish.

Store future post images in `assets/posts/` the same way: commit the
JPEG, then use `https://raw.githubusercontent.com/The11-11/datamatrixsocial/<commit>/assets/posts/<file>.jpg`.
