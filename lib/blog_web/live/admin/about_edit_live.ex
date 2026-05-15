defmodule BlogWeb.Admin.AboutEditLive do
  @moduledoc """
  Admin interface for editing the about/resume content. Underline-style form
  with tab-link sections.
  """

  use BlogWeb, :live_view

  alias Blog.ResumeData

  @tabs ~w(header summary skills experience projects education additional)

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       resume_data: load_resume(),
       active_tab: "header",
       tabs: @tabs,
       page_title: "edit about · admin"
     )}
  end

  @impl true
  def handle_event("change_tab", %{"tab" => tab}, socket) when tab in @tabs do
    {:noreply, assign(socket, :active_tab, tab)}
  end

  def handle_event("save", %{"resume" => resume_params}, socket) do
    attrs = parse_resume_params(resume_params, socket.assigns.resume_data)

    case ResumeData.update_resume(attrs) do
      {:ok, _resume} ->
        {:noreply,
         socket
         |> assign(:resume_data, load_resume())
         |> put_flash(:info, "saved")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "JSON 형식 오류")}
    end
  end

  defp load_resume do
    case ResumeData.get_resume_for_edit() do
      {:ok, data} -> data
      _ -> %{}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.link navigate={~p"/admin/posts"} class="back">← admin</.link>

    <div class="admin-head">
      <h1>edit about</h1>
      <.link navigate={~p"/about"} class="new">view public →</.link>
    </div>

    <nav class="tabs">
      <button
        :for={tab <- @tabs}
        type="button"
        phx-click="change_tab"
        phx-value-tab={tab}
        class={if @active_tab == tab, do: "current"}
      ><%= tab %></button>
    </nav>

    <.form for={%{}} phx-submit="save" class="form">
      <%= case @active_tab do %>
        <% "header" -> %>
          <.header_panel header={header(@resume_data)} />
        <% "summary" -> %>
          <.summary_panel additional={additional(@resume_data)} />
        <% "skills" -> %>
          <.json_panel name="skills" label="skills (json)"
            hint={~s([{"category":"Languages","items":["Elixir","Python"]}])}
            value={Jason.encode!(@resume_data[:skills] || [], pretty: true)} />
        <% "experience" -> %>
          <.json_panel name="experience" label="experience (json)"
            hint={~s([{"company","position","start_date","end_date","description_md","location"}])}
            value={Jason.encode!(@resume_data[:experience] || [], pretty: true)} />
        <% "projects" -> %>
          <.json_panel name="projects" label="projects (json)"
            hint={~s([{"name","url","description_md","tech_stack":[…]}])}
            value={Jason.encode!(@resume_data[:projects] || [], pretty: true)} />
        <% "education" -> %>
          <.json_panel name="education" label="education (json)"
            hint={~s([{"school","degree","field","start_date","end_date","description_md"}])}
            value={Jason.encode!(@resume_data[:education] || [], pretty: true)} />
        <% "additional" -> %>
          <.additional_panel additional={additional(@resume_data)} />
      <% end %>

      <div class="form-actions">
        <button type="submit" class="primary">save changes</button>
        <span class="spacer"></span>
        <.link navigate={~p"/about"}>preview →</.link>
      </div>
    </.form>
    """
  end

  defp header(data), do: data[:header] || %{}
  defp additional(data), do: data[:additional] || %{}

  attr :header, :map, required: true

  defp header_panel(assigns) do
    ~H"""
    <div class="field">
      <label for="ah-name">name</label>
      <input type="text" id="ah-name" name="resume[header][name]" value={@header["name"]} />
    </div>
    <div class="field title-field">
      <label for="ah-title">professional title</label>
      <input type="text" id="ah-title" name="resume[header][title]" value={@header["title"]} />
    </div>
    <div class="field-row">
      <div class="field">
        <label for="ah-email">email</label>
        <input type="text" id="ah-email" name="resume[header][email]" value={@header["email"]} />
      </div>
      <div class="field">
        <label for="ah-phone">phone</label>
        <input type="text" id="ah-phone" name="resume[header][phone]" value={@header["phone"]} />
      </div>
    </div>
    <div class="field">
      <label for="ah-location">location</label>
      <input type="text" id="ah-location" name="resume[header][location]" value={@header["location"]} />
    </div>
    <div class="field-row">
      <div class="field">
        <label for="ah-github">github</label>
        <input type="text" id="ah-github" name="resume[header][github]" value={@header["github"]} />
      </div>
      <div class="field">
        <label for="ah-linkedin">linkedin</label>
        <input type="text" id="ah-linkedin" name="resume[header][linkedin]" value={@header["linkedin"]} />
      </div>
    </div>
    <div class="field">
      <label for="ah-website">website</label>
      <input type="text" id="ah-website" name="resume[header][website]" value={@header["website"]} />
    </div>
    """
  end

  attr :additional, :map, required: true

  defp summary_panel(assigns) do
    ~H"""
    <p class="hint top">간단한 자기소개를 markdown으로.</p>
    <div class="field">
      <label for="ah-summary">summary (markdown)</label>
      <textarea id="ah-summary" name="resume[additional][summary_md]" spellcheck="false"><%= @additional["summary_md"] %></textarea>
    </div>
    """
  end

  attr :additional, :map, required: true

  defp additional_panel(assigns) do
    ~H"""
    <div class="field">
      <label for="ah-certs">certifications (json array of strings)</label>
      <textarea
        id="ah-certs"
        name="resume[additional][certifications]"
        spellcheck="false"
        style="min-height:120px"
      ><%= Jason.encode!(@additional["certifications"] || [], pretty: true) %></textarea>
    </div>
    <div class="field">
      <label for="ah-langs">languages (json array of strings)</label>
      <textarea
        id="ah-langs"
        name="resume[additional][languages]"
        spellcheck="false"
        style="min-height:120px"
      ><%= Jason.encode!(@additional["languages"] || [], pretty: true) %></textarea>
    </div>
    <div class="field">
      <label for="ah-interests">interests (json array of strings)</label>
      <textarea
        id="ah-interests"
        name="resume[additional][interests]"
        spellcheck="false"
        style="min-height:120px"
      ><%= Jason.encode!(@additional["interests"] || [], pretty: true) %></textarea>
    </div>
    """
  end

  attr :name, :string, required: true
  attr :label, :string, required: true
  attr :hint, :string, required: true
  attr :value, :string, required: true

  defp json_panel(assigns) do
    ~H"""
    <p class="hint top">JSON 배열. <code><%= @hint %></code></p>
    <div class="field">
      <label for={"ah-" <> @name}><%= @label %></label>
      <textarea
        id={"ah-" <> @name}
        name={"resume[" <> @name <> "]"}
        spellcheck="false"
      ><%= @value %></textarea>
    </div>
    """
  end

  defp parse_resume_params(params, existing) do
    %{
      header:
        if(Map.has_key?(params, "header"),
          do: params["header"],
          else: existing[:header] || %{}
        ),
      skills:
        if(Map.has_key?(params, "skills"),
          do: parse_json_field(params["skills"], []),
          else: existing[:skills] || []
        ),
      experience:
        if(Map.has_key?(params, "experience"),
          do: parse_json_field(params["experience"], []),
          else: existing[:experience] || []
        ),
      projects:
        if(Map.has_key?(params, "projects"),
          do: parse_json_field(params["projects"], []),
          else: existing[:projects] || []
        ),
      education:
        if(Map.has_key?(params, "education"),
          do: parse_json_field(params["education"], []),
          else: existing[:education] || []
        ),
      additional:
        if(Map.has_key?(params, "additional"),
          do: parse_additional(params["additional"]),
          else: existing[:additional] || %{}
        )
    }
  end

  defp parse_json_field(value, default) when is_binary(value) do
    case Jason.decode(value) do
      {:ok, data} -> data
      _ -> default
    end
  end

  defp parse_json_field(_, default), do: default

  defp parse_additional(nil),
    do: %{summary_md: "", certifications: [], languages: [], interests: []}

  defp parse_additional(additional) do
    %{
      summary_md: additional["summary_md"] || "",
      certifications: parse_json_field(additional["certifications"], []),
      languages: parse_json_field(additional["languages"], []),
      interests: parse_json_field(additional["interests"], [])
    }
  end
end
