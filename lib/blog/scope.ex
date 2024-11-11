defmodule BlogWeb.Scope do
  @moduledoc """
  사용자와 요청의 스코프를 정의하는 모듈입니다.
  """

  defstruct current_user: nil, current_user_id: nil, current_ip: nil

  @doc """
  현재 유저의 IP 주소를 포함한 스코프를 반환
  """
  def for_request(%{remote_ip: ip}) do
    IO.inspect("ip는 ????: #{ip}")
    ip_string = :inet.ntoa(ip) |> to_string()
    %__MODULE__{current_ip: ip_string}
  end

  @doc """
  유저 정보를 포함한 스코프를 반환
  """
  def for_user(nil, %{remote_ip: ip}) do
    ip_string = :inet.ntoa(ip) |> to_string()
    %__MODULE__{current_user: nil, current_user_id: nil, current_ip: ip_string}
  end

  @doc """
  아직 없음.
  """
#  def for_user(%BlogWeb.Accounts.User{} = user, %{remote_ip: ip}) do
#    ip_string = :inet.ntoa(ip) |> to_string()
#    %__MODULE__{current_user: user, current_user_id: user.id, current_ip: ip_string}
#  end
end
