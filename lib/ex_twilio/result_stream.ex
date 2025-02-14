defmodule ExTwilio.ResultStream do
  @moduledoc """
  Generate a stream of results for a given Twilio API URL. Pages are lazily
  loaded on demand.

  ## Example

      ExTwilio.ResultStream.new(ExTwilio.Call)
      |> Stream.map(fn call -> call.sid end)
      |> Enum.take(5)

      # => [%ExTwilio.Call{ ... }, %ExTwilio.Call{ ... }, ...]
  """

  alias ExTwilio.Api
  alias ExTwilio.Parser
  alias ExTwilio.UrlGenerator
  alias ExTwilio.Config

  @type url :: String.t()

  @doc """
  Create a new Stream.

  ## Parameters

  - `module`: The name of the module to create a Stream of results for.

  ## Example

      ExTwilio.ResultStream.new(ExTwilio.Call)
  """
  def new(module, options \\ []) do
    url = UrlGenerator.build_url(module, nil, options)
    IO.inspect url
    Stream.resource(fn -> {url, module, options} end, &process_page/1, fn _ -> nil end)
  end

  @spec fetch_page(url, module, options :: list) :: {list, {url, module, options :: list}}
####
#  defp fetch_page(url, module = ExTwilio.AvailablePhoneNumber, options) do
#    IO.puts "Shunt"
#    results = Api.get!(url, Api.auth_header(options))
#    IO.inspect results
#    {:ok, items, meta} = Parser.parse_list(results, module, module.resource_collection_name)
#    IO.inspect items
#    test = Map.get(meta, "countries")
#    test2 = for country <- test do
#                stuff = Map.get(country, "subresource_uris")
#                for local <- stuff do
#                  Map.get(stuff, "mobile")
#                end
#            end
#    IO.inspect test2
#    {[], {next_page_url(hd(test2)|> hd), module, options}}
#  end

  defp fetch_page(url, module, options) do
    results = Api.get!(url, Api.auth_header(options))
    {:ok, items, meta} = Parser.parse_list(results, module, module.resource_collection_name)
    {items, {next_page_url(meta["next_page_uri"]), module, options}}
  end

  @spec process_page({url | nil, module, options :: list}) ::
          {:halt, nil}
          | {list, {url, module}}
  defp process_page({nil, _module, _options}), do: {:halt, nil}

  defp process_page({next_page_uri, module, options}) do
    fetch_page(next_page_uri, module, options)
  end

  defp next_page_url(nil), do: nil
  defp next_page_url(uri), do: "https://#{Config.api_domain()}" <> uri
end
