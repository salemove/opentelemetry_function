defmodule OpentelemetryFunction do
  @moduledoc """
  Documentation for `OpentelemetryFunction`.

  This package provides functions to help propagating OpenTelemetry context
  across functions that are executed asynchronously.
  """

  require OpenTelemetry.Tracer

  @doc """
  Accepts a function and wraps it in a function which propagates OpenTelemetry
  context.

  This function supports functions with arity up to 9.

  ## Example

      # Before
      task = Task.async(func)
      Task.await(task, timeout)

      # With explicit context propagation
      ctx = OpenTelemetry.Ctx.get_current()
      task = Task.async(fn ->
        OpenTelemetry.Ctx.attach(ctx)
        func.()
      end)
      Task.await(task, timeout)

      # With this helper function
      task = Task.async(OpentelemetryFunction.wrap(func))
      Task.await(task, timeout)

  ## It is also possible to use this with MFA:

      # Before
      :jobs.enqueue(:tasks_queue, {mod, fun, args})

      # After
      wrapped_fun = OpentelemetryFunction.wrap({mod, fun, args})
      :jobs.enqueue(:tasks_queue, wrapped_fun)
  """
  def wrap(fun_or_mfa, span_name \\ "Function.wrap")

  @spec wrap(fun, binary) :: fun
  Enum.each(0..9, fn arity ->
    args = for _ <- 1..arity, arity > 0, do: Macro.unique_var(:arg, __MODULE__)

    def wrap(original_fun, span_name) when is_function(original_fun, unquote(arity)) do
      span_ctx = OpenTelemetry.Tracer.start_span(span_name)
      ctx = OpenTelemetry.Ctx.get_current()

      fn unquote_splicing(args) ->
        OpenTelemetry.Ctx.attach(ctx)
        OpenTelemetry.Tracer.set_current_span(span_ctx)

        try do
          original_fun.(unquote_splicing(args))
        rescue
          exception ->
            OpenTelemetry.Span.record_exception(span_ctx, exception, __STACKTRACE__, [])
            OpenTelemetry.Tracer.set_status(OpenTelemetry.status(:error, ""))
            reraise(exception, __STACKTRACE__)
        after
          OpenTelemetry.Span.end_span(span_ctx)
        end
      end
    end
  end)

  @spec wrap({module, atom, [term]}, binary()) :: fun
  def wrap({mod, fun, args}, span_name) do
    span_ctx = OpenTelemetry.Tracer.start_span(span_name)
    ctx = OpenTelemetry.Ctx.get_current()

    fn ->
      OpenTelemetry.Ctx.attach(ctx)
      OpenTelemetry.Tracer.set_current_span(span_ctx)

      try do
        apply(mod, fun, args)
      rescue
        exception ->
          OpenTelemetry.Span.record_exception(span_ctx, exception, __STACKTRACE__, [])
          OpenTelemetry.Tracer.set_status(OpenTelemetry.status(:error, ""))
          reraise(exception, __STACKTRACE__)
      after
        OpenTelemetry.Span.end_span(span_ctx)
      end
    end
  end
end
