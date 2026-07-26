# Real PDF Password Protection — Implementation Plan

> **This is a planning document only — writing the actual encryption code is
> explicitly out of scope here and belongs to a follow-up implementation
> issue.** This plan has already been through a security-reviewer pass (see
> "Security review gate" at the end); its revisions are incorporated
> throughout. This directly answers issue #23, which is itself scoped as
> planning-only, following up on #15 (which removed the previous "Password
> Protect & Share" feature after discovering it silently shipped unencrypted
> PDFs — the `password` parameter was accepted and never used).

**Goal:** Scope a *real* ISO 32000 Standard Security Handler implementation so
that when "Password Protect & Share" is re-added, the output PDF genuinely
requires the password to open, verifiable by an automated test.

**Why the previous attempt failed:** The original plan
(`docs/superpowers/plans/2026-03-29-pdf-compress-protect.md`) called
`Document(password: userPassword)` on the `pdf` package and shipped without
verifying that API actually encrypts anything. It doesn't — see below.

---

## Verified facts (not assumptions)

Checked directly against the `pdf` package source in
`~/.pub-cache/hosted/pub.dev/pdf-3.11.3/lib/src/pdf/obj/encryption.dart` and
`document.dart` (this project depends on `pdf: ^3.11.1`):

- `PdfEncryption` is a 3-line abstract class: a `PdfDict params` (becomes the
  trailer's `/Encrypt` dictionary) and one method,
  `Uint8List encrypt(Uint8List input, PdfObjectBase object)`. There is **no
  built-in subclass** — no RC4, no AES, no key derivation, no O/U computation.
  Anyone who wants real encryption must write the entire standard security
  handler themselves.
- The integration point is real and usable: `PdfDocument.encryption` is a
  settable field. `document.dart`'s `_write()` does
  `xref.params['/Encrypt'] = ob.ref()` when an object `is PdfEncryption`, and
  every string/stream write goes through
  `encryption?.encrypt(input, object) ?? input`. So a correct subclass *would*
  actually get wired into the output — the extension point itself is sound.
- `PdfDocument.documentID` is auto-generated (SHA-256 of a timestamp + secure
  random bytes) and exposed only as a getter. The standard security handler's
  key derivation needs the first element of the trailer's `/ID` array — the
  encryption object must read `pdfDocument.documentID` at O/U-computation
  time, not assume/generate its own.
- No proprietary dependency is available to us: Syncfusion's PDF SDK is
  commercial-licensed, incompatible with this project's AGPL-3.0 license.

## Research: does anything already do this? (survey per issue's first checkbox)

- **No safe, mature, drop-in Dart package exists.** pub.dev and GitHub search
  turned up nothing usable that isn't proprietary, a native-SDK wrapper, or
  unmaintained vaporware. Specifically checked and ruled out:
  - `pdf_crypto` (referenced in old blog posts) does not exist in the current
    upstream `DavBfr/dart_pdf` repo (Apache-2.0) — confirmed aspirational/dead.
  - `Locksmith` (MIT) wraps native Android PdfBox / iOS PdfKit rather than
    implementing anything in Dart — not usable for a pure-Dart cross-platform
    encrypt step, essentially unmaintained (single v0.0.1).
  - `ben-milanko/dart-pdf` (Apache-2.0, ~7 weeks old at time of writing) is a
    from-scratch fork of the `pdf` package with a genuine hand-rolled standard
    security handler (`packages/pdf_cos/lib/src/crypto/{rc4,aes,standard_security_handler}.dart`).
    This is the one real find — **useful as a line-by-line design reference**,
    but too new/low-adoption to depend on directly without independent
    verification of its correctness. Treat it the same way as any other
    unverified reference implementation: read it, don't trust it blindly.
- **Reference implementations worth reading** (algorithm ground-truth, not
  dependencies):
  - Apache PDFBox `org.apache.pdfbox.pdmodel.encryption.StandardSecurityHandler`
    (Java, Apache-2.0) — the clearest, most authoritative open reference.
  - pikepdf/qpdf (Python/C++, MPL-2.0 / Apache-2.0) — supports RC4, AES-128,
    AES-256 read+write; good second cross-check.
  - iText Community (**AGPL-3.0** — a direct license precedent for this
    project) has a full standard security handler. If any logic is ported
    (not just algorithm understanding) from iText, its AGPL attribution
    requirements apply. **Security-reviewer preference: prefer Apache-2.0
    PDFBox as the primary algorithm reference to avoid license-provenance
    entanglement entirely** — read iText only as a secondary cross-check if
    PDFBox is ambiguous on some point, and if so, do not copy code verbatim.
- **`pointycastle`** (pub.dev, verified publisher `bouncycastle.org`, v4.0.0,
  MIT) confirmed to provide AES-CBC, MD5, and SHA-256 — everything needed for
  R4 (AES-128) and R6 (AES-256). It does **not** provide RC4 (only
  Salsa20/ChaCha20 stream ciphers) — irrelevant to us since RC4 is being
  skipped (see below).

## Decision: target revision

RC4 (revisions R2/R3) is deprecated and explicitly flagged insecure by every
current PDF library's own documentation (PDFBox, qpdf). There is no
compatibility upside to supporting it — modern Adobe Acrobat, macOS Preview,
and essentially all current Android/iOS PDF viewers support AES.

**Target: R4 (AES-128, `/V 4`) as the baseline, with R6 (AES-256, `/V 5`,
PDF 2.0) required before the feature ships to general availability.** Do not
implement RC4 for content encryption at all.

**Security-reviewer note incorporated:** the meaningful weakness of R4 isn't
the 128- vs 256-bit cipher — AES-128 is fine for document confidentiality —
it's R4's key-derivation function: unsalted MD5 with only ~50 rounds, which
is cheap to brute-force offline regardless of cipher strength. R6's Algorithm
2.B (salted, hardened SHA-256-based KDF) is the actual security upgrade, not
just a bigger key. R4-first is still the right *build* sequencing (smaller,
simpler, proves the `PdfEncryption` integration architecture, no
`/UE`/`/OE`/`/Perms` dictionary complexity) — but treat it as an internal
milestone, not a shippable end state: **R6 must land, or the feature must
enforce a strong-password policy, before "Password Protect & Share" is
re-exposed in the UI.**

## Dependency decision

Add `pointycastle` (MIT) as a direct dependency for AES-CBC/MD5/SHA-256.
Nothing else needs to be added — RC4 is out of scope, and no PDF-specific
package is safe to depend on per the research above.

---

## Scope for the *implementation* issue (not this one)

This issue is planning-only. The following is the task breakdown the
follow-up implementation issue should use — captured here so the plan is
concrete enough to actually execute, not just a recommendation to "go figure
it out."

### New files
- `lib/core/services/pdf_encryption/standard_security_handler.dart` —
  `class StandardSecurityHandler extends PdfEncryption`. Constructor takes
  user password, owner password (default to user password if owner not set,
  matching common PDF tool UX), and a `PdfPermissions` value object for the
  P-value bits (print/copy/modify — default to "no restrictions besides
  requiring the password," since this feature is about confidentiality, not
  DRM).
- `lib/core/services/pdf_encryption/pdf_key_derivation.dart` — Algorithm 2
  (compute encryption key from password): pad password to 32 bytes with the
  ISO 32000 standard pad string, MD5 the result + O entry + P value (as
  little-endian 4 bytes) + first element of `/ID`, then 50 additional MD5
  rounds on the first n bytes for R3+ (n = key length / 8).
- `lib/core/services/pdf_encryption/pdf_owner_password.dart` — Algorithm 3
  (compute O entry): RC4-encrypt (yes, RC4 is still required *here* even
  though it's not used for the R4 object encryption — Algorithm 3 for R2-R4
  is defined in terms of RC4 regardless of the *content* encryption
  algorithm; this needs its own small hand-rolled RC4, ~20 lines, since
  pointycastle doesn't ship one) the padded user password keyed by an
  MD5-derived owner key.
- `lib/core/services/pdf_encryption/pdf_user_password.dart` — Algorithm 5 (R3+
  U entry, using MD5 of pad string + ID, then RC4/AES per revision).
- Per-object encryption: object-number+generation-derived key (Algorithm 1)
  feeding AES-128-CBC with a random IV prepended to ciphertext, per object
  string/stream, implementing `PdfEncryption.encrypt()`.

### Wiring
- `lib/core/services/pdf_tools_service.dart`: replace the removed
  `protectPdf` with a real implementation that sets
  `doc.encryption = StandardSecurityHandler(doc, userPassword: password)`
  before `doc.save()`.
- Re-add the "Password Protect & Share" menu entry in
  `lib/features/documents/document_detail_screen.dart` — **only after** the
  encryption implementation is merged and tested, not concurrently.

### Required tests (this is the acceptance-critical part)

These must be a **CI-enforced merge gate** — not advisory, not
skippable — since this is exactly the class of feature where a green test
suite is the only thing standing between "protected" and "silently not
protected."

- **Round-trip open test**: encrypt a known PDF, then *independently*
  attempt to open it — correct password succeeds, wrong/empty password fails.
  This must not just re-run our own decryption logic (that would only prove
  internal consistency, exactly the kind of self-satisfied bug that shipped
  last time) — verify against a second, independent implementation. Options,
  in preference order: (a) a golden-file test that shells out to `qpdf
  --check --password=X` if `qpdf` can be assumed present in CI, (b) a
  pointycastle-based *decryption* implementation written independently from
  the encryption code (different author/session, or at minimum written from
  the ISO 32000 spec directly rather than by inverting the encryption code
  line-by-line), (c) at absolute minimum, cross-check byte-for-byte against
  one of the reference implementations' test vectors (PDFBox and pikepdf both
  ship test fixtures with known passwords/keys — use those as golden inputs).
- **Ciphertext-is-not-plaintext assertion**: a direct, no-op-catching check
  that the encrypted object bytes differ from the original plaintext bytes.
  Cheap, blunt, and exactly what would have caught the original bug fastest.
- **`/Encrypt` dictionary shape assertions**: parse the output trailer and
  assert `/Filter /Standard`, `/V 4`, `/R 4`, and `/CFM /AESV2` (or the R6
  equivalents) are actually present — not just "some encryption happened."
- **IV assertions**: every encrypted object's IV is (a) unique across all
  objects in the same document, and (b) sourced from a CSPRNG (see below) —
  not zero, not a counter, not reused.
- Unit tests for each ISO 32000 algorithm in isolation (key derivation, O
  computation, U computation) against the spec's worked examples if any are
  publicly available, or against PDFBox/pikepdf output for the same
  password+permissions+ID inputs.
- A test confirming the *P* (permissions) value round-trips correctly,
  including its sign (P is a signed 32-bit little-endian integer — a classic
  off-by-sign bug) and the `/EncryptMetadata` byte.

### Randomness and password-hygiene requirements

- **IV source**: every AES-CBC IV must come from a real CSPRNG —
  `pointycastle`'s seeded `SecureRandom` (e.g. Fortuna, properly seeded) or
  Dart's `Random.secure()`. Never `Random()` (not cryptographically secure).
  This is a hard requirement, not a style preference — IV reuse under CBC
  leaks plaintext relationships between objects.
- **Password memory hygiene**: prefer passing passwords as `Uint8List`
  rather than `String` where possible and best-effort-zero the buffer after
  use (Dart `String`s are immutable and can't be reliably zeroed, so this is
  a mitigation, not a guarantee). Never log the password or include it in
  error messages/exceptions.
- **Padding-oracle note**: classic PDF-decryption padding oracles apply to
  *decrypting* CBC ciphertext behind a network-exposed decrypt endpoint —
  not applicable here since this is a local, encrypt-only feature with no
  decrypt service. Not a concern for this plan's scope, but worth
  remembering if a "verify this PDF's password" feature is ever added later.

### Explicitly not in scope for the implementation issue either
- DRM-style permission enforcement beyond what the PDF spec's P-bits express
  (i.e., don't build a custom permissions UI — expose "no printing" etc. as a
  detail only if there's a real user request for it).
- iOS (matches this repo's existing Android-only scope for PDF tools).

---

## Security review gate — COMPLETE

Per this repo's security-review triggers (cryptography touches this list
explicitly) and per this issue's own checklist, this plan went through a
security-reviewer pass on 2026-07-26. **Verdict: safe to proceed as the basis
for a follow-up implementation issue.** No blocking flaws found; four
revisions were requested and have been incorporated into this document:

1. Reframed R4's actual weakness as its MD5 key-derivation function (not
   cipher strength) and upgraded R6 from "fast-follow" to "required before
   the feature ships to general availability."
2. Expanded the required-tests list with ciphertext≠plaintext, `/Encrypt`
   dictionary-shape, and IV-uniqueness/CSPRNG assertions, and marked the
   whole test list as a CI-enforced merge gate rather than advisory.
3. Corrected the padding-oracle framing (a decrypt-time/network-exposed
   concern, not applicable to this local encrypt-only feature).
4. Added an explicit CSPRNG-IV mandate and password memory-hygiene
   requirements, plus a license-provenance preference for PDFBox over iText
   as the primary algorithm reference.

The reviewer also confirmed the plan's claim that RC4 is still required for
Algorithm 3 (owner-password computation) even under R4/AES content
encryption — that's correct per ISO 32000, and is a narrow legacy role
distinct from (and much lower-risk than) using RC4 for content
confidentiality.
