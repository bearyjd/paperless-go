# Google Play — Data Safety form (draft answers)

Draft answers for Play Console → App content → Data safety. The form asks what
data the **app/developer** collects or shares. Paperless Go is a self-hosted
client: it talks only to the user's own Paperless-ngx server, and the developer
(Ventoux) receives nothing.

## Dependency scan results (verified against pubspec.yaml, 2026-06-21)
- ✅ **No analytics / crash / ads SDKs** — no Firebase, Crashlytics, Sentry,
  AdMob/ads, or analytics packages in the dependency tree.
- ✅ **On-device ML only** — `google_mlkit_text_recognition` (OCR) and
  `cunning_document_scanner` process on-device; they don't upload images.
- ✅ **Credentials on-device** — `flutter_secure_storage` (Keystore-backed) holds
  the server URL + API token; not sent to the developer.
- ✅ **No runtime CDN font fetch** — `google_fonts` was removed (`ed0ad3d`); Inter
  is now bundled as a local variable-font asset. The app makes no third-party
  network calls beyond the user's own Paperless-ngx server.

## Recommended answers

**Does your app collect or share any of the required user data types?**
→ **No** — assuming the verifications above pass.

Rationale: "collection" = user data sent off-device to you or a third party.
Paperless Go transmits data only to the user's own Paperless-ngx server (the
user's own infrastructure, configured by them), not to the developer or any
third party. Credentials and cached documents stay on-device. There is no
analytics, no ads, no third-party data collection.

If you prefer the conservative reading (declare what leaves the device even to
the user's own server), declare:
- **Personal info → Other (account credentials)**: collected, NOT shared,
  processed only to authenticate to the user's server; stored encrypted
  on-device. Purpose: App functionality. Not optional.
- Mark **data encrypted in transit**: Yes (HTTPS to the user's server).
- This conservative path adds friction; the "No collection" answer is defensible
  for a pure self-hosted client and is what most such clients use.

**Security practices**
- Is all user data encrypted in transit? → **Yes** (HTTPS; the app talks to the
  user's server over TLS). [Verify the app doesn't allow cleartext for prod.]
- Do you provide a way to request data deletion? → Data lives on the user's own
  server; the app stores only local config/credentials, cleared on logout /
  uninstall. Answer per the form's options accordingly.

## Privacy policy
- A privacy policy URL is **required** regardless of the answers above. It should
  state: the app is a client for the user's self-hosted Paperless-ngx server; it
  stores server URL + credentials locally; it sends no data to the developer or
  third parties; contact info. Host it (e.g., project site / GitHub Pages) and
  put the URL in both the listing and the Data safety section.
