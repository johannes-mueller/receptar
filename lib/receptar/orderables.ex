defmodule Receptar.Orderables do

  def append(orderables, new_item) do
    new_number = length(orderables) + 1
    {new_number,
     [Map.put(new_item, :number, new_number) | orderables]
     |> Enum.sort(& &1.number < &2.number)
    }
  end

  def insert_before(orderables, new_item, target_item) do
    number = target_item.number
    orderables =
      orderables
      |> Enum.map(fn
      o when o.number < number -> o
      o -> %{o | number: o.number + 1}
    end)

    {number,
     [Map.put(new_item, :number, number) | orderables]
     |> Enum.sort(& &1.number < &2.number)
    }
  end

  def delete(orderables, target) do
    orderables
    |> Enum.filter(& &1.number != target.number)
    |> Enum.map(fn
      o when o.number > target.number -> %{o | number: o.number - 1}
      o -> o
    end)
    |> Enum.sort(& &1.number < &2.number)
  end

  def replace(orderables, new_item) do
    orderables
    |> Enum.map(fn
      o when o.number == new_item.number -> new_item
      o -> o
    end)
    |> Enum.sort(& &1.number < &2.number)
  end

  def is_pullable(_orderables, item) do
    item.number != 1
  end

  def is_pushable(orderables, item) do
    item.number < length(orderables)
  end

  def pull(orderables, number) when number == 1 do
    orderables
    |> Enum.sort(& &1.number < &2.number)
  end

  def pull(orderables, number) do
    orderables
    |> Enum.map(fn
      o when o.number == number -> %{o | number: o.number - 1}
      o when o.number == number - 1 -> %{o | number: o.number + 1}
      o -> o
    end)
    |> Enum.sort(& &1.number < &2.number)
  end

  def push(orderables, number) when number >= length(orderables) do
    orderables
    |> Enum.sort(& &1.number < &2.number)
  end

  def push(orderables, number) do
    orderables
    |> Enum.map(fn
      o when o.number == number -> %{o | number: o.number + 1}
      o when o.number == number + 1 -> %{o | number: o.number - 1}
      o -> o
    end)
    |> Enum.sort(& &1.number < &2.number)
  end
end
