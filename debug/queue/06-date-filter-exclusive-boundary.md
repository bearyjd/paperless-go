# Bug: date-filter-exclusive-boundary

## Observed behavior
Date range filters exclude documents created on the boundary dates. Selecting "From: Jan 1" and "To: Jan 31" excludes documents created on Jan 1 and Jan 31.

## Expected behavior
Boundary dates should be inclusive. Documents created on the selected start and end dates should appear in results.

## Steps to reproduce
1. Open documents screen
2. Open filter sheet and set date range to a specific start and end date
3. Notice documents created exactly on those dates are missing from results

## Severity
medium

## Notes
- `lib/core/api/paperless_api.dart:49` — uses `created__date__gt` (greater than, exclusive)
- `lib/core/api/paperless_api.dart:53` — uses `created__date__lt` (less than, exclusive)
- Django/Paperless-ngx supports `created__date__gte` (greater than or equal) and `created__date__lte` (less than or equal)
- Fix: change `__gt` to `__gte` and `__lt` to `__lte`
