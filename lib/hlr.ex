defmodule HLR do

  @moduledoc """
  A Home Location Register (HLR). Maintain the associations between Mobile Subscriber Integrated Services Digital
  Network (MSISDN) 'phone numbers and their corresponding 'phone controller process identifiers (PIDs).
  """

  def new() do
    :ets.new(:msisdn_pid, [:public, :named_table])
    :ets.new(:pid_msisdn, [:public, :named_table])
    :ok
  end

  @doc """
  Associate an MSISDN number, `ms`, with the current process. This code runs in the controller.
  """
  def attach(ms) do
    ms_id = self()
    :ets.insert(:msisdn_pid, {ms, ms_id})
    :ets.insert(:pid_msisdn, {ms_id, ms})
  end

  @doc """
  Disassociate the current process from its MSISDN number.
  """
  def detach() do
    case :ets.lookup(:pid_msisdn, self()) do
      [{pid, ms}] ->
        :ets.delete(:pid_msisdn, pid)
        :ets.delete(:msisdn_pid, ms)
      [] ->
        :ok
    end
  end

  @doc """
  Lookup the controller PID associated with an MSISDN `ms`.
  """
  def lookup_id(ms) do
    case :ets.lookup(:msisdn_pid, ms) do
      [{^ms, pid}] ->
        {:ok, pid}
      _ ->
        {:error, :invalid}
    end
  end

  @doc """
  Lookup the MSISDN associated with a controller PID.
  """
  def lookup_ms(pid) do
    case :ets.lookup(:pid_msisdn, pid) do
      [{^pid, ms}] ->
        {:ok, ms}
      _ ->
        {:error, :invalid}
    end
  end
end

