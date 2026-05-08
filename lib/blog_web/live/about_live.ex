defmodule BlogWeb.AboutLive do
  @moduledoc """
  Public-facing resume/about page.

  Displays professional resume information with clean, scannable layout.
  Supports markdown rendering in descriptions and responsive design.
  """

  use BlogWeb, :live_view

  alias Blog.ResumeData
  alias BlogWeb.Markdown
  alias BlogWeb.SEO
  alias Blog.Translation

  @impl true
  def mount(_params, _session, socket) do
    seo =
      SEO.seo_assigns(:page, %{
        title: "About - JunHo Lee",
        description:
          "Software engineer specializing in Elixir, Phoenix, and full-stack development.",
        path: "/about",
        json_ld: SEO.person_schema()
      })

    locale = socket.assigns[:locale] || "ko"

    case ResumeData.get_resume() do
      {:ok, resume} ->
        header = decode_json(resume.header, %{})
        skills = decode_json(resume.skills, [])
        experience = decode_json(resume.experience, [])
        projects = decode_json(resume.projects, [])
        education = decode_json(resume.education, [])
        additional = decode_json(resume.additional, %{})

        socket =
          socket
          |> assign(seo)
          |> assign(
            resume: resume,
            header: header,
            skills: skills,
            experience: experience,
            projects: projects,
            education: education,
            additional: additional,
            original_header: header,
            original_skills: skills,
            original_experience: experience,
            original_projects: projects,
            original_education: education,
            original_additional: additional
          )

        if locale != "ko" and connected?(socket) do
          send(self(), {:translate_resume, locale})
        end

        {:ok, socket}

      {:error, _} ->
        {:ok,
         socket
         |> assign(seo)
         |> assign(
           resume: nil,
           header: %{},
           skills: [],
           experience: [],
           projects: [],
           education: [],
           additional: %{},
           original_header: %{},
           original_skills: [],
           original_experience: [],
           original_projects: [],
           original_education: [],
           original_additional: %{}
         )}
    end
  end

  @impl true
  def handle_info({:locale_changed, locale}, socket) do
    if locale == "ko" do
      {:noreply,
       assign(socket,
         header: socket.assigns.original_header,
         skills: socket.assigns.original_skills,
         experience: socket.assigns.original_experience,
         projects: socket.assigns.original_projects,
         education: socket.assigns.original_education,
         additional: socket.assigns.original_additional
       )}
    else
      send(self(), {:translate_resume, locale})
      {:noreply, socket}
    end
  end

  def handle_info({:translate_resume, locale}, socket) do
    pid = self()

    original = %{
      header: socket.assigns.original_header,
      skills: socket.assigns.original_skills,
      experience: socket.assigns.original_experience,
      projects: socket.assigns.original_projects,
      education: socket.assigns.original_education,
      additional: socket.assigns.original_additional
    }

    Task.start(fn ->
      translated = translate_resume_data(original, locale)
      send(pid, {:resume_translated, translated, locale})
    end)

    {:noreply, socket}
  end

  def handle_info({:resume_translated, translated, locale}, socket) do
    if socket.assigns[:locale] == locale do
      {:noreply,
       assign(socket,
         header: translated.header,
         skills: translated.skills,
         experience: translated.experience,
         projects: translated.projects,
         education: translated.education,
         additional: translated.additional
       )}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%!-- $ whoami --verbose --%>
      <div class="flex flex-wrap items-center gap-2.5 pt-8 pb-3 text-sm">
        <span class="text-tm-accent">junho</span>
        <span class="text-tm-blue">~</span>
        <span class="text-muted-foreground">$</span>
        <span class="text-foreground">whoami --verbose</span>
      </div>

      <div class="space-y-0">
        <%!-- Header block: name, title, bio, contact kv --%>
        <section class="py-5 border-b border-dashed border-border">
          <div class="text-[28px] font-bold tracking-tight text-foreground leading-tight">
            <%= @header["name"] || "—" %>
          </div>
          <%= if @header["title"] && @header["title"] != "" do %>
            <div class="mt-1 text-sm text-tm-accent">
              $ <%= title_slug(@header["title"]) %>
            </div>
          <% end %>

          <%= if @additional["summary_md"] && @additional["summary_md"] != "" do %>
            <div class="mt-4 max-w-[580px] prose-blog text-sm text-foreground/90">
              <%= Markdown.render(@additional["summary_md"]) %>
            </div>
          <% end %>

          <div class="grid grid-cols-[120px_1fr] gap-x-4 gap-y-2 mt-4 text-[13px]">
            <%= if @header["email"] && @header["email"] != "" do %>
              <span class="text-muted-foreground">email</span>
              <a
                class="tm-link text-tm-blue truncate"
                href={"mailto:#{@header["email"]}"}
              >
                <%= @header["email"] %>
              </a>
            <% end %>
            <%= if @header["github"] && @header["github"] != "" do %>
              <span class="text-muted-foreground">github</span>
              <a class="tm-link text-tm-blue truncate" href={@header["github"]} target="_blank" rel="noopener">
                <%= @header["github"] %>
              </a>
            <% end %>
            <%= if @header["linkedin"] && @header["linkedin"] != "" do %>
              <span class="text-muted-foreground">linkedin</span>
              <a class="tm-link text-tm-blue truncate" href={@header["linkedin"]} target="_blank" rel="noopener">
                <%= @header["linkedin"] %>
              </a>
            <% end %>
            <%= if @header["website"] && @header["website"] != "" do %>
              <span class="text-muted-foreground">website</span>
              <a class="tm-link text-tm-blue truncate" href={@header["website"]} target="_blank" rel="noopener">
                <%= @header["website"] %>
              </a>
            <% end %>
            <%= if @header["location"] && @header["location"] != "" do %>
              <span class="text-muted-foreground">location</span>
              <span class="text-tm-blue"><%= @header["location"] %></span>
            <% end %>
            <%= if @header["phone"] && @header["phone"] != "" do %>
              <span class="text-muted-foreground">phone</span>
              <span class="text-tm-blue"><%= @header["phone"] %></span>
            <% end %>
          </div>
        </section>

        <%!-- $ cat experience.log --%>
        <%= if @experience != [] do %>
          <section class="py-5 border-b border-dashed border-border">
            <div class="text-[11px] uppercase tracking-[0.12em] text-muted-foreground mb-3">
              $ cat experience.log
            </div>
            <div>
              <%= for exp <- @experience do %>
                <div class="py-3 border-b border-dashed border-border last:border-b-0">
                  <div class="flex justify-between flex-wrap gap-3">
                    <div>
                      <span class="text-sm font-medium text-foreground">
                        <%= exp["position"] %>
                      </span>
                      <span class="text-sm text-tm-blue">
                        @ <%= exp["company"] %>
                      </span>
                      <%= if exp["location"] && exp["location"] != "" do %>
                        <span class="text-xs text-muted-foreground">· <%= exp["location"] %></span>
                      <% end %>
                    </div>
                    <span class="text-xs text-muted-foreground">
                      <%= exp["start_date"] %> →
                      <%= if exp["end_date"] in [nil, "", "현재"],
                        do: "now",
                        else: exp["end_date"] %>
                    </span>
                  </div>
                  <%= if exp["description_md"] && exp["description_md"] != "" do %>
                    <div class="mt-2 prose-blog text-sm text-foreground/90">
                      <%= Markdown.render(exp["description_md"]) %>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          </section>
        <% end %>

        <%!-- $ stack --print --%>
        <%= if @skills != [] do %>
          <section class="py-5 border-b border-dashed border-border">
            <div class="text-[11px] uppercase tracking-[0.12em] text-muted-foreground mb-3">
              $ stack --print
            </div>
            <div>
              <%= for skill_group <- @skills do %>
                <div class="grid grid-cols-[120px_1fr] gap-4 py-1.5 text-[13px] items-baseline">
                  <span class="text-muted-foreground">
                    <%= String.downcase(skill_group["category"] || "") %>:
                  </span>
                  <div class="flex flex-wrap gap-1.5">
                    <%= for item <- skill_group["items"] || [] do %>
                      <span class="inline-block border border-border px-2 py-px text-[11px] text-muted-foreground">
                        <%= item %>
                      </span>
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>
          </section>
        <% end %>

        <%!-- $ ls ~/projects --%>
        <%= if @projects != [] do %>
          <section class="py-5 border-b border-dashed border-border">
            <div class="text-[11px] uppercase tracking-[0.12em] text-muted-foreground mb-3">
              $ ls ~/projects
            </div>
            <div>
              <%= for project <- @projects do %>
                <div class="py-3 border-b border-dashed border-border last:border-b-0">
                  <div class="flex items-baseline justify-between gap-2">
                    <div class="text-sm font-medium text-tm-accent">
                      ▸ <%= project["name"] %>/
                    </div>
                    <%= if project["url"] && project["url"] != "" do %>
                      <a
                        href={project["url"]}
                        target="_blank"
                        rel="noopener"
                        class="tm-link text-xs text-muted-foreground"
                      >
                        →
                      </a>
                    <% end %>
                  </div>
                  <%= if project["description_md"] && project["description_md"] != "" do %>
                    <div class="mt-1 prose-blog text-[13px] text-foreground/90">
                      <%= Markdown.render(project["description_md"]) %>
                    </div>
                  <% end %>
                  <%= if (project["tech_stack"] && project["tech_stack"] != []) || (project["url"] && project["url"] != "") do %>
                    <div class="mt-2 text-[11px] text-muted-foreground">
                      <%= if project["tech_stack"] && project["tech_stack"] != [] do %>
                        <%= Enum.join(project["tech_stack"], " · ") %>
                      <% end %>
                      <%= if project["url"] && project["url"] != "" do %>
                        <span class="text-muted-foreground/60">
                          <%= if project["tech_stack"] && project["tech_stack"] != [], do: "  →  ", else: "→ " %>
                        </span>
                        <%= project["url"] %>
                      <% end %>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          </section>
        <% end %>

        <%!-- $ cat education.log --%>
        <%= if @education != [] do %>
          <section class="py-5 border-b border-dashed border-border">
            <div class="text-[11px] uppercase tracking-[0.12em] text-muted-foreground mb-3">
              $ cat education.log
            </div>
            <div>
              <%= for edu <- @education do %>
                <div class="py-3 border-b border-dashed border-border last:border-b-0">
                  <div class="flex justify-between flex-wrap gap-3">
                    <div class="text-sm text-foreground">
                      <%= cond do %>
                        <% edu["degree"] && edu["degree"] != "" && edu["field"] && edu["field"] != "" -> %>
                          <%= edu["degree"] %> in <%= edu["field"] %>
                        <% edu["degree"] && edu["degree"] != "" -> %>
                          <%= edu["degree"] %>
                        <% edu["field"] && edu["field"] != "" -> %>
                          <%= edu["field"] %>
                        <% true -> %>
                          <%= edu["school"] %>
                      <% end %>
                      <span class="text-tm-blue">@ <%= edu["school"] %></span>
                    </div>
                    <span class="text-xs text-muted-foreground">
                      <%= edu["start_date"] %> →
                      <%= if edu["end_date"] in [nil, "", "현재"],
                        do: "now",
                        else: edu["end_date"] %>
                    </span>
                  </div>
                  <%= if edu["description_md"] && edu["description_md"] != "" do %>
                    <div class="mt-2 prose-blog text-[13px] text-foreground/90">
                      <%= Markdown.render(edu["description_md"]) %>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          </section>
        <% end %>

        <%!-- additional info --%>
        <%= if has_additional_info?(@additional) do %>
          <section class="py-5">
            <%= if @additional["certifications"] && @additional["certifications"] != [] do %>
              <div class="grid grid-cols-[120px_1fr] gap-4 py-1.5 text-[13px] items-baseline">
                <span class="text-muted-foreground">certifications:</span>
                <div class="flex flex-wrap gap-1.5">
                  <%= for cert <- @additional["certifications"] do %>
                    <span class="inline-block border border-border px-2 py-px text-[11px] text-muted-foreground">
                      <%= cert %>
                    </span>
                  <% end %>
                </div>
              </div>
            <% end %>
            <%= if @additional["languages"] && @additional["languages"] != [] do %>
              <div class="grid grid-cols-[120px_1fr] gap-4 py-1.5 text-[13px] items-baseline">
                <span class="text-muted-foreground">languages:</span>
                <div class="flex flex-wrap gap-1.5">
                  <%= for lang <- @additional["languages"] do %>
                    <span class="inline-block border border-border px-2 py-px text-[11px] text-muted-foreground">
                      <%= lang %>
                    </span>
                  <% end %>
                </div>
              </div>
            <% end %>
            <%= if @additional["interests"] && @additional["interests"] != [] do %>
              <div class="grid grid-cols-[120px_1fr] gap-4 py-1.5 text-[13px] items-baseline">
                <span class="text-muted-foreground">interests:</span>
                <span class="text-foreground/90">
                  <%= Enum.join(@additional["interests"], ", ") %>
                </span>
              </div>
            <% end %>
          </section>
        <% end %>
      </div>
    </div>
    """
  end

  defp title_slug(title) do
    title
    |> to_string()
    |> String.downcase()
    |> String.replace(~r/\s+/, "_")
  end

  defp translate_resume_data(data, locale) do
    %{
      header: translate_header(data.header, locale),
      skills: translate_skills(data[:skills] || [], locale),
      experience: translate_list(data.experience, ["position", "description_md"], locale),
      projects: translate_list(data.projects, ["name", "description_md"], locale),
      education: translate_list(data.education, ["degree", "field", "description_md"], locale),
      additional: translate_additional(data.additional, locale)
    }
  end

  defp translate_skills(skills, locale) do
    Enum.map(skills, fn group ->
      category = translate_field(group["category"], locale)
      items = translate_string_list(group["items"], locale)

      group
      |> then(fn g -> if category, do: Map.put(g, "category", category), else: g end)
      |> then(fn g -> if items, do: Map.put(g, "items", items), else: g end)
    end)
  end

  defp translate_header(header, locale) do
    title = translate_field(header["title"], locale)
    Map.put(header, "title", title || header["title"])
  end

  defp translate_list(items, fields, locale) do
    Enum.map(items, fn item ->
      Enum.reduce(fields, item, fn field, acc ->
        case translate_field(acc[field], locale) do
          nil -> acc
          translated -> Map.put(acc, field, translated)
        end
      end)
    end)
  end

  defp translate_additional(additional, locale) do
    summary = translate_field(additional["summary_md"], locale)
    certs = translate_string_list(additional["certifications"], locale)
    interests = translate_string_list(additional["interests"], locale)

    additional
    |> then(fn a -> if summary, do: Map.put(a, "summary_md", summary), else: a end)
    |> then(fn a -> if certs, do: Map.put(a, "certifications", certs), else: a end)
    |> then(fn a -> if interests, do: Map.put(a, "interests", interests), else: a end)
  end

  defp translate_field(nil, _locale), do: nil
  defp translate_field("", _locale), do: nil

  defp translate_field(text, locale) do
    case Translation.translate(text, locale) do
      {:ok, translated} when is_binary(translated) -> translated
      _ -> nil
    end
  end

  defp translate_string_list(nil, _locale), do: nil
  defp translate_string_list([], _locale), do: nil

  defp translate_string_list(items, locale) when is_list(items) do
    joined = Enum.join(items, "\n")

    case translate_field(joined, locale) do
      nil -> nil
      translated -> String.split(translated, "\n", trim: true)
    end
  end

  defp decode_json(json_string, default) when is_binary(json_string) do
    case Jason.decode(json_string) do
      {:ok, data} -> data
      {:error, _} -> default
    end
  end

  defp decode_json(_, default), do: default

  defp has_additional_info?(additional) do
    (additional["certifications"] && additional["certifications"] != []) ||
      (additional["languages"] && additional["languages"] != []) ||
      (additional["interests"] && additional["interests"] != [])
  end
end
