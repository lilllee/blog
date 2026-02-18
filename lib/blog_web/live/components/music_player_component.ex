defmodule BlogWeb.MusicPlayerComponent do
  @moduledoc """
  Function component for the floating music player dock.
  State and events are handled by `BlogWeb.Hooks.MusicPlayer` on_mount hook.
  """
  use Phoenix.Component

  import BlogWeb.CoreComponents, only: [icon: 1]

  attr :tracks, :list, required: true
  attr :current_track, :any, default: nil
  attr :current_track_id, :any, default: nil
  attr :repeat_mode, :string, default: "off"
  attr :shuffle_enabled, :boolean, default: false

  def player(assigns) do
    ~H"""
    <div
      id="music-player"
      phx-hook="MusicPlayer"
      data-current-track-id={@current_track_id}
      data-current-src={track_src(@current_track)}
      data-repeat-mode={@repeat_mode}
      data-shuffle-enabled={@shuffle_enabled}
      class="fixed bottom-6 right-6 z-50 w-[280px] sm:w-[320px]"
    >
      <div class="rounded-2xl border border-border bg-background/95 p-4 shadow-lg backdrop-blur">
        <div data-player-collapsed class="flex items-center gap-3">
          <button
            type="button"
            data-player-play
            aria-label="Play or pause"
            class="inline-flex h-10 w-10 items-center justify-center rounded-full border border-border text-foreground transition hover:border-foreground/30 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-foreground/20 disabled:opacity-50"
            disabled={is_nil(@current_track)}
          >
            <span data-player-icon-play><.icon name="hero-play-solid" class="h-5 w-5" /></span>
            <span data-player-icon-pause class="hidden"><.icon name="hero-pause-solid" class="h-5 w-5" /></span>
          </button>

          <div class="min-w-0 flex-1">
            <p class="truncate text-sm font-semibold text-foreground">
              <%= @current_track && @current_track.title || "No tracks yet" %>
            </p>
            <div class="mt-2 h-1 w-full rounded-full bg-muted">
              <div data-player-progress class="h-full w-0 rounded-full bg-foreground/60"></div>
            </div>
          </div>

          <button
            type="button"
            data-player-expand
            aria-label="Expand player"
            class="inline-flex h-9 w-9 items-center justify-center rounded-full border border-border text-muted-foreground transition hover:border-foreground/30 hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-foreground/20"
          >
            <.icon name="hero-chevron-up-solid" class="h-4 w-4" />
          </button>
        </div>

        <div data-player-expanded class="hidden space-y-4 pt-4">
          <div class="flex items-start justify-between">
            <div class="min-w-0">
              <p class="truncate text-sm font-semibold text-foreground">
                <%= @current_track && @current_track.title || "No track selected" %>
              </p>
              <p class="mt-1 text-xs text-muted-foreground">
                <span data-player-current-time>0:00</span> / <span data-player-duration>--:--</span>
              </p>
            </div>

            <button
              type="button"
              data-player-collapse
              aria-label="Collapse player"
              class="inline-flex h-9 w-9 items-center justify-center rounded-full border border-border text-muted-foreground transition hover:border-foreground/30 hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-foreground/20"
            >
              <.icon name="hero-chevron-down-solid" class="h-4 w-4" />
            </button>
          </div>

          <input
            data-player-seek
            type="range"
            min="0"
            max="100"
            value="0"
            aria-label="Seek"
            class="h-2 w-full cursor-pointer accent-foreground"
            disabled={is_nil(@current_track)}
          />

          <div class="flex items-center justify-between">
            <button
              type="button"
              phx-click="player_prev"
              aria-label="Previous track"
              class="inline-flex h-9 w-9 items-center justify-center rounded-full border border-border text-muted-foreground transition hover:border-foreground/30 hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-foreground/20 disabled:opacity-50"
              disabled={is_nil(@current_track)}
            >
              <.icon name="hero-backward-solid" class="h-4 w-4" />
            </button>

            <button
              type="button"
              data-player-play
              aria-label="Play or pause"
              class="inline-flex h-11 w-11 items-center justify-center rounded-full border border-border text-foreground transition hover:border-foreground/30 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-foreground/20 disabled:opacity-50"
              disabled={is_nil(@current_track)}
            >
              <span data-player-icon-play><.icon name="hero-play-solid" class="h-5 w-5" /></span>
              <span data-player-icon-pause class="hidden"><.icon name="hero-pause-solid" class="h-5 w-5" /></span>
            </button>

            <button
              type="button"
              phx-click="player_next"
              aria-label="Next track"
              class="inline-flex h-9 w-9 items-center justify-center rounded-full border border-border text-muted-foreground transition hover:border-foreground/30 hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-foreground/20 disabled:opacity-50"
              disabled={is_nil(@current_track)}
            >
              <.icon name="hero-forward-solid" class="h-4 w-4" />
            </button>

            <button
              type="button"
              phx-click="player_toggle_repeat"
              aria-label="Repeat"
              class={[
                "inline-flex h-9 w-9 items-center justify-center rounded-full border transition focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-foreground/20",
                @repeat_mode == "all" && "border-foreground/50 text-foreground",
                @repeat_mode != "all" && "border-border text-muted-foreground hover:border-foreground/30 hover:text-foreground"
              ]}
            >
              <.icon name="hero-arrow-path-solid" class="h-4 w-4" />
            </button>

            <button
              type="button"
              phx-click="player_toggle_shuffle"
              aria-label="Shuffle"
              class={[
                "inline-flex h-9 w-9 items-center justify-center rounded-full border transition focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-foreground/20",
                @shuffle_enabled && "border-foreground/50 text-foreground",
                !@shuffle_enabled && "border-border text-muted-foreground hover:border-foreground/30 hover:text-foreground"
              ]}
            >
              <.icon name="hero-arrows-right-left-solid" class="h-4 w-4" />
            </button>
          </div>

          <div class="flex items-center gap-3">
            <button
              type="button"
              data-player-mute
              aria-label="Mute"
              class="inline-flex h-9 w-9 items-center justify-center rounded-full border border-border text-muted-foreground transition hover:border-foreground/30 hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-foreground/20"
              disabled={is_nil(@current_track)}
            >
              <span data-player-icon-volume><.icon name="hero-speaker-wave-solid" class="h-4 w-4" /></span>
              <span data-player-icon-muted class="hidden"><.icon name="hero-speaker-x-mark-solid" class="h-4 w-4" /></span>
            </button>

            <input
              data-player-volume
              type="range"
              min="0"
              max="100"
              value="80"
              aria-label="Volume"
              class="h-2 w-full cursor-pointer accent-foreground"
              disabled={is_nil(@current_track)}
            />
          </div>

          <div class="space-y-2">
            <p class="text-xs font-semibold uppercase tracking-wide text-muted-foreground/60">Playlist</p>
            <div class="max-h-40 space-y-1 overflow-auto pr-1">
              <button
                :for={track <- @tracks}
                type="button"
                phx-click="player_select_track"
                phx-value-track_id={track.id}
                data-track
                data-track-id={track.id}
                data-track-src={track_src(track)}
                class={[
                  "flex w-full items-center justify-between rounded-lg px-2.5 py-2 text-left text-sm transition focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-foreground/20",
                  track.id == @current_track_id && "bg-muted text-foreground",
                  track.id != @current_track_id && "text-muted-foreground hover:bg-muted/50 hover:text-foreground"
                ]}
                aria-current={track.id == @current_track_id && "true"}
              >
                <span class="truncate"><%= track.title %></span>
                <span class="text-[11px] text-muted-foreground/60">
                  <%= duration_label(track.duration_sec) %>
                </span>
              </button>

              <p :if={@tracks == []} class="text-sm text-muted-foreground">
                Upload a track to get started.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp track_src(nil), do: nil

  defp track_src(track) do
    path = to_string(track.file_path || "")

    cond do
      path == "" -> nil
      String.starts_with?(path, "/") -> path
      true -> "/" <> path
    end
  end

  defp duration_label(nil), do: "--:--"

  defp duration_label(seconds) when is_integer(seconds) and seconds >= 0 do
    minutes = div(seconds, 60)
    secs = rem(seconds, 60)
    "#{minutes}:#{String.pad_leading(Integer.to_string(secs), 2, "0")}"
  end

  defp duration_label(_), do: "--:--"
end
