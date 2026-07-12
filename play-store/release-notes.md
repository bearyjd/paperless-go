# Release notes — v1.1.6 (build 11)

## Google Play — "What's new" (max 500 chars)
Paste into the production release's release notes:
```
• Full UI redesign: new theme, bundled Space Grotesk font, and a refreshed
  bottom nav with a raised Scan button.
• Inbox: swipeable card stack with OCR suggestion chips.
• Library: omnibox search, stamp filter pills, restyled document cards.
• Scan: 3-tap capture flow with a reusable metadata sheet.
• Document details: edit metadata inline from the summary card.
• Settings: verify Paperless-AI credentials before saving.
```

## F-Droid changelog
Not yet written to `metadata/en-US/changelogs/`. Use the same text as above,
terser, with the versionCode-based filename (111 = base versionCode 11 x 10 + ABI
index 1, matching the 91/92/93 precedent for v1.1.4).

## Notes
This release bundles the full redesign that had been sitting on `main` since
the v1.1.5 tag (theme/palette tokens, StampChip, bottom nav, inbox card
stack, scan flow, library redesign, chat/settings restyle, and detail-screen
metadata editing), plus HTTP-mock contract tests for PaperlessApi.
