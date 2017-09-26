defmodule FrequencySup do
  use Supervisor

  # Client API

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def stop() do
    Supervisor.stop(__MODULE__)
  end

  # Server Callbacks

  def init(_arg) do
    Supervisor.init([FreqOverload, Frequency], strategy: :rest_for_one, max_restarts: 2, max_seconds: 3)
  end
end

