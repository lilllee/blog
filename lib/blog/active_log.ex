# defmodule BlogWeb.ActiveLog do
#   import Ecto.Query

#   alias Blog.Repo
#   alias BlogWeb.{Log, LogLive}

#   def log(location, event, scope, input) do
#     %Log{location: location, event: event, ip: scope.current_ip, input: input}
#     |> Log.changeset()
#     |> Repo.insert()
#     |> case do
#          {:ok, %{}} ->
#            Phoenix.PubSub.broadcast(Blog.PubSub, "activity_logs", :logs_updated)
#            {:ok, %{}}
#          {:error, changeset} ->
#            {:error, changeset}
#        end
#   end

#   def get_logs do
#     IO.puts("call get_logs")
#     from(l in Log, order_by: [desc: l.inserted_at])
#     |> Repo.all()
#     |> Enum.map(fn log ->
#       %{
#         location: log.location,
#         event: log.event,
#         ip: log.ip,
#         input: log.input,
#         inserted_at: log.inserted_at
#       }
#     end)
#   end
# end
