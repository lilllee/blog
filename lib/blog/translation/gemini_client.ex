defmodule Blog.Translation.GeminiClient do
  @moduledoc """
  Gemini API client for text translation using Finch.
  """

  require Logger

  @base_url "https://generativelanguage.googleapis.com/v1beta/models"
  @default_model "gemini-2.0-flash"
  @timeout 30_000

  def translate(text, source_lang, target_lang) do
    api_key = get_api_key()
    model = get_model()

    if is_nil(api_key) or api_key == "" do
      Logger.warning("Gemini API key not configured, skipping translation")
      {:error, :api_key_not_configured}
    else
      do_translate(text, source_lang, target_lang, api_key, model)
    end
  end

  defp do_translate(text, source_lang, target_lang, api_key, model) do
    url = "#{@base_url}/#{model}:generateContent?key=#{api_key}"

    prompt = build_prompt(text, source_lang, target_lang)

    body = Jason.encode!(%{
      contents: [%{parts: [%{text: prompt}]}],
      generationConfig: %{temperature: 0.1, maxOutputTokens: 8192}
    })

    request = Finch.build(:post, url, [{"content-type", "application/json"}], body)

    case Finch.request(request, Blog.Finch, receive_timeout: @timeout) do
      {:ok, %Finch.Response{status: 200, body: response_body}} ->
        parse_response(response_body)

      {:ok, %Finch.Response{status: status, body: response_body}} ->
        Logger.error("Gemini API error: #{status} - #{String.slice(response_body, 0, 500)}")
        {:error, {:api_error, status, response_body}}

      {:error, reason} ->
        Logger.error("Gemini API request failed: #{inspect(reason)}")
        {:error, {:request_failed, reason}}
    end
  end

  defp build_prompt(text, source_lang, target_lang) do
    source_name = language_name(source_lang)
    target_name = language_name(target_lang)

    """
    Translate the following text from #{source_name} to #{target_name}.
    Keep the original formatting, markdown syntax, and code blocks intact.
    Only translate the natural language text, not code or technical terms that should remain in English.
    Do not add any explanations or notes - only output the translated text.

    Text to translate:
    #{text}
    """
  end

  defp parse_response(response_body) do
    case Jason.decode(response_body) do
      {:ok, %{"candidates" => [%{"content" => %{"parts" => [%{"text" => text} | _]}} | _]}} ->
        {:ok, String.trim(text)}

      {:ok, %{"error" => error}} ->
        {:error, {:api_error, error["code"], error["message"]}}

      {:ok, unexpected} ->
        Logger.error("Unexpected Gemini response: #{inspect(unexpected)}")
        {:error, :unexpected_response}

      {:error, reason} ->
        {:error, {:json_decode_error, reason}}
    end
  end

  defp language_name("ko"), do: "Korean"
  defp language_name("en"), do: "English"
  defp language_name("ja"), do: "Japanese"
  defp language_name("zh"), do: "Chinese (Simplified)"
  defp language_name(code), do: code

  defp get_api_key do
    Application.get_env(:blog, __MODULE__)[:api_key]
  end

  defp get_model do
    Application.get_env(:blog, __MODULE__)[:model] || @default_model
  end
end
