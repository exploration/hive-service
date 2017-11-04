defmodule HiveServiceTest do
  use ExUnit.Case

  IO.puts "Make sure you've got your HIVE test server running!"

  setup do
    { 
      :ok,
      atom: %HiveAtom{
        application: "test_app",
        context: "test_context",
        process: "test_process",
        data: ~s({"hello":"world"}),
        id: 1
      }
    }
  end

  describe "methods" do 
    test "post, receive, delete", %{atom: atom} do
      new_atom = HiveService.post_atom(
        atom.application, atom.context, atom.process, atom.data
      )
      assert new_atom.__struct__ == HiveAtom
      assert new_atom.application == atom.application
      assert new_atom.context == atom.context
      assert new_atom.process == atom.process
      assert new_atom.data == atom.data


      received_atom = HiveService.put_receipt(new_atom.id, "test")
      assert received_atom.receipts == "test"


      delete_result = HiveService.delete_atom(new_atom.id)
      assert %{"success" => true} = delete_result
    end

    test "finding unseen atoms", %{atom: atom} do
      atoms = 
        Enum.map(1..3, fn _ ->
          HiveService.post_atom(
            atom.application, atom.context, atom.process, atom.data
          )
        end)

      find_application = HiveService.get_unseen_atoms("test", atom.application)
      app_count = Enum.count(find_application)
      assert is_list(find_application)
      assert app_count >= 3


      first_triplet_count =
        HiveService.get_unseen_atoms(
          "test", atom.application, atom.context, atom.process
        ) |> Enum.count()

      first_atom = Enum.at(atoms, 0)
      HiveService.put_receipt(first_atom.id, "test")

      second_triplet_count =
        HiveService.get_unseen_atoms(
          "test", atom.application, atom.context, atom.process
        ) |> Enum.count()

      assert second_triplet_count == first_triplet_count - 1

      # Cleanup
      Enum.each(atoms, fn a ->
        HiveService.delete_atom(a.id)
      end)
    end

  end
end

