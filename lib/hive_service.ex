defmodule HiveService do
  @moduledoc """
  Utilities for posting + retrieving atoms from
  EXPLO's [HIVE](https://bitbucket.org/explo/hive-2) service.
  """

  require Logger

  @doc """
  Deletes a HiveAtom from HIVE permanently.  
  """
  @spec delete_atom(integer()) :: map()
  def delete_atom(atom_id) do
    if debug_mode?() do
      debug(:delete, atom_id)
    else
      body = URI.encode_query(%{token: api_token()})
      endpoint = "#{api_url()}/atoms/#{atom_id}"

      delete(endpoint, body)
    end
  end

  @doc """
  Un-mark a given atom as having been received by `application`. 
  """
  @spec delete_receipt(integer(), String.t()) :: HiveAtom.t()
  def delete_receipt(atom_id, application) do
    if debug_mode?() do
      debug(:delete_receipt, {application, atom_id})
    else
      body = URI.encode_query(%{token: api_token()})
      endpoint = "#{api_url()}/atoms/#{atom_id}/receipts/#{application}"

      delete(endpoint, body)
      |> convert_maps_to_hiveatoms()
    end
  end


  @doc """
  Given an atom ID, return the atom from HIVE
  """
  @spec get_atom(integer()) :: map()
  def get_atom(atom_id) do
    endpoint = "#{api_url()}/atoms/#{atom_id}?#{URI.encode_query(%{token: api_token()})}"

    get(endpoint)
  end

  @doc """
  Get unseen atoms from HIVE by triplet.

  This variant of get_unseen_atoms is handy when you've already got a
  %HiveAtom{} struct and thus can use the HiveAtom.triplet() function to
  extract its triplet.

  See `HiveService.get_unseen_atoms/3` for more details about the usage of this
  function in general.
  """
  @spec get_unseen_atoms(String.t(), HiveAtom.triplet()) :: [HiveAtom.t()]
  def get_unseen_atoms(receipts, {application, context, process}) do
    get_unseen_atoms(receipts, application, context, process)
  end

  @spec get_unseen_atoms(String.t(), String.t()) :: [HiveAtom.t()]
  def get_unseen_atoms(receipts, application) do
    get_unseen_atoms(receipts, application, nil, nil)
  end

  @spec get_unseen_atoms(String.t(), String.t(), String.t()) :: [HiveAtom.t()]
  def get_unseen_atoms(receipts, application, context) do
    get_unseen_atoms(receipts, application, context, nil)
  end

  @doc """
  Search HIVE for atoms not seen by the `receipts` application.

  You can pass only an `application` to match, or optionally include `context`
  and/or `process`.
  """
  @spec get_unseen_atoms(
          String.t() | nil,
          String.t() | nil,
          String.t() | nil,
          String.t() | nil
        ) :: [HiveAtom.t()]
  def get_unseen_atoms(receipts, application, context, process) do
    params = %{
      token: api_token(),
      receipts: receipts,
      application: application
    }

    params = put_if_not_nil(params, :context, context)
    params = put_if_not_nil(params, :process, process)

    body = URI.encode_query(params)
    endpoint = "#{api_url()}/atom_search"

    post(endpoint, body)
  end

  @doc """
  Check for a valid API token. 

  We can use the presence of a token in the environment to determine whether
  automated tests hit an external API.
  """
  def has_token? do
    String.valid?(api_token())
  end

  @doc """
  Add a HiveAtom to HIVE
  """
  @spec post_atom(String.t(), String.t(), String.t(), String.t()) :: HiveAtom.t()
  def post_atom(application, context, process, data) when is_binary(data) do
    params = %{
      token: api_token(),
      application: application,
      context: context,
      process: process,
      data: data
    }

    if debug_mode?() do
      debug(:post, params)
    else
      body = URI.encode_query(params)
      endpoint = "#{api_url()}/atoms"

      post(endpoint, body)
    end
  end

  @spec post_atom(String.t(), String.t(), String.t(), map()) :: HiveAtom.t()
  def post_atom(application, context, process, data) when is_map(data) do
    with {:ok, bin} <- Jason.encode(data) do
      post_atom(application, context, process, bin)
    else
      _ -> 
        Logger.warn("HIVE Service: Failed to encode data for {#{application}, #{context}, #{process}, #{inspect data}}")
    end
  end

  @doc """
  Mark a given atom as having been received by `application`. 

  This is how you can get a list of "unseen" atoms - you mark every atom that
  you've processed as "received".
  """
  @spec put_receipt(integer(), String.t()) :: HiveAtom.t()
  def put_receipt(atom_id, application) do
    body =
      URI.encode_query(%{
        token: api_token(),
        application: application
      })

    endpoint = "#{api_url()}/atoms/#{atom_id}/receipts"

    post(endpoint, body)
  end

  defp put_if_not_nil(map, key, value) when is_map(map) do
    case value do
      nil -> map
      _ -> Map.put(map, key, value)
    end
  end

  defp api_token do
    Application.get_env(:hive_service, :hive_api_token)
  end

  defp api_url do
    Application.get_env(:hive_service, :hive_api_url, "https://hive.explo.org")
  end

  defp convert_maps_to_hiveatoms(map_list) when is_list(map_list) do
    map_list |> Enum.map(&convert_maps_to_hiveatoms/1)
  end

  defp convert_maps_to_hiveatoms(map) when is_map(map) do
    HiveAtom.from_map(map)
  end

  defp debug(mode, body) do
    IO.puts "HIVE Service DEBUG (#{mode}): #{inspect body}"
  end

  defp debug_mode? do
    Application.get_env(:hive_service, :debug_mode, false)
  end

  defp delete(endpoint, body) do
    :delete
    |> HTTPoison.request!(endpoint, body, headers())
    |> run_unless_auth_error(fn response ->
      Jason.decode!(response.body)
    end)
  end

  defp headers() do
    [
      {"User-Agent", "EXPLO HiveService"},
      {"Content-Type", "application/x-www-form-urlencoded"}
    ]
  end

  defp get(endpoint) do
    HTTPoison.get!(endpoint, headers())
    |> run_unless_auth_error(fn response ->
      Jason.decode!(response.body)
    end)
  end

  defp post(endpoint, body) do
    endpoint
    |> HTTPoison.post!(body, headers())
    |> run_unless_auth_error(fn response ->
      IO.puts(response.body)
      response.body
      |> Jason.decode!()
      |> convert_maps_to_hiveatoms()
    end)
  end

  defp run_unless_auth_error(response, fun) do
    case response.status_code == 401 or
           response.body
           |> String.downcase()
           |> String.contains?("unauthorized") do
      true -> {:error, :authentication}
      false -> fun.(response)
    end
  end
end
