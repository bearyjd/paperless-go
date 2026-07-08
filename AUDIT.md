# UI/UX Redesign Audit — Paperless Go

Step 1 deliverable. No code changed. Baseline: `main` @ `c2b4d3a` (v1.1.5).

## 1. Screen inventory

| Route | Screen | Notes |
|---|---|---|
| `/` | Dashboard | 6 stat cards (2-col grid), search action; only 2 cards navigate |
| `/documents` | Documents (list) | 4 app-bar actions (search, filter+badge, settings, sort), saved-view chip bar, active-filters bar, bulk-select mode |
| `/documents/:id` | Document detail | Heaviest screen: 2–3 app-bar actions + 11-item overflow menu; long scroll of inline-editable sections (title, 3 dropdowns, dates, ASN, tags, custom fields, notes, AI trail, share links, content) |
| `/documents/:id/preview` | PDF preview | 8 hardcoded colors |
| `/documents/:id/chat` | Per-document chat | Same widget as global chat |
| `/inbox` | Inbox | List of cards in `Dismissible`; swipe-left = quick-assign sheet, swipe-right = remove; per-card popup menu |
| `/scan` | Scanner hub | 3 option cards (Scan / Batch / Upload file) |
| `/scan/review` → `/scan/enhance` → `/scan/pdf-preview` → `/scan/upload` | Scan pipeline | 4 sequential full screens after capture; enhance has a `ChoiceChip` preset strip already |
| `/search` | Search | Own screen, app-bar `TextField`, 300ms-debounced autocomplete |
| `/chat` | AI chat (RAG) | Input bar + suggestion chips on empty |
| `/login`, lock overlay | Login / biometric lock | Form, max-width 400 |
| `/settings` | Settings | Has Theme picker (System/Light/Dark) via `SimpleDialog` |
| `/labels` | Labels | 4-tab CRUD (tags/correspondents/types/paths), FAB per tab |
| `/trash`, `/templates`, `/workflows(/:id)`, `/custom-fields`, `/annotate`, `/search/similar/:id` | Secondary | Reached from settings/detail, not nav |

## 2. Navigation structure

- `GoRouter` (`lib/app.dart`), auth redirect + deep-link/share-intent redirects.
- `ShellRoute` with M3 `NavigationBar`, 4 tabs: **Home(Dashboard) / Docs / Scan / Chat**. Plain tab icons — Scan is not elevated.
- Extra `FloatingActionButton` "+ Add document" on Home & Docs tabs → duplicates the Scan tab (two equal-weight paths to the same action; exactly the problem the brief names).
- Everything else (inbox! search, labels, trash…) is **outside** the shell — Inbox is currently a side screen despite being the highest-frequency workflow.
- Offline `MaterialBanner` injected above shell content.

## 3. Theme / token setup today

- `lib/core/theme.dart`: `AppTheme.light()/dark()` = `ColorScheme.fromSeed(seed: #17541f green)` — stock M3 derivation, the "dated Material defaults" the brief calls out. Shared `_buildTheme` styles app bar, cards (12dp radius + outline border), inputs, filled buttons (48dp min height already).
- `lib/core/design_tokens.dart`: `Spacing` (4–32) and `Radii` (4/12/16) only — **no color or type tokens**.
- Typography: **Inter already bundled** as a variable font (`assets/fonts/Inter-Variable.ttf`) — this was done deliberately for F-Droid (see §6). No display face; titles are Inter w600/700.
- **Light/dark already wired end-to-end**: `MaterialApp.router(theme, darkTheme, themeMode)`; `ThemeModeNotifier` (defined in `lib/core/auth/auth_provider.dart:196`, persisted via secure storage, defaults to system); Settings already has the System/Light/Dark picker the brief asks for. So the dark-mode work is *palette replacement*, not plumbing.
- Discipline is good: the primary screens are almost entirely `Theme.of/colorScheme`-driven. Repo-wide hardcoded colors: **68**, concentrated in `annotate_screen.dart` (26 — mostly a legitimate ink palette), `loading_skeleton.dart` (13 shimmer grays), `document_preview_screen.dart` (8), `crop_screen.dart`/`crop_overlay.dart` (10), plus intentional contrast logic in `tag_chip.dart`.
- **Server-defined tag colors** (user hex from Paperless-ngx) render via `TagChip.parseColor`/`contrastColor` and flow into chips, cards, filter sheet, pickers. Legitimately dynamic — interacts with the "stamp" chip spec (see §5).

