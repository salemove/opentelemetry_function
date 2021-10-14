# OpentelemetryFunction

This package provides functions to help propagating OpenTelemetry context
across functions that are executed asynchronously.

## Installation

The package can be installed by adding `opentelemetry_function` to your list of
dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:opentelemetry_function, "~> 0.1.0-rc.1"}
  ]
end
```

## Examples

Lets say you are executing a function in a different process. For example:

```elixir
task = Task.async(func)
Task.await(task, timeout)
```

OpenTelemetry by default does not propagate context through processes, so you'll have to do something like this:

```elixir
span_ctx = OpenTelemetry.Tracer.start_span("Some expensive calculation")
ctx = OpenTelemetry.Ctx.get_current()
task = Task.async(fn ->
  OpenTelemetry.Ctx.attach(ctx)
  OpenTelemetry.Tracer.set_current_span(span_ctx)

  func.()
end)
Task.await(task, timeout)
OpenTelemetry.Span.end_span(span_ctx)
```

With this module you can use `wrap/2` function instead:

```elixir
task = Task.async(OpentelemetryFunction.wrap(func, "Some expensive calculation"))
Task.await(task, timeout)
```

This helps to keep the code short and to the point.

If you do not provide the span name, then `Function.wrap` is used as the span name.

`OpenTelemetry.Tracer` functions that work on the current span can be used as well:

```elixir
OpenTelemetry.Tracer.update_name("Some expensive calculation")
```

## Documentation

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/opentelemetry_function](https://hexdocs.pm/opentelemetry_function).
