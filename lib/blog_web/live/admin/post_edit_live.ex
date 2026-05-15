defmodule BlogWeb.Admin.PostEditLive do
  use BlogWeb, :live_view

  alias Blog.Note
  alias Blog.NoteData
  alias BlogWeb.Uploads

  @impl true
  def mount(params, _session, socket) do
    note =
      case socket.assigns.live_action do
        :new -> %Note{status: "draft"}
        :edit -> NoteData.get_admin_note!(params["id"])
      end

    changeset = NoteData.change_note(note)

    {:ok,
     socket
     |> assign(
       note: note,
       changeset: changeset,
       page_title: page_title(socket.assigns.live_action)
     )
     |> allow_upload(:image,
       accept: ~w(.jpg .jpeg .png .gif .webp),
       max_entries: 1,
       max_file_size: 5_000_000
     )}
  end

  @impl true
  def handle_event("validate", %{"note" => note_params}, socket) do
    changeset =
      socket.assigns.note
      |> NoteData.change_note(note_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"note" => note_params} = params, socket) do
    status = params["status"] || note_params["status"] || "draft"
    attrs = Map.put(note_params, "status", status)

    {attrs, socket} = maybe_put_uploaded_image(attrs, socket)
    save_note(socket.assigns.live_action, socket.assigns.note, attrs, socket)
  end

  def handle_event("delete", _, socket) do
    case socket.assigns.note do
      %Note{id: id} when not is_nil(id) ->
        {:ok, _} = NoteData.soft_delete_note(socket.assigns.note)

        {:noreply,
         socket
         |> put_flash(:info, "post deleted")
         |> push_navigate(to: ~p"/admin/posts")}

      _ ->
        {:noreply, socket}
    end
  end

  defp save_note(:new, _note, attrs, socket) do
    case NoteData.create_note(attrs) do
      {:ok, _note} ->
        {:noreply,
         socket
         |> put_flash(:info, "post created")
         |> push_navigate(to: ~p"/admin/posts")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_note(:edit, note, attrs, socket) do
    case NoteData.update_note(note, attrs) do
      {:ok, _note} ->
        {:noreply,
         socket
         |> put_flash(:info, "post updated")
         |> push_navigate(to: ~p"/admin/posts")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.link navigate={~p"/admin/posts"} class="back">← posts</.link>

    <div class="admin-head">
      <h1><%= if @live_action == :new, do: "new post", else: "edit post" %></h1>
      <span :if={@live_action == :edit} class="crumb">
        <%= @note.status %><%= if date = @note.published_at || @note.inserted_at,
          do: " · " <> format_date(date) %>
      </span>
    </div>

    <.form
      :let={f}
      for={@changeset}
      as={:note}
      phx-change="validate"
      phx-submit="save"
      class="form"
      multipart
    >
      <div class="field title-field">
        <label for={f[:title].id}>title</label>
        <input
          type="text"
          name={f[:title].name}
          id={f[:title].id}
          value={Phoenix.HTML.Form.normalize_value("text", f[:title].value)}
          placeholder="제목"
        />
        <p :for={msg <- errors(f[:title])} class="error"><%= msg %></p>
      </div>

      <div class="field">
        <label for={f[:tags].id}>tags</label>
        <input
          type="text"
          name={f[:tags].name}
          id={f[:tags].id}
          value={Phoenix.HTML.Form.normalize_value("text", f[:tags].value)}
          placeholder="쉼표로 구분 — writing, web, elixir"
        />
      </div>

      <div class="field-row">
        <div class="field">
          <label for={f[:series_id].id}>series</label>
          <input
            type="text"
            name={f[:series_id].name}
            id={f[:series_id].id}
            value={Phoenix.HTML.Form.normalize_value("text", f[:series_id].value)}
            placeholder="series id (optional)"
          />
        </div>
        <div class="field">
          <label for={f[:series_order].id}>series order</label>
          <input
            type="number"
            name={f[:series_order].name}
            id={f[:series_order].id}
            value={Phoenix.HTML.Form.normalize_value("number", f[:series_order].value)}
            placeholder="2"
          />
        </div>
      </div>

      <div class="field">
        <label>cover image</label>
        <.live_file_input upload={@uploads.image} />
        <p class="hint">priv/static/images/uploads 에 저장됩니다.</p>
        <%= for entry <- @uploads.image.entries do %>
          <p class="hint"><%= entry.client_name %> — <%= entry.progress %>%</p>
          <p :for={err <- upload_errors(@uploads.image, entry)} class="error">
            <%= upload_error_to_string(err) %>
          </p>
        <% end %>
        <p :for={err <- upload_errors(@uploads.image)} class="error">
          <%= upload_error_to_string(err) %>
        </p>
      </div>

      <div class="field">
        <label for={f[:image_path].id}>cover image path (manual)</label>
        <input
          type="text"
          name={f[:image_path].name}
          id={f[:image_path].id}
          value={Phoenix.HTML.Form.normalize_value("text", f[:image_path].value)}
          placeholder="uploads/filename.png"
        />
      </div>

      <div class="field">
        <label for={f[:content].id}>markdown</label>
        <textarea
          name={f[:content].name}
          id={f[:content].id}
          spellcheck="false"
          placeholder="# 제목&#10;&#10;본문…"
        ><%= Phoenix.HTML.Form.normalize_value("textarea", f[:content].value) %></textarea>
        <p :for={msg <- errors(f[:content])} class="error"><%= msg %></p>
      </div>

      <div class="form-actions">
        <button type="submit" name="status" value="draft">save draft</button>
        <button type="submit" name="status" value="published" class="primary">publish</button>
        <span class="spacer"></span>
        <button
          :if={@live_action == :edit}
          type="button"
          phx-click="delete"
          data-confirm="삭제할까요?"
        >
          delete
        </button>
      </div>
    </.form>
    """
  end

  defp page_title(:new), do: "new post · admin"
  defp page_title(:edit), do: "edit post · admin"

  defp errors(field) do
    if Phoenix.Component.used_input?(field) do
      Enum.map(field.errors, fn {msg, opts} ->
        Enum.reduce(opts, msg, fn {k, v}, acc ->
          String.replace(acc, "%{#{k}}", to_string(v))
        end)
      end)
    else
      []
    end
  end

  defp format_date(%DateTime{} = d), do: Calendar.strftime(d, "%Y.%m.%d")

  defp format_date(%NaiveDateTime{} = d) do
    d |> DateTime.from_naive!("Etc/UTC") |> format_date()
  end

  defp format_date(_), do: ""

  defp maybe_put_uploaded_image(attrs, socket) do
    paths =
      consume_uploaded_entries(socket, :image, fn meta, entry ->
        {:ok, Uploads.store_note_image!(meta, entry)}
      end)

    case paths do
      [rel_path] -> {Map.put(attrs, "image_path", rel_path), socket}
      _ -> {attrs, socket}
    end
  end

  defp upload_error_to_string(:too_large), do: "file too large"
  defp upload_error_to_string(:too_many_files), do: "too many files"
  defp upload_error_to_string(:not_accepted), do: "unaccepted file type"
  defp upload_error_to_string(other), do: "upload error: #{inspect(other)}"
end
