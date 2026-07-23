# Bug: Thumbnails fail to load with 401 after token refresh

## Observed behavior
After a user's API token is rotated (re-login or manual token change in
Settings), document thumbnails in the Documents list keep showing the
broken-image placeholder even though the document list itself loads fine.
Tapping a document opens the PDF preview successfully.

## Expected behavior
Thumbnails should load using the current auth token, the same as the PDF
preview and download endpoints do.

## Steps to reproduce
1. Log in and let the Documents list load (thumbnails visible).
2. In Settings, update/rotate the API token (or log out and back in with a
   new token).
3. Return to the Documents list without a full app restart.
4. Observe thumbnails now fail to load while document metadata is current.

## Severity
medium

## Notes
`PaperlessApi.thumbnailUrl()` (lib/core/api/paperless_api.dart) builds a
plain URL string; whatever widget renders it (likely `CachedNetworkImage`
in `lib/shared/widgets/`) needs to attach the `Authorization` header
per-request, not just at image-widget construction time, or it will keep
using whatever token was captured when the widget/provider was first built.
This is a worked example bug file for the overnight queue format — remove
or replace once a real bug is queued.
