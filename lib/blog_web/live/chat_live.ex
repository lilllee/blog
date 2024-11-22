defmodule BlogWeb.ChatLive do
  use BlogWeb, :live_view

  def render(assigns) do
    ~H"""
    <div>
      chat
    </div>
    """

  end
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
