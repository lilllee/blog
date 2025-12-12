# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#

alias Blog.Repo
alias Blog.Note

# Read and parse CSV file
csv_path = Path.join([File.cwd!(), "note.csv"])

if File.exists?(csv_path) do
  # Read the entire file content
  content = File.read!(csv_path)

  # Split by lines and parse manually to handle multiline content
  lines = String.split(content, "\n", trim: true)

  # Skip the header
  lines = Enum.drop(lines, 1)

  # We need to parse this more carefully since content has newlines
  # Let's collect lines into records based on ID pattern
  parse_notes = fn lines ->
    {records, current} =
      Enum.reduce(lines, {[], []}, fn line, {records, current} ->
        # Check if line starts with a digit followed by |
        if Regex.match?(~r/^\d+\|/, line) do
          # This is a new record
          new_records =
            if current == [] do
              records
            else
              [Enum.reverse(current) |> Enum.join("\n") | records]
            end

          {new_records, [line]}
        else
          # This is a continuation of the current record
          {records, [line | current]}
        end
      end)

    # Add the last record
    final_records =
      if current == [] do
        records
      else
        [Enum.reverse(current) |> Enum.join("\n") | records]
      end

    Enum.reverse(final_records)
  end

  records = parse_notes.(lines)

  # Now parse each complete record
  Enum.each(records, fn record ->
    # Split by | but only take the first 6-7 fields
    parts = String.split(record, "|")

    case parts do
      [_id, title, content, image_path, inserted_at, tags | rest] ->
        categories = Enum.at(rest, 0, "")

        # Parse date (format: 2025.01.21)
        {:ok, date} =
          case String.split(inserted_at, ".") do
            [year, month, day] ->
              NaiveDateTime.new(
                String.to_integer(year),
                String.to_integer(month),
                String.to_integer(day),
                0,
                0,
                0
              )

            _ ->
              {:ok, ~N[2024-01-01 00:00:00]}
          end

        %Note{}
        |> Note.changeset(%{
          title: title,
          content: String.replace(content, ~s("), "\""),
          image_path: image_path,
          tags: tags,
          categories: categories,
          inserted_at: DateTime.from_naive!(date, "Etc/UTC"),
          updated_at: DateTime.from_naive!(date, "Etc/UTC")
        })
        |> Repo.insert!()

        IO.puts("Inserted note: #{title}")

      _ ->
        IO.puts("Skipping invalid row: #{inspect(parts)}")
    end
  end)

  IO.puts("\nData migration completed!")
else
  IO.puts("note.csv file not found at #{csv_path}")
end
