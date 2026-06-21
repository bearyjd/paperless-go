# 03 — Verdict

## Verdict: REDESIGN (scoped) — total 18/30

**One sentence:** Paperless Go has strong design bones (a coherent Material 3
system, all six UI states, honest copy, dark mode) but scores 18/30 because its
**information architecture carries structural redundancy** — the same affordance
appears in three places, a 13-item flat overflow menu, and duplicated
list scaffolds — which is an IA-level problem to reorganize, not a styling tweak,
so it crosses the REFINE→REDESIGN line.

## Why REDESIGN and not REFINE

Per the rule, total < 20 → REDESIGN. Critically, no load-bearing principle (#2
useful, #4 understandable, #6 honest) scored 0 — they are all 2 — so this is a
**scoped redesign with a large Preserve list**, not a from-scratch rebuild. The
two 1-scores (#3 aesthetic, #10 as-little-design) are the drivers, and #10 +
#5 are *structural*: fixing "scan lives in 3 places" and "13-item menu" changes
the navigation/IA, which the skill explicitly classifies as redesign-not-refine
territory ("if structure must change, this should be REDESIGN").

## Highest-leverage moves (spine of the next plan)

1. **#10 / #5 — Collapse the triplicated scan affordance to one home.**
   Scan appears as SpeedDial FAB (`app.dart:513/553/593`), a Scan nav tab
   (`app.dart:388`), and scanner_screen cards (`scanner_screen.dart:52/62/72`).
   Pick one; this is an IA decision, not a restyle.

2. **#10 — Flatten the 13-item document-detail overflow menu.**
   `document_detail_screen.dart:168-236` — collapse 3 rotate entries into one
   rotate control; group transform / share / destructive actions.

3. **#3 — Enforce the token + color system that already exists.**
   13 hardcoded spacing values vs 6 tokens, 9 theme-bypassing color families,
   destructive red split (`Colors.red` 9 sites vs `colorScheme.error` 5).
   Route everything through `design_tokens.dart` + the ColorScheme.

4. **#6 / #8 — Sanitize the error surface.**
   44 raw `$e`/`$err` interpolations leak `DioException` dumps incl. the server
   URL into SnackBars/error screens (e.g. `documents_screen.dart:214`,
   `document_detail_screen.dart:290`). Add one mapped exception layer.

5. **#2 / #4 (a11y) — Close the gesture-only and unlabeled-control gaps.**
   Inbox remove/assign are swipe-only with no button alternative
   (`inbox_screen.dart:125-177`); 5 icon buttons are unlabeled to screen readers
   (`inbox_screen.dart:35`, `document_detail_screen.dart:1680,1716`,
   `custom_fields_screen.dart:60`, `documents_screen.dart:149`).

## Honest framing

This is a high-REDESIGN / borderline call (2 points under the REFINE threshold).
The product is genuinely good; the verdict reflects that its *redundancy and
inconsistency are structural*, so the next pass should reorganize the IA and
enforce the system — while preserving the visual language, state handling, and
honest copy wholesale.
