defmodule BlogWeb.LogLive do
    use BlogWeb, :live_view

    alias BlogWeb.{ActiveLog, Scope}

    def render(assigns) do
        ~H"""
        <div id="activity_logs" class="mt-8">
          <ol class="relative border-s border-gray-200 dark:border-gray-700">
            <%= for log <- @logs do %>
            <li class="ms-4">
                <div class="absolute w-3 h-3 bg-gray-200 rounded-full mt-1.5 -start-1.5 border border-white dark:border-gray-900 dark:bg-gray-700"></div>
                <time class="mb-1 text-sm font-normal leading-none text-gray-400 dark:text-gray-500"><%= NaiveDateTime.to_string(log.inserted_at) %></time>
                <h3 class="text-lg font-semibold text-gray-900 dark:text-white"><%= log.location %></h3>
                <p class="text-base font-normal text-gray-500 dark:text-gray-400"><%= log.event %> : <%= log.input %></p>
            </li>
            <% end %>
          </ol>
        </div>
        """
    end

    def mount(_params, _session, socket) do
      Phoenix.PubSub.subscribe(Blog.PubSub, "activity_logs")
      # ActiveLog.log("LogLive", "로그 페이지", %Scope{}, "")
      {:ok, assign(socket, logs: ActiveLog.get_logs())}
    end

    @impl true
    def handle_info(:logs_updated, socket) do
      {:noreply, assign(socket, logs: ActiveLog.get_logs())}
    end
end
