defmodule BlogWeb.SEO do
  @moduledoc """
  SEO helper functions for generating structured data (JSON-LD), meta tags, and canonical URLs.
  """

  def seo_assigns(type, data, opts \\ [])

  def seo_assigns(:post, note, _opts) when is_map(note) do
    base_url = BlogWeb.Endpoint.url()
    url = base_url <> "/posts/#{note.slug}"

    description =
      (note.raw_markdown || note.content)
      |> to_string()
      |> String.replace(~r/!\[.*?\]\(.*?\)/, "")
      |> String.replace(~r/\[([^\]]*)\]\([^\)]*\)/, "\\1")
      |> String.replace(~r/[#*`\[\]()>_~\-|]/, "")
      |> String.replace(~r/\s+/, " ")
      |> String.trim()
      |> String.slice(0, 160)

    og_image = BlogWeb.OGImage.get_image_url(:post, note)

    meta = %{
      title: note.title,
      description: description,
      url: url,
      canonical_url: url,
      og_url: url,
      og_image: og_image,
      og_title: note.title,
      og_description: description,
      type: "article",
      image: og_image,
      published_time: iso8601_date(note.published_at || note.inserted_at),
      modified_time: iso8601_date(note.updated_at),
      author: "JunHo Lee"
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
    title = opts[:title] || "JunHo's Blog"
    description = opts[:description] || "Elixir, Phoenix, and daily engineering notes."
    path = opts[:path] || "/"
    url = base_url <> path

    meta = %{
      title: title,
      description: description,
      url: url,
      canonical_url: url,
      og_url: url,
      og_image: base_url <> "/images/og-default.png",
      og_title: title,
      og_description: description,
      type: "website",
      image: base_url <> "/images/og-default.png"
    }

    json_ld = [blog_schema(posts), website_schema()] |> encode_schema()

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
    url = base_url <> path
    resolved_image = image_url(image, base_url)

    meta = %{
      title: title,
      description: description,
      url: url,
      canonical_url: url,
      og_url: url,
      og_image: resolved_image,
      og_title: title,
      og_description: description,
      type: "website",
      image: resolved_image
    }

    page_json_ld = data[:json_ld] || opts[:json_ld]

    result = %{meta: meta, page_title: title}
    if page_json_ld, do: Map.put(result, :json_ld, encode_schema(page_json_ld)), else: result
  end

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

  def blog_schema(posts) do
    base_url = BlogWeb.Endpoint.url()

    %{
      "@context" => "https://schema.org",
      "@type" => "Blog",
      "name" => "JunHo's Blog",
      "description" => "Elixir, Phoenix, and daily engineering notes.",
      "url" => base_url,
      "publisher" => publisher_schema(),
      "blogPost" => Enum.map(posts, &blog_post_reference/1)
    }
  end

  def website_schema do
    base_url = BlogWeb.Endpoint.url()

    %{
      "@context" => "https://schema.org",
      "@type" => "WebSite",
      "name" => "JunHo's Blog",
      "url" => base_url,
      "potentialAction" => %{
        "@type" => "SearchAction",
        "target" => %{
          "@type" => "EntryPoint",
          "urlTemplate" => base_url <> "/search?query={search_term_string}"
        },
        "query-input" => "required name=search_term_string"
      }
    }
  end

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

  def person_schema do
    base_url = BlogWeb.Endpoint.url()

    %{
      "@context" => "https://schema.org",
      "@type" => "Person",
      "name" => "JunHo Lee",
      "url" => base_url <> "/about",
      "sameAs" => []
    }
  end

  def encode_schema(schema) do
    schema
    |> Jason.encode!()
    |> Phoenix.HTML.raw()
  end

  # Private helpers

  defp author_schema do
    %{
      "@type" => "Person",
      "name" => "JunHo Lee"
    }
  end

  defp publisher_schema do
    base_url = BlogWeb.Endpoint.url()

    %{
      "@type" => "Person",
      "name" => "JunHo Lee",
      "url" => base_url
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
    |> String.replace(~r/!\[.*?\]\(.*?\)/, "")
    |> String.replace(~r/\[([^\]]*)\]\([^\)]*\)/, "\\1")
    |> String.replace(~r/[#*`\[\]()>_~\-|]/, "")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
    |> String.slice(0, max)
  end

  defp image_url(nil, base_url), do: base_url <> "/images/og-default.png"
  defp image_url("/" <> _ = path, base_url), do: base_url <> path
  defp image_url(path, base_url) when is_binary(path), do: base_url <> "/images/" <> path
end
