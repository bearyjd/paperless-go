# Play Console — App access (reviewer instructions)

Paperless Go has no backend of its own — it's a client for the user's self-hosted
**Paperless-ngx** server, so reviewers cannot sign in without one. This is the
single most common rejection cause for self-hosted clients. In Play Console →
**App content → App access**, choose "All or some functionality is restricted"
and paste the blurb below (fill in the demo server details first).

## Reviewer blurb (paste into App access instructions)
```
Paperless Go is a client app for the self-hosted Paperless-ngx document
management server. It has no backend of its own and requires a server to sign in.

Demo server for review:
  Server URL: https://paperless-demo.ventouxlabs.com
  Username:   reviewer
  Password:   (see .env on the demo host, or reset.sh output — not committed here, repo is public)

To review:
  1. Launch the app.
  2. On the login screen, enter the Server URL above.
  3. Sign in with the username and password above.
  4. You'll land on the Dashboard. Browse and open documents, search, view the
     inbox, and try Scan/Upload — all features operate against this demo server.

If the demo server is unavailable, the app requires the user's own Paperless-ngx
instance (https://docs.paperless-ngx.com) and cannot be exercised without one.
```

## Demo server (live)
- Runs on the `.23` Docker host (`~/paperless-go-demo`), exposed via a named
  Cloudflare Tunnel at the hostname above.
- **Daily flush + reseed**: a cron job runs `reset.sh` at 04:00 UTC — tears the
  stack down (`docker compose down -v`), brings it back up, and reseeds the 3
  sample docs via `seed/make_samples.py`. Reviewer creds are stable across
  resets (set via `.env`, not stored data).
- **2G storage cap**: `data`/`media`/`redisdata` are bind-mounted into a
  loop-mounted ext4 filesystem capped at 2G (`/var/lib/paperless-go-demo-quota`,
  see `/etc/fstab` on the host), so uploads can't fill the host disk.
- Keep it running through review; first review on a new account can take days to
  ~2 weeks. Tear it down afterward with `docker compose down -v` and remove the
  Cloudflare tunnel + `/etc/fstab` entry + quota image.
