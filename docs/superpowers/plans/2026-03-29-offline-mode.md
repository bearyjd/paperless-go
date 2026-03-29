# Offline Mode Improvements — Future Plan

> **Status:** Planning only. This is a multi-session architectural project.

**Goal:** Cache documents, tags, correspondents, and other metadata locally so the app works offline. Sync changes when connectivity returns.

**Architecture approach:**
1. **Drift (SQLite) tables** for documents, tags, correspondents, document types, storage paths — mirror the server data
2. **Cache-first providers** — read from Drift first, fetch from API in background, update cache on success
3. **Write queue** — queue mutations (tag changes, metadata edits) when offline, flush on reconnect
4. **Thumbnail cache** — already using `CachedNetworkImage`, but needs offline fallback
5. **Conflict resolution** — last-write-wins for simple fields, merge for tags

**Key decisions needed before implementation:**
- How much data to cache (all documents vs recent N?)
- How to handle document content/PDFs (large files, storage budget)
- Sync frequency and background sync strategy
- Conflict UI (show conflicts to user vs auto-resolve?)

**Estimated scope:** 5-8 tasks across 2-3 sessions. Requires brainstorming session first.

**Dependencies:** Drift is already in the project (used for AI edit trail). The connectivity service already exists (`ConnectivityNotifier`). The offline banner already shows in `_AppShell`.
