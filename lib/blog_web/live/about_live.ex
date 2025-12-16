defmodule BlogWeb.AboutLive do
  @moduledoc """
  Public-facing resume/about page.

  Displays professional resume information with clean, scannable layout.
  Supports markdown rendering in descriptions and responsive design.
  """

  use BlogWeb, :live_view

  alias Blog.ResumeData
  alias BlogWeb.Markdown

  @impl true
  def mount(_params, _session, socket) do
    case ResumeData.get_resume() do
      {:ok, resume} ->
        {:ok,
         assign(socket,
           resume: resume,
           header: decode_json(resume.header, %{}),
           skills: decode_json(resume.skills, []),
           experience: decode_json(resume.experience, []),
           projects: decode_json(resume.projects, []),
           education: decode_json(resume.education, []),
           additional: decode_json(resume.additional, %{}),
           page_title: "About"
         )}

      {:error, _} ->
        {:ok,
         assign(socket,
           resume: nil,
           header: %{},
           skills: [],
           experience: [],
           projects: [],
           education: [],
           additional: %{},
           page_title: "About"
         )}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="px-4 pb-16 sm:px-8">
      <div class="mb-6 flex items-center gap-2 text-sm text-gray-500 dark:text-gray-400">
        <.link navigate={~p"/"} class="hover:text-indigo-600">Home</.link> <span>/</span>
        <span>About</span>
      </div>

      <div class="max-w-4xl mx-auto space-y-12">
        <!-- Header Section -->
        <header class="text-center space-y-3">
          <h1 class="text-4xl font-bold text-gray-900 dark:text-gray-100">
            <%= @header["name"] || "Your Name" %>
          </h1>

          <p class="text-xl text-gray-600 dark:text-gray-300">
            <%= @header["title"] || "Your Title" %>
          </p>

          <div class="flex flex-wrap items-center justify-center gap-4 text-sm text-gray-600 dark:text-gray-300">
            <%= if @header["email"] && @header["email"] != "" do %>
              <a
                href={"mailto:#{@header["email"]}"}
                class="hover:text-indigo-600 dark:hover:text-indigo-400"
              >
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
              <a
                href={@header["linkedin"]}
                target="_blank"
                class="hover:text-indigo-600 dark:hover:text-indigo-400"
              >
                LinkedIn
              </a>
            <% end %>

            <%= if @header["github"] && @header["github"] != "" do %>
              <a
                href={@header["github"]}
                target="_blank"
                class="hover:text-indigo-600 dark:hover:text-indigo-400"
              >
                GitHub
              </a>
            <% end %>

            <%= if @header["website"] && @header["website"] != "" do %>
              <a
                href={@header["website"]}
                target="_blank"
                class="hover:text-indigo-600 dark:hover:text-indigo-400"
              >
                Website
              </a>
            <% end %>
          </div>
        </header>
        <!-- Summary -->
        <%= if @additional["summary_md"] && @additional["summary_md"] != "" do %>
          <section class="prose prose-slate max-w-none dark:prose-invert">
            <%= Markdown.render(@additional["summary_md"]) %>
          </section>
        <% end %>
        <!-- Skills -->
        <%= if @skills != [] do %>
          <section>
            <h2 class="text-2xl font-bold text-gray-900 dark:text-gray-100 mb-4">Skills</h2>

            <div class="space-y-4">
              <%= for skill_group <- @skills do %>
                <div>
                  <h3 class="font-semibold text-gray-900 dark:text-gray-100 mb-2">
                    <%= skill_group["category"] %>
                  </h3>

                  <div class="flex flex-wrap gap-2">
                    <%= for item <- skill_group["items"] do %>
                      <span class="rounded-full bg-indigo-50 px-3 py-1 text-sm font-semibold text-indigo-700 dark:bg-indigo-900/40 dark:text-indigo-100">
                        <%= item %>
                      </span>
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>
          </section>
        <% end %>
        <!-- Experience -->
        <%= if @experience != [] do %>
          <section>
            <h2 class="text-2xl font-bold text-gray-900 dark:text-gray-100 mb-4">Experience</h2>

            <div class="space-y-6">
              <%= for exp <- @experience do %>
                <div class="border-l-2 border-indigo-600 pl-4">
                  <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100">
                    <%= exp["position"] %>
                  </h3>

                  <p class="text-gray-600 dark:text-gray-300">
                    <%= exp["company"] %>
                    <%= if exp["location"] do %>
                      · <%= exp["location"] %>
                    <% end %>
                  </p>

                  <p class="text-sm text-gray-500 dark:text-gray-400">
                    <%= exp["start_date"] %> - <%= exp["end_date"] || "Present" %>
                  </p>

                  <%= if exp["description_md"] do %>
                    <div class="mt-2 prose prose-sm prose-slate max-w-none dark:prose-invert">
                      <%= Markdown.render(exp["description_md"]) %>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          </section>
        <% end %>
        <!-- Projects -->
        <%= if @projects != [] do %>
          <section>
            <h2 class="text-2xl font-bold text-gray-900 dark:text-gray-100 mb-4">Projects</h2>

            <div class="grid gap-4 md:grid-cols-2">
              <%= for project <- @projects do %>
                <div class="rounded-xl border border-gray-200 bg-white p-4 shadow-sm dark:border-gray-800 dark:bg-gray-900">
                  <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100">
                    <%= if project["url"] do %>
                      <a
                        href={project["url"]}
                        target="_blank"
                        class="hover:text-indigo-600 dark:hover:text-indigo-400"
                      >
                        <%= project["name"] %>
                      </a>
                    <% else %>
                      <%= project["name"] %>
                    <% end %>
                  </h3>

                  <%= if project["description_md"] do %>
                    <div class="mt-2 prose prose-sm prose-slate max-w-none dark:prose-invert">
                      <%= Markdown.render(project["description_md"]) %>
                    </div>
                  <% end %>

                  <%= if project["tech_stack"] && project["tech_stack"] != [] do %>
                    <div class="mt-3 flex flex-wrap gap-1">
                      <%= for tech <- project["tech_stack"] do %>
                        <span class="rounded-full bg-gray-100 px-2 py-0.5 text-xs font-semibold text-gray-700 dark:bg-gray-800 dark:text-gray-200">
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
        <!-- Education -->
        <%= if @education != [] do %>
          <section>
            <h2 class="text-2xl font-bold text-gray-900 dark:text-gray-100 mb-4">Education</h2>

            <div class="space-y-4">
              <%= for edu <- @education do %>
                <div>
                  <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100">
                    <%= edu["degree"] %> <%= if edu["field"], do: "in #{edu["field"]}" %>
                  </h3>

                  <p class="text-gray-600 dark:text-gray-300"><%= edu["school"] %></p>

                  <p class="text-sm text-gray-500 dark:text-gray-400">
                    <%= edu["start_date"] %> - <%= edu["end_date"] || "Present" %>
                  </p>

                  <%= if edu["description_md"] do %>
                    <div class="mt-2 prose prose-sm prose-slate max-w-none dark:prose-invert">
                      <%= Markdown.render(edu["description_md"]) %>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          </section>
        <% end %>
        <!-- Additional Info -->
        <%= if has_additional_info?(@additional) do %>
          <section class="space-y-4">
            <%= if @additional["certifications"] && @additional["certifications"] != [] do %>
              <div>
                <h3 class="font-semibold text-gray-900 dark:text-gray-100 mb-2">Certifications</h3>

                <ul class="list-disc list-inside text-gray-700 dark:text-gray-300">
                  <%= for cert <- @additional["certifications"] do %>
                    <li><%= cert %></li>
                  <% end %>
                </ul>
              </div>
            <% end %>

            <%= if @additional["languages"] && @additional["languages"] != [] do %>
              <div>
                <h3 class="font-semibold text-gray-900 dark:text-gray-100 mb-2">Languages</h3>

                <div class="flex flex-wrap gap-2">
                  <%= for lang <- @additional["languages"] do %>
                    <span class="rounded-full bg-gray-100 px-3 py-1 text-sm text-gray-700 dark:bg-gray-800 dark:text-gray-200">
                      <%= lang %>
                    </span>
                  <% end %>
                </div>
              </div>
            <% end %>

            <%= if @additional["interests"] && @additional["interests"] != [] do %>
              <div>
                <h3 class="font-semibold text-gray-900 dark:text-gray-100 mb-2">Interests</h3>

                <p class="text-gray-700 dark:text-gray-300">
                  <%= Enum.join(@additional["interests"], ", ") %>
                </p>
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
