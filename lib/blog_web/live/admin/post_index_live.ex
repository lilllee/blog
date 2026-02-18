defmodule BlogWeb.Admin.PostIndexLive do
  use BlogWeb, :live_view

  alias Blog.NoteData
  alias BlogWeb.Markdown

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, posts: load_posts(), page_title: "Admin · Posts")}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    note = NoteData.get_admin_note!(id)
    {:ok, _} = NoteData.soft_delete_note(note)
    {:noreply, assign(socket, :posts, load_posts())}
  end

  def handle_event("set_status", %{"id" => id, "status" => status}, socket) do
    note = NoteData.get_admin_note!(id)
    {:ok, _} = NoteData.toggle_publish(note, status)
    {:noreply, assign(socket, :posts, load_posts())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="px-6 py-6 space-y-6">
      <div class="flex items-center justify-between">
        <div>
          <p class="text-xs uppercase tracking-wide text-muted-foreground">Admin</p>
          <h1 class="text-2xl font-bold text-foreground">Posts</h1>
        </div>
        <.link
          navigate={~p"/admin/posts/new"}
          class="rounded-lg bg-foreground px-4 py-2 text-sm font-semibold text-background hover:bg-foreground/90"
        >
          New post
        </.link>
      </div>

      <div class="overflow-x-auto rounded-xl border border-border bg-card shadow-sm">
        <table class="min-w-full divide-y divide-border text-sm">
          <thead class="bg-muted">
            <tr>
              <th class="px-4 py-3 text-left font-semibold text-muted-foreground">
                Title
              </th>
              <th class="px-4 py-3 text-left font-semibold text-muted-foreground">
                Status
              </th>
              <th class="px-4 py-3 text-left font-semibold text-muted-foreground">
                Published
              </th>
              <th class="px-4 py-3 text-left font-semibold text-muted-foreground">Tags</th>
              <th class="px-4 py-3 text-left font-semibold text-muted-foreground">
                Series
              </th>
              <th class="px-4 py-3 text-left font-semibold text-muted-foreground"></th>
            </tr>
          </thead>
          <tbody class="divide-y divide-border">
            <tr :for={post <- @posts} class="card-hover">
              <td class="px-4 py-3">
                <div class="font-semibold text-foreground"><%= post.title %></div>
                <div class="text-xs text-muted-foreground line-clamp-1">
                  <%= excerpt(post.raw_markdown || post.content) %>
                </div>
              </td>
              <td class="px-4 py-3">
                <span class={[
                  "inline-flex items-center rounded-full px-2 py-0.5 text-xs font-semibold",
                  post.status == "published" && "bg-emerald-100 text-emerald-800",
                  post.status == "draft" && "bg-amber-100 text-amber-800"
                ]}>
                  <%= String.capitalize(post.status) %>
                </span>
              </td>
              <td class="px-4 py-3 text-foreground">
                <%= format_date(post.published_at || post.inserted_at) %>
              </td>
              <td class="px-4 py-3 text-foreground">
                <div class="flex flex-wrap gap-1">
                  <span
                    :for={tag <- Markdown.tag_list(post.tags)}
                    class="rounded-full bg-muted px-2 py-0.5 text-[11px] font-semibold text-muted-foreground"
                  >
                    <%= tag %>
                  </span>
                </div>
              </td>
              <td class="px-4 py-3 text-foreground">
                <%= if post.series_id do %>
                  <span class="font-mono text-xs bg-muted px-2 py-1 rounded">
                    <%= post.series_id %> (#<%= post.series_order || 0 %>)
                  </span>
                <% end %>
              </td>
              <td class="px-4 py-3 text-right space-x-2">
                <.link
                  navigate={~p"/admin/posts/#{post.id}/edit"}
                  class="text-foreground text-sm font-semibold underline hover:text-foreground/80"
                >
                  Edit
                </.link>
                <button
                  phx-click="set_status"
                  phx-value-id={post.id}
                  phx-value-status={toggle_target(post.status)}
                  class="text-sm font-semibold text-muted-foreground hover:text-foreground"
                >
                  <%= if post.status == "published", do: "Unpublish", else: "Publish" %>
                </button>
                <button
                  phx-click="delete"
                  phx-value-id={post.id}
                  data-confirm="Delete this post?"
                  class="text-sm font-semibold text-rose-600 hover:text-rose-500"
                >
                  Delete
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  defp load_posts, do: NoteData.list_admin_notes()

  defp toggle_target("published"), do: "draft"
  defp toggle_target(_), do: "published"

  defp format_date(nil), do: "-"
  defp format_date(%DateTime{} = dt), do: Calendar.strftime(dt, "%Y-%m-%d")

  defp format_date(%NaiveDateTime{} = dt) do
    dt
    |> DateTime.from_naive!("Etc/UTC")
    |> format_date()
  end

  defp excerpt(content) do
    content
    |> to_string()
    |> String.replace(~r/\s+/, " ")
    |> String.slice(0, 80)
    |> case do
      text when byte_size(text) < 80 -> text
      text -> text <> "…"
    end
  end
end
