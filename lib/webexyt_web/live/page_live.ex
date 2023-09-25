defmodule WebexytWeb.PageLive do
  use WebexytWeb, :live_view

  alias Webexyt.Links.Youtube

  def mount(_session, _params, socket) do
    socket =
      socket
      |> assign(:info, nil)
      |> assign(:valid_url, nil)
      |> assign(:url, nil)
      |> assign(:loading, false)
      |> assign(:final_url, nil)

    {:ok, socket}
  end

  def handle_event("url-validate", params, socket) do
    url = params |> Map.get("value")

    {status, _url} = Youtube.validate_url(url)

    valid? = if status == :ok, do: true, else: false

    socket =
      if valid? do
        Task.async(fn ->
          get_data(url)
        end)

        socket
      else
        socket
        |> assign(:info, nil)
        |> assign(:valid_url, nil)
        |> assign(:url, nil)
        |> assign(:loading, false)
        |> assign(:title, nil)
        |> assign(:description, nil)
      end

    {:noreply, socket}
  end

  def handle_event("download", params, socket) do
    # https://www.youtube.com/watch?v=BaW_jenozK

    url = params |> Map.get("url")

    Task.async(fn ->
      Exyt.download_getting_filename(url)
    end)

    {:noreply, socket}
  end

  def get_data(url) do
    {:ok, title} = Exyt.get_title(url)
    {:ok, description} = Exyt.get_description(url)

    %{
      "title" => title,
      "description" => description,
      "valid_url" => true,
      "url" => url,
      "loading" => false
    }
  end

  def handle_info(
        {ref,
         %{
           "description" => desc,
           "loading" => loading,
           "title" => title,
           "url" => url,
           "valid_url" => valid_url
         }},
        socket
      ) do
    Process.demonitor(ref, [:flush])

    socket =
      socket
      |> assign(:title, title)
      |> assign(:description, desc)
      |> assign(:valid_url, valid_url)
      |> assign(:url, url)
      |> assign(:loading, loading)

    {:noreply, socket}
  end

  def handle_info({ref, {:ok, path}}, socket) do
    Process.demonitor(ref, [:flush])

    final_url =
      path
      |> Base.encode64()

    {:noreply, assign(socket, :final_url, final_url)}
  end

  def handle_params(_params, url, socket) do
    {:noreply, push_event(socket, "download", %{data: url})}
  end
end
