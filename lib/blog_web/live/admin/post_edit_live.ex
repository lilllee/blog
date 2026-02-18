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

  defp save_note(:new, _note, attrs, socket) do
    case NoteData.create_note(attrs) do
      {:ok, _note} ->
        {:noreply,
         socket
         |> put_flash(:info, "Post created")
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
         |> put_flash(:info, "Post updated")
         |> push_navigate(to: ~p"/admin/posts")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="px-6 py-6 space-y-6">
      <div class="flex items-center justify-between">
        <div>
          <p class="text-xs uppercase tracking-wide text-muted-foreground">Admin</p>

          <h1 class="text-2xl font-bold text-foreground"><%= @page_title %></h1>
        </div>
        
        <.link
          navigate={~p"/admin/posts"}
          class="text-sm font-semibold text-muted-foreground hover:text-foreground"
        >
          ← Back to posts
        </.link>
      </div>
      
      <.simple_form
        :let={f}
        for={@changeset}
        id="post-form"
        as={:note}
        phx-change="validate"
        phx-submit="save"
        multipart
      >
        <.input field={f[:title]} label="Title" />
        <div class="space-y-2">
          <label class="block text-sm font-semibold leading-6 text-foreground">
            Cover image upload
          </label>
          <.live_file_input upload={@uploads.image} class="block w-full text-sm" />
          <p class="text-xs text-muted-foreground">
            Saves to <code>priv/static/images/uploads</code> and stores <code>uploads/&lt;filename&gt;</code> in
            <code>image_path</code>.
          </p>
          <%= for entry <- @uploads.image.entries do %>
            <div class="flex items-center gap-3">
              <div class="h-14 w-20 overflow-hidden rounded-md border border-border bg-muted">
                <.live_img_preview entry={entry} class="h-full w-full object-cover" />
              </div>
              <div class="flex-1">
                <p class="text-xs text-muted-foreground"><%= entry.client_name %></p>
                <progress class="w-full" value={entry.progress} max="100"><%= entry.progress %>%</progress>
                <%= for err <- upload_errors(@uploads.image, entry) do %>
                  <p class="text-xs text-rose-600"><%= upload_error_to_string(err) %></p>
                <% end %>
              </div>
            </div>
          <% end %>
          <%= for err <- upload_errors(@uploads.image) do %>
            <p class="text-xs text-rose-600"><%= upload_error_to_string(err) %></p>
          <% end %>
        </div>

        <.input field={f[:image_path]} label="Cover image path (manual)" />
        <.input field={f[:tags]} label="Tags (comma-separated)" />
        <.input field={f[:categories]} label="Categories" />
        <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
          <.input field={f[:series_id]} label="Series ID" />
          <.input field={f[:series_order]} type="number" label="Series order" />
        </div>
        
        <.input
          field={f[:status]}
          type="select"
          label="Status"
          prompt="Select status"
          options={[{"Draft", "draft"}, {"Published", "published"}]}
        /> <.input field={f[:content]} type="textarea" label="Markdown" class="min-h-[240px]" />
        <:actions>
          <div class="flex gap-3">
            <.button type="submit" name="status" value="draft">Save draft</.button>
            
            <.button
              type="submit"
              name="status"
              value="published"
              class="bg-emerald-600 hover:bg-emerald-500"
            >
              Publish
            </.button>
          </div>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  defp page_title(:new), do: "New post"
  defp page_title(:edit), do: "Edit post"

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

  defp upload_error_to_string(:too_large), do: "File too large"
  defp upload_error_to_string(:too_many_files), do: "Too many files"
  defp upload_error_to_string(:not_accepted), do: "Unaccepted file type"
  defp upload_error_to_string(other), do: "Upload error: #{inspect(other)}"
end
