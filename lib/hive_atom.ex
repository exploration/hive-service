defmodule HiveAtom do
  
  @moduledoc """
  This is both a data representation (struct) for a HIVE Atom, and also some
  convenience methods to work with HIVE Atoms.

  Note that in HIVE parlance, they're just called atoms, but in Elixir this can
  create some confusion, hence us always referring to them as `HiveAtom` in
  this code.
  """ 

  defstruct [
    :application, :context, :process,
    :data,
    :receipts,
    :id, :created_at, :updated_at
  ]

  @doc """
  Return a given HiveAtom's data, as a `Map`.

  In the event of decode error, return an empty map.
  """
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

  # Return a map value regardless of whether it's passed as an atom or a
  # string.
  defp key_variants(map, key) when is_atom(key) do
    Map.get(map, key) || Map.get(map, Atom.to_string(key)) 
  end

  @doc """
  When working with HiveAtoms, we often refer to the "triplet", which is the
  combination of `application`, `context`, and `process` that uniquely
  identifies the source of the atom. It's handy to be able to grab those
  triplets quickly.

  This function returns a 3-tuple: `{application, context, process}`
  """
  def triplet(atom = %HiveAtom{}) do
    {atom.application, atom.context, atom.process}
  end
end

