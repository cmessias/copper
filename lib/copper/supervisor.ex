defmodule Copper.Supervisor do
    use Supervisor

    def start_link(opts) do
      Supervisor.start_link(__MODULE__, :ok, opts)
    end

    @impl true
    def init(:ok) do
      children = [
        %{
          id: :conversion_rate,
          start: {Cachex, :start_link, [:conversion_rate, []]}
        }
      ]

      Supervisor.init(children, strategy: :one_for_one)
    end
end
