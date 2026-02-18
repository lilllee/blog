defmodule Blog.NoteData do
  import Ecto.Query
  alias Blog.Note
  alias Blog.Repo

  def get_all_notes, do: list_notes()

  def get_note_by_id(id), do: Repo.get(Note, id)

  def get_published_note(id) do
    Note
    |> where([n], n.id == ^id and n.status == "published" and is_nil(n.deleted_at))
    |> Repo.one()
  end

  def get_published_note_by_slug(slug) do
    Note
    |> where([n], n.slug == ^slug and n.status == "published" and is_nil(n.deleted_at))
    |> Repo.one()
  end

  def get_admin_note!(id), do: Repo.get!(Note, id)

  def list_notes(opts \\ %{}) do
    query = String.trim(to_string(Map.get(opts, :query, Map.get(opts, "query", ""))))
    tag = String.trim(to_string(Map.get(opts, :tag, Map.get(opts, "tag", ""))))

    Note
    |> where([n], n.status == "published" and is_nil(n.deleted_at))
    |> order_recent()
    |> maybe_filter_tag(tag)
    |> maybe_search(query)
    |> Repo.all()
  end

  def search_notes(query_string), do: list_notes(%{query: query_string})

  def list_recent(limit \\ 50) do
    Note
    |> where([n], n.status == "published" and is_nil(n.deleted_at))
    |> order_recent()
    |> limit(^limit)
    |> Repo.all()
  end

  def timeline_recent_activity(limit \\ 5) when is_integer(limit) and limit > 0 do
    Note
    |> published_base()
    |> order_recent()
    |> select_timeline_fields()
    |> limit(^limit)
    |> Repo.all()
  end

  def timeline_year_archive do
    Note
    |> published_base()
    |> order_recent()
    |> select_timeline_fields()
    |> Repo.all()
  end

  def timeline_tag_timeline(tag) do
    tag = String.trim(to_string(tag))

    Note
    |> published_base()
    |> maybe_filter_tag(tag)
    |> order_recent()
    |> select_timeline_fields()
    |> Repo.all()
  end

  def list_admin_notes do
    Note
    |> where([n], is_nil(n.deleted_at))
    |> order_recent()
    |> Repo.all()
  end

  def change_note(%Note{} = note, attrs \\ %{}) do
    Note.changeset(note, attrs)
  end

  def create_note(attrs) do
    attrs = normalize_attrs(attrs)

    %Note{}
    |> Note.changeset(attrs_with_derivatives(attrs))
    |> Repo.insert()
  end

  def update_note(%Note{} = note, attrs) do
    attrs = normalize_attrs(attrs)

    note
    |> Note.changeset(attrs_with_derivatives(attrs, note))
    |> Repo.update()
  end

  def soft_delete_note(%Note{} = note) do
    note
    |> Note.changeset(%{deleted_at: DateTime.utc_now()})
    |> Repo.update()
  end

  def toggle_publish(%Note{} = note, status) when status in ["draft", "published"] do
    attrs =
      case status do
        "published" -> %{status: status, published_at: note.published_at || DateTime.utc_now()}
        "draft" -> %{status: status}
      end

    note
    |> Note.changeset(attrs)
    |> Repo.update()
  end

  def list_tags do
    Note
    |> where([n], n.status == "published" and is_nil(n.deleted_at))
    |> select([n], n.tags)
    |> Repo.all()
    |> Enum.flat_map(&split_tags/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def split_tags(tags) when is_binary(tags) do
    tags
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  def split_tags(_), do: []

  def related_notes(%Note{} = note, limit \\ 5) do
    tags = split_tags(note.tags)
    if tags == [], do: []

    matcher =
      Enum.reduce(tags, dynamic(false), fn tag, dyn ->
        dynamic([n], ^dyn or like(n.tags, ^"%#{escape_like(tag)}%"))
      end)

    Note
    |> where([n], n.id != ^note.id and n.status == "published" and is_nil(n.deleted_at))
    |> where(^matcher)
    |> Repo.all()
    |> Enum.map(fn candidate ->
      shared = shared_tag_count(tags, split_tags(candidate.tags))
      {candidate, shared}
    end)
    |> Enum.filter(fn {_note, count} -> count > 0 end)
    |> Enum.sort_by(fn {n, count} -> {-count, date_sort_key(n.inserted_at)} end)
    |> Enum.take(limit)
    |> Enum.map(&elem(&1, 0))
  end

  def series_neighbors(%Note{series_id: nil}), do: %{prev: nil, next: nil}

  def series_neighbors(%Note{} = note) do
    pos = note.series_order || 0

    base =
      from n in Note,
        where:
          n.series_id == ^note.series_id and n.id != ^note.id and n.status == "published" and
            is_nil(n.deleted_at)

    prev =
      base
      |> where([n], fragment("COALESCE(?, 0)", n.series_order) < ^pos)
      |> order_by([n], desc: fragment("COALESCE(?, 0)", n.series_order), desc: n.inserted_at)
      |> limit(1)
      |> Repo.one()

    next =
      base
      |> where([n], fragment("COALESCE(?, 0)", n.series_order) > ^pos)
      |> order_by([n], asc: fragment("COALESCE(?, 0)", n.series_order), desc: n.inserted_at)
      |> limit(1)
      |> Repo.one()

    %{prev: prev, next: next}
  end

  def chronological_neighbors(%Note{} = note) do
    published_at = note.published_at || note.inserted_at

    prev =
      Note
      |> where([n], n.status == "published" and is_nil(n.deleted_at))
      |> where([n], n.id != ^note.id)
      |> where([n], coalesce(n.published_at, n.inserted_at) < ^published_at)
      |> order_by([n], desc: coalesce(n.published_at, n.inserted_at))
      |> limit(1)
      |> Repo.one()

    next =
      Note
      |> where([n], n.status == "published" and is_nil(n.deleted_at))
      |> where([n], n.id != ^note.id)
      |> where([n], coalesce(n.published_at, n.inserted_at) > ^published_at)
      |> order_by([n], asc: coalesce(n.published_at, n.inserted_at))
      |> limit(1)
      |> Repo.one()

    %{prev: prev, next: next}
  end

  defp maybe_filter_tag(query, ""), do: query

  defp maybe_filter_tag(query, tag) do
    escaped = escape_like(tag)
    where(query, [note], like(note.tags, ^"%#{escaped}%"))
  end

  defp published_base(query) do
    where(query, [n], n.status == "published" and is_nil(n.deleted_at))
  end

  defp select_timeline_fields(query) do
    select(query, [n], %{
      id: n.id,
      slug: n.slug,
      title: n.title,
      tags: n.tags,
      published_at: n.published_at,
      inserted_at: n.inserted_at
    })
  end

  defp order_recent(query) do
    order_by(query, [n], desc: fragment("COALESCE(?, ?)", n.published_at, n.inserted_at))
  end

  defp escape_like(term) do
    term
    |> String.replace("\\", "\\\\")
    |> String.replace("%", "\\%")
    |> String.replace("_", "\\_")
  end

  defp maybe_search(query, ""), do: query

  defp maybe_search(query, text) do
    sanitized =
      text
      |> String.replace(~r/[\"'()*^:+\-~]/u, " ")
      |> String.replace(~r/\b(AND|OR|NOT|NEAR)\b/i, " ")
      |> String.split()
      |> Enum.reject(&(&1 == ""))
      |> Enum.join(" ")
      |> String.trim()

    case sanitized do
      "" ->
        query

      _ ->
        match = "#{sanitized}*"

        where(
          query,
          [note],
          note.id in fragment("SELECT rowid FROM note_fts WHERE note_fts MATCH ?", ^match)
        )
    end
  end

  defp shared_tag_count(base_tags, other_tags) do
    base_set = MapSet.new(base_tags)

    other_tags
    |> Enum.filter(&MapSet.member?(base_set, &1))
    |> length()
  end

  defp date_sort_key(%DateTime{} = dt), do: DateTime.to_unix(dt)

  defp date_sort_key(%NaiveDateTime{} = dt),
    do: dt |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix()

  defp date_sort_key(_), do: 0

  defp normalize_attrs(attrs) do
    attrs
    |> Map.new(fn {k, v} -> {to_string(k), v} end)
    |> then(fn map ->
      %{
        "title" => map["title"],
        "content" => map["content"] || map["raw_markdown"],
        "raw_markdown" => map["raw_markdown"] || map["content"],
        "image_path" => map["image_path"],
        "tags" => map["tags"],
        "categories" => map["categories"],
        "series_id" => map["series_id"],
        "series_order" => parse_int(map["series_order"]),
        "status" => map["status"] || map["publish_status"],
        "published_at" => map["published_at"]
      }
    end)
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Enum.into(%{})
    |> default_status()
  end

  defp default_status(%{"status" => status} = attrs) when status in ["draft", "published"],
    do: attrs

  defp default_status(attrs), do: Map.put(attrs, "status", "draft")

  defp attrs_with_derivatives(attrs, note \\ nil) do
    raw = Map.get(attrs, "content", "")
    {html, toc_list} = BlogWeb.Markdown.render_with_toc(raw)
    toc_json = Jason.encode!(toc_list)
    reading_time = BlogWeb.Markdown.reading_time_minutes(raw)

    attrs
    |> Map.put("rendered_html", html |> Phoenix.HTML.safe_to_string())
    |> Map.put("toc", toc_json)
    |> Map.put("reading_time", reading_time)
    |> Map.update("published_at", published_at_default(attrs, note), fn existing ->
      existing || published_at_default(attrs, note)
    end)
  end

  defp published_at_default(%{"status" => "published"}, %Note{published_at: nil}),
    do: DateTime.utc_now()

  defp published_at_default(%{"status" => "published"}, %Note{} = note), do: note.published_at
  defp published_at_default(%{"status" => status}, _note) when status != "published", do: nil
  defp published_at_default(_attrs, _note), do: nil

  defp parse_int(nil), do: nil
  defp parse_int(""), do: nil
  defp parse_int(val) when is_integer(val), do: val

  defp parse_int(val) when is_binary(val) do
    case Integer.parse(val) do
      {int, _} -> int
      _ -> nil
    end
  end

  defp parse_int(_), do: nil
end
