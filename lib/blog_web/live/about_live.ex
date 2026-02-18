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

  @impl true
  def mount(_params, _session, socket) do
    seo =
      SEO.seo_assigns(:page, %{
        title: "About",
        description: "Professional background, skills, and experience.",
        path: "/about"
      })

    case ResumeData.get_resume() do
      {:ok, resume} ->
        {:ok,
         socket
         |> assign(seo)
         |> assign(
           resume: resume,
           header: decode_json(resume.header, %{}),
           skills: decode_json(resume.skills, []),
           experience: decode_json(resume.experience, []),
           projects: decode_json(resume.projects, []),
           education: decode_json(resume.education, []),
           additional: decode_json(resume.additional, %{})
         )}

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
           additional: %{}
         )}
    end
  end

  @impl true
  def handle_info({:locale_changed, _locale}, socket), do: {:noreply, socket}

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
        <header class="space-y-3">
          <h1 class="text-3xl font-bold tracking-tight text-foreground">
            <%= @header["name"] || "Your Name" %>
          </h1>
          <p class="text-base text-muted-foreground">
            <%= @header["title"] || "Your Title" %>
          </p>
          <div class="flex flex-wrap items-center gap-4 text-sm text-muted-foreground">
            <%= if @header["email"] && @header["email"] != "" do %>
              <a href={"mailto:#{@header["email"]}"} class="transition-colors hover:text-foreground">
                <%= @header["email"] %>
              </a>
            <% end %>
            <%= if @header["phone"] && @header["phone"] != "" do %>
              <span><%= @header["phone"] %></span>
            <% end %>
            <%= if @header["location"] && @header["location"] != "" do %>
              <span><%= @header["location"] %></span>
            <% end %>
            <%= if @header["linkedin"] && @header["linkedin"] != "" do %>
              <a href={@header["linkedin"]} target="_blank" class="transition-colors hover:text-foreground">LinkedIn</a>
            <% end %>
            <%= if @header["github"] && @header["github"] != "" do %>
              <a href={@header["github"]} target="_blank" class="transition-colors hover:text-foreground">GitHub</a>
            <% end %>
            <%= if @header["website"] && @header["website"] != "" do %>
              <a href={@header["website"]} target="_blank" class="transition-colors hover:text-foreground">Website</a>
            <% end %>
          </div>
        </header>

        <%!-- Summary --%>
        <%= if @additional["summary_md"] && @additional["summary_md"] != "" do %>
          <section class="prose-blog text-base text-foreground/85">
            <%= Markdown.render(@additional["summary_md"]) %>
          </section>
        <% end %>

        <%!-- Skills --%>
        <%= if @skills != [] do %>
          <section>
            <h2 class="text-xs font-semibold uppercase tracking-[0.2em] text-muted-foreground/60 mb-6">Skills</h2>
            <div class="space-y-4">
              <%= for skill_group <- @skills do %>
                <div>
                  <h3 class="text-sm font-semibold text-foreground mb-2"><%= skill_group["category"] %></h3>
                  <div class="flex flex-wrap gap-2">
                    <%= for item <- skill_group["items"] do %>
                      <span class="rounded-full bg-secondary px-3 py-1 text-xs font-medium text-muted-foreground">
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
            <h2 class="text-xs font-semibold uppercase tracking-[0.2em] text-muted-foreground/60 mb-6">Experience</h2>
            <div class="space-y-6">
              <%= for exp <- @experience do %>
                <div class="border-l-2 border-border pl-4">
                  <h3 class="text-base font-semibold text-foreground"><%= exp["position"] %></h3>
                  <p class="text-sm text-muted-foreground">
                    <%= exp["company"] %>
                    <%= if exp["location"] do %> · <%= exp["location"] %><% end %>
                  </p>
                  <p class="text-xs text-muted-foreground/60">
                    <%= exp["start_date"] %> - <%= exp["end_date"] || "Present" %>
                  </p>
                  <%= if exp["description_md"] do %>
                    <div class="mt-2 prose-blog text-sm text-foreground/85">
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
            <h2 class="text-xs font-semibold uppercase tracking-[0.2em] text-muted-foreground/60 mb-6">Projects</h2>
            <div class="space-y-4">
              <%= for project <- @projects do %>
                <div class="rounded-lg border border-border/50 p-4">
                  <h3 class="text-base font-semibold text-foreground">
                    <%= if project["url"] do %>
                      <a href={project["url"]} target="_blank" class="transition-colors hover:text-muted-foreground"><%= project["name"] %></a>
                    <% else %>
                      <%= project["name"] %>
                    <% end %>
                  </h3>
                  <%= if project["description_md"] do %>
                    <div class="mt-2 prose-blog text-sm text-foreground/85">
                      <%= Markdown.render(project["description_md"]) %>
                    </div>
                  <% end %>
                  <%= if project["tech_stack"] && project["tech_stack"] != [] do %>
                    <div class="mt-3 flex flex-wrap gap-1">
                      <%= for tech <- project["tech_stack"] do %>
                        <span class="rounded-full bg-secondary px-2 py-0.5 text-xs font-medium text-muted-foreground">
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
            <h2 class="text-xs font-semibold uppercase tracking-[0.2em] text-muted-foreground/60 mb-6">Education</h2>
            <div class="space-y-4">
              <%= for edu <- @education do %>
                <div>
                  <h3 class="text-base font-semibold text-foreground">
                    <%= edu["degree"] %> <%= if edu["field"], do: "in #{edu["field"]}" %>
                  </h3>
                  <p class="text-sm text-muted-foreground"><%= edu["school"] %></p>
                  <p class="text-xs text-muted-foreground/60">
                    <%= edu["start_date"] %> - <%= edu["end_date"] || "Present" %>
                  </p>
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
          <section class="space-y-4">
            <%= if @additional["certifications"] && @additional["certifications"] != [] do %>
              <div>
                <h3 class="text-xs font-semibold uppercase tracking-[0.2em] text-muted-foreground/60 mb-2">Certifications</h3>
                <ul class="list-disc list-inside text-sm text-foreground/85">
                  <%= for cert <- @additional["certifications"] do %>
                    <li><%= cert %></li>
                  <% end %>
                </ul>
              </div>
            <% end %>
            <%= if @additional["languages"] && @additional["languages"] != [] do %>
              <div>
                <h3 class="text-xs font-semibold uppercase tracking-[0.2em] text-muted-foreground/60 mb-2">Languages</h3>
                <div class="flex flex-wrap gap-2">
                  <%= for lang <- @additional["languages"] do %>
                    <span class="rounded-full bg-secondary px-3 py-1 text-xs font-medium text-muted-foreground"><%= lang %></span>
                  <% end %>
                </div>
              </div>
            <% end %>
            <%= if @additional["interests"] && @additional["interests"] != [] do %>
              <div>
                <h3 class="text-xs font-semibold uppercase tracking-[0.2em] text-muted-foreground/60 mb-2">Interests</h3>
                <p class="text-sm text-foreground/85"><%= Enum.join(@additional["interests"], ", ") %></p>
              </div>
            <% end %>
          </section>
        <% end %>
      </div>
    </div>
    """
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
