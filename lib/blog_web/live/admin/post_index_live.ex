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
          <p class="text-xs uppercase tracking-wide text-gray-500">Admin</p>
          <h1 class="text-2xl font-bold text-gray-900 dark:text-gray-100">Posts</h1>
        </div>
        <.link
          navigate={~p"/admin/posts/new"}
          class="rounded-lg bg-indigo-600 px-4 py-2 text-sm font-semibold text-white hover:bg-indigo-500"
        >
          New post
        </.link>
      </div>

      <div class="overflow-x-auto rounded-xl border border-gray-200 bg-white shadow-sm dark:border-gray-800 dark:bg-gray-900">
        <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-800 text-sm">
          <thead class="bg-gray-50 dark:bg-gray-800">
            <tr>
              <th class="px-4 py-3 text-left font-semibold text-gray-700 dark:text-gray-200">
                Title
              </th>
              <th class="px-4 py-3 text-left font-semibold text-gray-700 dark:text-gray-200">
                Status
              </th>
              <th class="px-4 py-3 text-left font-semibold text-gray-700 dark:text-gray-200">
                Published
              </th>
              <th class="px-4 py-3 text-left font-semibold text-gray-700 dark:text-gray-200">Tags</th>
              <th class="px-4 py-3 text-left font-semibold text-gray-700 dark:text-gray-200">
                Series
              </th>
              <th class="px-4 py-3 text-left font-semibold text-gray-700 dark:text-gray-200"></th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-200 dark:divide-gray-800">
            <tr :for={post <- @posts} class="hover:bg-gray-50 dark:hover:bg-gray-800/60">
              <td class="px-4 py-3">
                <div class="font-semibold text-gray-900 dark:text-gray-100"><%= post.title %></div>
                <div class="text-xs text-gray-500 line-clamp-1 dark:text-gray-400">
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
              <td class="px-4 py-3 text-gray-700 dark:text-gray-200">
                <%= format_date(post.published_at || post.inserted_at) %>
              </td>
              <td class="px-4 py-3 text-gray-700 dark:text-gray-200">
                <div class="flex flex-wrap gap-1">
                  <span
                    :for={tag <- Markdown.tag_list(post.tags)}
                    class="rounded-full bg-gray-100 px-2 py-0.5 text-[11px] font-semibold text-gray-700 dark:bg-gray-800 dark:text-gray-200"
                  >
                    <%= tag %>
                  </span>
                </div>
              </td>
              <td class="px-4 py-3 text-gray-700 dark:text-gray-200">
                <%= if post.series_id do %>
                  <span class="font-mono text-xs bg-gray-100 dark:bg-gray-800 px-2 py-1 rounded">
                    <%= post.series_id %> (#<%= post.series_order || 0 %>)
                  </span>
                <% end %>
              </td>
              <td class="px-4 py-3 text-right space-x-2">
                <.link
                  navigate={~p"/admin/posts/#{post.id}/edit"}
                  class="text-indigo-600 text-sm font-semibold hover:text-indigo-500"
                >
                  Edit
                </.link>
                <button
                  phx-click="set_status"
                  phx-value-id={post.id}
                  phx-value-status={toggle_target(post.status)}
                  class="text-sm font-semibold text-gray-700 hover:text-gray-900 dark:text-gray-200 dark:hover:text-white"
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
