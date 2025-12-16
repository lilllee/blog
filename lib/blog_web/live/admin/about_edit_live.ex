defmodule BlogWeb.Admin.AboutEditLive do
  @moduledoc """
  Admin interface for editing resume/about page content.

  Features a tabbed interface for organizing different resume sections.
  Header section uses individual inputs, while structured sections use JSON textareas.
  """

  use BlogWeb, :live_view

  alias Blog.ResumeData

  @impl true
  def mount(_params, _session, socket) do
    case ResumeData.get_resume_for_edit() do
      {:ok, resume_data} ->
        {:ok,
         assign(socket,
           resume_data: resume_data,
           active_section: "header",
           page_title: "Edit About"
         )}

      {:error, _} ->
        {:ok,
         assign(socket,
           resume_data: %{},
           active_section: "header",
           page_title: "Edit About"
         )}
    end
  end

  @impl true
  def handle_event("change_section", %{"section" => section}, socket) do
    {:noreply, assign(socket, :active_section, section)}
  end

  def handle_event("validate", _params, socket) do
    # Just acknowledge validation, no complex changeset needed for JSON forms
    {:noreply, socket}
  end

  def handle_event("save", %{"resume" => resume_params}, socket) do
    # Parse JSON strings from textarea inputs and merge with existing data
    attrs = parse_resume_params(resume_params, socket.assigns.resume_data)

    case ResumeData.update_resume(attrs) do
      {:ok, _resume} ->
        # Reload the resume data
        case ResumeData.get_resume_for_edit() do
          {:ok, resume_data} ->
            {:noreply,
             socket
             |> assign(:resume_data, resume_data)
             |> put_flash(:info, "Resume updated successfully")}

          {:error, _} ->
            {:noreply,
             socket
             |> put_flash(:info, "Resume updated successfully")}
        end

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to update resume. Check your JSON syntax.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="px-6 py-6 space-y-6">
      <div class="flex items-center justify-between">
        <div>
          <p class="text-xs uppercase tracking-wide text-gray-500">Admin</p>
          
          <h1 class="text-2xl font-bold text-gray-900 dark:text-gray-100">Edit About Page</h1>
        </div>
        
        <div class="flex gap-3">
          <.link
            navigate={~p"/about"}
            class="text-sm font-semibold text-gray-600 hover:text-gray-900 dark:text-gray-300"
          >
            View public page
          </.link>
          
          <.link
            navigate={~p"/admin/posts"}
            class="text-sm font-semibold text-gray-600 hover:text-gray-900 dark:text-gray-300"
          >
            Back to posts
          </.link>
        </div>
      </div>
      <!-- Section Tabs -->
      <div class="border-b border-gray-200 dark:border-gray-800">
        <nav class="-mb-px flex space-x-8">
          <.section_tab section="header" active={@active_section} label="Header" />
          <.section_tab section="summary" active={@active_section} label="Summary" />
          <.section_tab section="skills" active={@active_section} label="Skills" />
          <.section_tab section="experience" active={@active_section} label="Experience" />
          <.section_tab section="projects" active={@active_section} label="Projects" />
          <.section_tab section="education" active={@active_section} label="Education" />
          <.section_tab section="additional" active={@active_section} label="Additional" />
        </nav>
      </div>
      <!-- Form -->
      <.form for={%{}} phx-change="validate" phx-submit="save" class="space-y-6">
        <div class="bg-white dark:bg-gray-900 rounded-lg p-6 border border-gray-200 dark:border-gray-800">
          <%= case @active_section do %>
            <% "header" -> %>
              <.header_section resume_data={@resume_data} />
            <% "summary" -> %>
              <.summary_section resume_data={@resume_data} />
            <% "skills" -> %>
              <.skills_section resume_data={@resume_data} />
            <% "experience" -> %>
              <.experience_section resume_data={@resume_data} />
            <% "projects" -> %>
              <.projects_section resume_data={@resume_data} />
            <% "education" -> %>
              <.education_section resume_data={@resume_data} />
            <% "additional" -> %>
              <.additional_section resume_data={@resume_data} />
          <% end %>
        </div>
        
        <div class="flex justify-end">
          <.button type="submit">Save changes</.button>
        </div>
      </.form>
    </div>
    """
  end

  defp section_tab(assigns) do
    ~H"""
    <button
      type="button"
      phx-click="change_section"
      phx-value-section={@section}
      class={[
        "border-b-2 py-2 px-1 text-sm font-medium",
        @section == @active &&
          "border-indigo-600 text-indigo-600 dark:border-indigo-400 dark:text-indigo-400",
        @section != @active &&
          "border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300"
      ]}
    >
      <%= @label %>
    </button>
    """
  end

  defp header_section(assigns) do
    header = assigns.resume_data[:header] || %{}

    ~H"""
    <div class="space-y-4">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100">Contact Information</h3>
       <.input type="text" name="resume[header][name]" label="Name" value={header["name"]} />
      <.input
        type="text"
        name="resume[header][title]"
        label="Professional Title"
        value={header["title"]}
      />
      <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
        <.input type="email" name="resume[header][email]" label="Email" value={header["email"]} />
        <.input type="text" name="resume[header][phone]" label="Phone" value={header["phone"]} />
      </div>
      
      <.input type="text" name="resume[header][location]" label="Location" value={header["location"]} />
      <div class="grid grid-cols-1 gap-4 md:grid-cols-3">
        <.input
          type="url"
          name="resume[header][linkedin]"
          label="LinkedIn URL"
          value={header["linkedin"]}
        />
        <.input type="url" name="resume[header][github]" label="GitHub URL" value={header["github"]} />
        <.input
          type="url"
          name="resume[header][website]"
          label="Website URL"
          value={header["website"]}
        />
      </div>
    </div>
    """
  end

  defp summary_section(assigns) do
    additional = assigns.resume_data[:additional] || %{}

    ~H"""
    <div class="space-y-4">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100">Professional Summary</h3>
      
      <p class="text-sm text-gray-600 dark:text-gray-400">
        Write a brief professional summary using Markdown formatting.
      </p>
      
      <.input
        type="textarea"
        name="resume[additional][summary_md]"
        label="Summary (Markdown)"
        value={additional["summary_md"]}
        class="min-h-[200px] font-mono"
      />
    </div>
    """
  end

  defp skills_section(assigns) do
    skills = assigns.resume_data[:skills] || []

    ~H"""
    <div class="space-y-4">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100">Skills</h3>
      
      <p class="text-sm text-gray-600 dark:text-gray-400">
        Edit as JSON array. Format:
        <code class="bg-gray-100 dark:bg-gray-800 px-1 rounded">
          [{"category": "Languages", "items": ["Elixir", "Python"]}]
        </code>
      </p>
      
      <.input
        type="textarea"
        name="resume[skills]"
        label="Skills (JSON)"
        value={Jason.encode!(skills, pretty: true)}
        class="min-h-[300px] font-mono text-sm"
      />
    </div>
    """
  end

  defp experience_section(assigns) do
    experience = assigns.resume_data[:experience] || []

    ~H"""
    <div class="space-y-4">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100">Work Experience</h3>
      
      <p class="text-sm text-gray-600 dark:text-gray-400">
        Edit as JSON array. Format:
        <code class="bg-gray-100 dark:bg-gray-800 px-1 rounded text-xs">
          [{"company": "...", "position": "...", "start_date": "...", "end_date": "...", "description_md": "...", "location": "..."}]
        </code>
      </p>
      
      <.input
        type="textarea"
        name="resume[experience]"
        label="Experience (JSON)"
        value={Jason.encode!(experience, pretty: true)}
        class="min-h-[400px] font-mono text-sm"
      />
    </div>
    """
  end

  defp projects_section(assigns) do
    projects = assigns.resume_data[:projects] || []

    ~H"""
    <div class="space-y-4">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100">Projects</h3>
      
      <p class="text-sm text-gray-600 dark:text-gray-400">
        Edit as JSON array. Format:
        <code class="bg-gray-100 dark:bg-gray-800 px-1 rounded text-xs">
          [{"name": "...", "url": "...", "description_md": "...", "tech_stack": ["...", "..."]}]
        </code>
      </p>
      
      <.input
        type="textarea"
        name="resume[projects]"
        label="Projects (JSON)"
        value={Jason.encode!(projects, pretty: true)}
        class="min-h-[400px] font-mono text-sm"
      />
    </div>
    """
  end

  defp education_section(assigns) do
    education = assigns.resume_data[:education] || []

    ~H"""
    <div class="space-y-4">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100">Education</h3>
      
      <p class="text-sm text-gray-600 dark:text-gray-400">
        Edit as JSON array. Format:
        <code class="bg-gray-100 dark:bg-gray-800 px-1 rounded text-xs">
          [{"school": "...", "degree": "...", "field": "...", "start_date": "...", "end_date": "...", "description_md": "..."}]
        </code>
      </p>
      
      <.input
        type="textarea"
        name="resume[education]"
        label="Education (JSON)"
        value={Jason.encode!(education, pretty: true)}
        class="min-h-[300px] font-mono text-sm"
      />
    </div>
    """
  end

  defp additional_section(assigns) do
    additional = assigns.resume_data[:additional] || %{}
    certs = additional["certifications"] || []
    langs = additional["languages"] || []
    interests = additional["interests"] || []

    ~H"""
    <div class="space-y-6">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100">Additional Information</h3>
      
      <div>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-2">
          Certifications (JSON array of strings)
        </p>
        
        <.input
          type="textarea"
          name="resume[additional][certifications]"
          label="Certifications"
          value={Jason.encode!(certs, pretty: true)}
          class="min-h-[100px] font-mono text-sm"
        />
      </div>
      
      <div>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-2">
          Languages (JSON array of strings)
        </p>
        
        <.input
          type="textarea"
          name="resume[additional][languages]"
          label="Languages"
          value={Jason.encode!(langs, pretty: true)}
          class="min-h-[100px] font-mono text-sm"
        />
      </div>
      
      <div>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-2">
          Interests (JSON array of strings)
        </p>
        
        <.input
          type="textarea"
          name="resume[additional][interests]"
          label="Interests"
          value={Jason.encode!(interests, pretty: true)}
          class="min-h-[100px] font-mono text-sm"
        />
      </div>
    </div>
    """
  end

  defp parse_resume_params(params, existing_data) do
    # Only update fields that are present in params
    # This prevents clearing other sections when saving one section
    %{
      header:
        if(Map.has_key?(params, "header"),
          do: params["header"],
          else: existing_data[:header] || %{}
        ),
      skills:
        if(Map.has_key?(params, "skills"),
          do: parse_json_field(params["skills"], []),
          else: existing_data[:skills] || []
        ),
      experience:
        if(Map.has_key?(params, "experience"),
          do: parse_json_field(params["experience"], []),
          else: existing_data[:experience] || []
        ),
      projects:
        if(Map.has_key?(params, "projects"),
          do: parse_json_field(params["projects"], []),
          else: existing_data[:projects] || []
        ),
      education:
        if(Map.has_key?(params, "education"),
          do: parse_json_field(params["education"], []),
          else: existing_data[:education] || []
        ),
      additional:
        if(Map.has_key?(params, "additional"),
          do: parse_additional(params["additional"]),
          else: existing_data[:additional] || %{}
        )
    }
  end

  defp parse_json_field(value, default) when is_binary(value) do
    case Jason.decode(value) do
      {:ok, data} -> data
      {:error, _} -> default
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
