defmodule Mobile do
  use Application

  def start(_type, _args) do
    BscSup.start_link()
  end
end
