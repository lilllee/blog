# Blog Admin Interface Documentation

## Overview

This blog includes a built-in admin interface for managing blog posts. The admin panel provides a complete content management system with features for creating, editing, publishing, and organizing posts using a simple markdown-based workflow.

**Key Features:**
- Create and edit blog posts with markdown
- Draft/publish workflow for content control
- Soft delete posts (recoverable from database)
- Tag and series management
- Automatic HTML rendering, table of contents, and reading time calculation
- Simple HTTP Basic Authentication for security

## Authentication

The admin interface is protected by HTTP Basic Authentication, which prompts for a username and password when you access any admin page.

### Development

In development mode, the default credentials are:
- **Username:** `admin`
- **Password:** `admin`

No additional configuration is needed for local development.

### Production

For production deployment, set these environment variables to secure your admin interface:

```bash
BLOG_ADMIN_USER=your_username
BLOG_ADMIN_PASS=your_secure_password
```

**Security Notes:**
- Always use HTTPS in production to encrypt credentials in transit
- Choose a strong, unique password
- HTTP Basic Auth is simple but stores credentials in the browser
- Consider IP whitelisting for additional security
- For multi-user scenarios, consider upgrading to session-based authentication

## Accessing the Admin Interface

1. Start your server (development: `mix phx.server`)
2. Navigate to: `http://localhost:4000/admin/posts` (or your production domain)
3. Enter your username and password when prompted
4. Your browser will remember the credentials for the session

## Features

### Post Management

#### Listing Posts

**URL:** `/admin/posts`

The post list shows all your blog posts (published and drafts) in a table format, excluding deleted posts.

**Columns:**
- **Title** - Post title with a preview of the first 80 characters of content
- **Status** - Visual badge showing "Draft" (amber) or "Published" (green)
- **Published** - Publication date, or insertion date for drafts
- **Tags** - Pill-style tag display
- **Series** - Series ID and order number (if part of a series)
- **Actions** - Quick action buttons for each post

**Available Actions:**
- **Edit** - Opens the post editor
- **Publish/Unpublish** - Toggle between draft and published status
- **Delete** - Soft delete the post (with confirmation dialog)

#### Creating Posts

**URL:** `/admin/posts/new`

Click the "New post" button from the post list to create a new post.

**Form Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| **Title** | Text | Yes | Post title (displayed in lists and as page heading) |
| **Image path** | Text | No | Path to header image (e.g., `/images/header.jpg`) |
| **Tags** | Text | No | Comma-separated tags (e.g., `elixir, phoenix, liveview`) |
| **Categories** | Text | No | Post categories |
| **Series ID** | Text | No | Identifier for grouping related posts (e.g., `getting-started`) |
| **Series order** | Number | No | Numeric position within series (1, 2, 3, ...) |
| **Status** | Select | Yes | Choose "Draft" or "Published" |
| **Markdown** | Textarea | Yes | Post content in markdown format |

**Actions:**
- **Save draft** - Saves the post with "draft" status (not visible publicly)
- **Publish** - Saves the post with "published" status (visible publicly)

**Behavior:**
- Form validates in real-time as you type
- Title and markdown content are required
- Saving automatically generates HTML, TOC, and reading time
- A flash message confirms successful creation
- Redirects to post list after saving

#### Editing Posts

**URL:** `/admin/posts/:id/edit`

Click "Edit" next to any post in the list to modify it.

**Features:**
- All form fields are pre-populated with current values
- Changes are saved to the database
- Markdown is re-rendered on every save
- TOC and reading time are recalculated
- Flash message confirms successful update
- Click "Back to posts" to return without saving

### Post Status Workflow

Posts can be in one of three states:

#### Draft
- **Visibility:** NOT visible on public pages (`/list`, `/item/:id`)
- **Purpose:** Work-in-progress posts, unpublished content
- **Published date:** Not set (remains NULL)
- **Badge color:** Amber/yellow

**Creating drafts:**
- Set status dropdown to "Draft"
- Click "Save draft" button
- Or click "Publish" on a draft in the post list to promote it

#### Published
- **Visibility:** Visible on public blog pages
- **Purpose:** Live, public-facing content
- **Published date:** Automatically set to current UTC time on first publish
- **Badge color:** Green/emerald

**Publishing posts:**
- Set status dropdown to "Published"
- Click "Publish" button
- Or click "Publish" on a draft in the post list

**Important:** The `published_at` timestamp is set once when first published and preserved even if you unpublish and re-publish later.

