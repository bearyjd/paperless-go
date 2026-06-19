# Paperless-ngx Feature Inventory

## Web UI Features

### Core Document Management

**Document Operations**
- View documents in three different list styles (grid, table, etc.)
- Full-text search across all documents with advanced syntax
- Drag-and-drop file upload to dashboard
- Web upload form with metadata entry
- Batch upload with progress tracking
- Bulk edit operations on multiple documents (set tags, correspondent, document type, storage path, etc.)

**Document Detail View**
- View document metadata (title, created date, correspondent, document type, tags, storage path)
- Download original document
- View archived PDF/A version
- Download PNG thumbnail
- View inline document preview
- Edit all document metadata
- Add and view document notes
- View document change history/audit log
- Set document permissions (owner, view/change rights)
- Share document via email
- Generate public share links with optional expiration

**Document Organization**
- Tag documents (hierarchical support, up to 5 levels deep, parent tags cascade)
- Assign correspondent (source/sender)
- Set document type classification
- Assign storage path (physical filing location)
- Set archive serial number (ASN)
- Create and manage custom fields (text, boolean, date, URL, integer, currency, document links, select lists)
- Filter by custom field values

### Dashboard

- Customizable landing page
- Saved views shortcuts
- Quick document upload
- Recent documents display
- Stats and overview

### Search & Filtering

**Search Capabilities**
- Full-text search with multiple query terms
- Similarity search (`more_like_id` parameter)
- Advanced search syntax: logical operators (AND, OR), field-specific matching (type, tag, correspondent)
- Date range filtering
- Wildcard pattern matching
- Auto-complete suggestions while typing

**Filtering Options**
- Filter by correspondent
- Filter by document type
- Filter by tags (single or multiple)
- Filter by storage path
- Filter by owner/permissions
- Filter by creation date range
- Filter by custom field values

### Saved Views

- Create and name custom document views
- Save filter combinations
- Display on dashboard
- Display in sidebar for quick access
- Dynamic updates as documents added
- Reorder saved views

### Management Sections

**Tags Management**
- Create, edit, delete tags
- Organize hierarchically (nested up to 5 levels)
- Assign colors/icons
- Set permissions on tags
- Bulk tag operations

**Correspondents Management**
- Create, edit, delete correspondents
- Set correspondence rules
- Assign permissions
- Bulk operations on correspondents

**Document Types Management**
- Create, edit, delete document types
- Set permissions
- Bulk operations

**Storage Paths Management**
- Create, edit, delete storage paths
- Organize documents by physical location
- Set permissions

**Custom Fields Management**
- Create custom field types (text, boolean, date, URL, integer, currency, document links, select)
- Edit field definitions
- Define select list options
- Set field visibility
- Assign permissions

### Document Workflows

- Create workflow triggers:
  - Consumption started
  - Document added
  - Document updated/modified
  - Scheduled (cron-based)
- Create workflow actions:
  - Assign tags
  - Remove tags
  - Set correspondent
  - Set document type
  - Set storage path
  - Set owner
  - Set permissions
  - Send email
  - Trigger webhooks
- Enable/disable workflows
- Multiple triggers per workflow
- Multiple actions per workflow

### Email Integration

**Mail Account Configuration**
- Connect to mail servers (IMAP)
- OAuth2 support (Gmail, Outlook) with auto-refresh
- Fetch configuration

**Mail Rules**
- Filter by sender
- Filter by subject
- Filter by body content
- Filter attachments
- Extract attachments
- Apply actions:
  - Delete message
  - Mark as read
  - Flag message
  - Move to folder
  - Add tags
  - Set correspondent
  - Set document type

### PDF Editing

- Rotate pages (90°, 180°, 270°)
- Delete pages
- Rearrange/reorder pages
- Split documents
- Merge multiple documents
- Edit and save as new PDF/A archive

### Access Control & Permissions

**User Management**
- Create/manage users
- Superuser role (full access)
- Admin status (can view logs)
- Two-factor authentication (authenticator app with recovery codes)
- User groups

**Permissions System**
- Global permissions (feature-level access control)
- Object-level permissions (per document, tag, correspondent, etc.)
- Owner assignment
- View rights (read documents)
- Change rights (modify documents)
- Group-based permissions
- Hierarchical permission inheritance

### Document Lifecycle

- Trash system (30 days configurable retention before permanent deletion)
- Restore deleted documents
- Permanent deletion
- Document version tracking
- Audit log of all changes

