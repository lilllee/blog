defmodule BlogWeb.Hooks.MusicPlayer do
  @moduledoc """
  LiveView on_mount hook that provides music player state and event handling.
  Attach via `live_session` so the player works across all public pages.
  """
  import Phoenix.LiveView
  import Phoenix.Component, only: [assign: 3]

  alias Blog.Music

  def on_mount(:default, _params, _session, socket) do
    tracks = Music.list_tracks()
    current_track = List.first(tracks)

    current_path =
      case socket.private do
        %{connect_info: %{request_path: path}} -> path
        _ -> nil
      end

    {:cont,
     socket
     |> assign(:current_path, current_path)
     |> assign(:music_tracks, tracks)
     |> assign(:music_current_track_id, current_track && current_track.id)
     |> assign(:music_current_track, current_track)
     |> assign(:music_repeat_mode, "off")
     |> assign(:music_shuffle_enabled, false)
     |> attach_hook(:music_player_events, :handle_event, &handle_event/3)
     |> attach_hook(:nav_active_path, :handle_params, &handle_params/3)}
  end

  defp handle_params(_params, uri, socket) do
    path = URI.parse(uri).path
    {:cont, assign(socket, :current_path, path)}
  end

  defp handle_event("player_select_track", %{"track_id" => track_id}, socket) do
    track_id = parse_id(track_id)
    tracks = socket.assigns.music_tracks

    if track_id && Enum.any?(tracks, &(&1.id == track_id)) do
      {:halt,
       socket
       |> assign(:music_current_track_id, track_id)
       |> assign(:music_current_track, Enum.find(tracks, &(&1.id == track_id)))}
    else
      {:halt, socket}
    end
  end

  defp handle_event("player_next", _params, socket) do
    next_id =
      next_track_id(
        socket.assigns.music_tracks,
        socket.assigns.music_current_track_id,
        socket.assigns.music_shuffle_enabled,
        socket.assigns.music_repeat_mode
      )

    case next_id do
      nil ->
        {:halt, socket}

      id ->
        {:halt,
         socket
         |> assign(:music_current_track_id, id)
         |> assign(:music_current_track, Enum.find(socket.assigns.music_tracks, &(&1.id == id)))}
    end
  end

  defp handle_event("player_prev", _params, socket) do
    prev_id =
      prev_track_id(
        socket.assigns.music_tracks,
        socket.assigns.music_current_track_id,
        socket.assigns.music_repeat_mode
      )

    case prev_id do
      nil ->
        {:halt, socket}

      id ->
        {:halt,
         socket
         |> assign(:music_current_track_id, id)
         |> assign(:music_current_track, Enum.find(socket.assigns.music_tracks, &(&1.id == id)))}
    end
  end

  defp handle_event("player_toggle_repeat", _params, socket) do
    mode = if socket.assigns.music_repeat_mode == "all", do: "off", else: "all"
    {:halt, assign(socket, :music_repeat_mode, mode)}
  end

  defp handle_event("player_toggle_shuffle", _params, socket) do
    {:halt, assign(socket, :music_shuffle_enabled, !socket.assigns.music_shuffle_enabled)}
  end

  defp handle_event(_event, _params, socket), do: {:cont, socket}

  # -- track navigation helpers --

  defp next_track_id([], _current_id, _shuffle, _repeat), do: nil

  defp next_track_id(tracks, current_id, true, repeat_mode) do
    ids = Enum.map(tracks, & &1.id)
    remaining = Enum.reject(ids, &(&1 == current_id))

    case remaining do
      [] -> if repeat_mode == "all", do: current_id, else: nil
      _ -> Enum.random(remaining)
    end
  end

  defp next_track_id(tracks, current_id, false, repeat_mode) do
    ids = Enum.map(tracks, & &1.id)
    index = Enum.find_index(ids, &(&1 == current_id))

    cond do
      is_nil(index) -> List.first(ids)
      index + 1 < length(ids) -> Enum.at(ids, index + 1)
      repeat_mode == "all" -> List.first(ids)
      true -> nil
    end
  end

  defp prev_track_id([], _current_id, _repeat), do: nil

  defp prev_track_id(tracks, current_id, repeat_mode) do
    ids = Enum.map(tracks, & &1.id)
    index = Enum.find_index(ids, &(&1 == current_id))

    cond do
      is_nil(index) -> List.first(ids)
      index - 1 >= 0 -> Enum.at(ids, index - 1)
      repeat_mode == "all" -> List.last(ids)
      true -> nil
    end
  end

  defp parse_id(nil), do: nil

  defp parse_id(value) do
    case Integer.parse(to_string(value)) do
      {id, _} -> id
      _ -> nil
    end
  end
end
