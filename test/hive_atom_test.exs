defmodule HiveAtomTest do
  use ExUnit.Case, async: true

  setup do
    {
      :ok,
      atom: %HiveAtom{
        application: "test_app",
        context: "test_context",
        process: "test_process",
        data: ~s({"hello":"world"}),
        id: 1,
        created_at: "2018-11-13T15:01:00.378449",
        updated_at: "2018-11-13T15:01:22.072457"
      },
      atom_map: %{
        "application" => "test_app",
        "context" => "test_context",
        "process" => "test_process",
        "data" => ~s({"hello":"world"}),
        "id" => 1,
        "created_at" => "2018-11-13T15:01:00.378449",
        "updated_at" => "2018-11-13T15:01:22.072457"
      },
      atom_map_atom_keys: %{
        :application => "test_app",
        :context => "test_context",
        :process => "test_process",
        :data => ~s({"hello":"world"}),
        :id => 1,
        :created_at => "2018-11-13T15:01:00.378449",
        :updated_at => "2018-11-13T15:01:22.072457"
      }
    }
  end

  describe "atoms" do
    test "getting the triplet", %{atom: atom} do
      expected_triplet = {"test_app", "test_context", "test_process"}
      assert HiveAtom.triplet(atom) == expected_triplet
    end

    test "getting the data map as a map", %{atom: atom} do
      expected_map = %{"hello" => "world"}
      assert HiveAtom.data_map(atom) == expected_map
    end

    test "converting a map to an atom", %{atom: atom, atom_map: atom_map} do
      assert HiveAtom.from_map(atom_map) == atom
    end

    test "converting a map with atom keys to an atom",
         %{atom: atom, atom_map_atom_keys: atom_map_atom_keys} do
      assert HiveAtom.from_map(atom_map_atom_keys) == atom
    end

    test "creation date", %{atom: atom} do
      assert ~N[2018-11-13 15:01:00.378449] = HiveAtom.created_at(atom)
    end

    test "updated date", %{atom: atom} do
      assert ~N[2018-11-13 15:01:22.072457] = HiveAtom.updated_at(atom)
    end

    test "date comparison", %{atom: atom} do
      assert :lt = NaiveDateTime.compare(HiveAtom.created_at(atom), HiveAtom.updated_at(atom))
    end
  end
end
