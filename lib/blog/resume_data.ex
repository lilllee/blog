defmodule Blog.ResumeData do
  @moduledoc """
  Context module for resume/about page operations.

  Manages the single resume record for the blog. The resume data is stored
  as JSON in the database for flexibility.

  ## Single Record Pattern

  The resume table always contains exactly one record. Functions return that
  record or create it if missing (defensive programming).

  ## JSON Structure

  All fields except timestamps are JSON strings:

  - `header` - Map with name, title, contact info
  - `skills` - Array of skill categories with items
  - `experience` - Array of work experience entries
  - `projects` - Array of project entries
  - `education` - Array of education entries
  - `additional` - Map with summary and supplementary info

  ## Public vs Admin Access

  - `get_resume/0` - Returns resume for public display
  - `get_resume_for_edit/0` - Returns resume with parsed JSON for editing
  - `update_resume/1` - Updates resume with new data

  """

  import Ecto.Query
  alias Blog.Resume
  alias Blog.Repo

  @doc """
  Gets the resume record for public display.

  Returns the single resume record. If none exists, creates one with
  default empty data.

  ## Examples

      iex> get_resume()
      {:ok, %Resume{}}

  """
  def get_resume do
    case Repo.one(Resume) do
      nil -> create_default_resume()
      resume -> {:ok, resume}
    end
  end

  @doc """
  Gets the resume record with parsed JSON for editing.

  Returns a map with decoded JSON fields for easier form handling.

  ## Examples

      iex> get_resume_for_edit()
      {:ok, %{
        id: 1,
        header: %{"name" => "John", "title" => "Developer"},
        skills: [%{"category" => "Languages", "items" => ["Elixir"]}],
        ...
      }}

  """
  def get_resume_for_edit do
    with {:ok, resume} <- get_resume() do
      {:ok,
       %{
         id: resume.id,
         header: decode_json(resume.header, %{}),
         skills: decode_json(resume.skills, []),
         experience: decode_json(resume.experience, []),
         projects: decode_json(resume.projects, []),
         education: decode_json(resume.education, []),
         additional: decode_json(resume.additional, %{}),
         inserted_at: resume.inserted_at,
         updated_at: resume.updated_at
       }}
    end
  end

  @doc """
  Updates the resume with new data.

  Accepts a map of fields to update. JSON fields will be encoded
  before saving.

  ## Examples

      iex> update_resume(%{header: %{"name" => "John Doe"}})
      {:ok, %Resume{}}

  """
  def update_resume(attrs) do
    with {:ok, resume} <- get_resume() do
      resume
      |> Resume.changeset(encode_json_fields(attrs))
      |> Repo.update()
    end
  end

  @doc """
  Creates a changeset for the resume.

  Used for form validation in LiveView.

  ## Examples

      iex> change_resume(%{header: %{"name" => ""}})
      %Ecto.Changeset{}

  """
  def change_resume(attrs \\ %{}) do
    with {:ok, resume} <- get_resume() do
      Resume.changeset(resume, encode_json_fields(attrs))
    end
  end

  defp create_default_resume do
    %Resume{}
    |> Resume.changeset(%{
      header:
        Jason.encode!(%{
          name: "",
          title: "",
          email: "",
          phone: "",
          location: "",
          linkedin: "",
          github: "",
          website: ""
        }),
      skills: Jason.encode!([]),
      experience: Jason.encode!([]),
      projects: Jason.encode!([]),
      education: Jason.encode!([]),
      additional:
        Jason.encode!(%{summary_md: "", certifications: [], languages: [], interests: []})
    })
    |> Repo.insert()
  end

  defp decode_json(json_string, default) when is_binary(json_string) do
    case Jason.decode(json_string) do
      {:ok, data} -> data
      {:error, _} -> default
    end
  end

  defp decode_json(_, default), do: default

  defp encode_json_fields(attrs) do
    attrs
    |> Enum.map(fn {k, v} ->
      key = to_string(k)

      if key in ["header", "skills", "experience", "projects", "education", "additional"] do
        {key, Jason.encode!(v)}
      else
        {key, v}
      end
    end)
    |> Enum.into(%{})
  end
end
