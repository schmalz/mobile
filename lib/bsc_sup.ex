defmodule BscSup do
  use Supervisor

  @file_logger_path Application.get_env(:mobile, :bsc_sup_file_logger_path)

  # Client API

  def start_link() do
    {:ok, pid} = Supervisor.start_link(__MODULE__, [], name: __MODULE__)
    FreqOverload.add_handler(Counters, {})
    FreqOverload.add_handler(FileLogger, {:file, @file_logger_path})
    {:ok, pid}
  end

  # Server Callbacks

  def init(_arg) do
    Supervisor.init([FreqOverload, Frequency, PhoneSup], strategy: :rest_for_one, max_restarts: 2, max_seconds: 3_600)
  end
end

