# 02 — Scorecard

Scored by the orchestrator. Rules applied: **score the worst representative
instance**, **tie-break to the lower score**, equal weight, integers 0–3.
Evidence anchors reference `01-evidence.md`.

1. **Good design is innovative — Score: 2/3**
   Evidence: standard Material 3 patterns (NavigationBar, SpeedDial, list/detail, AsyncValue states) — no new UI form; BUT genuine tech-led features: on-device ML Kit OCR → auto metadata suggestion, scan→enhance→OCR pipeline, Paperless-AI chat.
   Justification: refreshes the category with a real technology-driven improvement (2), not a novel UI form (3) nor a wholesale copy (1).

2. **Good design makes a product useful — Score: 2/3**
   Evidence: open-a-document is 1 tap; cold-launch lands on Dashboard not Documents (2 taps); find is split off to a separate search route; 5 decoy stat cards on the dashboard.
   Justification: primary task completes but adjacent surfaces (dashboard-first, split find, decoy cards) add steps (2), more than fewest-possible (3).

3. **Good design is aesthetic — Score: 1/3**
   Evidence: coherent single-seed M3 system, but 13 hardcoded spacing values vs 6 tokens, 9 theme-bypassing color families, destructive red split (9 vs 5 sites), 4 off-theme font sizes.
   Justification: more than two real inconsistencies / orphan styles across the surface (1), though a visible system exists (not 0).

4. **Good design makes a product understandable — Score: 2/3**
   Evidence: domain vocabulary (Correspondent/Storage Path/ASN) is native to the Paperless-ngx target user and mostly clear; concrete defects are 5 unlabeled icon buttons + inconsistent ASN abbreviation.
   Justification: a small number of controls need labels/glosses for the target user (2), not pervasive unclarity with the primary action unidentifiable (0/1).

5. **Good design is unobtrusive — Score: 2/3**
   Evidence: flat M3 (elevation-0 app bar/cards) keeps chrome visually quiet, but there is a lot of it (~6–9 always-visible controls, triplicated scan affordance).
   Justification: chrome is visible but quiet (2), not actively competing decoration (1) nor receding completely (3).

6. **Good design is honest — Score: 2/3**
   Evidence: zero inflation, zero dark patterns, accurate destructive dialogs; one cosmetic "Delete"-means-trash label imprecision, mitigated by a correct confirm dialog.
   Justification: ≤1 minor label imprecision (2); not a clean 1:1 map of every label to behavior (3), and nowhere near a dark pattern (0/1).

7. **Good design is long-lasting — Score: 2/3**
   Evidence: restrained, no fad markers (no glassmorphism, fad gradients, skeuomorphism); total reliance on Material 3's current expressive era is the one dated-marker risk.
   Justification: clean and durable with a single era-marker (2), not trend-chasing (0/1) nor era-neutral (3).

8. **Good design is thorough down to the last detail — Score: 2/3**
   Evidence: all 6 states present and considered, BUT error state is rough (leaks raw Dio dumps), focus rings are framework-default, no semantic headings / liveRegion / focus restoration.
   Justification: states complete but one state rough plus several last-detail gaps (2), not every edge considered (3).

9. **Good design is environmentally friendly — Score: 2/3**
   Evidence: no idle animation, dark mode honored, reduce-motion respected (the three anchor-3 pillars met); offset by runtime font fetch, uncached stats re-fetch, two redundant PDF stacks.
   Justification: motion gated and resource-aware at idle (2), but real avoidable network/dep waste keeps it off a clean 3.

10. **Good design is as little design as possible — Score: 1/3**
    Evidence: scan affordance in 3 places, 13-item overflow menu (3 separate rotate entries), 5 decoy dashboard cards, duplicated list scaffolds + `_TagPickerSheet` ×2 + metadata dropdown ×3.
    Justification: clearly more than two removable/duplicated elements across the surface (1); functional, so not total decoration domination (0).

---

## Total

| # | Principle | Score |
|---|-----------|-------|
| 1 | innovative | 2 |
| 2 | useful | 2 |
| 3 | aesthetic | 1 |
| 4 | understandable | 2 |
| 5 | unobtrusive | 2 |
| 6 | honest | 2 |
| 7 | long-lasting | 2 |
| 8 | thorough | 2 |
| 9 | environmentally friendly | 2 |
| 10 | as little design as possible | 1 |
| | **TOTAL** | **18 / 30** |

No principle scored 0. Two principles (#3 aesthetic, #10 as-little-design)
scored 1 — both rooted in **enforcement/structure** (token drift, redundant
affordances) rather than a broken primary task.
