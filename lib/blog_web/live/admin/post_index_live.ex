defmodule BlogWeb.Admin.PostIndexLive do
  use BlogWeb, :live_view

  alias Blog.NoteData

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, posts: load_posts(), page_title: "posts · admin")}
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
    <.link navigate={~p"/"} class="back">← 홈</.link>

    <div class="admin-head">
      <h1>posts <span class="crumb"><%= summary(@posts) %></span></h1>
      <span class="admin-head-right">
        <.link navigate={~p"/admin/about"} class="new">edit about</.link>
        <.link navigate={~p"/admin/posts/new"} class="new">+ new post</.link>
      </span>
    </div>

    <ul class="admin-list">
      <li :for={post <- @posts}>
        <div class="admin-row">
          <.link navigate={~p"/admin/posts/#{post.id}/edit"} class="rtitle">
            <%= post.title %><span :if={post.status == "draft"} class="draft-mark">draft</span>
          </.link>
          <div class="rmeta">
            <%= format_date(post.published_at || post.inserted_at) %>
          </div>
          <div class="ractions">
            <.link navigate={~p"/admin/posts/#{post.id}/edit"}>edit</.link>
            <button
              type="button"
              phx-click="set_status"
              phx-value-id={post.id}
              phx-value-status={toggle_target(post.status)}
            >
              <%= if post.status == "published", do: "unpublish", else: "publish" %>
            </button>
            <button
              type="button"
              phx-click="delete"
              phx-value-id={post.id}
              data-confirm={"\"#{post.title}\" 을(를) 삭제할까요?"}
            >
              delete
            </button>
          </div>
        </div>
      </li>
    </ul>
    """
  end

  defp summary([]), do: ""

  defp summary(posts) do
    pub = Enum.count(posts, &(&1.status == "published"))
    "(#{length(posts)} · #{pub} published)"
  end

  defp load_posts, do: NoteData.list_admin_notes()

  defp toggle_target("published"), do: "draft"
  defp toggle_target(_), do: "published"

  defp format_date(%DateTime{} = d), do: Calendar.strftime(d, "%Y.%m.%d")

  defp format_date(%NaiveDateTime{} = d) do
    d |> DateTime.from_naive!("Etc/UTC") |> format_date()
  end

  defp format_date(_), do: ""
end
