defmodule Blog.Resume do
  @moduledoc """
  Schema for resume/about page data.

  The resume table contains a single record with JSON-encoded fields
  for flexible resume content storage.

  ## JSON Fields

  All content fields store JSON as TEXT strings:

  - `header` - Map with name, title, email, phone, location, linkedin, github, website
  - `skills` - Array of skill categories: `[{category, items: []}]`
  - `experience` - Array of work experience entries
  - `projects` - Array of project entries with tech stack
  - `education` - Array of education entries
  - `additional` - Map with summary_md, certifications, languages, interests

  ## Usage

  This schema should not be used directly. Instead, use the `Blog.ResumeData`
  context module which handles JSON encoding/decoding.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "resume" do
    field :header, :string
    field :skills, :string
    field :experience, :string
    field :projects, :string
    field :education, :string
    field :additional, :string

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for the resume.

  Validates that all JSON fields contain valid JSON syntax.
  No fields are required - resume can be empty.
  """
  def changeset(resume, params \\ %{}) do
    resume
    |> cast(params, [:header, :skills, :experience, :projects, :education, :additional])
    |> validate_json_field(:header)
    |> validate_json_field(:skills)
    |> validate_json_field(:experience)
    |> validate_json_field(:projects)
    |> validate_json_field(:education)
    |> validate_json_field(:additional)
  end

  defp validate_json_field(changeset, field) do
    validate_change(changeset, field, fn ^field, value ->
      case Jason.decode(value) do
        {:ok, _} -> []
        {:error, _} -> [{field, "must be valid JSON"}]
      end
    end)
  end
end
