defmodule PlugBasicAuthTest do
  use ExUnit.Case, async: true
  use Plug.Test

  defmodule PrivatePlug do
    import Plug.Conn
    use Plug.Router

    plug PlugBasicAuth, username: "Tester", password: "McTester"
    plug :match
    plug :dispatch

    get "/" do
      conn
      |> assign(:called, true)
      |> put_resp_content_type("text/plain")
      |> send_resp(200, "Hello Tester")
    end
  end

  defp call(conn) do
    PrivatePlug.call(conn, [])
  end

  test "prompts for username and password" do
    conn = conn(:get, "/") |> call
    assert conn.status == 401
    assert get_resp_header(conn, "www-authenticate") == ["Basic realm=\"Private Area\""]
    refute conn.assigns[:called]
  end

  test "passes connection through on successful login" do
    auth_header = "Basic " <> Base.encode64("Tester:McTester")
    conn = conn(:get, "/")
    |> put_req_header("authorization", auth_header) 
    |> call

    assert conn.status == 200
    assert conn.resp_body == "Hello Tester"
    assert conn.assigns[:called]
  end

  test "prompts for username and password again if they are incorrect" do
    incorrect_credentials = "Basic " <> Base.encode64("Not:Valid")
    conn = conn(:get, "/")
    |> put_req_header("authorization", incorrect_credentials) 
    |> call

    assert conn.status == 401
    assert get_resp_header(conn, "www-authenticate") == ["Basic realm=\"Private Area\""]
    refute conn.assigns[:called]
  end
end
