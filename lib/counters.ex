defmodule Counters do
  use GenServer

  @moduledoc """
  An event counter.
  """

  # Client API

  def get_counters(pid), do: GenServer.call(pid, :get_counters)

  # Server Callbacks

  @doc """
  Initialise the counter.
  """
  def init(_), do: {:ok, :ets.new(:counters, [])}

  @doc """
  Handle `event`.
  """
  def handle_cast(event, tab_id) do
    :ets.update_counter(tab_id, event, 1, {event, 0})
    {:noreply, tab_id}
  end

  @doc """
  Handle a call to obtain the current counters.
  """
  def handle_call(:get_counters, _from, tab_id), do: {:reply, {:counters, :ets.tab2list(tab_id)}, tab_id}

  @doc """
  Terminate the counter.
  """
  def terminate(_reason, tab_id) do
    counters = :ets.tab2list(tab_id)
    :ets.delete(tab_id)
    {:counters, counters}
  end
end

