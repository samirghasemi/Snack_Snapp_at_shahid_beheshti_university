defmodule Arango.Ecto.Adapter do
  # @impl true
  def dumpers({:map, _}, type),        do: [&Arango.Ecto.Type.embedded_dump(type, &1, :json)]
  def dumpers({:in, sub}, {:in, sub}), do: [{:array, sub}]
  def dumpers(:binary_id, type),       do: [type, Ecto.UUID]
  def dumpers(_, type),                do: [type]

  # @impl true
  def loaders({:map, _}, type),   do: [&Arango.Ecto.Type.embedded_load(type, &1, :json)]
  def loaders(:binary_id, type),  do: [Ecto.UUID, type]
  def loaders(_, type),           do: [type]
end
