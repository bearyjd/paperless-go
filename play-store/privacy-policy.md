# Privacy Policy — Paperless Go

_Last updated: 2026-06-21_

Paperless Go ("the app") is a mobile client for **Paperless-ngx**, a self-hosted
document management system. The app is published by Ventoux. This policy explains
what the app does and does not do with your data.

> **Hosted at:** https://bearyjd.github.io/paperless-go/privacy-policy.html
> (source of truth is this file; the HTML on the `gh-pages` branch mirrors it).

## The short version

Paperless Go talks **only** to the Paperless-ngx server **you** configure. It
sends **no** data to the developer or to any third party. There is no analytics,
no advertising, and no tracking.

## What the app stores

- **Server connection details** — the server URL and your authentication
  credentials (API token or username/password) are stored **on your device** in
  the operating system's secure storage (Android Keystore-backed). They are used
  only to connect to your server and are never transmitted to the developer.
- **Cached content** — document thumbnails and data fetched from your server may
  be cached locally on your device to improve performance.
- **Local app data** — preferences, saved views, upload templates, and any
  pending offline edits are stored locally on your device.

## What the app sends, and where

- The app communicates **only** with the Paperless-ngx server address you enter,
  over an encrypted (HTTPS) connection. Your documents, searches, and edits go to
  **your** server — not to the developer.
- Document scanning and on-device text recognition (OCR) are performed **on your
  device**. Builds distributed via Google Play use Google ML Kit for on-device
  text recognition; ML Kit runs **entirely on your device** and sends no images
  or text to Google or any third party. Captured images are not uploaded to the
  developer or to any third-party service by the app.

## What the app does NOT do

- It does **not** collect personal data for the developer.
- It does **not** include analytics, crash-reporting, or advertising SDKs.
- It does **not** share your data with third parties.

## Permissions

The app requests only the permissions needed for its features: network access
(to reach your server), camera (to scan documents), storage/photos (to pick or
save files), notifications (upload progress and completion), and
biometric/fingerprint (optional app-level and per-document lock). These are used
solely on your device and to communicate with the server you configure; no data
from them is sent to the developer or any third party.

## Data retention and deletion

- Locally stored credentials and cached data are removed when you log out or
  uninstall the app.
- Your documents are stored on your own Paperless-ngx server; manage or delete
  them there.

## Children

The app is a productivity tool and is not directed at children.

## Changes to this policy

We may update this policy; material changes will be reflected by the "Last
updated" date above.

## Contact

- Email: jd@beary.us
- Project: https://github.com/bearyjd/paperless-go
