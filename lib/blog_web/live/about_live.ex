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
        title: "About",
        description: "Professional background, skills, and experience.",
        path: "/about"
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
      <%!-- Back link --%>
      <.link navigate={~p"/"} class="inline-flex items-center gap-1.5 text-sm text-muted-foreground transition-colors hover:text-foreground">
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="h-4 w-4">
          <path fill-rule="evenodd" d="M12.79 5.23a.75.75 0 01-.02 1.06L8.832 10l3.938 3.71a.75.75 0 11-1.04 1.08l-4.5-4.25a.75.75 0 010-1.08l4.5-4.25a.75.75 0 011.06.02z" clip-rule="evenodd" />
        </svg>
        <%= Blog.Translation.t("blog", @locale) %>
      </.link>

      <div class="mt-10 space-y-12">
        <%!-- Header Section --%>
        <header class="space-y-5 pb-10 border-b border-border">
          <%!-- Professional Title badge --%>
          <%= if @header["title"] && @header["title"] != "" do %>
            <div class="inline-flex items-center gap-2 rounded-full border border-border bg-secondary px-4 py-1.5 text-xs font-medium text-muted-foreground">
              <%= @header["title"] %>
            </div>
          <% end %>
          <%!-- Name: gradient text --%>
          <h1 class="text-5xl font-bold tracking-tight"
              style="background: linear-gradient(135deg, var(--foreground) 0%, #60a5fa 50%, #a78bfa 100%); -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text;">
            <%= @header["name"] || "Your Name" %>
          </h1>
          <%!-- Contact info: icon button style --%>
          <div class="flex flex-wrap items-center gap-2 pt-1">
            <%= if @header["email"] && @header["email"] != "" do %>
              <a href={"mailto:#{@header["email"]}"}
                 class="inline-flex items-center gap-2 rounded-lg border border-border px-3 py-1.5 text-sm text-muted-foreground transition-colors hover:border-blue-500/50 hover:text-blue-400">
                <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <rect width="20" height="16" x="2" y="4" rx="2"/><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/>
                </svg>
                <%= @header["email"] %>
              </a>
            <% end %>
            <%= if @header["phone"] && @header["phone"] != "" do %>
              <span class="inline-flex items-center gap-2 rounded-lg border border-border px-3 py-1.5 text-sm text-muted-foreground">
                <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-5.51-5.25 19.79 19.79 0 0 1-3.07-8.63A2 2 0 0 1 3.53 2h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L7.09 10.09a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 22 16.92z"/>
                </svg>
                <%= @header["phone"] %>
              </span>
            <% end %>
            <%= if @header["location"] && @header["location"] != "" do %>
              <span class="inline-flex items-center gap-2 rounded-lg border border-border px-3 py-1.5 text-sm text-muted-foreground">
                <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"/><circle cx="12" cy="10" r="3"/>
                </svg>
                <%= @header["location"] %>
              </span>
            <% end %>
            <%!-- Social links --%>
            <%= if @header["github"] && @header["github"] != "" do %>
              <a href={@header["github"]} target="_blank"
                 class="inline-flex items-center gap-2 rounded-lg border border-border px-3 py-1.5 text-sm text-muted-foreground transition-colors hover:border-blue-500/50 hover:text-blue-400">
                <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M12 0C5.37 0 0 5.37 0 12c0 5.31 3.435 9.795 8.205 11.385.6.105.825-.255.825-.57 0-.285-.015-1.23-.015-2.235-3.015.555-3.795-.735-4.035-1.41-.135-.345-.72-1.41-1.23-1.695-.42-.225-1.02-.78-.015-.795.945-.015 1.62.87 1.845 1.23 1.08 1.815 2.805 1.305 3.495.99.105-.78.42-1.305.765-1.605-2.67-.3-5.46-1.335-5.46-5.925 0-1.305.465-2.385 1.23-3.225-.12-.3-.54-1.53.12-3.18 0 0 1.005-.315 3.3 1.23.96-.27 1.98-.405 3-.405s2.04.135 3 .405c2.295-1.56 3.3-1.23 3.3-1.23.66 1.65.24 2.88.12 3.18.765.84 1.23 1.905 1.23 3.225 0 4.605-2.805 5.625-5.475 5.925.435.375.81 1.095.81 2.22 0 1.605-.015 2.895-.015 3.3 0 .315.225.69.825.57A12.02 12.02 0 0 0 24 12c0-6.63-5.37-12-12-12z"/>
                </svg>
                GitHub
              </a>
            <% end %>
            <%= if @header["linkedin"] && @header["linkedin"] != "" do %>
              <a href={@header["linkedin"]} target="_blank"
                 class="inline-flex items-center gap-2 rounded-lg border border-border px-3 py-1.5 text-sm text-muted-foreground transition-colors hover:border-blue-500/50 hover:text-blue-400">
                <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433a2.062 2.062 0 0 1-2.063-2.065 2.064 2.064 0 1 1 2.063 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"/>
                </svg>
                LinkedIn
              </a>
            <% end %>
            <%= if @header["website"] && @header["website"] != "" do %>
              <a href={@header["website"]} target="_blank"
                 class="inline-flex items-center gap-2 rounded-lg border border-border px-3 py-1.5 text-sm text-muted-foreground transition-colors hover:border-blue-500/50 hover:text-blue-400">
                <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <circle cx="12" cy="12" r="10"/><path d="M2 12h20"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/>
                </svg>
                Website
              </a>
            <% end %>
          </div>
        </header>

        <%!-- Summary 섹션: 자기소개 문구 준비되면 주석 해제
        <%= if @additional["summary_md"] && @additional["summary_md"] != "" do %>
          <section>
            <div class="flex items-center gap-3 mb-4">
              <div class="h-4 w-1 rounded-full bg-blue-500"></div>
              <h2 class="text-xs font-semibold uppercase tracking-[0.2em] text-muted-foreground">
                Summary
              </h2>
            </div>
            <div class="rounded-xl border border-border/50 bg-secondary/30 px-6 py-5 prose-blog text-sm text-foreground/85 leading-relaxed">
              <%= Markdown.render(@additional["summary_md"]) %>
            </div>
          </section>
        <% end %>
        --%>

        <%!-- Skills --%>
        <%= if @skills != [] do %>
          <section>
            <div class="flex items-center gap-3 mb-6">
              <div class="h-4 w-1 rounded-full bg-blue-500"></div>
              <h2 class="text-xs font-semibold uppercase tracking-[0.2em] text-muted-foreground"><%= Translation.t("skills", @locale) %></h2>
            </div>
            <div class="space-y-5">
              <%= for skill_group <- @skills do %>
                <div>
                  <h3 class="text-sm font-semibold mb-2 text-foreground">
                    <%= skill_group["category"] %>
                  </h3>
                  <div class="flex flex-wrap gap-2">
                    <%= for item <- skill_group["items"] || [] do %>
                      <span class="rounded-full border border-border bg-secondary px-3 py-1 text-xs font-medium text-muted-foreground">
                        <%= item %>
                      </span>
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>
          </section>
        <% end %>

        <%!-- Experience --%>
        <%= if @experience != [] do %>
          <section>
            <div class="flex items-center gap-3 mb-6">
              <div class="h-4 w-1 rounded-full bg-blue-500"></div>
              <h2 class="text-xs font-semibold uppercase tracking-[0.2em] text-muted-foreground"><%= Translation.t("experience", @locale) %></h2>
            </div>
            <div class="space-y-8">
              <%= for exp <- @experience do %>
                <div class="relative border-l-2 border-blue-500/30 pl-6">
                  <%!-- Timeline dot --%>
                  <div class="absolute -left-[9px] top-1.5 h-4 w-4 rounded-full border-2 border-blue-500 bg-background"></div>
                  <%!-- Position + currently employed badge --%>
                  <div class="flex flex-wrap items-center gap-2">
                    <h3 class="text-base font-semibold text-foreground"><%= exp["position"] %></h3>
                    <%= if exp["end_date"] in [nil, "", "현재"] do %>
                      <span class="rounded-full border border-green-500/20 bg-green-500/10 px-2 py-0.5 text-xs font-medium text-green-400">
                        <%= Translation.t("currently_employed", @locale) %>
                      </span>
                    <% end %>
                  </div>
                  <%!-- Company · Location --%>
                  <p class="mt-0.5 text-sm font-medium text-muted-foreground">
                    <%= exp["company"] %>
                    <%= if exp["location"] && exp["location"] != "" do %>
                      <span class="text-muted-foreground/50"> · <%= exp["location"] %></span>
                    <% end %>
                  </p>
                  <%!-- Date range --%>
                  <p class="text-xs text-muted-foreground/60 mt-0.5">
                    <%= exp["start_date"] %> - <%= if exp["end_date"] in [nil, "", "현재"], do: Translation.t("present", @locale), else: exp["end_date"] %>
                  </p>
                  <%!-- Description --%>
                  <%= if exp["description_md"] do %>
                    <div class="mt-3 prose-blog text-sm text-foreground/85">
                      <%= Markdown.render(exp["description_md"]) %>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          </section>
        <% end %>

        <%!-- Projects --%>
        <%= if @projects != [] do %>
          <section>
            <div class="flex items-center gap-3 mb-6">
              <div class="h-4 w-1 rounded-full bg-blue-500"></div>
              <h2 class="text-xs font-semibold uppercase tracking-[0.2em] text-muted-foreground"><%= Translation.t("projects", @locale) %></h2>
            </div>
            <div class="space-y-4">
              <%= for project <- @projects do %>
                <div class="rounded-xl border border-border/50 bg-secondary/20 p-5 transition-colors hover:border-blue-500/30 hover:bg-secondary/40">
                  <%!-- Project name + link icon --%>
                  <div class="flex items-start justify-between gap-2">
                    <h3 class="text-base font-semibold text-foreground">
                      <%= project["name"] %>
                    </h3>
                    <%= if project["url"] && project["url"] != "" do %>
                      <a href={project["url"]} target="_blank"
                         class="shrink-0 text-muted-foreground/50 transition-colors hover:text-blue-400">
                        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                          <path d="M15 3h6v6"/><path d="M10 14 21 3"/><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/>
                        </svg>
                      </a>
                    <% end %>
                  </div>
                  <%!-- Description --%>
                  <%= if project["description_md"] do %>
                    <div class="mt-2 prose-blog text-sm text-foreground/85">
                      <%= Markdown.render(project["description_md"]) %>
                    </div>
                  <% end %>
                  <%!-- Tech stack tags --%>
                  <%= if project["tech_stack"] && project["tech_stack"] != [] do %>
                    <div class="mt-3 flex flex-wrap gap-1">
                      <%= for tech <- project["tech_stack"] do %>
                        <span class="rounded-full border border-blue-500/20 bg-blue-500/10 px-2 py-0.5 text-xs font-medium text-blue-400">
                          <%= tech %>
                        </span>
                      <% end %>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          </section>
        <% end %>

        <%!-- Education --%>
        <%= if @education != [] do %>
          <section>
            <div class="flex items-center gap-3 mb-6">
              <div class="h-4 w-1 rounded-full bg-blue-500"></div>
              <h2 class="text-xs font-semibold uppercase tracking-[0.2em] text-muted-foreground"><%= Translation.t("education", @locale) %></h2>
            </div>
            <div class="space-y-6">
              <%= for edu <- @education do %>
                <div class="relative border-l-2 border-blue-500/30 pl-6">
                  <%!-- Timeline dot --%>
                  <div class="absolute -left-[9px] top-1.5 h-4 w-4 rounded-full border-2 border-blue-500 bg-background"></div>
                  <%!-- Degree + Field --%>
                  <h3 class="text-base font-semibold text-foreground">
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
                  </h3>
                  <%!-- School --%>
                  <p class="text-sm text-muted-foreground"><%= edu["school"] %></p>
                  <%!-- Date range --%>
                  <p class="text-xs text-muted-foreground/60 mt-0.5">
                    <%= edu["start_date"] %> - <%= if edu["end_date"] in [nil, "", "현재"], do: Translation.t("present", @locale), else: edu["end_date"] %>
                  </p>
                  <%!-- Description --%>
                  <%= if edu["description_md"] do %>
                    <div class="mt-2 prose-blog text-sm text-foreground/85">
                      <%= Markdown.render(edu["description_md"]) %>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          </section>
        <% end %>

        <%!-- Additional Info --%>
        <%= if has_additional_info?(@additional) do %>
          <section class="space-y-6">
            <%= if @additional["certifications"] && @additional["certifications"] != [] do %>
              <div>
                <div class="flex items-center gap-3 mb-3">
                  <div class="h-4 w-1 rounded-full bg-blue-500"></div>
                  <h3 class="text-xs font-semibold uppercase tracking-[0.2em] text-muted-foreground"><%= Translation.t("certifications", @locale) %></h3>
                </div>
                <ul class="list-disc list-inside text-sm text-foreground/85 space-y-1">
                  <%= for cert <- @additional["certifications"] do %>
                    <li><%= cert %></li>
                  <% end %>
                </ul>
              </div>
            <% end %>
            <%= if @additional["languages"] && @additional["languages"] != [] do %>
              <div>
                <div class="flex items-center gap-3 mb-3">
                  <div class="h-4 w-1 rounded-full bg-blue-500"></div>
                  <h3 class="text-xs font-semibold uppercase tracking-[0.2em] text-muted-foreground"><%= Translation.t("spoken_languages", @locale) %></h3>
                </div>
                <div class="flex flex-wrap gap-2">
                  <%= for lang <- @additional["languages"] do %>
                    <span class="rounded-full border border-border px-3 py-1 text-xs font-medium text-muted-foreground"><%= lang %></span>
                  <% end %>
                </div>
              </div>
            <% end %>
            <%= if @additional["interests"] && @additional["interests"] != [] do %>
              <div>
                <div class="flex items-center gap-3 mb-3">
                  <div class="h-4 w-1 rounded-full bg-blue-500"></div>
                  <h3 class="text-xs font-semibold uppercase tracking-[0.2em] text-muted-foreground"><%= Translation.t("interests", @locale) %></h3>
                </div>
                <p class="text-sm text-foreground/85"><%= Enum.join(@additional["interests"], ", ") %></p>
              </div>
            <% end %>
          </section>
        <% end %>
      </div>
    </div>
    """
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
