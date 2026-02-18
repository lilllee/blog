# JunHo's Dev Blog

A personal developer blog built with Elixir/Phoenix, focused on backend engineering, Elixir, Phoenix, and infrastructure topics.

## Features

- **Blog Engine**: Full CRUD with draft/publish workflow, soft deletes, cover images
- **Full-Text Search**: SQLite FTS5 with real-time search, tag filtering, query highlighting
- **SEO Optimized**: JSON-LD structured data, dynamic OG images, RSS feed, sitemap, slug-based URLs
- **Music Player**: Upload and manage audio tracks with a floating player UI
- **Admin Panel**: Protected admin routes for content management
- **Modern UI**: Tailwind CSS, dark mode support, responsive design, card/compact view toggle

## Tech Stack

| Category | Technology |
|----------|-----------|
| Language | Elixir ~> 1.14 |
| Framework | Phoenix 1.7.14 + LiveView 1.0.0-rc.1 |
| Database | SQLite (ecto_sqlite3) |
| HTTP Server | Bandit |
| CSS | Tailwind CSS 3.4.3 + Flowbite |
| Bundler | esbuild |
| Markdown | mdex, earmark |

## Getting Started

### Prerequisites

- Elixir ~> 1.14
- Erlang/OTP
- Node.js (for asset building)

### Setup

```bash
# Clone the repository
git clone <repo-url>
cd blog

# Install dependencies and setup database
mix setup

# Start the development server
mix phx.server
```

Visit [localhost:4000](http://localhost:4000) to see the blog.

### Useful Commands

```bash
mix phx.server          # Start dev server
iex -S mix phx.server   # Start with IEx console
mix ecto.migrate        # Run database migrations
mix ecto.reset          # Reset database
mix test                # Run tests
mix format              # Format code
mix assets.deploy       # Build production assets
```

## Project Structure

```
lib/
├── blog/                    # Domain layer (contexts & schemas)
│   ├── note.ex              # Blog post schema
│   ├── note_data.ex         # Blog post queries & CRUD
│   ├── music.ex             # Music context
│   └── slug.ex              # URL slug generation
├── blog_web/                # Web layer
│   ├── controllers/         # Page, Feed, Redirect controllers
│   ├── live/                # LiveView modules
│   │   └── admin/           # Admin CRUD interfaces
│   ├── components/          # UI components & layouts
│   ├── seo.ex               # SEO meta tags & JSON-LD
│   └── markdown.ex          # Markdown rendering
assets/
├── js/                      # JavaScript (app.js, hooks)
├── css/                     # Stylesheets (Tailwind)
└── tailwind.config.js       # Tailwind configuration
priv/
├── repo/migrations/         # Database migrations
└── static/                  # Static assets & uploads
```

## Deployment

Build production assets:

```bash
mix assets.deploy
```

For deployment guides, see the [Phoenix deployment docs](https://hexdocs.pm/phoenix/deployment.html).

## License

Private project.
