# Bug: document-card-tag-row-overflow

## Observed behavior
Yellow/black "bottom overflowing" stripe appears on document cards when tags have long names. Three tags with 15+ character names overflow the Row's horizontal space.

## Expected behavior
Tag chips should wrap to a new line or be constrained with ellipsis to fit within the card width.

## Steps to reproduce
1. Open documents or inbox screen
2. View a document that has 3 tags with long names (e.g., "Financial Documents", "Tax Preparation", "Year End Reports")
3. Observe yellow/black RenderFlex overflow indicator on the right side

## Severity
high

## Notes
- `lib/shared/widgets/document_card.dart:133-144` — `Row` with no wrapping or flexible constraints
- `TagChip` at `lib/shared/widgets/tag_chip.dart:15` — `Container` sizes to content with no max width
- The chip has `maxLines: 1` and `TextOverflow.ellipsis` (line 28-29) but the `Container` itself has no width constraint, so ellipsis never triggers
- Fix options:
  1. Change `Row` to `Wrap` for multi-line tag layout
  2. Wrap each `TagChip` in `Flexible` so they shrink to fit
  3. Add `ConstrainedBox(maxWidth: 120)` around each `TagChip`
  4. Combination: use `Flexible` + max width constraint