### Document Sharing

- Share individual documents via email
- Generate public share links
- Set link expiration dates
- Share via workflow/email action
- Share via API

---

## REST API Endpoints

### Authentication

**POST /api/token/**
- Acquire authentication tokens
- Request: username, password (form or JSON)
- Response: Bearer token for Authorization header

### Document Endpoints

**GET /api/documents/**
- List all documents (paginated)
- Query parameters:
  - `page` (pagination)
  - `page_size` (items per page, default varies)
  - `query` (full-text search)
  - `more_like_id` (similarity search)
  - `custom_field_query` (filter by custom field values)
  - `correspondent__id` (filter by correspondent)
  - `document_type__id` (filter by document type)
  - `tags__id__in` (filter by tags, comma-separated)
  - `storage_path__id` (filter by storage path)
  - `owner__id` (filter by owner)
  - Filtering by created/modified dates
- Response: Paginated list with count, next, previous, results
- Full-text search returns: __search_hit__ (score, highlights, rank)

**GET /api/documents/{id}/**
- Retrieve single document metadata and details

**POST /api/documents/**
- Create document (via API, for programmatic consumption)

**PUT /api/documents/{id}/**
- Update document metadata (title, correspondent, document_type, tags, storage_path, custom_fields, permissions, owner)

**PATCH /api/documents/{id}/**
- Partial update of document metadata

**DELETE /api/documents/{id}/**
- Delete document (moves to trash)

**GET /api/documents/{id}/download/**
- Download original document file
- Query parameter: `original=true` to force original vs. archived

**GET /api/documents/{id}/preview/**
- Get inline preview (viewable in browser, not download)

**GET /api/documents/{id}/thumb/**
- Get PNG thumbnail of document

**GET /api/documents/{id}/metadata/**
- Get file metadata (read-only):
  - media_filename: Current stored filename
  - has_archive_version: Boolean
  - original_metadata: List of metadata from original
  - archive_checksum: MD5 checksum (or null)

**GET /api/documents/{id}/notes/**
- List all notes on a document
- Each note includes: id, note text, created date, user info

**POST /api/documents/{id}/notes/**
- Add a note to a document

**GET/PUT/DELETE /api/documents/{id}/notes/{note_id}/**
- Manage individual notes

**POST /api/documents/post_document/**
- Upload document for consumption (multipart/form-data)
- Fields:
  - `document` (file, required)
  - `title` (optional)
  - `correspondent` (optional, ID)
  - `document_type` (optional, ID)
  - `storage_path` (optional, ID)
  - `tags` (optional, repeated field for multiple)
  - `created` (optional, date)
  - `archive_serial_number` (optional)
  - `custom_fields` (optional, array or object mapping)
- Response: task_id (UUID) for tracking consumption progress
- Note: Returns 200 OK but consumption happens asynchronously

### Bulk Operations

**POST /api/documents/bulk_edit/**
- Bulk operations on documents (asynchronous)
- Operations:
  - `set_correspondent`: Set correspondent on documents
  - `set_document_type`: Set document type on documents
  - `set_storage_path`: Set storage path on documents
  - `add_tag`: Add tag to documents
  - `remove_tag`: Remove tag from documents
  - `modify_tags`: Set exact tags on documents
  - `delete`: Delete documents
  - `reprocess`: Reprocess documents (OCR, archive)
  - `set_permissions`: Set view/change permissions
  - `edit_pdf`: Rotate, delete, rearrange pages, merge, split
  - `merge`: Merge multiple documents
  - `split`: Split document into multiple
  - `rotate`: Rotate pages
  - `delete_pages`: Delete pages from document
  - `modify_custom_fields`: Set custom field values
- Request: JSON with documents list, method, parameters
- Response: task_id for tracking

**POST /api/bulk_edit_objects/**
- Bulk operations on tags, correspondents, document_types, storage_paths
- Operations: `set_permissions`, `delete`
- Request: JSON specifying object_type, ids, operation, parameters

### Search & Auto-complete

**GET /api/search/autocomplete/**
- Auto-complete for search terms
- Query parameters:
  - `term` (required, partial search string)
  - `limit` (optional, default 10)
- Response: Ordered suggestions by Tf/Idf score

### Task Management

**GET /api/tasks/**
- List all tasks
- Query parameter: `task_id={uuid}` to get specific task
- Response: Task status, result, progress
- Polling endpoint for tracking uploads, bulk edits, reprocessing

**GET /api/tasks/{task_id}/**
- Get single task details

**POST /api/tasks/acknowledge/**
- Acknowledge/dismiss completed task (API v6+)

### Tags Endpoints

**GET /api/tags/**
- List all tags (paginated)

**GET /api/tags/{id}/**
- Get single tag

**POST /api/tags/**
- Create tag

**PUT /api/tags/{id}/**
- Update tag

**PATCH /api/tags/{id}/**
- Partial update tag

**DELETE /api/tags/{id}/**
- Delete tag

### Correspondents Endpoints

**GET /api/correspondents/**
- List all correspondents (paginated)

**GET /api/correspondents/{id}/**
- Get single correspondent

**POST /api/correspondents/**
- Create correspondent

**PUT /api/correspondents/{id}/**
- Update correspondent

**PATCH /api/correspondents/{id}/**
- Partial update correspondent

**DELETE /api/correspondents/{id}/**
- Delete correspondent

### Document Types Endpoints

**GET /api/document_types/**
- List all document types (paginated)

**GET /api/document_types/{id}/**
- Get single document type

**POST /api/document_types/**
- Create document type

**PUT /api/document_types/{id}/**
- Update document type

**PATCH /api/document_types/{id}/**
- Partial update document type

**DELETE /api/document_types/{id}/**
- Delete document type

### Storage Paths Endpoints

**GET /api/storage_paths/**
- List all storage paths (paginated)

**GET /api/storage_paths/{id}/**
- Get single storage path

**POST /api/storage_paths/**
- Create storage path

**PUT /api/storage_paths/{id}/**
- Update storage path

**PATCH /api/storage_paths/{id}/**
- Partial update storage path

**DELETE /api/storage_paths/{id}/**
- Delete storage path

### Custom Fields Endpoints

**GET /api/custom_fields/**
- List all custom field definitions (paginated)

**GET /api/custom_fields/{id}/**
- Get single custom field definition

**POST /api/custom_fields/**
- Create custom field (type: text, boolean, date, URL, integer, currency, document_link, select)

**PUT /api/custom_fields/{id}/**
- Update custom field

**PATCH /api/custom_fields/{id}/**
- Partial update custom field

**DELETE /api/custom_fields/{id}/**
- Delete custom field

### Saved Views Endpoints

**GET /api/saved_views/**
- List all saved views (paginated)

**GET /api/saved_views/{id}/**
- Get single saved view (filter config, display name, position)

**POST /api/saved_views/**
- Create saved view

**PUT /api/saved_views/{id}/**
- Update saved view

**PATCH /api/saved_views/{id}/**
- Partial update saved view

**DELETE /api/saved_views/{id}/**
- Delete saved view

### Workflows Endpoints

**GET /api/workflows/**
- List all workflows (paginated)

**GET /api/workflows/{id}/**
- Get single workflow

**POST /api/workflows/**
- Create workflow

**PUT /api/workflows/{id}/**
- Update workflow

**PATCH /api/workflows/{id}/**
- Partial update workflow

**DELETE /api/workflows/{id}/**
- Delete workflow

### Mail Account Endpoints

**GET /api/mail_accounts/**
- List all mail accounts (paginated)

**GET /api/mail_accounts/{id}/**
- Get single mail account

**POST /api/mail_accounts/**
- Create mail account (IMAP config, OAuth2 support)

**PUT /api/mail_accounts/{id}/**
- Update mail account

**PATCH /api/mail_accounts/{id}/**
- Partial update mail account

**DELETE /api/mail_accounts/{id}/**
- Delete mail account

### Mail Rules Endpoints

**GET /api/mail_rules/**
- List all mail rules (paginated)

**GET /api/mail_rules/{id}/**
- Get single mail rule

**POST /api/mail_rules/**
- Create mail rule

**PUT /api/mail_rules/{id}/**
- Update mail rule

**PATCH /api/mail_rules/{id}/**
- Partial update mail rule

**DELETE /api/mail_rules/{id}/**
- Delete mail rule

### Users & Groups Endpoints

**GET /api/users/**
- List all users (paginated)

**GET /api/users/{id}/**
- Get single user

**POST /api/users/**
- Create user

**PUT /api/users/{id}/**
- Update user

**PATCH /api/users/{id}/**
- Partial update user

**DELETE /api/users/{id}/**
- Delete user

**GET /api/groups/**
- List all groups (paginated)

**GET /api/groups/{id}/**
- Get single group

**POST /api/groups/**
- Create group

**PUT /api/groups/{id}/**
- Update group

**PATCH /api/groups/{id}/**
- Partial update group

**DELETE /api/groups/{id}/**
- Delete group

### UI Settings & System Endpoints

**GET /api/ui_settings/**
- Get UI configuration (format changed in API v3)

**GET /api/schema/view/**
- Browsable API documentation (interactive endpoint explorer)

---

## Features Ideal for Mobile Client Exposure

### High Priority (Core Functionality)

1. **Document Search & Retrieval**
   - Full-text search
   - Filtering by tags, correspondents, document type
   - Pagination
   - Sorting options
   - Date range filtering

2. **Document Viewing**
   - Thumbnails
   - Inline preview
   - Download original/archived files
   - Quick view mode

3. **Document Metadata Management**
   - View/edit title, created date
   - Assign correspondent, document type, tags, storage path
   - Custom field editing (all types)
   - Permission viewing

4. **Document Notes**
   - View notes
   - Add notes
   - Delete own notes (if permitted)

5. **Bulk Document Operations**
   - Bulk tag assignment
   - Bulk correspondent assignment
   - Bulk document type assignment
   - Bulk storage path assignment
   - Bulk custom field updates
   - Bulk deletion

6. **Quick Document Upload**
   - File upload from camera/gallery
   - Metadata entry during upload
   - Progress tracking
   - Task status polling

7. **Saved Views Access**
   - Browse saved views
   - Apply saved views (open filtered list)

### Medium Priority (Enhanced Features)

8. **Tag Management**
   - View all tags
   - Create new tags on-the-fly
   - Assign/remove tags from documents

9. **Document Sharing**
   - Generate share links
   - Share via email (if app has email capability)

10. **Task Tracking**
    - Monitor upload status
    - Monitor bulk operation status
    - View task completion/failure

11. **Correspondent Quick Access**
    - View correspondents list
    - Auto-complete for correspondent selection

12. **Document Type Quick Access**
    - View document types list
    - Auto-complete for document type selection

### Lower Priority (Advanced Features)

13. **Workflow Viewing** (read-only)
    - View configured workflows
    - Understand automation rules

14. **Storage Path Management**
    - View storage paths
    - Assign storage path to documents

15. **Custom Field Management**
    - View custom field definitions
    - Edit custom field values

16. **Mail Account/Rules Viewing**
    - View mail accounts (status, last sync)
    - View mail rules (read-only)
    - Manual sync trigger

17. **Authentication Features**
    - Token-based auth
    - Session management
    - Token refresh/rotation

18. **Permissions Viewing**
    - View who owns documents
    - See permission restrictions

---

## API Design Recommendations for Mobile Client

### Authentication
- Use `/api/token/` endpoint for login
- Store token securely (iOS Keychain, Android Keystore)
- Implement token refresh mechanism
- Handle 401 Unauthorized gracefully

### Pagination
- Always paginate list endpoints
- Recommended page_size: 25-50 (mobile-friendly)
- Implement infinite scroll or page navigation
- Cache results for offline-ready functionality

### Search & Filtering
- Leverage `query` parameter for full-text search
- Use filter parameters for efficient queries
- Implement local search refinement for cached results
- Show search suggestions from `/api/search/autocomplete/`

### File Downloads
- Cache thumbnails locally
- Include auth headers for image requests (Dio/http interceptors)
- Implement progressive loading (thumb → preview → full document)
- Handle large file downloads with progress indicators

### Async Operations
- Poll `/api/tasks/` after upload or bulk operation
- Show upload/processing progress
- Handle task success/failure states
- Implement exponential backoff for polling

### Custom Fields
- Support all types: text, boolean, date, URL, integer, currency, document_link, select
- Validate based on field definition
- Handle select field options from custom field endpoint

### Error Handling
- Distinguish between client errors (4xx) and server errors (5xx)
- Handle API versioning mismatches
- Implement retry logic for transient failures
- Display user-friendly error messages

### API Versioning
- Specify API version in Accept header: `application/json; version=X`
- Current version: 9 (as of latest docs)
- Handle version-specific field differences
- Document breaking changes in CHANGELOG

