defmodule BlogWeb.AboutLive do
  @moduledoc """
  Public-facing resume/about page. Minimal, reading-first.
  """

  use BlogWeb, :live_view

  alias Blog.ResumeData
  alias Blog.Translation
  alias BlogWeb.Markdown
  alias BlogWeb.SEO

  @impl true
  def mount(_params, _session, socket) do
    seo =
      SEO.seo_assigns(:page, %{
        title: "about · junho",
        description:
          "Software engineer specializing in Elixir, Phoenix, and full-stack development.",
        path: "/about",
        json_ld: SEO.person_schema()
      })

    locale = socket.assigns[:locale] || "ko"

    case ResumeData.get_resume() do
      {:ok, resume} ->
        data = %{
          header: decode_json(resume.header, %{}),
          skills: decode_json(resume.skills, []),
          experience: decode_json(resume.experience, []),
          projects: decode_json(resume.projects, []),
          education: decode_json(resume.education, []),
          additional: decode_json(resume.additional, %{})
        }

        socket =
          socket
          |> assign(seo)
          |> assign(
            header: data.header,
            skills: data.skills,
            experience: data.experience,
            projects: data.projects,
            education: data.education,
            additional: data.additional,
            original: data
          )

        if locale != "ko" and connected?(socket) do
          send(self(), {:translate_resume, locale})
        end

        {:ok, socket}

      {:error, _} ->
        empty = %{header: %{}, skills: [], experience: [], projects: [], education: [], additional: %{}}

        {:ok,
         socket
         |> assign(seo)
         |> assign(header: %{}, skills: [], experience: [], projects: [], education: [], additional: %{}, original: empty)}
    end
  end

  @impl true
  def handle_info({:locale_changed, locale}, socket) do
    if locale == "ko" do
      o = socket.assigns.original

      {:noreply,
       assign(socket,
         header: o.header,
         skills: o.skills,
         experience: o.experience,
         projects: o.projects,
         education: o.education,
         additional: o.additional
       )}
    else
      send(self(), {:translate_resume, locale})
      {:noreply, socket}
    end
  end

  def handle_info({:translate_resume, locale}, socket) do
    pid = self()
    original = socket.assigns.original

    Task.start(fn ->
      send(pid, {:resume_translated, translate_resume_data(original, locale), locale})
    end)

    {:noreply, socket}
  end

  def handle_info({:resume_translated, data, locale}, socket) do
    if socket.assigns[:locale] == locale do
      {:noreply,
       assign(socket,
         header: data.header,
         skills: data.skills,
         experience: data.experience,
         projects: data.projects,
         education: data.education,
         additional: data.additional
       )}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.link navigate={~p"/"} class="back">← <%= Translation.t("back_to_list", @locale) %></.link>

    <article class="about">
      <header class="about-head">
        <h1><%= @header["name"] || "—" %></h1>
        <p :if={present?(@header["title"])} class="about-title"><%= @header["title"] %></p>
      </header>

      <div :if={present?(@additional["summary_md"])} class="about-summary">
        <%= Markdown.render(@additional["summary_md"]) %>
      </div>

      <dl :if={has_contact?(@header)} class="about-contact">
        <%= for {label, content} <- contact_rows(@header) do %>
          <dt><%= label %></dt>
          <dd><%= content %></dd>
        <% end %>
      </dl>

      <section :if={@experience != []} class="about-section">
        <h2><%= Translation.t("experience", @locale) %></h2>
        <div class="about-items">
          <div :for={e <- @experience} class="a-item">
            <div class="row1">
              <div class="lead">
                <%= e["position"] %><span class="sub">
                  · <%= e["company"] %><%= if present?(e["location"]), do: " · " <> e["location"] %>
                </span>
              </div>
              <div class="dates">
                <%= e["start_date"] %> – <%= end_date(e["end_date"], @locale) %>
              </div>
            </div>
            <div :if={present?(e["description_md"])} class="desc">
              <%= Markdown.render(e["description_md"]) %>
            </div>
          </div>
        </div>
      </section>

      <section :if={@skills != []} class="about-section">
        <h2><%= Translation.t("skills", @locale) %></h2>
        <dl class="about-kv">
          <%= for s <- @skills do %>
            <dt><%= String.downcase(to_string(s["category"] || "")) %></dt>
            <dd><%= Enum.join(s["items"] || [], ", ") %></dd>
          <% end %>
        </dl>
      </section>

      <section :if={@projects != []} class="about-section">
        <h2><%= Translation.t("projects", @locale) %></h2>
        <div class="about-items">
          <div :for={p <- @projects} class="a-item">
            <div class="row1">
              <div class="lead">
                <%= if present?(p["url"]) do %>
                  <a href={p["url"]} target="_blank" rel="noopener"><%= p["name"] %></a>
                <% else %>
                  <%= p["name"] %>
                <% end %>
              </div>
            </div>
            <div :if={present?(p["description_md"])} class="desc">
              <%= Markdown.render(p["description_md"]) %>
            </div>
            <div :if={p["tech_stack"] && p["tech_stack"] != []} class="tech">
              <%= Enum.join(p["tech_stack"], " · ") %>
            </div>
          </div>
        </div>
      </section>

      <section :if={@education != []} class="about-section">
        <h2><%= Translation.t("education", @locale) %></h2>
        <div class="about-items">
          <div :for={ed <- @education} class="a-item">
            <div class="row1">
              <div class="lead">
                <%= education_head(ed) %><span class="sub"> · <%= ed["school"] %></span>
              </div>
              <div class="dates">
                <%= ed["start_date"] %> – <%= end_date(ed["end_date"], @locale) %>
              </div>
            </div>
            <div :if={present?(ed["description_md"])} class="desc">
              <%= Markdown.render(ed["description_md"]) %>
            </div>
          </div>
        </div>
      </section>

      <section :if={additional_rows(@additional) != []} class="about-section">
        <dl class="about-kv">
          <%= for {label, value} <- additional_rows(@additional) do %>
            <dt><%= label %></dt>
            <dd><%= value %></dd>
          <% end %>
        </dl>
      </section>
    </article>

    <footer class="qfooter">
      <.link navigate={~p"/"}>← <%= Translation.t("back_to_list", @locale) %></.link>
      <span class="langs">
        <button
          :for={code <- ~w(ko en ja zh)}
          type="button"
          phx-click="set_locale"
          phx-value-locale={code}
          class={if @locale == code, do: "current"}
        ><%= lang_label(code) %></button>
      </span>
    </footer>
    """
  end

  defp lang_label("ko"), do: "한국어"
  defp lang_label("en"), do: "English"
  defp lang_label("ja"), do: "日本語"
  defp lang_label("zh"), do: "中文"

  defp present?(nil), do: false
  defp present?(""), do: false
  defp present?(_), do: true

  defp has_contact?(header) do
    Enum.any?(~w(email github linkedin website location phone), &present?(header[&1]))
  end

  defp contact_rows(header) do
    [
      {"email", email_link(header["email"])},
      {"github", url_link(header["github"])},
      {"linkedin", url_link(header["linkedin"])},
      {"website", url_link(header["website"])},
      {"location", header["location"]},
      {"phone", header["phone"]}
    ]
    |> Enum.filter(fn {_label, content} -> content != nil end)
  end

  defp email_link(nil), do: nil
  defp email_link(""), do: nil

  defp email_link(addr),
    do: Phoenix.HTML.raw(~s(<a href="mailto:#{addr}">#{addr}</a>))

  defp url_link(nil), do: nil
  defp url_link(""), do: nil

  defp url_link(url) do
    label = String.replace(url, ~r{^https?://}, "")

    Phoenix.HTML.raw(
      ~s(<a href="#{url}" target="_blank" rel="noopener">#{label}</a>)
    )
  end

  defp education_head(ed) do
    cond do
      present?(ed["degree"]) and present?(ed["field"]) -> "#{ed["degree"]} in #{ed["field"]}"
      present?(ed["degree"]) -> ed["degree"]
      present?(ed["field"]) -> ed["field"]
      true -> ed["school"] || ""
    end
  end

  defp end_date(date, locale) when date in [nil, "", "현재"], do: Translation.t("present", locale)
  defp end_date(date, _), do: date

  defp additional_rows(additional) do
    [
      {"certifications", list_or_nil(additional["certifications"])},
      {"languages", list_or_nil(additional["languages"])},
      {"interests", list_or_nil(additional["interests"])}
    ]
    |> Enum.filter(fn {_l, v} -> v end)
  end

  defp list_or_nil(nil), do: nil
  defp list_or_nil([]), do: nil
  defp list_or_nil(list) when is_list(list), do: Enum.join(list, ", ")

  defp decode_json(json, default) when is_binary(json) do
    case Jason.decode(json) do
      {:ok, data} -> data
      _ -> default
    end
  end

  defp decode_json(_, default), do: default

  defp translate_resume_data(data, locale) do
    %{
      header: translate_header(data.header, locale),
      skills: translate_skills(data.skills, locale),
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
    case translate_field(header["title"], locale) do
      nil -> header
      title -> Map.put(header, "title", title)
    end
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
end
