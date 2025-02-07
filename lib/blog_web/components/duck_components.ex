defmodule BlogWeb.DuckComponents do
  @moduledoc """
    duckDB 모듈로 연결되나 테스트
  """
  def init_duck_db(%{table_nm: name}) do
    with {:ok, db} <- Duckdbex.open(),
         {:ok, conn} <- Duckdbex.connection(db),
         {:ok, table_result} <- Duckdbex.query(conn, """
           CREATE TABLE IF NOT EXISTS note AS SELECT * FROM read_csv_auto(
             '#{name}.csv',
             delim='|',
             quote='"',
             escape='"',
             header=true,
             ignore_errors=true,
             null_padding=true,
             all_varchar=true
           )
         """) do
      {:ok, %{table: table_result, conn: conn}}
    else
      error ->
        IO.inspect(error, label: "DuckDB 초기화 에러")
        error
    end
  end
end
