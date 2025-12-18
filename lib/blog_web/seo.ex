defmodule BlogWeb.SEO do
  @moduledoc """
  SEO helper functions for generating structured data (JSON-LD), meta tags, and canonical URLs.
  """

  @doc """
  Returns SEO assigns for use in LiveView mount/3 or controller actions.
  Provides both meta tags and JSON-LD structured data.

  ## Usage

      # In LiveView
      def mount(%{"slug" => slug}, _session, socket) do
        note = get_note(slug)
        seo = SEO.seo_assigns(:post, note)
        {:ok, assign(socket, seo)}
      end

      # In Controller
      def index(conn, _params) do
        posts = list_posts()
        seo = SEO.seo_assigns(:blog, posts)
        render(conn, "index.html", seo)
      end

  ## Content Types

  - `:post` - Individual blog post (requires note with slug)
  - `:blog` - Blog homepage/list (requires list of posts)
  - `:page` - Generic page (requires title, description, path)

  ## Returns

      %{
        meta: %{title, description, url, type, image, ...},
        json_ld: safe_html_encoded_json
      }
  """
  def seo_assigns(type, data, opts \\ [])

  def seo_assigns(:post, note, _opts) when is_map(note) do
    base_url = BlogWeb.Endpoint.url()
    url = base_url <> "/posts/#{note.slug}"

    description =
      (note.raw_markdown || note.content)
      |> to_string()
      |> String.replace(~r/\s+/, " ")
      |> String.slice(0, 160)

    og_image = BlogWeb.OGImage.get_image_url(:post, note)

    meta = %{
      title: note.title,
      description: description,
      url: url,
      type: "article",
      image: og_image,
      published_time: iso8601_date(note.published_at || note.inserted_at),
      modified_time: iso8601_date(note.updated_at),
      author: "Your Name"
    }

    json_ld = blog_posting_schema(note, url) |> encode_schema()

    %{
      meta: meta,
      json_ld: json_ld,
      page_title: note.title
    }
  end

  def seo_assigns(:blog, posts, opts) when is_list(posts) do
    base_url = BlogWeb.Endpoint.url()
    title = opts[:title] || "Personal development blog"
    description = opts[:description] || "Elixir, Phoenix, and daily engineering notes."
    path = opts[:path] || "/"

    meta = %{
      title: title,
      description: description,
      url: base_url <> path,
      type: "website",
      image: base_url <> "/images/dark.jpg"
    }

    json_ld = blog_schema(posts) |> encode_schema()

    %{
      meta: meta,
      json_ld: json_ld,
      page_title: title
    }
  end

  def seo_assigns(:page, data, opts) when is_map(data) do
    base_url = BlogWeb.Endpoint.url()
    title = data[:title] || opts[:title] || "Page"
    description = data[:description] || opts[:description] || ""
    path = data[:path] || opts[:path] || "/"
    image = data[:image] || opts[:image]

    meta = %{
      title: title,
      description: description,
      url: base_url <> path,
      type: "website",
      image: image_url(image, base_url)
    }

    %{
      meta: meta,
      page_title: title
    }
  end

  @doc """
  Generates JSON-LD structured data for a blog post (BlogPosting schema).

  ## Example
      iex> BlogWeb.SEO.blog_posting_schema(note, "https://example.com/item/1")
      %{...}
  """
  def blog_posting_schema(note, url) do
    base_url = BlogWeb.Endpoint.url()

    %{
      "@context" => "https://schema.org",
      "@type" => "BlogPosting",
      "headline" => note.title,
      "url" => url,
      "datePublished" => iso8601_date(note.published_at || note.inserted_at),
      "dateModified" => iso8601_date(note.updated_at),
      "author" => author_schema(),
      "publisher" => publisher_schema(),
      "description" => excerpt(note.raw_markdown || note.content, 160),
      "image" => image_url(note.image_path, base_url),
      "mainEntityOfPage" => %{
        "@type" => "WebPage",
        "@id" => url
      }
    }
    |> maybe_add_keywords(note.tags)
  end

  @doc """
  Generates JSON-LD for a Blog schema (for the homepage/list page).
  """
  def blog_schema(posts) do
    base_url = BlogWeb.Endpoint.url()

    %{
      "@context" => "https://schema.org",
      "@type" => "Blog",
      "name" => "Personal Developer Blog",
      "description" => "Elixir, Phoenix, and daily engineering notes.",
      "url" => base_url,
      "publisher" => publisher_schema(),
      "blogPost" => Enum.map(posts, &blog_post_reference/1)
    }
  end

  @doc """
  Generates BreadcrumbList JSON-LD for navigation paths.
  """
  def breadcrumb_schema(items) do
    %{
      "@context" => "https://schema.org",
      "@type" => "BreadcrumbList",
      "itemListElement" =>
        Enum.with_index(items, 1)
        |> Enum.map(fn {{name, url}, position} ->
          %{
            "@type" => "ListItem",
            "position" => position,
            "name" => name,
            "item" => url
          }
        end)
    }
  end

  @doc """
  Generates Person JSON-LD schema for author/profile pages.
  """
  def person_schema do
    base_url = BlogWeb.Endpoint.url()

    %{
      "@context" => "https://schema.org",
      "@type" => "Person",
      "name" => "Your Name",
      "url" => base_url,
      "sameAs" => [
        # Add your social profiles here
        # "https://github.com/yourusername",
        # "https://twitter.com/yourusername"
      ]
    }
  end

  @doc """
  Encodes JSON-LD schema to safe HTML script tag content.
  """
  def encode_schema(schema) do
    schema
    |> Jason.encode!()
    |> Phoenix.HTML.raw()
  end

  # Private helpers

  defp author_schema do
    %{
      "@type" => "Person",
      "name" => "Your Name"
      # Add "url" or "sameAs" for author's profile page
    }
  end

  defp publisher_schema do
    base_url = BlogWeb.Endpoint.url()

    %{
      "@type" => "Organization",
      "name" => "Personal Developer Blog",
      "logo" => %{
        "@type" => "ImageObject",
        "url" => base_url <> "/images/dark.jpg"
      }
    }
  end

  defp blog_post_reference(post) do
    base_url = BlogWeb.Endpoint.url()
    path = "/posts/#{post.slug}"

    %{
      "@type" => "BlogPosting",
      "headline" => post.title,
      "url" => base_url <> path,
      "datePublished" => iso8601_date(post.published_at || post.inserted_at)
    }
  end

  defp maybe_add_keywords(schema, nil), do: schema
  defp maybe_add_keywords(schema, ""), do: schema

  defp maybe_add_keywords(schema, tags) when is_binary(tags) do
    keywords =
      tags
      |> BlogWeb.Markdown.tag_list()
      |> Enum.join(", ")

    Map.put(schema, "keywords", keywords)
  end

  defp maybe_add_keywords(schema, tags) when is_list(tags) do
    Map.put(schema, "keywords", Enum.join(tags, ", "))
  end

  defp iso8601_date(%DateTime{} = dt), do: DateTime.to_iso8601(dt)

  defp iso8601_date(%NaiveDateTime{} = dt) do
    dt
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.to_iso8601()
  end

  defp iso8601_date(_), do: nil

  defp excerpt(nil, _max), do: ""

  defp excerpt(content, max) do
    content
    |> to_string()
    |> String.replace(~r/\s+/, " ")
    |> String.slice(0, max)
  end

  defp image_url(nil, base_url), do: base_url <> "/images/dark.jpg"
  defp image_url(path, base_url) when is_binary(path), do: base_url <> "/images/" <> path
end
