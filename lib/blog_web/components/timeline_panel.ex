defmodule BlogWeb.TimelinePanel do
  use BlogWeb, :live_component

  alias Blog.NoteData
  alias BlogWeb.Markdown

  @recent_limit 5
  @modes ~w(recent_activity year_archive tag_timeline)

  @impl true
  def mount(socket) do
    {:ok,
     assign(socket,
       modes: @modes,
       current_note_id: nil,
       mode: "recent_activity",
       recent_loaded: false,
       recent: [],
       archive_loaded: false,
       archive_groups: [],
       expanded_archive_years: MapSet.new(),
       tags_loaded: false,
       available_tags: [],
       tag_counts_loaded: false,
       tag_counts: %{},
       selected_tag: "",
       tag_loaded_for: nil,
       tag_groups: [],
       expanded_tag_years: MapSet.new()
     )}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> ensure_recent_loaded()

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="space-y-4">
      <div class="rounded-2xl border border-gray-200 bg-white p-4 shadow-sm dark:border-gray-800 dark:bg-gray-900 lg:max-h-[calc(100vh-6rem)] lg:overflow-hidden lg:flex lg:flex-col">
        <div class="flex items-center justify-between gap-2">
          <p class="text-sm font-semibold text-gray-800 dark:text-gray-100">Timeline</p>
          <button
            type="button"
            class="inline-flex items-center gap-1 rounded-md px-2 py-1 text-xs font-semibold text-gray-600 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-800 lg:hidden"
            phx-click={JS.toggle(to: "##{@id}-body")}
            aria-controls={"#{@id}-body"}
          >
            Toggle <.icon name="hero-chevron-down-mini" class="h-4 w-4" />
          </button>
        </div>

        <div
          id={"#{@id}-body"}
          class="mt-3 hidden space-y-4 lg:block lg:flex-1 lg:overflow-y-auto lg:pr-1"
        >
          <div class="sticky top-0 z-10 bg-white/95 pb-2 backdrop-blur dark:bg-gray-900/95">
            <div class="inline-flex rounded-xl bg-gray-100 p-1 dark:bg-gray-800">
              <button
                :for={mode <- @modes}
                type="button"
                phx-click="timeline_set_mode"
                phx-target={@myself}
                phx-value-mode={mode}
                class={[
                  "rounded-lg px-2.5 py-1 text-xs font-semibold transition",
                  @mode == mode &&
                    "bg-white text-indigo-700 shadow-sm dark:bg-gray-950 dark:text-indigo-200",
                  @mode != mode &&
                    "text-gray-600 hover:text-gray-900 dark:text-gray-300 dark:hover:text-gray-100"
                ]}
              >
                <%= mode_label(mode) %>
              </button>
            </div>
          </div>

          <div :if={@mode == "recent_activity"} class="space-y-2">
            <.timeline_empty :if={@recent == []} label="No recent posts yet." />
            <%= for {item, index} <- Enum.with_index(@recent) do %>
              <.timeline_item
                current_note_id={@current_note_id}
                item={item}
                show_tags
                highlight={index == 0}
              />
            <% end %>
          </div>

          <div :if={@mode == "year_archive"} class="space-y-2">
            <.timeline_empty :if={@archive_groups == []} label="No archive entries yet." />
            <%= for group <- @archive_groups do %>
              <.year_group
                id={"#{@id}-archive-#{group.year}"}
                kind="archive"
                year={group.year}
                count={group.count}
                months={group.months}
                expanded?={MapSet.member?(@expanded_archive_years, group.year)}
                current_note_id={@current_note_id}
                target={@myself}
              />
            <% end %>
          </div>

          <div :if={@mode == "tag_timeline"} class="space-y-3">
            <div class="sticky top-12 z-10 rounded-xl bg-white/95 py-2 backdrop-blur dark:bg-gray-900/95">
              <div class="flex items-center justify-between gap-3">
                <label
                  class="text-xs font-semibold text-gray-600 dark:text-gray-300"
                  for={"#{@id}-tag"}
                >
                  Tag
                </label>
                <select
                  id={"#{@id}-tag"}
                  name="tag"
                  phx-change="timeline_select_tag"
                  phx-target={@myself}
                  class="w-full rounded-lg border border-gray-200 bg-white px-2 py-1 text-xs text-gray-800 shadow-sm focus:border-indigo-400 focus:ring-2 focus:ring-indigo-300 dark:border-gray-800 dark:bg-gray-950 dark:text-gray-100"
                >
                  <option :if={@available_tags == []} value="" selected={@selected_tag == ""}>
                    No tags
                  </option>
                  <option :for={tag <- @available_tags} value={tag} selected={tag == @selected_tag}>
                    <%= if count = @tag_counts[tag], do: "#{tag} (#{count})", else: tag %>
                  </option>
                </select>
              </div>
              <p
                :if={@selected_tag != "" and @tag_counts[@selected_tag]}
                class="mt-1 text-[11px] text-gray-500 dark:text-gray-400"
              >
                <%= @tag_counts[@selected_tag] %> posts tagged “<%= @selected_tag %>”
              </p>
            </div>

            <.timeline_empty :if={@available_tags == []} label="No tags available yet." />
            <.timeline_empty
              :if={@available_tags != [] and @tag_groups == []}
              label="No posts found for this tag."
            />

            <%= for group <- @tag_groups do %>
              <.year_group
                id={"#{@id}-tag-#{group.year}"}
                kind="tag"
                year={group.year}
                count={group.count}
                months={group.months}
                expanded?={MapSet.member?(@expanded_tag_years, group.year)}
                current_note_id={@current_note_id}
                target={@myself}
              />
            <% end %>
          </div>
        </div>
      </div>
    </section>
    """
  end

  attr :label, :string, required: true

  defp timeline_empty(assigns) do
    ~H"""
    <div class="rounded-xl border border-dashed border-gray-200 bg-gray-50 p-3 text-xs text-gray-600 dark:border-gray-800 dark:bg-gray-950 dark:text-gray-300">
      <%= @label %>
    </div>
    """
  end

  attr :item, :map, required: true
  attr :current_note_id, :any, default: nil
  attr :show_tags, :boolean, default: false
  attr :highlight, :boolean, default: false

  defp timeline_item(assigns) do
    date = display_date(assigns.item)
    tags = if assigns.show_tags, do: Markdown.tag_list(assigns.item.tags), else: []

    assigns =
      assigns
      |> assign(:date, date)
      |> assign(:tags, tags)

    ~H"""
    <.link
      navigate={~p"/posts/#{@item.slug}"}
      class={[
        "block rounded-xl border border-gray-200 bg-white p-3 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md dark:border-gray-800 dark:bg-gray-950",
        @highlight &&
          "border-indigo-200 bg-indigo-50/60 dark:border-indigo-900/50 dark:bg-indigo-900/20",
        @current_note_id == @item.id &&
          "border-indigo-200 bg-indigo-50 dark:border-indigo-900/50 dark:bg-indigo-900/20"
      ]}
    >
      <div class="flex items-start justify-between gap-2">
        <p class="text-sm font-semibold text-gray-900 dark:text-gray-100 line-clamp-2">
          <%= @item.title %>
        </p>
        <span
          :if={@highlight}
          class="shrink-0 rounded-full bg-indigo-600/10 px-2 py-0.5 text-[10px] font-semibold text-indigo-700 dark:bg-indigo-400/10 dark:text-indigo-200"
        >
          Latest
        </span>
      </div>
      <p class="mt-1 text-xs text-gray-500 dark:text-gray-400"><%= format_date(@date) %></p>
      <div :if={@tags != []} class="mt-2 flex flex-wrap gap-1">
        <span
          :for={tag <- @tags}
          class="rounded-full bg-indigo-50 px-2 py-0.5 text-[11px] font-semibold text-indigo-700 dark:bg-indigo-900/40 dark:text-indigo-100"
        >
          <%= tag %>
        </span>
      </div>
    </.link>
    """
  end

  attr :id, :string, required: true
  attr :kind, :string, values: ["archive", "tag"], required: true
  attr :year, :integer, required: true
  attr :count, :integer, required: true
  attr :months, :list, default: []
  attr :expanded?, :boolean, required: true
  attr :current_note_id, :any, default: nil
  attr :target, :any, required: true

  defp year_group(assigns) do
    ~H"""
    <div class="overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm dark:border-gray-800 dark:bg-gray-950">
      <button
        type="button"
        class="flex w-full items-center justify-between gap-3 px-3 py-2 text-left text-sm font-semibold text-gray-800 hover:bg-gray-50 dark:text-gray-100 dark:hover:bg-gray-900"
        phx-click="timeline_toggle_year"
        phx-target={@target}
        phx-value-kind={@kind}
        phx-value-year={@year}
        aria-expanded={@expanded?}
        aria-controls={"#{@id}-items"}
      >
        <span><%= @year %></span>
        <span class="flex items-center gap-2 text-xs font-semibold text-gray-500 dark:text-gray-400">
          <%= @count %>
          <.icon name={(@expanded? && "hero-minus-mini") || "hero-plus-mini"} class="h-4 w-4" />
        </span>
      </button>

      <div
        :if={@expanded?}
        id={"#{@id}-items"}
        phx-mounted={show("##{@id}-items")}
        phx-remove={hide("##{@id}-items")}
        class="hidden border-t border-gray-200 bg-white p-3 dark:border-gray-800 dark:bg-gray-950"
      >
        <%= for month <- @months do %>
          <div class="first:pt-0 pt-3">
            <div class="flex items-center justify-between text-xs font-semibold text-gray-600 dark:text-gray-300">
              <span><%= month.label %></span>
              <span class="text-[11px] text-gray-500 dark:text-gray-400"><%= month.count %></span>
            </div>
            <div class="mt-2 space-y-2">
              <%= for item <- month.entries do %>
                <.timeline_item current_note_id={@current_note_id} item={item} />
              <% end %>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("timeline_set_mode", %{"mode" => mode}, socket) do
    mode = if mode in @modes, do: mode, else: "recent_activity"

    socket =
      socket
      |> assign(:mode, mode)
      |> maybe_load_for_mode()

    {:noreply, socket}
  end

  def handle_event("timeline_toggle_year", %{"kind" => kind, "year" => year}, socket) do
    year = parse_int(year)

    socket =
      case {kind, year} do
        {"archive", year} when is_integer(year) ->
          update(socket, :expanded_archive_years, &toggle_year(&1, year))

        {"tag", year} when is_integer(year) ->
          update(socket, :expanded_tag_years, &toggle_year(&1, year))

        _ ->
          socket
      end

    {:noreply, socket}
  end

  def handle_event("timeline_select_tag", %{"tag" => tag}, socket) do
    tag = String.trim(to_string(tag))

    socket =
      socket
      |> assign(:selected_tag, tag)
      |> ensure_tag_timeline_loaded()

    {:noreply, socket}
  end

  defp ensure_recent_loaded(socket) do
    if socket.assigns.recent_loaded do
      socket
    else
      recent = NoteData.timeline_recent_activity(@recent_limit)
      assign(socket, recent_loaded: true, recent: recent)
    end
  end

  defp maybe_load_for_mode(%{assigns: %{mode: "recent_activity"}} = socket),
    do: ensure_recent_loaded(socket)

  defp maybe_load_for_mode(%{assigns: %{mode: "year_archive"}} = socket),
    do: ensure_archive_loaded(socket)

  defp maybe_load_for_mode(%{assigns: %{mode: "tag_timeline"}} = socket),
    do: ensure_tag_timeline_loaded(socket)

  defp ensure_archive_loaded(socket) do
    if socket.assigns.archive_loaded do
      socket
    else
      groups =
        NoteData.timeline_year_archive()
        |> group_by_year_month()

      expanded_years = default_expanded_years(groups)

      assign(socket,
        archive_loaded: true,
        archive_groups: groups,
        expanded_archive_years: expanded_years
      )
    end
  end

  defp ensure_tags_loaded(socket) do
    if socket.assigns.tags_loaded do
      socket
    else
      tags = NoteData.list_tags()
      assign(socket, tags_loaded: true, available_tags: tags)
    end
  end

  defp ensure_tag_timeline_loaded(socket) do
    socket =
      socket
      |> ensure_archive_loaded()
      |> ensure_tag_counts_loaded()
      |> ensure_tags_loaded()

    selected = default_selected_tag(socket.assigns.selected_tag, socket.assigns.available_tags)

    socket =
      socket
      |> assign(:selected_tag, selected)
      |> maybe_load_selected_tag(selected)

    socket
  end

  defp maybe_load_selected_tag(socket, ""), do: assign(socket, tag_groups: [], tag_loaded_for: "")

  defp maybe_load_selected_tag(socket, tag) do
    if socket.assigns.tag_loaded_for == tag do
      socket
    else
      groups =
        NoteData.timeline_tag_timeline(tag)
        |> group_by_year_month()

      expanded_years = default_expanded_years(groups)

      assign(socket,
        tag_loaded_for: tag,
        tag_groups: groups,
        expanded_tag_years: expanded_years
      )
    end
  end

  defp ensure_tag_counts_loaded(socket) do
    if socket.assigns.tag_counts_loaded do
      socket
    else
      counts = tag_counts_from_archive(socket.assigns.archive_groups)
      assign(socket, tag_counts_loaded: true, tag_counts: counts)
    end
  end

  defp tag_counts_from_archive(groups) do
    groups
    |> Enum.flat_map(fn group -> Enum.flat_map(group.months, & &1.entries) end)
    |> Enum.flat_map(fn entry -> Markdown.tag_list(entry.tags) end)
    |> Enum.frequencies()
  end

  defp group_by_year_month(entries) do
    entries
    |> Enum.reduce([], fn entry, acc ->
      year = entry |> display_date() |> year_of()
      month = entry |> display_date() |> month_of()

      case acc do
        [%{year: ^year, months: months} = group | rest] ->
          months =
            case months do
              [%{month: ^month, entries: month_entries} = month_group | month_rest] ->
                [%{month_group | entries: [entry | month_entries]} | month_rest]

              _ ->
                [%{month: month, entries: [entry]} | months]
            end

          [%{group | months: months} | rest]

        _ ->
          [%{year: year, months: [%{month: month, entries: [entry]}]} | acc]
      end
    end)
    |> Enum.reverse()
    |> Enum.map(fn group ->
      months =
        group.months
        |> Enum.reverse()
        |> Enum.map(fn month_group ->
          entries = Enum.reverse(month_group.entries)

          %{
            month: month_group.month,
            label: month_label(month_group.month),
            count: length(entries),
            entries: entries
          }
        end)

      count = Enum.reduce(months, 0, fn m, sum -> sum + m.count end)

      %{
        year: group.year,
        count: count,
        months: months
      }
    end)
  end

  defp default_expanded_years([]), do: MapSet.new()
  defp default_expanded_years([%{year: year} | _]), do: MapSet.new([year])

  defp display_date(%{published_at: %DateTime{} = dt}), do: dt
  defp display_date(%{published_at: %NaiveDateTime{} = dt}), do: dt
  defp display_date(%{inserted_at: %DateTime{} = dt}), do: dt
  defp display_date(%{inserted_at: %NaiveDateTime{} = dt}), do: dt
  defp display_date(_), do: nil

  defp year_of(%DateTime{} = dt), do: dt.year
  defp year_of(%NaiveDateTime{} = dt), do: dt.year
  defp year_of(_), do: 0

  defp month_of(%DateTime{} = dt), do: dt.month
  defp month_of(%NaiveDateTime{} = dt), do: dt.month
  defp month_of(_), do: 1

  defp month_label(month) when month in 1..12 do
    ~w(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec) |> Enum.at(month - 1)
  end

  defp format_date(%DateTime{} = date), do: Calendar.strftime(date, "%Y-%m-%d")
  defp format_date(%NaiveDateTime{} = date), do: Calendar.strftime(date, "%Y-%m-%d")
  defp format_date(_), do: ""

  defp toggle_year(set, year) do
    if MapSet.member?(set, year), do: MapSet.delete(set, year), else: MapSet.put(set, year)
  end

  defp default_selected_tag("", [first | _]), do: first
  defp default_selected_tag(tag, _tags), do: tag

  defp mode_label("recent_activity"), do: "Recent"
  defp mode_label("year_archive"), do: "Archive"
  defp mode_label("tag_timeline"), do: "Tag"
  defp mode_label(_), do: "Mode"

  defp parse_int(val) when is_integer(val), do: val

  defp parse_int(val) when is_binary(val) do
    case Integer.parse(val) do
      {int, _} -> int
      _ -> nil
    end
  end

  defp parse_int(_), do: nil
end