## 4. Gap analysis vs the 7 goals

1. **One primary action/screen** — Documents (4 app-bar actions + FAB + chips), Document detail (11-item menu + ~8 inline-edit sections), and the shell FAB/Scan-tab duplication are the offenders. Dashboard, search, chat, login are already close.
2. **Inbox card stack** — Currently a `Dismissible` list; swipe *left* = quick-assign, *right* = remove (nearly opposite of the target semantics). No card stack, no OCR-suggestion accept. Suggestion machinery exists (`metadata_suggestion_provider`, OCR extractor, AI edit trail) but is only used in the *upload* flow — the inbox redesign can reuse it.
3. **Bottom nav** — Already 4 slots, but the set is Home/Docs/Scan/Chat, not Inbox/Library/Chat/⊕Scan. Inbox must move into the shell; Dashboard loses its slot (see open question A). Scan needs the raised circular treatment.
4. **Metadata bottom sheet** — Today: full-page form in upload + inline sections in detail. `tag_picker_sheet`, `metadata_dropdown`, quick-assign sheet all exist as parts to consolidate.
5. **Scan ≤3 taps** — Today capture → review → enhance → pdf-preview → upload = 4 screens + form. Preset chip strip already exists on *enhance* (6 presets in `processing/presets.dart`: none/auto/receipt/bwText/colorDocument/photo) — needs to move to capture time; review/enhance/preview collapse into one confirm step with progressive disclosure.
6. **Omnibox** — Search is a separate route; filters live in Documents' bottom sheet + a permanently docked active-filters bar. Merge target: Library header.
7. **Saved-view carousel** — Already exists as a `FilterChip` bar on Documents. Restyle to stamp pills, keep behavior.

## 5. Flags & open questions (answer before step 2+)

**A. Dashboard/Home has no slot in the target nav.** Options: fold the 2 useful tiles (doc count, inbox count) into Library's header / Inbox badge and retire the screen; or keep it reachable from Settings. Recommend fold-and-retire. **Needs your call** (feature-cut rule).
**B. Space Grotesk must be BUNDLED, not `google_fonts`.** The brief says "via google_fonts package" — that package fetches from Google's CDN at runtime, which is exactly what F-Droid MR !34430 blocked on last month (we removed `google_fonts` and bundled Inter in v1.1.5). Plan: ship `SpaceGrotesk-Variable.ttf` (OFL) in `assets/fonts/` alongside Inter. Same visual result, no dependency. I'll proceed this way unless you object.
**C. Stamp chips vs server tag colors.** Spec says accent-tinted stamp chips; Paperless tags carry user-chosen colors that users rely on for recognition. Proposal: stamp *styling* (pill, dashed border, −1° tilt) with the server color as border/tint where a tag color exists, accentSoft otherwise; OCR-suggested tags and filters always accentSoft. Confirm or simplify.
**D. Secondary screens** (labels, trash, templates, workflows, custom fields) stay functionally intact, restyled only, reachable from Settings/Library overflow — confirming this is the intent.
**E. Swipe semantics flip.** Current inbox swipe-right = remove; target swipe-right = accept. Fine on a new card-stack UI, but we should keep an accessible non-gesture path (buttons on card) like the current popup menu provides.
**F. minSdk** is `flutter.minSdkVersion` (currently 21) — comfortably below the API 23 target; no constraint issues with anything in the direction (no blur-heavy effects planned).
**G. Repo hygiene:** do **not** run `dart format` repo-wide (tree isn't format-clean; CI is analyze+test only). All work must keep the F-Droid degoogled build green: no new Google/Play dependencies in core code paths (ML Kit pattern shows how to stub if ever needed).

## 6. What's already in our favor

- Light/dark plumbing + settings toggle: done. Palette swap in one file will propagate.
- 48dp min button height already themed; card borders (not shadows) already the pattern — matches the dark-elevation spec.
- Consistent `.when(loading/error/data)` + skeletons + `EmptyState` widget across screens — the states the brief requires largely exist and just need restyling.
- OCR/AI suggestion providers exist and are UI-independent — the inbox card stack is a presentation change, not new data work.

**Proposed step-2 kickoff (after your review):** replace `theme.dart` + extend `design_tokens.dart` with the approved palette as a `ThemeExtension` (paper/ink/inkSoft/accent/accentSoft/card/line/stamp × light/dark), bundle Space Grotesk, restyle the shell nav with the raised Scan button, and verify the Settings theme toggle end-to-end on device.
