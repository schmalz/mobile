defmodule FrequencySup do
  use Supervisor

  # Client API

  def start_link() do
    {:ok, pid} = Supervisor.start_link(__MODULE__, [], name: __MODULE__)
    FreqOverload.add_handler(Counters, {})
    FreqOverload.add_handler(FileLogger, {:file, "log"})
    {:ok, pid}
  end

  def stop() do
    Supervisor.stop(__MODULE__)
  end

  # Server Callbacks

  def init(_arg) do
    Supervisor.init([FreqOverload, Frequency], strategy: :rest_for_one, max_restarts: 2, max_seconds: 3600)
  end
end

