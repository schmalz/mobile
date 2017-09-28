defmodule PhoneSup do
  use Supervisor

  # Client API

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def attach_phone(ms) do
    case HLR.lookup_id(ms) do
      {:ok, _pid} -> {:error, :attached}
      _ -> Supervisor.start_child(__MODULE__, [ms])
    end
  end

  def detach_phone(ms) do
    case HLR.lookup_id(ms) do
      {:ok, pid} -> Supervisor.terminate_child(__MODULE__, pid)
      _ -> {:error, :detached}
    end
  end

  # Server Callbacks

  def init(_arg) do
    HLR.new()
    child = worker(PhoneFSM, [], restart: :transient, shutdown: 2_000)
    Supervisor.init([child], strategy: :simple_one_for_one, max_restarts: 10, max_seconds: 3_600)
  end
end