#### Deleted
- **Visibility:** Hidden from both admin list and public pages
- **Purpose:** Removed content (but recoverable from database)
- **Technical:** Sets `deleted_at` timestamp (soft delete)
- **Recovery:** Requires direct database update

**Deleting posts:**
- Click "Delete" in the post list
- Confirm in the dialog
- Post disappears from list immediately

### Markdown Features

The editor supports GitHub-flavored markdown with additional extensions via the MDEx library.

**Supported Syntax:**

| Feature | Syntax | Example |
|---------|--------|---------|
| Headings | `# H1`, `## H2`, `### H3` | `## Introduction` |
| Bold | `**text**` | `**important**` |
| Italic | `*text*` or `_text_` | `*emphasis*` |
| Strikethrough | `~~text~~` | `~~deleted~~` |
| Code inline | `` `code` `` | `` `let x = 1` `` |
| Code block | ` ```language` | ` ```elixir` |
| Links | `[text](url)` | `[Blog](https://example.com)` |
| Images | `![alt](url)` | `![Logo](/logo.png)` |
| Lists | `- item` or `1. item` | `- First item` |
| Task lists | `- [ ] task` | `- [x] Done` |
| Tables | GitHub markdown tables | See example below |
| Footnotes | `[^1]` with `[^1]: note` | `Reference[^1]` |
| Autolinks | URLs automatically linked | `https://example.com` |

**Table Example:**
```markdown
| Column 1 | Column 2 |
|----------|----------|
| Value A  | Value B  |
```

**Code Block with Syntax Highlighting:**
````markdown
```elixir
defmodule Hello do
  def world do
    IO.puts("Hello, World!")
  end
end
```
````

**Configuration:**
- Smart punctuation enabled (converts quotes, dashes)
- Sanitization enabled for security
- Escape enabled to prevent XSS attacks
- GitHub-style code blocks with language labels

### Auto-Generated Content

When you save a post, the system automatically generates:

#### 1. Rendered HTML
- **Purpose:** Pre-rendered HTML for fast page loads
- **Storage:** `rendered_html` field in database
- **Behavior:** Automatically re-generated on every save
- **Display:** Used on public post pages instead of rendering markdown on demand

#### 2. Table of Contents (TOC)
- **Source:** Extracted from H2 (`##`) and H3 (`###`) headings in markdown
- **Threshold:** Only generated if post has 3 or more headings
- **Format:** JSON array with `{id, title, level}` for each heading
- **IDs:** Auto-generated slugs from heading text (e.g., "Getting Started" → "getting-started")
- **Collision handling:** Duplicate headings get numbered suffixes (e.g., "heading-2", "heading-3")
- **Storage:** `toc` field as JSON string
- **Display:** Rendered as navigation on post detail pages

**Example TOC output:**
```json
[
  {"id": "introduction", "title": "Introduction", "level": 2},
  {"id": "installation", "title": "Installation", "level": 2},
  {"id": "basic-usage", "title": "Basic Usage", "level": 3}
]
```

#### 3. Reading Time
- **Calculation:** Word count ÷ 200 words per minute
- **Word counting:** Excludes code blocks (both fenced and inline) to avoid inflating technical posts
- **Rounding:** Rounded up to nearest minute
- **Minimum:** 1 minute (even for very short posts)
- **Storage:** `reading_time` integer field
- **Display:** Shown on post detail pages (e.g., "5 min read")

### Series Management

Series allow you to group related posts together and provide navigation between them.

#### Creating a Series

1. **Create the first post** with:
   - **Series ID:** A unique identifier (e.g., `elixir-basics`, `phoenix-tutorial`)
   - **Series order:** `1`
2. **Create subsequent posts** with:
   - **Same Series ID** as the first post
   - **Series order:** `2`, `3`, `4`, etc.
3. **Publish all posts** in the series for navigation to work

#### Series Navigation

On public post pages, posts in a series display:
- Previous post link (if exists)
- Next post link (if exists)
- Navigation only shows published, non-deleted posts
- Navigation respects `series_order` field

**Tips:**
- Use descriptive, URL-friendly series IDs (lowercase, hyphens)
- Number posts sequentially (1, 2, 3)
- You can publish posts out of order
- Unpublishing a post hides it from navigation

**Example Series:**
```
Series ID: "phoenix-tutorial"
- Post 1: "Getting Started with Phoenix" (order: 1)
- Post 2: "Creating Your First Controller" (order: 2)
- Post 3: "Working with Ecto" (order: 3)
```

