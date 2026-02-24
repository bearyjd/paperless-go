# Bug: tag-color-field-name-mismatch

## Observed behavior
Tag colors are never displayed. All tags render with the default theme `secondaryContainer` color instead of their configured color from Paperless-ngx.

## Expected behavior
Tags should display with their configured background color from the server (e.g., `#a6cee3`).

## Steps to reproduce
1. Open any screen showing tag chips (inbox, documents, document detail)
2. Observe all tags use the same default theme color
3. Compare with Paperless-ngx web UI where tags have distinct colors

## Severity
critical

## Notes
- `lib/core/models/tag.dart:12` — field is named `colour` (British spelling)
- `lib/core/models/tag.g.dart:13` — generated code reads `json['colour']` from API response
- Paperless-ngx API v9 sends the field as `color` (American spelling)
- The field will always deserialize as `null` since the key never matches
- Fix: add `@JsonKey(name: 'color')` annotation to the `colour` field, or rename to `color`
- Additionally, `textColor` at line 13 with `@JsonKey(name: 'text_color')` does not exist in API v9 — text color is computed client-side from background color contrast
- `lib/shared/widgets/tag_chip.dart:10-13` — uses `tag.colour` and `tag.textColor`, both always null
