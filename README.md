# Mobile

Working through the "mobile" application from "Designing for Scalability with Erlang/OTP" by Francesco Cesarini and
Steve Vinoski.

I am translating to Elixir (version 1.5.1 on Erlang/OTP 20) as I go.

In some cases things I have changed things; e.g. since `GenEvent` is deprecated, I have used the approach advocated
[here](http://blog.plataformatec.com.br/2016/11/replacing-genevent-by-a-supervisor-genserver/) to implement the
`FreqOverload` event manager.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `mobile` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mobile, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/mobile](https://hexdocs.pm/mobile).

