defmodule Phone do

  @moduledoc """
  A mobile 'phone simulator for testing 'phone finite state machines.
  """

  def start_test(num, calls) do
    Enum.map_every(1..num, 1, &PhoneFSM.start_link/1)
    call(calls, num)
  end

  defp call(0, _), do: :ok
  defp call(x, num) do
    {:ok, from_ms_id} = HLR.lookup_id(:rand.uniform(num))
    case PhoneFSM.action({:outbound, :rand.uniform(num)}, from_ms_id) do 
      :ok -> call(x - 1, num)
      _error -> call(x, num)
    end
  end

  def reply(:outbound, to_ms_id, ms) do
    clear()
    from_ms_id = self()
    IO.puts("#{inspect(from_ms_id)} dialing #{inspect(to_ms_id)}")
    Process.put(:pid,
                spawn(fn() ->
                        :rand.seed(:exs1024)
                        :timer.sleep(:rand.uniform(3_000))
                        IO.puts("#{inspect(from_ms_id)} hanging up #{ms}")
                        PhoneFSM.action(:hangup, from_ms_id)
                      end))
  end
  def reply(:connected, other_ms_id, _ms) do
    clear()
    from_ms_id = self()
    IO.puts("#{inspect(from_ms_id)} connected to #{inspect(other_ms_id)}")
    Process.put(:pid,
                spawn(fn() ->
                        :rand.seed(:exs1024)
                        :timer.sleep(:rand.uniform(3_000))
                        IO.puts("#{inspect(from_ms_id)} hanging up #{inspect(other_ms_id)}")
                        PhoneFSM.action(:hangup, from_ms_id)
                      end))
  end
  def reply(:invalid, to_ms, ms) do
    IO.puts("#{to_ms} connecting to #{ms} failed, invalid number")
    clear()
  end
  def reply(:inbound, from_ms_id, _ms) do
    clear()
    to_ms_id = self()
    Process.put(:pid,
                spawn(fn() ->
                        :rand.seed(:exs1024)
                        :timer.sleep(:rand.uniform(1_500))
                        case :rand.uniform(2) do
                          1 ->
                            IO.puts("accept(#{inspect(to_ms_id)}, #{inspect(from_ms_id)})")
                            PhoneFSM.action(:accept, to_ms_id)
                            :timer.sleep(:rand.uniform(3_000))
                            PhoneFSM.action(:hangup, to_ms_id)
                          2 -> PhoneFSM.action(:reject, to_ms_id)
                        end
                      end))
  end
  def reply(:hangup, _from_ms_id, _ms) do
    clear()
  end
  def reply(reason, from_ms_id, ms) do
    IO.puts("#{elem(HLR.lookup_ms(from_ms_id), 1)} connecting to #{ms} failed, #{inspect(reason)}")
    clear()
  end

  defp clear() do
    case Process.get(:pid, :undefined) do
      :undefined -> :ok
      pid ->
        Process.exit(pid, :kill)
        Process.delete(:pid)
        IO.puts("#{inspect(self())} cleared")
    end
  end
end

