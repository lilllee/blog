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

  defp build_rss(posts, base) do
    items =
      Enum.map_join(posts, "\n", fn post ->
        link = base <> ~p"/item/#{post.id}"

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
          sitemap_url(base <> ~p"/item/#{post.id}", post.published_at || post.inserted_at)
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
