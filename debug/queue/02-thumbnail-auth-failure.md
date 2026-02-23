# Bug: thumbnail-auth-failure

## Observed behavior
Document thumbnails fail to load in the document list view. The list renders but all thumbnails show the broken image placeholder. Console shows 403 Forbidden errors for thumbnail requests.

## Expected behavior
Thumbnails should load correctly, displaying a preview of each document in the list.

## Steps to reproduce
1. Open the app and connect to the Paperless-ngx server
2. Navigate to the Documents list
3. Observe that no thumbnails are displayed
4. Check debug console for 403 errors on `/api/documents/<id>/thumb/`

## Severity
high

## Notes
Thumbnails require the auth token in the request headers. The Paperless-ngx API does not support query-parameter auth for these endpoints. If using `Image.network()`, a custom HTTP client or `CachedNetworkImage` with headers is needed.
