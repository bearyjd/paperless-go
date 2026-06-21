# 05 — Refine Plan (Rams audit follow-through)

Reframes the audit's REDESIGN moves as a **REFINE**: iterate on a good
foundation. Each phase is self-contained and runnable in a fresh chat context.
Tasks are framed to **copy an existing in-repo pattern**, not invent APIs.

Source audit: `DESIGN-IS-2026-06-20/01-evidence.md` … `04-handoff-prompt.md`.
Run order is by isolation/risk: additive helper → mechanical sweep → a11y →
dedup → IA-touch → verify. Phases 1-3 are independent; 4 should precede 5.

---

## Phase 0 — Discovery (consolidated; already gathered)

**Allowed APIs / patterns that ACTUALLY exist (use these, cite them):**
- Design tokens: `Spacing` (4/8/12/16/24/32) and `Radii` (4/12/16) in `lib/core/design_tokens.dart:1-14`. USE these; do not invent new token names.
- Single seeded `ColorScheme` (light+dark) in `lib/core/theme.dart:8-20`; semantic roles available via `Theme.of(context).colorScheme.*` (`error`, `onSurfaceVariant`, `primary`, `surface`). The error role is already used correctly at `trash_screen.dart:61,167`, `documents_screen.dart:210`.
- Dio layer: `lib/core/api/dio_client.dart` (`DioClient.create`, a `_RetryInterceptor`, a `_CsrfInterceptor`). Errors thrown to callers are raw `DioException`. **There is NO custom exception type** — `lib/core/api/` contains only `api_providers.dart`, `dio_client.dart`, `paperless_api.dart` (no `api_exceptions.dart`).
- Existing GOOD error pattern to copy: `upload_screen.dart:137` uses a pre-mapped `errorMessage` instead of `$e`; `upload_notifier.dart:184-191` (`_isNetworkError`) shows the `DioExceptionType` switch to copy.
- Existing GOOD a11y pattern: `tooltip:` on IconButtons at `documents_screen.dart:160,168,173,178`; trailing `PopupMenuButton` action on a list row at `trash_screen.dart:146`.
- Lint surface: `analysis_options.yaml` is bare `flutter_lints` — **no custom-lint plugin**. Enforcement of "no hardcoded colors/spacing" must be a **grep-based guard test** under `test/`, matching the repo's pure-unit convention (e.g. `test/unit/router/scan_route_args_test.dart`).
- Test convention: pure unit tests, no `path_provider`/widget-harness mocks. Subclass concrete classes for fakes (see `documents_notifier_loadmore_test.dart`).

**Anti-patterns to avoid (do NOT do):**
- Do NOT add a custom-lint/dart_code_metrics dependency for Phase 2 — use a grep test.
- Do NOT touch the deliberately-literal-color editor surfaces (`annotate_screen.dart`, `crop_screen.dart`, `crop_overlay.dart`, `document_preview_screen.dart`) — their `Colors.*` are an annotation palette / forced-dark viewer, intentional.
- Do NOT invent `ColorScheme` roles that don't exist; only use M3 roles.

---

## Phase 1 — Sanitize the error surface (#6 / #8)

