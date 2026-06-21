# 01 — Consolidated Evidence

Five evidence subagents (Structural, Visual, Copy & Honesty, Weight & Friction,
Accessibility). Facts only, cited. Scoring is in `02-scorecard.md`.

## Design system (theme + tokens)
- Single seed color `Color(0xFF17541f)` → `ColorScheme.fromSeed` for light + dark — `theme.dart:8-20`. Material 3 on — `theme.dart:40`. Inter via `google_fonts` — `theme.dart:25`. Centralized component themes (AppBar elev 0, Card elev 0 hairline, InputDecoration, FilledButton 48px) — `theme.dart:43-69`.
- Tokens: 6 spacing (4/8/12/16/24/32) + 3 radii (4/12/16) — `design_tokens.dart:1-14`.
- Dark mode implemented + persisted (system/light/dark) — `app.dart:300-302`, `auth_provider.dart:197-221`, `settings_screen.dart:102-103`.

## Aesthetic drift (orphan styles)
- 13 distinct hardcoded spacing values vs 6 tokens; raw `8` and `16` written ×54 each instead of `Spacing.sm/lg` — visual report §1, e.g. `inbox_screen.dart:106,120`, `filter_bottom_sheet.dart:62-262`, `documents_screen.dart:211-249`.
- 9 hardcoded color families bypass the theme: `Colors.white` ×45, black ×14, red ×10, etc. — concentrated in editor surfaces (`annotate_screen.dart`, `crop_screen.dart`, `document_preview_screen.dart`).
- Destructive color split: `Colors.red` (9 sites: `document_detail_screen.dart:233,234,837`, `labels_screen.dart:205…`) vs `colorScheme.error` (5 sites: `trash_screen.dart:61,167`, `documents_screen.dart:210`) — inconsistent.
- 4 hardcoded font sizes (10-13) bypass text theme — `document_detail_screen.dart:998,1708`, `enhance_screen.dart:355`. Off-scale radius `14` — `loading_skeleton.dart:255`.

## States (#8)
- ALL 6 present and consistent via `AsyncValue.when`: empty (`documents_screen.dart:228-247`), loading skeletons (`loading_skeleton.dart:25-264`), error+Retry (`documents_screen.dart:206-221`), success, focus (autofocus ×20; `search_screen.dart:21`), disabled-while-busy (`login_screen.dart:262`, +6). Reduce-motion honored in skeletons — `loading_skeleton.dart:13-15`. Contextual empty copy (filtered vs unfiltered) — `documents_screen.dart:239-253`.

## Structure / usefulness / redundancy (#2 #5 #10)
- Open a document = 1 tap (`documents_screen.dart:386`). Cold launch → open = 2 taps; app opens to **Dashboard**, not Documents (`app.dart:245`, Docs is nav index 1 `app.dart:387`). No inline search on the list; full search is a separate route (`documents_screen.dart:158`).
- Scan affordance triplicated: SpeedDial FAB (`app.dart:513/553/593`) + Scan nav tab (`app.dart:388`) + scanner_screen cards (`scanner_screen.dart:52/62/72`).
- document_detail overflow = **13 items + 4 dividers**, incl. 3 separate rotate entries (CW/180/CCW) — `document_detail_screen.dart:168-236`.
- Dashboard: 6 stat cards, only 1 (Inbox) interactive; other 5 styled identically but non-navigable — `dashboard_screen.dart:88-118`.
- Duplicated code patterns: loadMore block + error-SnackBar `ref.listen` + empty/error-state Columns copied verbatim across documents/inbox/trash (`documents_screen.dart:128-275`, `inbox_screen.dart:17-122`, `trash_screen.dart:34-126`); `_TagPickerSheet` defined twice (`document_detail_screen.dart:1031`, `upload_screen.dart:615`); metadata dropdown inlined 3×.
- Always-visible global chrome on Dashboard/Docs ≈ 6, expands to 9 with FAB open. Flat M3 keeps it visually quiet (elevation 0). `flutter analyze` clean (no unused-import/dead-code flagged).

## Copy & honesty (#4 #6)
- ~230-260 user-facing strings. **No marketing inflation. No dark patterns.** Destructive copy honest and matches behavior (trash dialog "Move to trash… restore it later" — `document_detail_screen.dart:831-838`; permanent delete warns "cannot be undone" — `trash_screen.dart:214-215`).
- One cosmetic label imprecision: menu/tooltip word **"Delete"** (`document_detail_screen.dart:234`, `bulk_action_bar.dart:72`) actually calls `api.trashDocuments` (soft delete) — mitigated by accurate confirm dialogs.
- Jargon surfaced raw (native Paperless-ngx vocabulary): "Correspondent", "Storage Path", "ASN" (inconsistent — spelled out `:458`, abbreviated `:41,:472`), "OCR". Some de-jargoning done well (`settings_screen.dart:160` subtitle).
- **44 raw `$e`/`$err` interpolations** leak `DioException` dumps (incl. server URL, status, body) into SnackBars/error screens — no sanitizing exception layer exists. e.g. `documents_screen.dart:214`, `document_detail_screen.dart:290,1527`. Good counter-example: `upload_screen.dart:137,141` uses mapped messages.

## Weight & friction (#9)
- 31 direct deps, 185 transitive. Heavy native: ML Kit OCR, **two PDF stacks** (`pdf` + `pdfx`), `image`, drift/sqlite — `pubspec.yaml:34,44,64,76`. `flutter_markdown` discontinued — `:30`.
- In-app bundled assets ≈ 0 KB (no `assets:`/`fonts:` block). **google_fonts fetches Inter over the network on first launch** (no bundled fallback, no `allowRuntimeFetching:false`) → first-run network + font swap.
- Dashboard: 1 HTTP `GET /api/statistics/` per load, **no TTL/cache** (re-fetch on refresh) + 2 home-widget platform writes — `dashboard_statistics.dart:42-44`.
- Idle animations: **zero continuous**. One tap-driven `AnimationController` (FAB, `app.dart:407`). Shimmer only during load, disabled under reduce-motion. No nag/update dialogs on launch.

## Accessibility (#2 #4 angle)
- 15 `Semantics(` widgets, **0 `semanticLabel:`**, 36 tooltips. 5 icon-only buttons unlabeled to screen readers: inbox search (`inbox_screen.dart:35`), share-link add/delete (`document_detail_screen.dart:1680,1716`), custom-field delete (`custom_fields_screen.dart:60`), selection-close (`documents_screen.dart:149`).
- Tap targets: IconButton defaults preserve 48×48 even with shrunk glyphs; no sub-48 tappable found.
- Focus: no `FocusTraversal`/`FocusScope` ordering; relies on default tree order. autofocus ×20 in dialogs. No focus restoration on modal dismiss.
- **Gesture-only actions with NO button alternative**: inbox swipe = remove + quick-assign (`inbox_screen.dart:125-177`); chip-management long-press (`documents_screen.dart:291`); enhance compare long-press (`enhance_screen.dart:214`). (Document selection HAS a context-menu alternative — `documents_screen.dart:87`.)
- Text scaling: no `textScaler` read/cap; single-line `maxLines:1`+ellipsis truncates under large scale (`document_card.dart:109-136`, `tag_chip.dart:26-34`). Reduce-motion only honored by skeletons.
- Landmarks: Scaffold/AppBar/NavigationBar present. But **0 `header:true`** — section headers are plain Text (`settings_screen.dart:438`). No `liveRegion` on async status.
