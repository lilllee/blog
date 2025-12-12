defmodule BlogWeb.PageController do
  use BlogWeb, :live_view
  alias BlogWeb.Scope
  alias Blog.NoteData

  # :controller 는 HTTP 요청을 처리하고 응답을 반환
  # :live_view 는 사용자 인터페이스를 렌더링하고 사용자와 상호작용
  def render(assigns) do
    ~H"""
    <div id="home" class="space-y-5">
      <.header>
        <div class="flex items-center space-x-6">
          <div class="relative">
            <input
              type="text"
              placeholder="Search"
              phx-debounce="300"
              phx-keyup="update_input"
              phx-change="update_input"
              id="query"
              name="query"
              class="bg-gray-100 dark:bg-gray-800 text-gray-800 dark:text-gray-200 py-1 px-4 rounded-full focus:outline-none focus:ring-2 focus:ring-indigo-500 w-64 shadow-sm"
            >
            <span class="absolute inset-y-0 right-0 flex items-center pr-3">
              <kbd class="bg-gray-200 dark:bg-gray-700 text-gray-500 dark:text-gray-300 rounded px-1">Ctrl</kbd>
              <span class="mx-1 text-gray-500 dark:text-gray-300">+</span>
              <kbd class="bg-gray-200 dark:bg-gray-700 text-gray-500 dark:text-gray-300 rounded px-1">K</kbd>
            </span>
          </div>
        </div>
      </.header>
      <%!-- <div style="display: flex; align-items: center;">
        정렬
        <.link patch={~p"/list?sort=#{@sort_order}"} alt="Sort by date">
          <%= if @sort_order == :asc do %>
            <Heroicons.icon name="arrow-long-up" type="outline" class="h-4 w-4" />
          <% else %>
            <Heroicons.icon name="arrow-long-down" type="outline" class="h-4 w-4" />
          <% end %>
        </.link>
      </div> --%>
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <%= for n <- @note do %>
          <.link href={~p"/item/#{n.id}"}>
            <div class="note-item border rounded-lg overflow-hidden shadow-md hover:shadow-lg transition transform group">
              <img phx-track-static src={~p"/images/#{n.image_path}"} alt="Note Image"
                  class="w-full h-60 object-cover hover:rotate-1 hover:scale- transition-transform duration-300" />
              <div class="p-4">
                <span class="block text-sm font-semibold text-blue-600 mb-1"><%= n.tags %></span>
                <h2 class="text-xl font-bold mb-2">
                  <%= n.title %>
                </h2>
                <p class="text-base text-gray-700 mb-4">
                  <%= n.content |> String.slice(0, 50) %>...
                </p>
                <div class="flex items-center">
                  <div>
                    <p class="text-sm font-semibold text-gray-900">junho</p>
                    <p class="text-xs text-gray-500"><%= n.inserted_at %></p>
                  </div>
                </div>
              </div>
            </div>
          </.link>
        <% end %>
      </div>
    </div>
    """
  end

  @spec mount(any(), any(), any()) :: none()
  def mount(_params, %{"remote_ip" => remote_ip}, socket) do
    scope = %Scope{current_ip: remote_ip} |> IO.inspect()
    notes = NoteData.get_all_notes()

    {:ok, assign(socket,
      remote_ip: remote_ip,
      note: notes,
      scope: scope,
      message: "",
      messages: ["123", "123123", "123123123"]
    )}
  end

  @spec handle_params(nil | maybe_improper_list() | map(), any(), any()) :: {:noreply, any()}
  def handle_params(params, _uri, socket) do
    socket =
      if query = params["query"] do
        notes = NoteData.search_notes(query)
        assign(socket, note: notes, query: query)
      else
        socket
      end

    {:noreply, socket}
  end

  defp apply_action(socket, :list, _params) do
    assign(socket, note: socket.assigns.note )
  end

  defp apply_action(socket, :home, _params) do
    socket
  end

  @spec handle_event(<<_::96>>, map(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_event("update_input", %{"value" => value}, socket) do
    {:noreply, push_patch(socket, to: ~p"/list?#{[query: value]}")}
  end
end
