# Google Play — Store Listing (draft)

Draft copy for the Play Console store listing. Review/tweak before submitting.
App: **Paperless Go** · package `com.ventoux.paperlessgo` · publisher: Ventoux.

## Title (max 30 chars)
```
Paperless Go
```

## Short description (max 80 chars)
```
A fast, modern mobile client for your self-hosted Paperless-ngx server.
```

## Full description (max 4000 chars)
```
Paperless Go is a modern, native mobile client for Paperless-ngx, the
self-hosted document management system. Connect it to your own Paperless-ngx
server and manage your documents from anywhere.

IMPORTANT: Paperless Go is a client app. It requires your own running
Paperless-ngx server — it does not provide document storage on its own.

FEATURES
• Browse, search, and full-text search your entire document archive
• Scan paper documents with your camera (single page or batch) and upload
• Upload existing PDFs and images from your device
• Triage your inbox: quick-assign correspondents/types or remove from inbox
• Organize with tags, correspondents, document types, and storage paths
• Edit document metadata, custom fields, dates, and archive serial numbers
• Document actions: rotate, split, annotate, share, compress, password-protect
• Saved views and a dashboard overview of your archive
• Optional AI chat about your documents (via Paperless-AI, if you run it)
• Clean Material 3 interface with light and dark themes
• Accessibility: screen-reader labels and non-gesture alternatives

PRIVACY
Paperless Go talks only to the Paperless-ngx server you configure. Your
documents and credentials are not sent to the developer or any third party.

Paperless Go is open source.
```

## Categorization & contact
- Application type: App
- Category: Productivity
- Tags: documents, productivity, self-hosted
- Contact email: <Ventoux support email — FILL IN>
- Website: <Ventoux / project URL — FILL IN>
- Privacy policy URL: <REQUIRED — host the privacy policy and put the URL here>

## Graphic assets to produce (Play requirements)
- [ ] App icon — 512×512 PNG, 32-bit, no alpha issues (Play uses its own)
- [ ] Feature graphic — 1024×500 PNG/JPG (shown at top of listing)
- [ ] Phone screenshots — 2–8, 16:9 or 9:16, min side ≥ 320px (capture: dashboard,
      documents list, document detail, scan/upload, inbox)
- [ ] (optional) 7" and 10" tablet screenshots
- Note: screenshots can come from the Pixel 9 (`adb screencap`), but scrub any
  real document content / personal data first.

## Content rating
- Run the IARC questionnaire in Play Console. Expected result: **Everyone**
  (no violence/sexual/gambling content; it's a document manager).

## App access (REQUIRED — top rejection cause for self-hosted apps)
Reviewers can't sign in without a server. In Play Console → App content → App
access, choose "All or some functionality is restricted" and provide either:
- a demo Paperless-ngx URL + username/password the reviewer can use, OR
- clear instructions stating the app requires the user's own self-hosted
  Paperless-ngx server and cannot be exercised without one.
Strongly prefer a working demo instance — instructions-only reviews often bounce.
```
