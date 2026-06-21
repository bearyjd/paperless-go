# Google Play — Submission Checklist (v1.1.4+9)

Single source of truth for the Play submission. Status as of 2026-06-21.
App: **Paperless Go** · package `com.ventoux.paperlessgo` · versionCode **9**.

Legend: ✅ done · 🟡 ready to paste/transcribe (no work left but yours) · ⛔ blocked on you (external)

## Build & signing
- ✅ Version `1.1.4+9`, `flutter analyze` clean, 185 tests pass.
- ✅ Signed AAB built → `build/app/outputs/bundle/release/app-release.aab`
  (rebuild: `flutter build appbundle --release --obfuscate --split-debug-info=./debug-info/`).
- ✅ Release/upload key: `CN=Paperless Go, O=Grepon` (`~/keys/paperless-go/paperless-go-release.jks`).
- ℹ️ Each re-upload needs a **higher versionCode** — bump `pubspec.yaml` before rebuilding.

## Store listing → `play-store/listing.md`
- ✅ Title, short + full description (feature list verified against code).
- ✅ Contact email `jd@beary.us`, website `github.com/bearyjd/paperless-go`.
- 🟡 Paste copy into Console → Main store listing.

## Graphic assets (all produced)
- ✅ Hi-res icon 512×512 → `assets/icon/icon-512.png`
- ✅ Feature graphic 1024×500 → `metadata/en-US/images/featureGraphic.png`
- ✅ 4 phone screenshots (framed) 1080×2400 → `metadata/en-US/images/phoneScreenshots/framed/`
- 🟡 Eyeball screenshots once for any real personal-doc content before upload.

## Privacy policy → hosted ✅
- ✅ Policy written + filled (`play-store/privacy-policy.md`).
- ✅ Published (GitHub Pages): **https://bearyjd.github.io/paperless-go/privacy-policy.html**
- 🟡 Paste that URL into Console listing **and** the Data safety section.

## Data safety → `play-store/data-safety.md`
- ✅ Verified: no analytics/ads/crash SDKs; on-device ML; credentials on-device;
  no CDN font fetch; shipped build is HTTPS-only (cleartext blocked).
- 🟡 Transcribe answers into Console → App content → Data safety.
  - Collect/share user data? **No** · Encrypted in transit? **Yes**.

## Content rating (IARC) → `play-store/listing.md`
- 🟡 Run the questionnaire; expected result **Everyone**.

## App access (REQUIRED — top rejection cause) → `play-store/app-access-instructions.md`
- ✅ Reviewer blurb drafted.
- ⛔ **Stand up a demo Paperless-ngx server** (HTTPS, seeded with non-sensitive
  docs, dedicated reviewer account). Fill URL + username/password into the blurb,
  paste into Console → App content → App access. Keep it up through review.

## "What's new" (first release: optional) → `play-store/release-notes.md`
- ✅ Drafted (≤500 chars). 🟡 Paste into the production release.

## Account / Console (external)
- ⛔ Ventoux **Organization** developer account live (D-U-N-S, $25, identity
  verification). Org account avoids the closed-testing requirement.
- ⛔ Confirm `com.ventoux.paperlessgo` is free / not burned on another account.
- ⛔ Enroll in **Play App Signing** (the release key is the *upload* key).
- ⛔ Production release: upload AAB → fill the above → submit. First review on a
  new account: days to ~2 weeks.

## Known non-blockers (track separately, do NOT fix during submission)
- Login screen offers an `http://` server option that silently fails on Android 9+
  (shipped build blocks cleartext). UX bug; either remove the http option or add a
  scoped `network_security_config`. Filed as follow-up, not a release blocker.
