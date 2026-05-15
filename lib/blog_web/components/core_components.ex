defmodule BlogWeb.CoreComponents do
  @moduledoc """
  Minimal core UI components — flash messages plus changeset error helpers.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  import BlogWeb.Gettext

  attr :id, :string, doc: "the optional id of the flash container"
  attr :flash, :map, default: %{}
  attr :kind, :atom, values: [:info, :error]
  attr :rest, :global

  slot :inner_block

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <p
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> JS.hide(to: "##{@id}")}
      role="alert"
      class={["flash", @kind == :error && "error"]}
      {@rest}
    ><%= msg %></p>
    """
  end

  attr :flash, :map, required: true
  attr :id, :string, default: "flash-group"

  def flash_group(assigns) do
    ~H"""
    <div id={@id}>
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />
    </div>
    """
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    if count = opts[:count] do
      Gettext.dngettext(BlogWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(BlogWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
