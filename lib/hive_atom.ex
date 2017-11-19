defmodule HiveAtom do
  
  @moduledoc """
  This is both a data representation (struct) for a HIVE Atom, and also some
  convenience methods to work with HIVE Atoms.

  Note that in HIVE parlance, they're just called atoms, but in Elixir this can
  create some confusion, hence us always referring to them as `HiveAtom` in
  this code.
  """ 


  ### STRUCTS ###

  defstruct [
    :application, :context, :process,
    :data,
    :receipts,
    :id,
    :created_at, :updated_at
  ]

  @typedoc "A Hive ATOM"
  @type t :: %__MODULE__{
    application: String.t(),
    context: String.t(),
    process: String.t(),
    data: String.t(),
    receipts: String.t() | nil,
    id: integer() | nil,
    created_at: String.t() | nil,
    updated_at: String.t() | nil
  }

  @typedoc """
  A "triplet" is a fundamental unit of a HIVE Atom: it is the application,
  context, and process that created the atom.
  
  For example, an atom created by Portico, where a user is updated might have
  the triplet signature `{"portico", "user", "update"}`.
  """
  @type triplet :: {String.t(), String.t(), String.t()}


  ### FUNCTIONS ###
  
  @doc """
  Return a given HiveAtom's data, as a `Map`.

  In the event of decode error, return an empty map.
  """
  @spec data_map(HiveAtom.t()) :: Poison.Parser.t() | no_return() | map()
  def data_map(atom = %HiveAtom{}) do
    try do
      Poison.decode!(atom.data)
    rescue
      _ -> %{}
    end
  end

  @doc """
  Convert an Elixir map into a HiveAtom, as best as is possible. Any fields
  that aren't in the `%HiveAtom{}` struct will be ignored.

  Returns a `%HiveAtom{}` struct.
  """
  @spec from_map(map()) :: HiveAtom.t()
  def from_map(atom_map) when is_map(atom_map) do
    %HiveAtom{
      application: key_variants(atom_map, :application),
      context: key_variants(atom_map, :context),
      process: key_variants(atom_map, :process),
      data: key_variants(atom_map, :data),
      receipts: key_variants(atom_map, :receipts),
      id: key_variants(atom_map, :id),
      created_at: key_variants(atom_map, :created_at),
      updated_at: key_variants(atom_map, :updated_at)
    }
  end

  @doc """
  When working with HiveAtoms, we often refer to the "triplet", which is the
  combination of `application`, `context`, and `process` that uniquely
  identifies the source of the atom. It's handy to be able to grab those
  triplets quickly.

  This function returns a triplet (see the triplet() type above)
  """
  @spec triplet(HiveAtom.t()) :: triplet()
  def triplet(atom = %HiveAtom{}) do
    {atom.application, atom.context, atom.process}
  end
  


  # Return a map value regardless of whether it's passed as an atom or a
  # string.
  defp key_variants(map, key) when is_atom(key) do
    Map.get(map, key) || Map.get(map, Atom.to_string(key)) 
  end
end