**What to implement (copy, don't transform):**
1. Create `lib/core/api/api_error_mapper.dart` with a PURE function:
   `String friendlyApiMessage(Object error, {String fallback = 'Something went wrong'})`.
   Copy the `DioExceptionType` branching from `upload_notifier.dart:184-191`; map:
   connectionError/timeout → "No connection to the server"; 401/403 →
   "Session expired — please sign in again"; 404 → "Not found"; 5xx →
   "Server error — try again"; else → `fallback`. **Never** interpolate the
   `DioException` object, its `requestOptions.uri`, or response body.
2. Replace the 44 raw `$e`/`$err` interpolations with
   `friendlyApiMessage(e, fallback: '<action-scoped message>')`. Inventory in
   `01-evidence.md` §Copy; start with the full-screen ones
   (`documents_screen.dart:214`, `inbox`/`trash`/`dashboard` error branches,
   `document_detail_screen.dart:1527`) then the SnackBars.

**Documentation references:** `upload_notifier.dart:184-191` (type switch),
`upload_screen.dart:137,141` (good mapped-message example), `dio_client.dart:148-192`
(what a DioException carries — confirm the URL lives in `requestOptions`).

**Verification checklist:**
- New file `test/unit/api/api_error_mapper_test.dart`: feed a `DioException`
  built with a `requestOptions` whose `path` contains `secret-server.example.com`;
  assert the returned string does NOT contain `example.com`, the path, `DioException`,
  or a status code. Cover each mapped type.
- `grep -rn "\\$e'" lib/features | wc -l` trends toward 0 for user-facing `Text(...$e)`.
- `flutter analyze` clean; `flutter test` green.

**Anti-pattern guards:** do not log-and-swallow; do not include the URL in the
"friendly" string; do not add a new dependency — pure Dart function only.

---

## Phase 2 — Enforce the token + color system (#3)

**What to implement (copy, don't transform):**
1. Replace theme-bypassing destructive `Colors.red` with
   `Theme.of(context).colorScheme.error` — copy the exact usage at
   `trash_screen.dart:61`. Sites: `document_detail_screen.dart:233,234,837`,
   `labels_screen.dart:205,362,514,687`, `workflow_detail_screen.dart:170`
   (NOT the editor surfaces).
2. Replace raw spacing literals with `Spacing.*` — copy the usage at
   `dashboard_screen.dart:42,44,50,78`. Target the high-frequency raw `8`/`16`
   in `documents_screen.dart:211-249`, `inbox_screen.dart:106,120`,
   `filter_bottom_sheet.dart:62-262`, `enhance_screen.dart:196-258`. Map
   4→xs, 8→sm, 12→md, 16→lg, 24→xl, 32→xxl. Off-scale values (2/3/6/10/18/20/48)
   stay literal but add a one-line comment why.
3. Move the 4 hardcoded caption `fontSize` (10-13) to the nearest text-theme
   role (`labelSmall`/`bodySmall`) where reasonable.

**Documentation references:** `design_tokens.dart:1-14`, `theme.dart:8-20`,
good examples `trash_screen.dart:61`, `dashboard_screen.dart:42-78`.

**Verification checklist:**
- New `test/unit/style_guard_test.dart`: read every `lib/features/**.dart`
  EXCLUDING the editor allowlist (`annotate_screen`, `crop_screen`,
  `crop_overlay`, `document_preview_screen`, `tag_chip` which computes contrast);
  assert no `Colors.red`/`Colors.green`/`Colors.blue` remain. (Pure file-read
  test, no Flutter binding.)
- `flutter analyze` clean; `flutter test` green; visual smoke unchanged.

**Anti-pattern guards:** do not retheme the editor surfaces; do not change the
seed color; do not introduce a new spacing token — reuse the six.

---

## Phase 3 — Close the accessibility gaps (#2 / #4)

**What to implement (copy, don't transform):**
1. Add `tooltip:` to the 5 unlabeled icon buttons — copy the form at
   `documents_screen.dart:160`. Sites: `inbox_screen.dart:35` ('Search'),
   `document_detail_screen.dart:1680` ('Add share link') / `:1716` ('Delete link'),
   `custom_fields_screen.dart:60` ('Delete field'), `documents_screen.dart:149`
   ('Cancel selection').
2. Give the swipe-only inbox actions a non-gesture alternative: add a trailing
   `PopupMenuButton` to the inbox card with "Remove from inbox" and "Quick assign"
   — copy the trailing-menu pattern from `trash_screen.dart:146`. Keep the
   Dismissible; the menu is the additive accessible path.
3. Mark visual section headers as headings — wrap the `_SectionHeader` Text in
   `Semantics(header: true, child: …)` at `settings_screen.dart:438-452` (and the
   detail-screen section headers).

**Documentation references:** `documents_screen.dart:160` (tooltip),
`trash_screen.dart:146` (trailing PopupMenu), `inbox_screen.dart:125-177`
(the Dismissible to augment).

**Verification checklist:**
- `grep -rn "IconButton(" lib/features | …` spot-check the 5 sites now have
  `tooltip:`.
- Manual: enable TalkBack/VoiceOver, confirm the 5 buttons announce and the
  inbox remove/assign are reachable without swiping.
- `flutter analyze` clean; `flutter test` green.

**Anti-pattern guards:** do not remove the Dismissible (keep the gesture for
sighted users); do not use `semanticLabel:` on the IconButton (use `tooltip:`,
which doubles as the semantic label) — matches the existing 36-tooltip pattern.

---

## Phase 4 — Delete the duplicated scaffolds (#10)

**What to implement (copy, don't transform):**
1. Extract a shared `PaginatedListView<T>` widget into `lib/shared/widgets/`
   that owns the `RefreshIndicator` + `NotificationListener` loadMore block +
   trailing `isLoadingMore` spinner + `loadMoreError` SnackBar listener. Copy the
   canonical implementation from `documents_screen.dart:128-275` (the most
   complete one). Then have inbox + trash consume it
   (`inbox_screen.dart:17-122`, `trash_screen.dart:34-126`).
2. Extract the duplicated `_TagPickerSheet` (defined twice:
   `document_detail_screen.dart:1031`, `upload_screen.dart:615`) into one shared
   `lib/shared/widgets/tag_picker_sheet.dart` — copy the detail-screen version
   as canonical; delete the upload copy and import the shared one.
3. Extract the inlined metadata dropdown (3×) into the existing `_MetadataDropdown`
   pattern at `document_detail_screen.dart:935-957`; promote it to
   `lib/shared/widgets/metadata_dropdown.dart` and reuse in inbox + upload.

**Documentation references:** canonical scaffolds at `documents_screen.dart:128-275`,
`document_detail_screen.dart:935-957,1031-1091`.

**Verification checklist:**
- After extraction, `grep -rn "NotificationListener<ScrollNotification>" lib/features`
  drops from 3 to 0 (now in the shared widget).
- `grep -rn "_TagPickerSheet" lib` shows one definition.
- `flutter analyze` clean; `flutter test` green; the loadMore race regression
  test (`documents_notifier_loadmore_test.dart`) still passes (behavior preserved).

**Anti-pattern guards:** preserve the `identical(state, loadingState)` race guard
when moving the loadMore block (see the comment at `documents_notifier.dart`);
do not change notifier logic — this is a widget extraction only.

---

## Phase 5 — Consolidate redundant affordances (#10 / #5 / #2)

These are judgment calls — present the recommendation, let the executor confirm.

**What to implement:**
1. **Scan affordance (3 → 1 primary):** RECOMMENDED — keep the Scan **nav tab**
   (`app.dart:388`) as the canonical home and the scanner_screen cards
   (`scanner_screen.dart:52/62/72`) as its content; REMOVE the SpeedDial FAB's 3
   scan sub-actions (`app.dart:513/553/593`) so the FAB on Docs becomes a single
   "Upload" quick-action (or drop the FAB on the Docs tab). Rationale: a dedicated
   tab + screen already exists; the FAB triplicates it.
2. **Detail overflow menu (13 → grouped):** collapse the 3 rotate entries
   (`document_detail_screen.dart:185-199`) into one "Rotate" item that opens a
   small CW/180/CCW chooser; group the menu into sections (Transform / Share /
   Danger) using `PopupMenuDivider` you already use.
3. **Dashboard decoy cards:** make the 5 non-interactive stat cards
   (`dashboard_screen.dart:88-118`) either navigate to their filtered list or
   visually de-emphasize (remove the card chrome that implies tappability), so
   only real actions look like actions.

**Documentation references:** `app.dart:382-390,504-644` (nav + FAB),
`document_detail_screen.dart:168-236` (menu), `dashboard_screen.dart:88-118`.

**Verification checklist:**
- Scan reachable from exactly one primary home; cold-launch → scan still ≤2 taps.
- Detail menu item count drops from 13; rotate is one entry.
- `flutter analyze` clean; `flutter test` green; manual pass of scan + detail flows.

**Anti-pattern guards:** do not remove the Scan capability, only its duplicate
entry points; do not introduce a brand-new navigation paradigm (this is REFINE —
Material 3 nav stays); confirm the scan-consolidation choice with the user before
deleting entry points.

---

## Phase 6 — Final Verification

1. `flutter analyze` → clean.
2. `flutter test` → all green (incl. the new `api_error_mapper_test` and
   `style_guard_test`, and the preserved loadMore race + route-args tests).
3. Anti-pattern greps: no user-facing `Text('...$e')`; no `Colors.red` outside
   the editor allowlist; one `_TagPickerSheet`; zero `NotificationListener` copies
   in feature screens.
4. Re-score the five audited principles informally; target: #3 and #10 move from
   1 → 2 (total ≥ 20, crossing into REFINE-confirmed territory).
5. Manual device pass: scan flow, document open/detail, inbox triage with
   TalkBack, an induced network error (confirm no server URL leaks).

## Out of scope (do NOT do in this pass)
- New information architecture or navigation paradigm.
- Re-theming editor surfaces.
- The F-Droid release ritual (separate).
- Admin surfaces (mail rules, user/group perms — out of mobile scope).
