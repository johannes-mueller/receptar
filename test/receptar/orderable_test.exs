defmodule Receptar.OrderableTest do
  use ExUnit.Case

  alias Receptar.Orderables

  describe "orderables" do
    setup do
      %{orderables: [
	   %{number: 1, foo: 'a'},
	   %{number: 3, foo: 'b'},
	   %{number: 2, foo: 'c'}
	 ]}
    end

    test "append to empty list" do
      assert {1, [%{number: 1, foo: 'x'}]} = [] |> Orderables.append(%{foo: 'x'})
    end

    test "append orderable", %{orderables: orderables} do
      assert {
	4, [
	  %{number: 1, foo: 'a'},
	  %{number: 2, foo: 'c'},
	  %{number: 3, foo: 'b'},
	  %{number: 4, foo: 'x'},
	]} = Orderables.append(orderables, %{foo: 'x'})
    end

    test "append orderable twice", %{orderables: orderables} do
      {_number, orderables} = Orderables.append(orderables, %{foo: 'x'})
      assert {
	5, [
	  %{number: 1, foo: 'a'},
	  %{number: 2, foo: 'c'},
	  %{number: 3, foo: 'b'},
	  %{number: 4, foo: 'x'},
	  %{number: 5, foo: 'y'},
	]} = Orderables.append(orderables, %{foo: 'y'})
    end

    test "prepend orderable", %{orderables: orderables} do
      assert {
	1, [
	  %{number: 1, foo: 'x'},
	  %{number: 2, foo: 'a'},
	  %{number: 3, foo: 'c'},
	  %{number: 4, foo: 'b'},
	]} = Orderables.insert_before(orderables, %{foo: 'x'}, Enum.at(orderables, 0))
    end

    test "insert orderable", %{orderables: orderables} do
      assert {
	2, [
	  %{number: 1, foo: 'a'},
	  %{number: 2, foo: 'x'},
	  %{number: 3, foo: 'c'},
	  %{number: 4, foo: 'b'},
	]} = Orderables.insert_before(orderables, %{foo: 'x'}, Enum.at(orderables, 2))
    end

    test "delete orderable at end", %{orderables: orderables} do
      assert [
	   %{number: 1, foo: 'a'},
	   %{number: 2, foo: 'c'}
      ] = orderables |> Orderables.delete(%{number: 3})
    end

    test "delete orderable before end", %{orderables: orderables} do
      assert [
	%{number: 1, foo: 'a'},
	%{number: 2, foo: 'b'}
      ] = orderables |> Orderables.delete(%{number: 2})
    end

    test "replace orderable", %{orderables: orderables} do
      assert [
	%{number: 1, foo: 'a'},
	%{number: 2, foo: 'x'},
	%{number: 3, foo: 'b'}
      ] = Orderables.replace(orderables, %{number: 2, foo: 'x'})
    end

    test "item is pullable", %{orderables: orderables} do
      assert Orderables.is_pullable(orderables, %{number: 2, foo: 'c'})
    end

    test "first item is not pullable", %{orderables: orderables} do
      refute Orderables.is_pullable(orderables, %{number: 1, foo: 'a'})
    end

    test "item is pushable", %{orderables: orderables} do
      assert Orderables.is_pushable(orderables, %{number: 2, foo: 'c'})
    end

    test "last item is not pushable", %{orderables: orderables} do
      refute Orderables.is_pushable(orderables, %{number: 3, foo: 'b'})
    end

    test "pull last item", %{orderables: orderables} do
      assert [
	%{number: 1, foo: 'a'},
	%{number: 2, foo: 'b'},
	%{number: 3, foo: 'c'}
      ] = orderables |> Orderables.pull(%{number: 3, foo: 'b'})
    end

    test "pull first item does not change", %{orderables: orderables} do
      assert [
	%{number: 1, foo: 'a'},
	%{number: 2, foo: 'c'},
	%{number: 3, foo: 'b'},
      ] = orderables |> Orderables.pull(%{number: 1, foo: 'a'})
    end

    test "push first item", %{orderables: orderables} do
      assert [
	%{number: 1, foo: 'c'},
	%{number: 2, foo: 'a'},
	%{number: 3, foo: 'b'},
      ] = orderables |> Orderables.push(%{number: 1, foo: 'a'})
    end

    test "push last item does not change", %{orderables: orderables} do
      assert [
	%{number: 1, foo: 'a'},
	%{number: 2, foo: 'c'},
	%{number: 3, foo: 'b'},
      ] = orderables |> Orderables.push(%{number: 3, foo: 'b'})
    end
  end

end
