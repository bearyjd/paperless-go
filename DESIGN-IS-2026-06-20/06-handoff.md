# 06 — Session Handoff (2026-06-20)

Pick-up doc so a fresh session can continue cold. Everything below is verified
(analyze clean, full test suite green) at handoff time.

## Git state

| Ref | HEAD | Notes |
|-----|------|-------|
| local `main` | `e0cde8b` | **8 commits ahead of origin/main, unpushed** |
| `origin/main` (GitHub) | `c5cb030` | has the PR #2 work (audit-bug fixes + CI workflow) |
| `gitlab/main` (F-Droid) | `1fa811a` | has the 2 audit-bug fixes cherry-picked; NOT the error/color work |

**8 unpushed commits on local main** (this session's refine work):
- `f899e9f` fix: sanitize API errors so the UI stops leaking server internals
- `2269d15` fix: sanitize upload-failure errors and harden the API error mapper
- `24a8cd2` refactor: theme destructive colors and add a style guard test
- `32b839d` refactor: extract destructiveButtonStyle helper; harden style guard
- `7330a10` feat: close accessibility gaps (tooltips, inbox actions menu, header semantics)
- `cd99df0` refactor: extract shared PaginatedListView for documents/inbox/trash
- `cf76c1a` refactor: extract shared TagPickerSheet, dedupe detail/upload copies
- `e0cde8b` refactor: extract shared MetadataDropdown, reuse in detail/inbox/upload

**Untracked:** `DESIGN-IS-2026-06-20/` (the audit + plan + this handoff). Not committed — decide whether to `git add` as `docs:` or `.gitignore`.

Tests: **175 passing**. `flutter analyze`: clean.

## What shipped this session

1. **Earlier (already on origin via PR #2):** loadMore race fix across documents/inbox/trash, `/scan/*` route-arg guards (`lib/core/router/scan_route_args.dart`), scan/upload lifecycle fixes, a PR CI workflow (`.github/workflows/ci.yml` — analyze + test on PRs).
2. **Dieter Rams design audit** → verdict **18/30, scoped REDESIGN**, reframed as a **REFINE** plan. Artifacts: `00`–`05` in this dir.
3. **Refine Phase 1 (error sanitization) — DONE.** `lib/core/api/api_error_mapper.dart` (`friendlyApiMessage()`); 68 user-facing error renders sanitized; upload-failure leak closed; debug-only breadcrumb. Tests: `api_error_mapper_test.dart`, `upload_error_sanitization_test.dart`.
4. **Refine Phase 2 (token/color) — PARTIAL DONE.** 8 destructive `Colors.red` → `colorScheme.error` via `lib/shared/widgets/destructive_button_style.dart`; guard test `test/unit/style_guard_test.dart` (Colors.red + raw errorMessage).

## Refine plan status (see `05-refine-plan.md`)

- **Phase 1 (errors)** — ✅ DONE
- **Phase 2 (token/color)** — ✅ color half + guard DONE. **DEFERRED:** the spacing-token sweep (`16`→`Spacing.lg`, ~120 invisible edits, no guard) and 4 font-size moves. Do as a standalone `style:` commit only if strict token discipline is wanted.
- **Phase 3 (a11y)** — ✅ DONE (`7330a10`). Tooltips on the 5 icon buttons; `DocumentCard` gained an optional `trailing` slot, used by the inbox card for a `PopupMenuButton` (Remove from inbox / Quick assign) as a non-swipe alternative (Dismissible kept); section headers wrapped in `Semantics(header: true)` — settings `_SectionHeader` + 6 detail headers. analyze clean, 175 tests green. **Device-verified** on Pixel 9 Pro Fold (release build, same-signed install over the top, login preserved): inbox cards show the ⋮ menu → opens to Remove from inbox / Quick assign; detail screen renders all section headers (Tags/Custom Fields/Notes/Share Links/Content) with no layout regression. **Remaining (screen-reader-only):** confirm header role + tooltip labels announce under TalkBack — not observable in screenshots.
- **Phase 4 (dedup)** — ✅ DONE. `PaginatedListView` (`cd99df0`), shared `TagPickerSheet` (`cf76c1a`), shared `MetadataDropdown` (`e0cde8b`) — all in `lib/shared/widgets/`. `NotificationListener<ScrollNotification>` copies in features 3→0; one `TagPickerSheet` definition; id-keyed inline dropdowns in inbox+upload replaced by the shared object-keyed widget (extended with optional `suffix` + nullable `onChanged` for upload's AI badge + disabled state). analyze clean, 175 tests green. (`destructiveButtonStyle` was extracted in Phase 2.)
- **Phase 5 (consolidate)** — ✅ DONE (`7682ef9`). Scan 3→1: SpeedDial FAB on Home/Docs replaced by a single + FAB that opens the canonical Scan tab (`_SpeedDialFab` deleted). Detail menu: 3 rotate items → one "Rotate" with a CW/180/CCW chooser. Dashboard: Documents card now navigates to `/documents` (Inbox already did); the other 4 stat cards stay non-interactive (already drop the chevron/ripple when `onTap` is null). User sign-off: FAB→open-Scan-tab, collapse-rotate+group, navigate-where-possible. analyze clean, 181 tests green.
- **Phase 6 (verify)** — ⏳ final.

## Open threads / decisions for next session

1. **Push the 4 unpushed commits** to `origin` (`git push`). User convention: "merge it" = push; never push `main` to **gitlab** (diverged history).
2. **GitLab/F-Droid:** the error-sanitization + color work (`f899e9f`..`32b839d`) is NOT on gitlab. If it should reach F-Droid, cherry-pick onto a branch off `gitlab/main` and fast-forward (the loadMore/route fixes were delivered this way → `1fa811a`). The GitHub-specific `ci.yml` should NOT cross over.
3. **`DESIGN-IS-2026-06-20/`** — commit as `docs:` or gitignore? Currently untracked.
4. **F-Droid release ritual** (version bump + `metadata/en-US/changelogs/<versionCode>.txt` + git tag) is a separate step, not done.

## Gotchas (read before editing)

- **DO NOT run `dart format`** on edits. The repo is NOT format-clean (lines >80 everywhere); a `dart format` pass reformatted ~2,800 lines in Phase 1 and had to be reverted. Make minimal, surgical edits only. CI runs analyze + test, NOT format.
- Relative cross-layer imports resolve against the **package root** — excess `../` clamps (so `../../../core` and `../../core` both worked, but normalize to the correct depth `../../core`).
- The `claude-mem` PostToolUse hook emits "Malformed JSON" errors on large multi-line edits — harmless plugin noise, not a real failure.
- Generated `.g.dart`/`.freezed.dart` are committed; no `build_runner` needed unless model/provider signatures change.