### Tag Management

Tags help organize and filter posts.

#### Adding Tags

In the post editor:
1. Enter tags in the **Tags** field
2. Separate multiple tags with commas
3. Spaces around tags are automatically trimmed
4. Example: `elixir, phoenix, web development, tutorial`

#### Tag Behavior

- **Storage:** Tags are stored as comma-separated strings in the database
- **Parsing:** Split on commas and trimmed when displayed
- **Filtering:** Public list page supports filtering by tag via URL
- **Display:** Tags appear as pills/badges in the admin list and public pages

#### Tag Filtering (Public Site)

Users can filter posts by tag using the URL:
```
http://localhost:4000/list?tag=elixir
```

This shows only published posts containing the tag "elixir".

#### Viewing All Tags

The system tracks all unique tags from published posts:
- Function: `NoteData.list_tags/0`
- Returns: Sorted list of unique tags
- Source: Only published, non-deleted posts

## Common Tasks

### Publishing a New Post

1. Navigate to `/admin/posts`
2. Click **"New post"** button
3. Fill in:
   - **Title:** "My Awesome Blog Post"
   - **Tags:** "tutorial, elixir"
   - **Markdown:** Your post content
4. Click **"Publish"** button
5. Verify post appears in list with green "Published" badge
6. Navigate to `/list` on public site to confirm it's visible

### Saving a Draft for Later

1. Create or edit a post
2. Fill in title and content
3. Set **Status** dropdown to "Draft" (or leave as default)
4. Click **"Save draft"** button
5. Post is saved but NOT visible on public pages
6. You can return to edit it anytime before publishing

### Updating an Existing Post

1. Go to `/admin/posts`
2. Find the post you want to edit
3. Click **"Edit"**
4. Make your changes
5. Click **"Save draft"** to keep as draft, or **"Publish"** to publish
6. Changes are reflected immediately
7. Markdown is re-rendered and TOC/reading time recalculated

### Unpublishing a Post

To remove a post from public view without deleting:

1. In the post list, find the published post
2. Click **"Unpublish"** button
3. Status changes to "Draft" immediately
4. Post disappears from public pages (`/list`, `/item/:id`)
5. Original `published_at` date is preserved
6. Click **"Publish"** again to make it public again

### Deleting a Post

To remove a post from the admin interface:

1. In the post list, find the post
2. Click **"Delete"** button
3. Confirm in the dialog: "Delete this post?"
4. Post disappears from the admin list
5. Post is NOT physically deleted (soft delete)
6. Database record remains with `deleted_at` timestamp set

**Note:** Deleted posts are hidden from both admin and public views. To recover a deleted post, you must manually update the database:

```sql
UPDATE note SET deleted_at = NULL WHERE id = :id;
```

After recovery, the post will reappear in the admin list.

## Troubleshooting

### Cannot Access Admin Pages

**Symptom:** Browser doesn't prompt for login, or shows "Not Found"

**Solutions:**
- Verify server is running (`mix phx.server`)
- Check URL is correct: `/admin/posts` (not `/admin`, not `/posts`)
- Ensure admin routes are defined in `router.ex`
- Check server logs for errors

### Authentication Fails

**Symptom:** Username/password rejected, or repeated login prompts

**Solutions:**
- **Development:** Default is `admin` / `admin` (both lowercase)
- **Production:** Check environment variables are set correctly:
  ```bash
  echo $BLOG_ADMIN_USER
  echo $BLOG_ADMIN_PASS
  ```
- **Browser cache:** Try incognito/private window
- **Typos:** Credentials are case-sensitive
- **Server restart:** Restart server after changing environment variables

### Post Not Appearing on Public Pages

**Symptom:** Published post doesn't show on `/list` or `/item/:id`

**Checklist:**
- ✓ Post status is "Published" (check admin list for green badge)
- ✓ Post is not deleted (`deleted_at` should be NULL)
- ✓ Hard refresh browser (Ctrl+F5 or Cmd+Shift+R)
- ✓ Check database: `SELECT id, title, status, deleted_at FROM note WHERE id = :id`
- ✓ Check server logs for errors

### Markdown Not Rendering Correctly

**Symptom:** Markdown appears as plain text, or formatting is broken

**Solutions:**
- **Check syntax:** Validate markdown in a preview tool (e.g., StackEdit, Dillinger)
- **Code blocks:** Use triple backticks with language:
  ````
  ```elixir
  code here
  ```
  ````
