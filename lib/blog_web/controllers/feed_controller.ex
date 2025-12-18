defmodule BlogWeb.FeedController do
  use BlogWeb, :controller

  alias Blog.NoteData

  @rss_limit 30

  def rss(conn, _params) do
    base = BlogWeb.Endpoint.url()

    xml =
      NoteData.list_recent(@rss_limit)
      |> build_rss(base)

    conn
    |> put_resp_content_type("application/rss+xml; charset=utf-8")
    |> send_resp(200, xml)
  end

  def sitemap(conn, _params) do
    base = BlogWeb.Endpoint.url()

    xml =
      NoteData.list_recent(200)
      |> build_sitemap(base, NoteData.list_tags())

    conn
    |> put_resp_content_type("application/xml; charset=utf-8")
    |> send_resp(200, xml)
  end

  def robots(conn, _params) do
    base = BlogWeb.Endpoint.url()

    content = """
    # robots.txt for #{base}
    # Updated: #{Date.utc_today() |> Date.to_iso8601()}

    # Block all crawlers from admin area
    User-agent: *
    Disallow: /admin/
    Disallow: /admin
    Disallow: /dev/

    # Block crawlers from LiveView internal routes
    Disallow: /live/
    Disallow: /phoenix/

    # Block search-specific paths (if they exist)
    Disallow: /*?query=
    Disallow: /*?search=
    Disallow: /*&query=
    Disallow: /*&search=

    # Allow specific public paths
    Allow: /
    Allow: /posts/
    Allow: /list
    Allow: /about
    Allow: /images/
    Allow: /assets/

    # Allow old URLs for redirect crawling
    Allow: /item/

    # Crawl-delay to be respectful (optional)
    # Crawl-delay: 1

    # Sitemap location
    Sitemap: #{base}/sitemap.xml

    # Block bad bots (aggressive crawlers)
    User-agent: AhrefsBot
    Disallow: /

    User-agent: SemrushBot
    Disallow: /

    User-agent: DotBot
    Disallow: /

    User-agent: MJ12bot
    Disallow: /

    # Allow good bots explicitly (redundant but clear)
    User-agent: Googlebot
    Allow: /
    Disallow: /admin/

    User-agent: Bingbot
    Allow: /
    Disallow: /admin/
    """

    conn
    |> put_resp_content_type("text/plain; charset=utf-8")
    |> put_resp_header("cache-control", "public, max-age=3600")
    |> send_resp(200, content)
  end

  defp build_rss(posts, base) do
    items =
      Enum.map_join(posts, "\n", fn post ->
        link = base <> ~p"/posts/#{post.slug}"

        """
        <item>
          <title>#{escape(post.title)}</title>
          <link>#{link}</link>
          <guid isPermaLink="true">#{link}</guid>
          <pubDate>#{rss_date(post.published_at || post.inserted_at)}</pubDate>
          <description><![CDATA[#{excerpt(post.content)}]]></description>
        </item>
        """
      end)

    """
    <?xml version="1.0" encoding="UTF-8"?>
    <rss version="2.0">
      <channel>
        <title>Personal developer blog</title>
        <link>#{base}</link>
        <description>Posts about Elixir, Phoenix, and engineering notes.</description>
        #{items}
      </channel>
    </rss>
    """
  end

  defp build_sitemap(posts, base, tags) do
    urls =
      [
        sitemap_url("#{base}/"),
        sitemap_url("#{base}/list")
      ] ++
        Enum.map(posts, fn post ->
          sitemap_url(base <> ~p"/posts/#{post.slug}", post.published_at || post.inserted_at)
        end) ++
        Enum.map(tags, fn tag ->
          query = URI.encode(tag)
          sitemap_url("#{base}/list?tag=#{query}")
        end)

    """
    <?xml version="1.0" encoding="UTF-8"?>
    <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
      #{Enum.join(urls, "\n")}
    </urlset>
    """
  end

  defp sitemap_url(loc, lastmod \\ nil) do
    lastmod_xml =
      case lastmod do
        nil -> ""
        date -> "<lastmod>#{iso_date(date)}</lastmod>"
      end

    """
    <url>
      <loc>#{escape(loc)}</loc>
      #{lastmod_xml}
    </url>
    """
  end

  defp rss_date(%DateTime{} = dt) do
    dt
    |> DateTime.shift_zone!("Etc/UTC")
    |> Calendar.strftime("%a, %d %b %Y %H:%M:%S GMT")
  end

  defp rss_date(%NaiveDateTime{} = dt) do
    dt
    |> DateTime.from_naive!("Etc/UTC")
    |> rss_date()
  end

  defp rss_date(_), do: ""

  defp iso_date(%DateTime{} = dt), do: Calendar.strftime(dt, "%Y-%m-%d")

  defp iso_date(%NaiveDateTime{} = dt) do
    dt
    |> DateTime.from_naive!("Etc/UTC")
    |> iso_date()
  end

  defp iso_date(_), do: ""

  defp excerpt(content) do
    content
    |> to_string()
    |> String.replace(~r/\s+/, " ")
    |> String.slice(0, 200)
    |> case do
      text when byte_size(text) < 200 -> text
      text -> text <> "…"
    end
  end

  defp escape(nil), do: ""

  defp escape(text) do
    text
    |> to_string()
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&apos;")
  end
end
