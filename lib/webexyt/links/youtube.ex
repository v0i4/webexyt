defmodule Webexyt.Links.Youtube do
  def validate_url(url) do
    try do
      url = url |> String.trim()
      check = Regex.match?(~r/^https\:\/\/www\.youtube\.com\/|^https\:\/\/youtu\.be\//, url)

      case check do
        true ->
          {:ok, url}

        false ->
          {:error, :match}
      end
    rescue
      e ->
        {:error, ["url_verify", e]}
    end
  end

  def download(url) do
    {status, path} = Exyt.download_getting_filename(url)

    case status do
      :ok ->
        {:ok, path}

      _ ->
        {:error, "error while downloading.."}
    end
  end
end
