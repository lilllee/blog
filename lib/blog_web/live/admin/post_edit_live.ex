defmodule BlogWeb.Admin.PostEditLive do
  use BlogWeb, :live_view

  alias Blog.Note
  alias Blog.NoteData

  @impl true
  def mount(params, _session, socket) do
    note =
      case socket.assigns.live_action do
        :new -> %Note{status: "draft"}
        :edit -> NoteData.get_admin_note!(params["id"])
      end

    changeset = NoteData.change_note(note)

    {:ok,
     assign(socket,
       note: note,
       changeset: changeset,
       page_title: page_title(socket.assigns.live_action)
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

  def render(assigns) do
    ~H"""
    <div class="px-6 py-6 space-y-6">
      <div class="flex items-center justify-between">
        <div>
          <p class="text-xs uppercase tracking-wide text-gray-500">Admin</p>
          <h1 class="text-2xl font-bold text-gray-900 dark:text-gray-100"><%= @page_title %></h1>
        </div>
        <.link
          navigate={~p"/admin/posts"}
          class="text-sm font-semibold text-gray-600 hover:text-gray-900 dark:text-gray-300"
        >
          ← Back to posts
        </.link>
      </div>

      <.simple_form for={@changeset} id="post-form" as={:note} phx-change="validate" phx-submit="save">
        <.input field={@changeset[:title]} label="Title" />
        <.input field={@changeset[:image_path]} label="Image path" />
        <.input field={@changeset[:tags]} label="Tags (comma-separated)" />
        <.input field={@changeset[:categories]} label="Categories" />
        <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
          <.input field={@changeset[:series_id]} label="Series ID" />
          <.input field={@changeset[:series_order]} type="number" label="Series order" />
        </div>
        <.input
          field={@changeset[:status]}
          type="select"
          label="Status"
          prompt="Select status"
          options={[{"Draft", "draft"}, {"Published", "published"}]}
        />
        <.input field={@changeset[:content]} type="textarea" label="Markdown" class="min-h-[240px]" />
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
end