- **Special characters:** Escape characters like `<`, `>`, `&` in text
- **Re-save post:** Edit post and save again to re-render HTML
- **Check logs:** Look for MDEx parsing errors in server console

### Table of Contents Not Appearing

**Symptom:** Post has headings but no TOC renders

**Requirements:**
- ✓ Post must have **at least 3 headings** (H2 or H3)
- ✓ Use `##` (H2) or `###` (H3) syntax
- ✓ H1 (`#`) headings are NOT included in TOC
- ✓ Save the post to regenerate TOC

**Example of valid TOC-generating markdown:**
```markdown
## Introduction
Some content here.

## Getting Started
More content.

### Installation
Details about installation.
```

This has 2 H2 and 1 H3 = 3 total headings, so TOC will be generated.

### Changes Not Saving

**Symptom:** Edits disappear after clicking save

**Solutions:**
- Check for validation errors (red text under fields)
- Ensure **Title** and **Markdown** fields are filled
- Check server logs for database errors
- Verify database connection is working
- Check browser console for JavaScript errors

### "Stale" or Outdated Content

**Symptom:** Public page shows old version after editing

**Solutions:**
- **Hard refresh** browser: Ctrl+F5 (Windows) or Cmd+Shift+R (Mac)
- **Check database:** Verify `rendered_html` was updated
- **Re-save post:** Open in editor and save again
- **Clear browser cache:** Or try incognito/private window

## Technical Details

### Database Schema

**Table:** `note`

**Key Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `id` | Integer | Primary key |
| `title` | String | Post title (required) |
| `content` | Text | Legacy field, mirrors `raw_markdown` |
| `raw_markdown` | Text | Original markdown input |
| `rendered_html` | Text | Pre-rendered HTML output |
| `image_path` | String | Optional header image path |
| `tags` | String | Comma-separated tag list |
| `categories` | String | Post categories |
| `series_id` | String | Series identifier |
| `series_order` | Integer | Position within series |
| `status` | String | "draft" or "published" |
| `published_at` | DateTime (UTC) | Publication timestamp |
| `deleted_at` | DateTime (UTC) | Soft delete timestamp |
| `reading_time` | Integer | Estimated minutes to read |
| `toc` | Text | JSON-encoded table of contents |
| `inserted_at` | DateTime (UTC) | Creation timestamp |
| `updated_at` | DateTime (UTC) | Last update timestamp |

**Indexes:**
- `note(title)`
- `note(tags)`
- `note(series_id)`
- `note(status)`
- `note(deleted_at)`

**Additional:**
- Full-text search table: `note_fts` (SQLite FTS5)

### Key Files

**Admin Interface:**
- `lib/blog_web/router.ex` - Route definitions
- `lib/blog_web/admin_auth.ex` - HTTP Basic Auth plug
- `lib/blog_web/live/admin/post_index_live.ex` - Post list LiveView
- `lib/blog_web/live/admin/post_edit_live.ex` - Post editor LiveView

**Business Logic:**
- `lib/blog/note.ex` - Note schema and changeset
- `lib/blog/note_data.ex` - CRUD operations and queries
- `lib/blog_web/markdown.ex` - Markdown rendering and TOC generation

**Database:**
- `priv/repo/migrations/*_note.exs` - Initial table
- `priv/repo/migrations/*_add_series_fields_to_note.exs` - Series support
- `priv/repo/migrations/*_add_admin_fields_to_notes.exs` - Admin fields

### Architecture

**Technology Stack:**
- **Framework:** Phoenix 1.7+ with LiveView
- **Database:** SQLite3
- **Markdown:** MDEx library (Rust-based, fast)
- **HTML Parsing:** Floki (for TOC extraction)
- **Authentication:** Plug.BasicAuth (HTTP Basic Auth)
- **Styling:** Tailwind CSS

**LiveView Benefits:**
- Real-time form validation without page refresh
- Instant UI updates (publish/unpublish, delete)
- Persistent connection for responsive admin experience
- Server-rendered for security (no client-side auth bypass)

### Security Considerations

**Current Security:**
- HTTP Basic Authentication for admin access
- CSRF protection on all forms
- XSS prevention via MDEx sanitization and HTML escaping
- SQL injection prevention via Ecto parameterized queries
- Soft deletes prevent accidental data loss

**Production Recommendations:**
- ✓ Always use HTTPS (encrypts basic auth credentials)
- ✓ Use strong, unique password (16+ characters, mixed case, numbers, symbols)
- ✓ Change default admin credentials immediately
- ✓ Consider IP whitelisting for admin routes
- ✓ Regular database backups
- ✓ Monitor server logs for suspicious activity

