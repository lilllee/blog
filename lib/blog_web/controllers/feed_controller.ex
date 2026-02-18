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
    |> put_resp_header("cache-control", "public, max-age=3600, s-maxage=3600")
    |> send_resp(200, xml)
  end

  def sitemap(conn, _params) do
    base = BlogWeb.Endpoint.url()

    xml =
      NoteData.list_recent(500)
      |> build_sitemap(base, NoteData.list_tags())

    conn
    |> put_resp_content_type("application/xml; charset=utf-8")
    |> put_resp_header("cache-control", "public, max-age=3600, s-maxage=3600")
    |> send_resp(200, xml)
  end

  def robots(conn, _params) do
    base = BlogWeb.Endpoint.url()

    content = """
    # robots.txt for #{base}

    User-agent: *
    Disallow: /admin/
    Disallow: /admin
    Disallow: /dev/
    Disallow: /live/
    Disallow: /phoenix/
    Disallow: /*?query=
    Disallow: /*?search=

    Allow: /
    Allow: /posts/
    Allow: /list
    Allow: /about
    Allow: /images/
    Allow: /assets/

    # Sitemap
    Sitemap: #{base}/sitemap.xml

    # Block AI training crawlers
    User-agent: GPTBot
    Disallow: /

    User-agent: ChatGPT-User
    Disallow: /

    User-agent: CCBot
    Disallow: /

    User-agent: anthropic-ai
    Disallow: /

    User-agent: ClaudeBot
    Disallow: /

    User-agent: Google-Extended
    Disallow: /

    User-agent: FacebookBot
    Disallow: /

    User-agent: Bytespider
    Disallow: /

    # Block aggressive SEO crawlers
    User-agent: AhrefsBot
    Disallow: /

    User-agent: SemrushBot
    Disallow: /

    User-agent: DotBot
    Disallow: /

    User-agent: MJ12bot
    Disallow: /

    # Allow search engine bots explicitly
    User-agent: Googlebot
    Allow: /
    Disallow: /admin/

    User-agent: Bingbot
    Allow: /
    Disallow: /admin/

    User-agent: Yeti
    Allow: /
    Disallow: /admin/
    """

    conn
    |> put_resp_content_type("text/plain; charset=utf-8")
    |> put_resp_header("cache-control", "public, max-age=86400")
    |> send_resp(200, content)
  end

  defp build_rss(posts, base) do
    last_build =
      case posts do
        [first | _] -> rss_date(first.published_at || first.inserted_at)
        [] -> rss_date(DateTime.utc_now())
      end

    items =
      Enum.map_join(posts, "\n", fn post ->
        link = base <> ~p"/posts/#{post.slug}"
        tags = parse_tags(post.tags)

        categories =
          Enum.map_join(tags, "\n", fn tag ->
            "      <category>#{escape(tag)}</category>"
          end)

        content_encoded = excerpt_html(post.content || post.raw_markdown)

        """
            <item>
              <title>#{escape(post.title)}</title>
              <link>#{link}</link>
              <guid isPermaLink="true">#{link}</guid>
              <pubDate>#{rss_date(post.published_at || post.inserted_at)}</pubDate>
              <dc:creator>JunHo Lee</dc:creator>
              <description><![CDATA[#{excerpt(post.content || post.raw_markdown)}]]></description>
              <content:encoded><![CDATA[#{content_encoded}]]></content:encoded>
        #{categories}
            </item>
        """
      end)

    """
    <?xml version="1.0" encoding="UTF-8"?>
    <rss version="2.0"
      xmlns:atom="http://www.w3.org/2005/Atom"
      xmlns:content="http://purl.org/rss/1.0/modules/content/"
      xmlns:dc="http://purl.org/dc/elements/1.1/">
      <channel>
        <title>JunHo's Blog</title>
        <link>#{base}</link>
        <description>Elixir, Phoenix, and daily engineering notes.</description>
        <language>ko</language>
        <lastBuildDate>#{last_build}</lastBuildDate>
        <atom:link href="#{base}/rss.xml" rel="self" type="application/rss+xml" />
    #{items}
      </channel>
    </rss>
    """
  end

  defp build_sitemap(posts, base, tags) do
    static_urls =
      [
        sitemap_url("#{base}/", "daily", "1.0"),
        sitemap_url("#{base}/about", "monthly", "0.7"),
        sitemap_url("#{base}/list", "daily", "0.6")
      ]

    post_urls =
      Enum.map(posts, fn post ->
        sitemap_url(
          base <> ~p"/posts/#{post.slug}",
          "weekly",
          "0.8",
          post.updated_at || post.published_at || post.inserted_at
        )
      end)

    tag_urls =
      Enum.map(tags, fn tag ->
        query = URI.encode(tag)
        sitemap_url("#{base}/list?tag=#{query}", "weekly", "0.4")
      end)

    urls = static_urls ++ post_urls ++ tag_urls

    """
    <?xml version="1.0" encoding="UTF-8"?>
    <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    #{Enum.join(urls, "\n")}
    </urlset>
    """
  end

  defp sitemap_url(loc, changefreq, priority, lastmod \\ nil) do
    lastmod_xml =
      case lastmod do
        nil -> ""
        date -> "\n    <lastmod>#{iso_date(date)}</lastmod>"
      end

    """
      <url>
        <loc>#{escape(loc)}</loc>#{lastmod_xml}
        <changefreq>#{changefreq}</changefreq>
        <priority>#{priority}</priority>
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
    |> String.replace(~r/[#*`\[\]()>_~\-|]/, "")
    |> String.replace(~r/!\[.*?\]\(.*?\)/, "")
    |> String.replace(~r/\[([^\]]*)\]\([^\)]*\)/, "\\1")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
    |> String.slice(0, 300)
  end

  defp excerpt_html(content) do
    content
    |> to_string()
    |> String.slice(0, 2000)
  end

  defp parse_tags(nil), do: []
  defp parse_tags(""), do: []

  defp parse_tags(tags) when is_binary(tags) do
    tags
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
  end

  defp parse_tags(tags) when is_list(tags), do: tags

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
