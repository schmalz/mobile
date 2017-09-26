defmodule FileLogger do
  use GenServer

  @moduledoc """
  A logger that logs to either a file or standard I/O (depending on the initialisation argument).
  """

  # Server Callbacks

  @doc """
  Initialise the logger, either with `:standard_IO` or the path to a file.
  """
  def init(:standard_io), do: {:ok, {:standard_io, 1}}
  def init({:file, path}) do
    {:ok, fd} = File.open(path, [:append, :utf8])
    {:ok, {fd, 1}}
  end
  def init(args), do: {:error, {:args, args}}

  @doc """
  Handle `event`.
  """
  def handle_cast(event, {fd, count}) do
    print(fd, count, event, "event")
    {:noreply, {fd, count + 1}}
  end

  @doc """
  Terminate the logger, closing any associated resources.
  """
  def terminate(_reason, {:standard_io, count}), do: {:count, count}
  def terminate(_reason, {fd, count}) do
    File.close(fd)
    {:count, count}
  end

  # Private functions

  defp print(fd, count, event, tag) do
    IO.puts(fd, "#{now_string()} - #{count_string(count)} - #{tag}: #{inspect(event)}")
  end

  defp now_string(), do: DateTime.to_string(DateTime.utc_now())

  defp count_string(count), do: String.pad_leading(Integer.to_string(count), 5)
end

