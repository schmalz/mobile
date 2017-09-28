defmodule FreqOverload do
  use Supervisor

  @moduledoc """
  The event manager for frequency overload events. This is implemented as a `Supervisor` following the pattern
  outlined in http://blog.plataformatec.com.br/2016/11/replacing-genevent-by-a-supervisor-genserver/.
  """

  # Client API

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def stop() do
    for {_, pid, _, _} <- Supervisor.which_children(__MODULE__) do
      GenServer.stop(pid)
    end
    Supervisor.stop(__MODULE__)
  end

  def no_frequency(), do: notify({:set_alarm, {:no_frequency, self()}})

  def frequency_available(), do: notify({:clear_alarm, :no_frequency})

  def frequency_denied(), do: notify({:event, {:frequency_denied, self()}})

  def add_handler(handler, args) do
    Supervisor.start_child(__MODULE__, [handler, args])
  end

  # Server Callbacks

  def init(_arg) do
    child = worker(GenServer, [], restart: :temporary)
    Supervisor.init([child], strategy: :simple_one_for_one)
  end

  # Private Functions

  defp notify(event) do
    for {_, pid, _, _} <- Supervisor.which_children(__MODULE__) do
      GenServer.cast(pid, event)
    end
    :ok
  end
end