**Limitations of HTTP Basic Auth:**
- No session management or logout
- Credentials stored in browser memory
- Not suitable for multiple users with different permissions
- For production multi-user scenarios, consider upgrading to:
  - Session-based authentication with bcrypt password hashing
  - Two-factor authentication (2FA)
  - Role-based access control (RBAC)

### Environment Variables

**Required for Production:**

| Variable | Purpose | Default (Dev) | Example |
|----------|---------|---------------|---------|
| `BLOG_ADMIN_USER` | Admin username | `admin` | `blogauthor` |
| `BLOG_ADMIN_PASS` | Admin password | `admin` | `MyS3cur3P@ssw0rd!` |

**Setting in Production:**

```bash
# Linux/Mac
export BLOG_ADMIN_USER="your_username"
export BLOG_ADMIN_PASS="your_secure_password"

# Or in .env file (with proper security)
BLOG_ADMIN_USER=your_username
BLOG_ADMIN_PASS=your_secure_password
```

```powershell
# Windows PowerShell
$env:BLOG_ADMIN_USER="your_username"
$env:BLOG_ADMIN_PASS="your_secure_password"
```

For deployment platforms (Fly.io, Render, Heroku), use their environment variable configuration interface.

## Advanced Usage

### Bulk Operations

Currently, bulk operations (delete/publish multiple posts) are not supported in the UI. For bulk changes, use Elixir console:

```elixir
# Start IEx console
iex -S mix

# Publish all drafts
Blog.NoteData.list_admin_notes()
|> Enum.filter(&(&1.status == "draft"))
|> Enum.each(fn post ->
  Blog.NoteData.toggle_publish(post, "published")
end)

# Delete posts by tag
Blog.NoteData.list_admin_notes()
|> Enum.filter(fn post -> String.contains?(post.tags || "", "outdated") end)
|> Enum.each(&Blog.NoteData.soft_delete_note/1)
```

### Direct Database Access

For advanced operations or data recovery, connect to SQLite:

```bash
# Development
sqlite3 blog_dev.db

# Common queries
SELECT id, title, status, deleted_at FROM note;
UPDATE note SET deleted_at = NULL WHERE id = 123;  -- Recover deleted post
UPDATE note SET status = 'published' WHERE id = 456;  -- Force publish
```

**Warning:** Direct database edits bypass validation and auto-generation. Always use the admin interface when possible.

### Custom Markdown Extensions

The markdown renderer is configured in `lib/blog_web/markdown.ex`. To enable additional MDEx features, edit the `@mdex_opts` module attribute.

Current extensions:
- Strikethrough, tables, autolinks, task lists, footnotes, shortcodes
- Smart punctuation, relaxed task lists
- GitHub-style code blocks
- HTML sanitization for security

Refer to [MDEx documentation](https://hexdocs.pm/mdex/) for additional options.

## Future Enhancements

Potential features for future development:

- **Image Upload:** Direct file upload instead of manual path entry
- **Live Preview:** Split-pane markdown editor with real-time rendering
- **Rich Tag Editor:** Chip-based tag input with autocomplete
- **Series Selector:** Dropdown of existing series instead of text input
- **Search & Filter:** Search posts in admin list by title/content
- **Pagination:** Page through large post lists
- **Bulk Actions:** Select multiple posts for bulk delete/publish
- **Post Scheduling:** Schedule posts to publish at a future date
- **Version History:** Track post revisions and revert changes
- **Multi-user Support:** User accounts with role-based permissions
- **Analytics:** View counts, popular posts dashboard
- **Import/Export:** Backup posts as markdown files

## Getting Help

If you encounter issues not covered in this documentation:

1. **Check server logs:** Look for error messages in the console
2. **Verify database:** Use `sqlite3 blog_dev.db` to inspect data
3. **Review code:** Check the files listed in "Key Files" section
4. **Test in isolation:** Create a minimal test post to isolate the issue
5. **Restart server:** Sometimes a fresh start resolves state issues

For Phoenix/Elixir questions:
- [Phoenix Framework Guides](https://hexdocs.pm/phoenix/overview.html)
- [Phoenix LiveView Docs](https://hexdocs.pm/phoenix_live_view/)
- [Elixir Forum](https://elixirforum.com/)

---

**Version:** 1.0
**Last Updated:** 2025-12-16
