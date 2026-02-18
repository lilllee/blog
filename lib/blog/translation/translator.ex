defmodule Blog.Translation.Translator do
  @moduledoc """
  Main translation module with caching support.
  """

  alias Blog.Translation.{Translation, GeminiClient}

  @chunk_size 4000

  def translate(text, target_lang, source_lang \\ "ko")

  def translate(_text, target_lang, source_lang) when target_lang == source_lang do
    {:ok, nil}
  end

  def translate(text, target_lang, source_lang) when is_binary(text) and byte_size(text) > 0 do
    content_hash = Translation.compute_hash(text)

    case Translation.get_cached(content_hash, target_lang) do
      %Translation{translated_text: translated} ->
        {:ok, translated}

      nil ->
        translate_and_cache(text, content_hash, source_lang, target_lang)
    end
  end

  def translate(_text, _target_lang, _source_lang), do: {:ok, nil}

  def translate_post(post, target_lang, source_lang \\ "ko") do
    if target_lang == source_lang do
      post
    else
      source_text = post.raw_markdown || post.content
      translated_title = translate_field(post.title, target_lang, source_lang)
      translated_body = translate_field(source_text, target_lang, source_lang)

      post
      |> Map.put(:title, translated_title || post.title)
      |> Map.put(:raw_markdown, translated_body || source_text)
      |> Map.put(:content, translated_body || source_text)
      |> maybe_update_rendered_html(translated_body)
    end
  end

  defp translate_field(nil, _target_lang, _source_lang), do: nil
  defp translate_field("", _target_lang, _source_lang), do: ""

  defp translate_field(text, target_lang, source_lang) do
    case translate(text, target_lang, source_lang) do
      {:ok, translated} when is_binary(translated) -> translated
      _ -> text
    end
  end

  defp maybe_update_rendered_html(post, nil), do: post

  defp maybe_update_rendered_html(post, _translated_body) do
    post
    |> Map.put(:rendered_html, nil)
    |> Map.put(:toc, nil)
  end

  defp translate_and_cache(text, content_hash, source_lang, target_lang) do
    if String.length(text) > @chunk_size do
      translate_chunked(text, content_hash, source_lang, target_lang)
    else
      translate_single(text, content_hash, source_lang, target_lang)
    end
  end

  defp translate_single(text, content_hash, source_lang, target_lang) do
    case GeminiClient.translate(text, source_lang, target_lang) do
      {:ok, translated} ->
        Translation.cache_translation(%{
          content_hash: content_hash,
          source_lang: source_lang,
          target_lang: target_lang,
          original_text: text,
          translated_text: translated
        })

        {:ok, translated}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp translate_chunked(text, content_hash, source_lang, target_lang) do
    chunks = split_into_chunks(text)

    translated_chunks =
      Enum.reduce_while(chunks, [], fn chunk, acc ->
        case GeminiClient.translate(chunk, source_lang, target_lang) do
          {:ok, translated} -> {:cont, [translated | acc]}
          {:error, reason} -> {:halt, {:error, reason}}
        end
      end)

    case translated_chunks do
      {:error, reason} ->
        {:error, reason}

      chunks when is_list(chunks) ->
        translated = chunks |> Enum.reverse() |> Enum.join("\n\n")

        Translation.cache_translation(%{
          content_hash: content_hash,
          source_lang: source_lang,
          target_lang: target_lang,
          original_text: text,
          translated_text: translated
        })

        {:ok, translated}
    end
  end

  defp split_into_chunks(text) do
    paragraphs = String.split(text, ~r/\n\n+/)

    paragraphs
    |> Enum.reduce([[]], fn paragraph, [current | rest] = acc ->
      current_text = Enum.join(current, "\n\n")
      new_length = String.length(current_text) + String.length(paragraph) + 2

      if new_length > @chunk_size and current != [] do
        [[paragraph] | acc]
      else
        [[paragraph | current] | rest]
      end
    end)
    |> Enum.map(fn chunk ->
      chunk
      |> Enum.reverse()
      |> Enum.join("\n\n")
    end)
    |> Enum.reverse()
  end
end
