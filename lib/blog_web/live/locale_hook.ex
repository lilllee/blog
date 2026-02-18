defmodule BlogWeb.LocaleHook do
  @moduledoc """
  LiveView hook for managing locale/language state.

  Priority: connect_params (JS localStorage) > session (cookie) > default "ko"
  """

  import Phoenix.LiveView
  import Phoenix.Component

  def on_mount(:default, _params, session, socket) do
    locale =
      session["locale"] ||
        get_connect_params(socket)["locale"] ||
        "ko"

    locale =
      if locale in Blog.Translation.supported_languages(), do: locale, else: "ko"

    socket =
      socket
      |> assign(:locale, locale)
      |> attach_hook(:locale_handler, :handle_event, &handle_locale_event/3)

    {:cont, socket}
  end

  defp handle_locale_event("set_locale", %{"locale" => locale}, socket) do
    if locale in Blog.Translation.supported_languages() do
      socket =
        socket
        |> assign(:locale, locale)
        |> push_event("locale-changed", %{locale: locale})

      send(self(), {:locale_changed, locale})

      {:halt, socket}
    else
      {:cont, socket}
    end
  end

  defp handle_locale_event(_event, _params, socket) do
    {:cont, socket}
  end
end
