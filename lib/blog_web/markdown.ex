defmodule BlogWeb.Markdown do
  @moduledoc false

  alias Phoenix.HTML

  @words_per_minute 200

  @mdex_opts [
    extension: [
      strikethrough: true,
      tagfilter: true,
      table: true,
      autolink: true,
      tasklist: true,
      footnotes: true,
      shortcodes: true
    ],
    parse: [
      smart: true,
      relaxed_tasklist_matching: true,
      relaxed_autolinks: true
    ],
    render: [
      github_pre_lang: true,
      unsafe_: true,
      escape: true
    ],
    features: [
      sanitize: true
    ]
  ]

  def render(markdown) do
    markdown
    |> to_string()
    |> MDEx.to_html!(@mdex_opts)
    |> HTML.raw()
  end

  def render_with_toc(markdown) do
    markdown = to_string(markdown)

    html = MDEx.to_html!(markdown, @mdex_opts)
    {doc, toc} = build_toc(html)
    toc = maybe_render_toc(toc)

    {HTML.raw(doc), toc}
  end

  @doc """
  Estimate reading time in minutes.

  Rule: ignore fenced/inline code blocks so code-heavy posts don't inflate the count.
  """
  def reading_time_minutes(markdown) do
    markdown
    |> to_string()
    |> strip_code()
    |> String.split(~r/[\s\n\r]+/, trim: true)
    |> length()
    |> Kernel./(@words_per_minute)
    |> Float.ceil()
    |> trunc()
    |> max(1)
  end

  def tag_list(tags) when is_binary(tags) do
    tags
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  def tag_list(_), do: []

  defp build_toc(html) do
    heading_regex = ~r/<h([23])([^>]*)>(.*?)<\/h\1>/s

    {doc, _last, {_seen, toc}} =
      heading_regex
      |> Regex.scan(html, return: :index)
      |> Enum.reduce({[], 0, {%{}, []}}, fn
        [{start, len}, {level_start, level_len}, {attrs_start, attrs_len}, {inner_start, inner_len}],
        {chunks, last, {seen, toc}} ->
          level = html |> binary_part(level_start, level_len) |> String.to_integer()
          attrs = binary_part(html, attrs_start, attrs_len)
          inner = binary_part(html, inner_start, inner_len)

          title =
            inner
            |> strip_html_tags()
            |> String.trim()

          {id, seen} = heading_id(title, seen)
          toc = [%{id: id, title: title, level: level} | toc]

          before_heading = binary_part(html, last, start - last)
          heading = ~s(<h#{level} id="#{id}"#{attrs}>#{inner}</h#{level}>)

          {[chunks, before_heading, heading], start + len, {seen, toc}}
      end)

    doc = [doc, binary_part(html, _last, byte_size(html) - _last)] |> IO.iodata_to_binary()

    {doc, Enum.reverse(toc)}
  end

  defp strip_html_tags(html) do
    String.replace(html, ~r/<[^>]*>/, "")
  end

  defp maybe_render_toc(toc) when length(toc) < 3, do: []
  defp maybe_render_toc(toc), do: toc

  defp strip_code(markdown) do
    markdown
    |> String.replace(~r/```.*?```/s, " ")
    |> String.replace(~r/`[^`]*`/, " ")
  end

  defp heading_id(title, seen) do
    base =
      title
      |> slugify()
      |> case do
        "" -> "section-#{map_size(seen) + 1}"
        slug -> slug
      end

    case Map.get(seen, base) do
      nil ->
        {base, Map.put(seen, base, 1)}

      count ->
        slug = "#{base}-#{count + 1}"
        {slug, Map.put(seen, base, count + 1)}
    end
  end

  defp slugify(title) do
    title
    |> String.downcase()
    |> String.replace(~r/[^[:alnum:]\s-]/u, "")
    |> String.replace(~r/\s+/, "-", trim: true)
    |> String.trim("-")
  end
end
