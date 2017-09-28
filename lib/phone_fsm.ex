defmodule PhoneFSM do
  @behaviour :gen_statem

  @moduledoc """
  A mobile 'phone controller.
  """

  # Client API

  def start_link(ms), do: :gen_statem.start_link(__MODULE__, ms, [])

  def stop(ms_id), do: :gen_statem.stop(ms_id)

  @doc """
  Perform an action on behalf of the 'phone connected to this controller.
  """
  def action({:outbound, _to_ms} = event, ms_id), do: :gen_statem.call(ms_id, event)
  def action(event, ms_id), do: :gen_statem.cast(ms_id, {:action, event})

  @doc """
  Send a `busy` event to another controller (`ms_id`).
  """
  def busy(ms_id), do: :gen_statem.cast(ms_id, {:busy, self()})

  @doc """
  Send a `reject` event to another controller (`ms_id`).
  """
  def reject(ms_id), do: :gen_statem.cast(ms_id, {:reject, self()})

  @doc """
  Send an `accept` event to another controller (`ms_id`).
  """
  def accept(ms_id), do: :gen_statem.cast(ms_id, {:accept, self()})

  @doc """
  Send a `hangup` event to another controller (`ms_id`).
  """
  def hangup(ms_id), do: :gen_statem.cast(ms_id, {:hangup, self()})

  @doc """
  Send an `inbound` event to another controller (`ms_id`).
  """
  def inbound(ms_id), do: :gen_statem.cast(ms_id, {:inbound, self()})

  # Server Callbacks

  def callback_mode, do: :state_functions

  def init(ms) do
    HLR.attach(ms)
    {:ok, :idle, ms} 
  end

  def terminate(_reason, _state, _data), do: HLR.detach()

  @doc """
  Idle state functions.
  """
  def idle({:call, from}, {:outbound, to_ms}, ms) do
    case HLR.lookup_id(to_ms) do # Lookup the other 'phone controller's id.
      {:error, :invalid} ->
        IO.puts("ERROR, INVALID")
        Phone.reply(:invalid, to_ms, ms)
        {:next_state, :idle, ms, [{:reply, from, {:error, :invalid}}]}
      {:ok, to_ms_id} when is_pid(to_ms_id)->
        Phone.reply(:outbound, to_ms, ms)
        PhoneFSM.inbound(to_ms_id)
        {:next_state, :calling, {ms, to_ms_id}, [{:reply, from, :ok}]}
    end
  end
  def idle(:cast, {:inbound, from_ms_id}, ms) do
    Phone.reply(:inbound, from_ms_id, ms)
    {:next_state, :receiving, {ms, from_ms_id}}
  end
  def idle(:cast, event, data) do
    IO.puts("#{inspect(self())} in idle, data #{inspect(data)}, #{inspect(event)} ignored")
    {:next_state, :idle, data}
  end

  @doc """
  Calling state functions.
  """
  def calling({:call, from}, {:outbound, _to_ms}, ms) do
    {:next_state, :calling, ms, [{:reply, from, {:error, :busy}}]}
  end
  def calling(:cast, {:action, :hangup}, {ms, other_ms_id}) do
    PhoneFSM.hangup(other_ms_id)
    {:next_state, :idle, ms}
  end
  def calling(:cast, {:busy, other_ms_id}, {ms, other_ms_id}) do
    Phone.reply(:busy, other_ms_id, ms)
    {:next_state, :idle, ms}
  end
  def calling(:cast, {:reject, other_ms_id}, {ms, other_ms_id}) do
    Phone.reply(:reject, other_ms_id, ms)
    {:next_state, :idle, ms}
  end
  def calling(:cast, {:accept, other_ms_id}, {ms, other_ms_id}) do
    case Frequency.allocate() do
      {:error, :no_frequency} ->
        PhoneFSM.reject(other_ms_id)
        Phone.reply(:reject, other_ms_id, ms)
        {:next_state, :idle, ms}
      {:ok, frequency} ->
        Phone.reply(:connected, other_ms_id, ms)
        {:next_state, :connected, {ms, other_ms_id, frequency}}
    end
  end
  def calling(:cast, {:inbound, other_ms_id}, data) do
    PhoneFSM.busy(other_ms_id)
    {:next_state, :calling, data}
  end
  def calling(:cast, event, data) do
    IO.puts("#{inspect(self())} in calling, data #{inspect(data)}, #{inspect(event)} ignored")
    {:next_state, :calling, data}
  end

  @doc """
  Connected state functions.
  """
  def connected({:call, from}, {:outbound, _to_ms}, ms) do
    {:next_state, :connected, ms, [{:reply, from, {:error, :busy}}]}
  end
  def connected(:cast, {:inbound, other_ms_id}, data) do
    PhoneFSM.busy(other_ms_id)
    {:next_state, :connected, data}
  end
  def connected(:cast, {:action, :hangup}, {ms, other_ms_id, frequency}) do
    PhoneFSM.hangup(other_ms_id)
    Frequency.deallocate(frequency)
    {:next_state, :idle, ms}
  end
  def connected(:cast, {:action, :hangup}, {ms, other_ms_id}) do
    PhoneFSM.hangup(other_ms_id)
    {:next_state, :idle, ms}
  end
  def connected(:cast, {:hangup, other_ms_id}, {ms, other_ms_id, frequency}) do
    Phone.reply(:hangup, other_ms_id, ms)
    Frequency.deallocate(frequency)
    {:next_state, :idle, ms}
  end
  def connected(:cast, {:hangup, other_ms_id}, {ms, other_ms_id}) do
    Phone.reply(:hangup, other_ms_id, ms)
    {:next_state, :idle, ms}
  end
  def connected(:cast, event, data) do
    IO.puts("#{inspect(self())} in connected, data #{inspect(data)}, #{inspect(event)} ignored")
    {:next_state, :connected, data}
  end

  @doc """
  Receiving state functions.
  """
  def receiving({:call, from}, {:outbound, _to_ms}, ms) do
    {:next_state, :receiving, ms, [{:reply, from, {:error, :busy}}]}
  end
  def receiving(:cast, {:action, :accept}, {_ms, other_ms_id} = data) do
    PhoneFSM.accept(other_ms_id)
    {:next_state, :connected, data}
  end
  def receiving(:cast, {:action, :reject}, {ms, other_ms_id}) do
    PhoneFSM.reject(other_ms_id)
    {:next_state, :idle, ms}
  end
  def receiving(:cast, {:hangup, other_ms_id}, {ms, other_ms_id}) do
    Phone.reply(:hangup, other_ms_id, ms)
    {:next_state, :idle, ms}
  end
  def receiving(:cast, {:inbound, other_ms_id}, data) do
    PhoneFSM.busy(other_ms_id)
    {:next_state, :receiving, data}
  end
  def receiving(:cast, event, data) do
    IO.puts("#{inspect(self())} in receiving, data #{inspect(data)}, #{inspect(event)} ignored")
    {:next_state, :receiving, data}
  end
end

