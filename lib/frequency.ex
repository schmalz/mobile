defmodule Frequency do
  use GenServer

  @moduledoc """
  Maintain a list of available radio frequencies and any associations between process identifiers and their
  allocated frequencies.
  """

  @initial_allocations []
  @initial_frequencies [10, 11, 12, 13, 14, 15]

  # Client API

  def start_link(_arg) do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def allocate() do
    GenServer.call(__MODULE__, {:allocate, self()})
  end

  def deallocate(frequency) do
    GenServer.cast(__MODULE__, {:deallocate, frequency})
  end

  # Server Callbacks

  def init(_args) do
    {:ok, {@initial_frequencies, @initial_allocations}}
  end

  def handle_call({:allocate, pid}, _from, frequencies) do
    {new_frequencies, reply} = allocate_frequency(frequencies, pid)
    {:reply, reply, new_frequencies}
  end

  def handle_cast({:deallocate, frequency}, frequencies) do
    {:noreply, deallocate_frequency(frequencies, frequency)}
  end

  # Private Functions

  defp allocate_frequency({[], _allocated} = frequencies, _pid) do
    FreqOverload.frequency_denied()
    {frequencies, {:error, :no_frequency}}
  end
  defp allocate_frequency({[frequency | free], allocated}, pid) do
    case free do
      [] -> FreqOverload.no_frequency()
      _ -> :ok
    end
    {{free, [{frequency, pid} | allocated]}, {:ok, frequency}}
  end

  defp deallocate_frequency({free, allocated}, frequency) do
    case free do
      [] -> FreqOverload.frequency_available()
      _ -> :ok
    end
    {[frequency | free], List.keydelete(allocated, frequency, 0)}
  end
end

