# 04 — /make-plan Handoff

Copy-paste the fenced prompt below into a fresh session. It is self-contained.

````
/make-plan Redesign Paperless Go's information architecture and design-system enforcement. Current design scored 18/30 on a Dieter Rams audit with critical gaps in principles #3 (aesthetic, 1/3) and #10 (as little design as possible, 1/3), driven by structural redundancy in the IA.

Verdict paragraph (quoted from the audit):
> Paperless Go has strong design bones (a coherent Material 3 system, all six UI states, honest copy, dark mode) but scores 18/30 because its information architecture carries structural redundancy — the same affordance appears in three places, a 13-item flat overflow menu, and duplicated list scaffolds — which is an IA-level problem to reorganize, not a styling tweak, so it crosses the REFINE→REDESIGN line.

Why redesign and not refine: total < 20, AND the two failing principles (#10, #5) are structural — "scan lives in 3 places" and a 13-item flat menu are navigation/IA problems, and changing structure is redesign territory, not refinement. No load-bearing principle (#2/#4/#6) scored 0, so this is a scoped redesign with a LARGE preserve list, not a from-scratch rebuild.

Preserve from current design (do NOT rebuild these):
- The single-seed Material 3 ColorScheme system and centralized component themes — lib/core/theme.dart:8-69 (seed Color(0xFF17541f), useMaterial3, flat elevation-0 AppBar/Card).
- All six UI states via AsyncValue.when (empty/loading/error/success/focus/disabled) and the reduce-motion-aware skeletons — lib/shared/widgets/loading_skeleton.dart:13-15; lib/features/documents/documents_screen.dart:204-260.
- Honest copy and accurate destructive dialogs (no dark patterns, no inflation) — lib/features/trash/trash_screen.dart:213-227; lib/features/documents/document_detail_screen.dart:831-838.
- Dark mode + persistence (system/light/dark) — lib/core/auth/auth_provider.dart:197-221; lib/app.dart:300-302.
- Inter typography — lib/core/theme.dart:25. The token definitions in lib/core/design_tokens.dart (Spacing 4/8/12/16/24/32, Radii 4/12/16) — keep as the system to ENFORCE everywhere.

Discard (structural patterns causing the failures):
- Triplicated scan affordance. Evidence: lib/app.dart:513/553/593 (FAB) + :388 (nav tab) + lib/features/scanner/scanner_screen.dart:52/62/72 (cards). Caused failure on #10 and #5.
- 13-item flat overflow menu with 3 separate rotate entries. Evidence: lib/features/documents/document_detail_screen.dart:168-236. Caused failure on #10.
- Duplicated list scaffolds (loadMore + error-SnackBar + empty/error Columns copied across 3 screens) and _TagPickerSheet defined twice + metadata dropdown inlined 3×. Evidence: lib/features/documents/documents_screen.dart:128-275, lib/features/inbox/inbox_screen.dart:17-122, lib/features/trash/trash_screen.dart:34-126; lib/features/documents/document_detail_screen.dart:1031 + lib/features/scanner/upload_screen.dart:615. Caused failure on #10.
- Token-bypassing hardcoded styles: 13 spacing literals vs 6 tokens, 9 theme-bypassing color families, destructive red split (Colors.red 9 sites vs colorScheme.error 5). Caused failure on #3.
- Dashboard decoy cards: 5 of 6 stat cards non-interactive but styled like the 1 interactive one. Evidence: lib/features/dashboard/dashboard_screen.dart:88-118. Caused failure on #2/#10.
- Raw-exception error interpolation: 44 sites leak DioException dumps (incl. server URL). Evidence: lib/features/documents/documents_screen.dart:214; lib/features/documents/document_detail_screen.dart:290,1527. Caused failure on #6/#8.

Top 5 moves from the audit (verbatim):
1. #10/#5 — Collapse the triplicated scan affordance to one home. Evidence: app.dart:513/553/593 + :388 + scanner_screen.dart:52/62/72.
2. #10 — Flatten the 13-item document-detail overflow menu; 3 rotate entries → one control; group transform/share/destructive. Evidence: document_detail_screen.dart:168-236.
3. #3 — Enforce the existing token + ColorScheme system everywhere; remove hardcoded spacing/color/font. Evidence: 13 spacing literals vs 6 tokens; Colors.red 9 vs colorScheme.error 5.
4. #6/#8 — Add one mapped exception layer so errors stop leaking Dio/server-URL dumps into SnackBars. Evidence: 44 raw $e interpolations, documents_screen.dart:214.
5. #2/#4 (a11y) — Replace gesture-only inbox actions with button alternatives and label the 5 unlabeled icon buttons. Evidence: inbox_screen.dart:125-177; inbox_screen.dart:35, document_detail_screen.dart:1680/1716, custom_fields_screen.dart:60.

Redesign principles in priority order:
1. As little design as possible (#10) — one affordance per task, one home for scan, flat-menu consolidation; removing any surviving element should break a task.
2. Aesthetic (#3) — every spacing/color/type value flows from design_tokens.dart + the ColorScheme; zero orphan styles.
3. Useful (#2) — land on the document list or make the dashboard's cards all real navigation; no decoy actions.

Deliverables for the plan:
- New information architecture (scan home, nav structure, detail-action grouping) — not derived from the old triplication.
- New primary flow (find→open, scan→upload) low-fi and labeled, compared side-by-side to current.
- States checklist (empty/loading/error/success/focus/disabled) — preserve current coverage, add sanitized error copy + liveRegion/semantic headings.
- A shared list-scaffold + shared TagPicker/metadata-dropdown to delete the duplication.
- Migration path: this is an in-place app update (no user-facing data migration); cutover = the redundant entry points removed in one release with the changelog noting the consolidated scan flow.
- Cutover criteria: old scan FAB/tab/card triplication retired; token-lint (no hardcoded Colors.red / raw spacing) passes; mapped exception layer in place.

Anti-patterns to guard against (specific to REDESIGN):
- Porting the old triplicated structure under new styling.
- Keeping both the old and new scan entry points behind a flag indefinitely.
- Redesigning to a trend rather than to the principles above (Material 3 restraint stays).
- Treating the Preserve list as optional — the M3 system, states, honesty, and dark mode must survive intact.
````
