defmodule HiveService do

  @moduledoc """
  HiveService is a group of utilities for posting + retrieving atoms from
  EXPLO's [HIVE](https://bitbucket.org/explo/hive-2) service.
  """

  @doc """
  Deletes a HiveAtom from HIVE permanently.  
  """
  def delete_atom(atom_id) do
    body = URI.encode_query %{token: api_token()}
    endpoint = "#{api_url()}/atoms/#{atom_id}"

    delete(endpoint, body)
  end

  @doc """
  This variant of get_unseen_atoms is handy when you've already got a
  %HiveAtom{} struct and thus can use the HiveAtom.triplet() function to
  extract its triplet.

  See `HiveService.get_unseen_atoms/3` for more details about the usage of this
  function in general.
  """ 
  def get_unseen_atoms(receipts, {application, context, process}) do
    get_unseen_atoms(receipts, application, context, process)
  end
  def get_unseen_atoms(receipts, application) do
    get_unseen_atoms(receipts, application, nil, nil)
  end
  def get_unseen_atoms(receipts, application, context) do
    get_unseen_atoms(receipts, application, context, nil)
  end
  @doc """
  This is a HIVE search, which should return a list of HiveAtoms that are
  unseen by the given `receipts`, or receiving application. You can pass only
  an `application` to match, or optionally include `context` and/or `process`.
  """
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
  Add a HiveAtom to HIVE
  """
  def post_atom(application, context, process, data) do
    body = URI.encode_query %{
      token: api_token(),
      application: application,
      context: context,
      process: process,
      data: data
    }

    endpoint = "#{api_url()}/atoms"

    post(endpoint, body)
  end

  @doc """
  Mark a given atom as having been received by `application`. This is how you
  can get a list of "unseen" atoms - you mark every atom that you've processed
  as "received".
  """
  def put_receipt(atom_id, application) do
    body = URI.encode_query %{
      token: api_token(),
      application: application
    }
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
    System.get_env("HIVE_API_TOKEN") ||
    Application.get_env(:hive_service, :hive_api_token)
  end

  defp api_url do
    System.get_env("HIVE_API_URL") ||
    Application.get_env(:hive_service, :hive_api_url) ||
    "https://hive.explo.org"
  end

  defp convert_maps_to_hiveatoms(map_list) when is_list(map_list) do
    map_list |> Enum.map(&HiveAtom.from_map/1)
  end
  defp convert_maps_to_hiveatoms(map) when is_map(map) do
    HiveAtom.from_map(map)
  end

  defp run_unless_auth_error(response, fun) do
    case response.status_code == 401 or
          response.body 
          |> String.downcase 
          |> String.contains?("unauthorized") do
      true -> {:error, :authentication}
      false -> fun.(response)
    end
  end

  defp delete(endpoint, body) do
    HTTPoison.request!(:delete, endpoint, body, headers())
    |> run_unless_auth_error(fn response ->
        Poison.decode!(response.body)
      end)
  end

  defp headers do
    [
      "User-Agent": "EXPLO HiveService",
      "Content-Type": "application/x-www-form-urlencoded"
    ]
  end

  defp post(endpoint, body) do
    HTTPoison.post!(endpoint, body, headers())
    |> run_unless_auth_error(fn response ->
        Poison.decode!(response.body)
        |> convert_maps_to_hiveatoms()
      end)
  end

end

