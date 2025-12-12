defmodule Blog.Repo.Migrations.AddNoteFts do
  use Ecto.Migration

  def up do
    execute("""
    CREATE VIRTUAL TABLE IF NOT EXISTS note_fts USING fts5(
      title,
      content,
      content='note',
      content_rowid='id'
    );
    """)

    execute("""
    CREATE TRIGGER IF NOT EXISTS note_ai AFTER INSERT ON note BEGIN
      INSERT INTO note_fts(rowid, title, content) VALUES (new.id, new.title, new.content);
    END;
    """)

    execute("""
    CREATE TRIGGER IF NOT EXISTS note_ad AFTER DELETE ON note BEGIN
      INSERT INTO note_fts(note_fts, rowid, title, content) VALUES('delete', old.id, old.title, old.content);
    END;
    """)

    execute("""
    CREATE TRIGGER IF NOT EXISTS note_au AFTER UPDATE ON note BEGIN
      INSERT INTO note_fts(note_fts, rowid, title, content) VALUES('delete', old.id, old.title, old.content);
      INSERT INTO note_fts(rowid, title, content) VALUES (new.id, new.title, new.content);
    END;
    """)

    execute("""
    INSERT INTO note_fts(rowid, title, content)
    SELECT id, title, content FROM note;
    """)
  end

  def down do
    execute("DROP TRIGGER IF EXISTS note_ai;")
    execute("DROP TRIGGER IF EXISTS note_ad;")
    execute("DROP TRIGGER IF EXISTS note_au;")
    execute("DROP TABLE IF EXISTS note_fts;")
  end
end
