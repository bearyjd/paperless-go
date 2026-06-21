# Google Play — Store Listing (ready to paste)

Canonical store-listing copy for the Play Console. App: **Paperless Go** ·
package `com.ventoux.paperlessgo` · publisher: Ventoux.
Feature list below was verified against the codebase (every feature ships).

## Title (max 30 chars)
```
Paperless Go
```

## Short description (max 80 chars)
```
A modern mobile client for your self-hosted Paperless-ngx document server.
```

## Full description (max 4000 chars)
```
Paperless Go is a modern, native mobile client for Paperless-ngx, the popular
self-hosted document management system. Connect it to your own Paperless-ngx
server and manage your documents from anywhere.

IMPORTANT: Paperless Go is a client app. It requires your own running
Paperless-ngx server — it does not provide document storage on its own.

Manage your documents on the go with a clean, modern interface:

• Browse, search, and filter your library with full-text search and autocomplete
• View document details, thumbnails, and PDF previews
• Annotate documents — draw, highlight, and mark up pages; export composited
  annotations back to your server
• Scan with the camera and enhance with smart image processing — deskew,
  contrast, shadow removal, and denoising across multiple presets
• Upload via camera scan, file picker, or share intent from other apps
• Document templates — save reusable upload presets for fast, consistent filing
• Manage tags, correspondents, document types, and storage paths
• Edit document metadata, custom fields, dates, and notes
• Generate share links with optional expiration
• Bulk operations: tag, re-tag, delete, batch OCR re-run, and more
• Save and reuse custom filter and sort combinations with saved views
• Find related documents with content-similarity search
• Swipe-to-assign inbox for fast document triage
• Trash management — view and restore deleted documents
• AI chat — ask questions about your documents via Paperless-AI (optional)
• Switch between multiple Paperless-ngx servers
• Offline edit queue — make changes without a connection; auto-syncs when back
  online, plus local caching
• Home screen widget with document count and quick-launch buttons
• Biometric authentication — app-level and per-document lock
• Clean Material 3 interface with light and dark themes
• Accessibility: screen-reader labels and non-gesture alternatives

PRIVACY
Paperless Go connects directly to the self-hosted Paperless-ngx server you
configure, using token-based authentication. Your documents and credentials are
not sent to the developer or any third party. No cloud services, no tracking,
no ads.

Requirements:
• A running Paperless-ngx instance (https://docs.paperless-ngx.com)
• Network access to your server (local network or via reverse proxy)

Paperless Go is free and open source software, licensed under AGPL-3.0. View the
source code at https://github.com/bearyjd/paperless-go
```

## Categorization & contact
- Application type: App
- Category: Productivity
- Tags: documents, productivity, self-hosted, scanner, paperless-ngx, open source
- Contact email: `jd@beary.us`
- Website: `https://github.com/bearyjd/paperless-go`
- Privacy policy URL: `https://bearyjd.github.io/paperless-go/privacy-policy.html`

## Graphic assets (all produced ✓)
- [x] App icon (hi-res) — 512×512 PNG → `assets/icon/icon-512.png`
- [x] Feature graphic — 1024×500 PNG → `metadata/en-US/images/featureGraphic.png`
      (also `assets/feature-graphic.png`)
- [x] Phone screenshots — 4 framed @ 1080×2400 →
      `metadata/en-US/images/phoneScreenshots/framed/` (document list, scan/upload,
      AI chat, login). Unframed originals alongside in `phoneScreenshots/`.
- [ ] (optional) 7" / 10" tablet screenshots — not required
- Reminder: confirm no real personal document content is visible in screenshots
  before upload (current set appears to use sample/redacted data — eyeball once).

## Content rating (IARC questionnaire) — expected result: Everyone
- Violence: No · Sexuality: No · Language: No · Controlled substances: No
- User-generated content: No (connects to the user's own server)
- Shares location: No · In-app purchases: No

## Data safety
- See `play-store/data-safety.md` for the verified, copy-into-the-form answers.
- Summary: no data collected/shared by the developer; encrypted in transit (the
  shipped build is HTTPS-only); privacy policy URL above.

## App access (REQUIRED — top rejection cause)
- See `play-store/app-access-instructions.md`. Provide a demo Paperless-ngx
  server URL + reviewer credentials. A working demo instance is strongly
  preferred over instructions-only.
