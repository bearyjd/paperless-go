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
  Server URL: https://<DEMO-INSTANCE>        (FILL IN)
  Username:   <REVIEWER-USERNAME>            (FILL IN)
  Password:   <REVIEWER-PASSWORD>            (FILL IN)

To review:
  1. Launch the app.
  2. On the login screen, enter the Server URL above.
  3. Sign in with the username and password above.
  4. You'll land on the Dashboard. Browse and open documents, search, view the
     inbox, and try Scan/Upload — all features operate against this demo server.

If the demo server is unavailable, the app requires the user's own Paperless-ngx
instance (https://docs.paperless-ngx.com) and cannot be exercised without one.
```

## Setting up the demo server (recommended)
- Stand up a throwaway Paperless-ngx instance (Docker compose is the standard
  install) reachable over HTTPS, seed it with a few non-sensitive sample docs,
  and create a dedicated reviewer account.
- Keep it running through review; first review on a new account can take days to
  ~2 weeks. Tear it down afterward.
- Instructions-only (no demo server) reviews frequently bounce — provide the
  working server if at all possible.
