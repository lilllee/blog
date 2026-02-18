defmodule BlogWeb.MusicManageLive do
  use BlogWeb, :live_view

  alias Blog.Music
  alias Blog.Music.MusicTrack
  alias BlogWeb.Uploads

  @max_file_size 20_000_000

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       changeset: Music.change_track(%MusicTrack{}),
       tracks: Music.list_tracks(),
       audio_duration: nil
     )
     |> allow_upload(:audio,
       accept: ~w(.mp3 .wav .m4a .ogg),
       max_entries: 1,
       max_file_size: @max_file_size
     )}
  end

  @impl true
  def handle_info({:locale_changed, _locale}, socket), do: {:noreply, socket}

  @impl true
  def handle_event("validate", %{"track" => params}, socket) do
    changeset =
      %MusicTrack{}
      |> Music.change_track(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("audio_duration", %{"duration_sec" => duration}, socket) do
    {:noreply, assign(socket, :audio_duration, duration)}
  end

  def handle_event("save", %{"track" => params}, socket) do
    {attrs, socket} = maybe_put_uploaded_audio(params, socket)

    # Add duration if available from client-side extraction
    attrs =
      if socket.assigns.audio_duration do
        Map.put(attrs, "duration_sec", socket.assigns.audio_duration)
      else
        attrs
      end

    case Music.create_track(attrs) do
      {:ok, _track} ->
        send_update(BlogWeb.MusicPlayerComponent, id: "music-player")

        {:noreply,
         socket
         |> put_flash(:info, "Track uploaded")
         |> assign(
           changeset: Music.change_track(%MusicTrack{}),
           tracks: Music.list_tracks(),
           audio_duration: nil
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto w-full max-w-3xl space-y-6 px-6 py-10 text-slate-100">
      <div class="space-y-1">
        <p class="text-xs uppercase tracking-wide text-slate-400">Music</p>
        <h1 class="text-2xl font-semibold text-white">Manage tracks</h1>
        <p class="text-sm text-slate-400">
          Upload lo-fi tracks (mp3, wav, m4a, ogg). Files are stored under <code>/uploads/audio</code>.
        </p>
      </div>

      <.simple_form
        :let={f}
        for={@changeset}
        id="music-upload-form"
        as={:track}
        phx-change="validate"
        phx-submit="save"
        phx-hook="AudioUploadMeta"
        multipart
        class="space-y-4 rounded-2xl border border-white/10 bg-[var(--panel-bg)]/80 p-6 shadow-sm"
      >
        <.input field={f[:title]} label="Title" placeholder="Cafe Sunset" />
        <div class="space-y-2">
          <label class="block text-sm font-semibold leading-6 text-slate-200">
            Audio file
          </label>
          <.live_file_input upload={@uploads.audio} class="block w-full text-sm text-slate-200" />
          <p class="text-xs text-slate-400">
            Max size: <%= @uploads.audio.max_file_size / 1_000_000 %>MB. Allowed: mp3, wav, m4a, ogg.
          </p>

          <%= for entry <- @uploads.audio.entries do %>
            <div class="space-y-1 rounded-lg border border-white/10 bg-black/40 px-3 py-2 text-xs text-slate-200">
              <p><%= entry.client_name %></p>
              <progress class="w-full" value={entry.progress} max="100">
                <%= entry.progress %>%
              </progress>
              <%= for err <- upload_errors(@uploads.audio, entry) do %>
                <p class="text-rose-400"><%= upload_error_to_string(err) %></p>
              <% end %>
            </div>
          <% end %>

          <%= for err <- upload_errors(@uploads.audio) do %>
            <p class="text-xs text-rose-400"><%= upload_error_to_string(err) %></p>
          <% end %>
        </div>

        <:actions>
          <.button type="submit">Upload</.button>
        </:actions>
      </.simple_form>

      <div class="space-y-3">
        <h2 class="text-sm font-semibold text-slate-200">Playlist</h2>
        <div class="space-y-2">
          <div
            :for={track <- @tracks}
            class="flex items-center justify-between rounded-xl border border-white/10 bg-black/30 px-4 py-3 text-sm text-slate-200"
          >
            <span class="truncate font-medium"><%= track.title %></span>
            <span class="text-xs text-slate-400"><%= track.file_path %></span>
          </div>

          <p :if={@tracks == []} class="text-sm text-slate-400">
            No tracks uploaded yet.
          </p>
        </div>
      </div>
    </div>
    """
  end

  defp maybe_put_uploaded_audio(attrs, socket) do
    paths =
      consume_uploaded_entries(socket, :audio, fn meta, entry ->
        title = derive_title(attrs, entry.client_name)

        {:ok,
         %{
           "title" => title,
           "file_path" => Uploads.store_audio_file!(meta, entry),
           "mime_type" => entry.client_type || "audio/mpeg",
           "file_size" => entry.client_size
         }}
      end)

    case paths do
      [file_attrs] -> {Map.merge(attrs, file_attrs), socket}
      _ -> {attrs, socket}
    end
  end

  defp derive_title(%{"title" => title}, client_name) do
    title = title |> to_string() |> String.trim()
    if title == "", do: derive_title(%{}, client_name), else: title
  end

  defp derive_title(_, client_name) do
    client_name
    |> to_string()
    |> Path.rootname()
    |> String.replace("_", " ")
    |> String.replace("-", " ")
    |> String.trim()
    |> case do
      "" -> "Untitled track"
      title -> title
    end
  end

  defp upload_error_to_string(:too_large), do: "File too large"
  defp upload_error_to_string(:too_many_files), do: "Too many files"
  defp upload_error_to_string(:not_accepted), do: "Unaccepted file type"
  defp upload_error_to_string(other), do: "Upload error: #{inspect(other)}"
end
