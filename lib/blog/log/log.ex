# defmodule BlogWeb.Log do
#   use Ecto.Schema
#   import Ecto.Changeset

#   schema "log" do
#     field :location, :string
#     field :event, :string
#     field :ip, :string
# #    field :user, :string # 아직 없음 그래서 주석 처리
#     field :input, :string

#     timestamps()
#   end

#   def changeset(log, params \\ %{}) do
#     log
#     |> cast(params, [:location, :event, :ip, :input])
#     |> validate_required([:location, :event])
#   end

# end
