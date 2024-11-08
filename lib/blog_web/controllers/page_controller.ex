defmodule BlogWeb.PageController do
  use BlogWeb, :live_view

  alias Blog.NoteData

  # :controller 는 HTTP 요청을 처리하고 응답을 반환
  # :live_view 는 사용자 인터페이스를 렌더링하고 사용자와 상호작용
  def render(assigns) do
    ~H"""
    <div id="home" class="space-y-5">
      <.header>
        <h1 class="text-4xl font-bold text-center">dev</h1>
        <div class="flex items-center space-x-6">
          <div class="relative">
            <input type="text" placeholder="Search"
              phx-debounce="300"
              phx-keyup="update_input"
              phx-change="update_input"
              id="query" name="query" class="bg-gray-100 text-gray-800 py-1 px-4 rounded-full focus:outline-none focus:ring-2 focus:ring-indigo-500 w-64 shadow-sm">
            <span class="absolute inset-y-0 right-0 flex items-center pr-3">
              <kbd class="bg-gray-200 text-gray-500 rounded px-1">Ctrl</kbd>
              <span class="mx-1 text-gray-500">+</span>
              <kbd class="bg-gray-200 text-gray-500 rounded px-1">K</kbd>
            </span>
          </div>
        </div>
      </.header>
      <div style="display: flex; align-items: center;">
        정렬
        <.link patch={~p"/list?sort=#{@sort_order}"} alt="Sort by date">
          <%= if @sort_order == :asc do %>
            <Heroicons.icon name="arrow-long-up" type="outline" class="h-4 w-4" />
          <% else %>
            <Heroicons.icon name="arrow-long-down" type="outline" class="h-4 w-4" />
          <% end %>
        </.link>
      </div>
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <%= for n <- @note do %>
          <.link href={~p"/item/#{n.id}"}>
            <div class="note-item border rounded-lg overflow-hidden shadow-md hover:shadow-lg transition transform group">
              <img src='https://res.cloudinary.com/daily-now/image/upload/f_auto,q_auto/v1/posts/dad187517df28299613ac0ac4caa1194?_a=AQAEuj9' alt="Note Image"
                  class="w-full h-60 object-cover hover:rotate-1 hover:scale- transition-transform duration-300" />
              <div class="p-4">
                <span class="block text-sm font-semibold text-blue-600 mb-1">#테스트, #테스트2</span>
                <h2 class="text-xl font-bold mb-2">
                  <%= n.title %>
                </h2>
                <p class="text-base text-gray-700 mb-4">
                  <%= n.content |> String.slice(0, 100) %>...
                </p>
                <div class="flex items-center">
                  <div>
                    <p class="text-sm font-semibold text-gray-900">junho</p>
                    <p class="text-xs text-gray-500"><%= Date.to_string(n.inserted_at) %></p>
                  </div>
                </div>
              </div>
            </div>
          </.link>
        <% end %>
      </div>
    </div>
    <.modal
      :if={@live_action in [:add]}
      id="post-modal"
      show
      on_cancel={JS.patch(~p"/")}
    >
      <.live_component
        module={BlogWeb.FormComponent}
        id={:add}
        input={:test}
        title={@page_title}
        action={@live_action}
        patch={~p"/"}
      />
    </.modal>
    """
  end

  def mount(_params, _session, socket) do
    notes = NoteData.get_all_content()
    {:ok, assign(socket, note: notes, sort_order: :desc)}
  end

  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  # sorting_event
  defp apply_action(socket, :list, _params) do
    notes = socket.assigns.note
    notes = if socket.assigns.sort_order == :asc do
      Enum.sort_by(notes, & &1.inserted_at)
    else
      Enum.sort_by(notes, & &1.inserted_at, &>=/2)
    end
    assign(socket, note: notes, sort_order: if socket.assigns.sort_order == :desc do :asc else :desc end )
  end

  defp apply_action(socket, :home, _params) do
    socket
  end

  defp apply_action(socket, :add, _params) do
    socket
    |> assign(:page_title, "New Post")
  end

  def handle_event("update_input", %{"value" => value}, socket) do
    notes = NoteData.get_content_by_title([title: value])
    {:noreply, assign(socket, note: notes)}
  end

end