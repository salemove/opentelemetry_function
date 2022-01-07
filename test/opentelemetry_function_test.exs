defmodule OpentelemetryFunctionTest do
  use ExUnit.Case
  doctest OpentelemetryFunction

  require OpenTelemetry.Tracer
  require OpenTelemetry.Span
  require Record

  for {name, spec} <- Record.extract_all(from_lib: "opentelemetry/include/otel_span.hrl") do
    Record.defrecord(name, spec)
  end

  for {name, spec} <- Record.extract_all(from_lib: "opentelemetry_api/include/opentelemetry.hrl") do
    Record.defrecord(name, spec)
  end

  setup do
    :application.stop(:opentelemetry)
    :application.set_env(:opentelemetry, :tracer, :otel_tracer_default)

    :application.set_env(:opentelemetry, :processors, [
      {:otel_batch_processor, %{scheduled_delay_ms: 1, exporter: {:otel_exporter_pid, self()}}}
    ])

    :application.start(:opentelemetry)

    :ok
  end

  test "wraps funtion that takes 0 arguments" do
    fun = fn ->
      OpenTelemetry.Tracer.with_span "child span" do
        :it_works
      end
    end

    result =
      OpenTelemetry.Tracer.with_span "root span" do
        task = async(OpentelemetryFunction.wrap(fun), 0)
        Task.await(task)
      end

    assert result == :it_works

    assert_receive {:span, span(name: "root span", trace_id: root_span_trace_id)}
    assert_receive {:span, span(name: "Function.wrap", trace_id: implicit_child_trace_id)}
    assert_receive {:span, span(name: "child span", trace_id: explicit_child_span_trace_id)}
    assert root_span_trace_id == implicit_child_trace_id
    assert implicit_child_trace_id == explicit_child_span_trace_id
  end

  test "wraps funtion that takes 1 argument" do
    fun = fn arg1 ->
      OpenTelemetry.Tracer.with_span "child span" do
        {:it_works, arg1}
      end
    end

    result =
      OpenTelemetry.Tracer.with_span "root span" do
        task = async(OpentelemetryFunction.wrap(fun), 1)
        Task.await(task)
      end

    assert result == {:it_works, :arg1}

    assert_receive {:span, span(name: "root span", trace_id: root_span_trace_id)}
    assert_receive {:span, span(name: "Function.wrap", trace_id: implicit_child_trace_id)}
    assert_receive {:span, span(name: "child span", trace_id: explicit_child_span_trace_id)}
    assert root_span_trace_id == implicit_child_trace_id
    assert implicit_child_trace_id == explicit_child_span_trace_id
  end

  test "wraps funtion that takes 9 arguments" do
    fun = fn arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9 ->
      OpenTelemetry.Tracer.with_span "child span" do
        {:it_works, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9}
      end
    end

    result =
      OpenTelemetry.Tracer.with_span "root span" do
        task = async(OpentelemetryFunction.wrap(fun), 9)
        Task.await(task)
      end

    assert result == {:it_works, :arg1, :arg2, :arg3, :arg4, :arg5, :arg6, :arg7, :arg8, :arg9}

    assert_receive {:span, span(name: "root span", trace_id: root_span_trace_id)}
    assert_receive {:span, span(name: "Function.wrap", trace_id: implicit_child_trace_id)}
    assert_receive {:span, span(name: "child span", trace_id: explicit_child_span_trace_id)}
    assert root_span_trace_id == implicit_child_trace_id
    assert implicit_child_trace_id == explicit_child_span_trace_id
  end

  test "wraps mfa" do
    fun = fn ->
      OpenTelemetry.Tracer.with_span "child span" do
        :it_works
      end
    end

    result =
      OpenTelemetry.Tracer.with_span "root span" do
        task = async(OpentelemetryFunction.wrap({:erlang, :apply, [fun, []]}), 0)
        Task.await(task)
      end

    assert result == :it_works

    assert_receive {:span, span(name: "root span", trace_id: root_span_trace_id)}
    assert_receive {:span, span(name: "Function.wrap", trace_id: implicit_child_trace_id)}
    assert_receive {:span, span(name: "child span", trace_id: explicit_child_span_trace_id)}
    assert root_span_trace_id == implicit_child_trace_id
    assert implicit_child_trace_id == explicit_child_span_trace_id
  end

  test "allows changing automatically created span name" do
    fun = fn -> :it_works end

    result =
      OpenTelemetry.Tracer.with_span "root span" do
        task = async(OpentelemetryFunction.wrap(fun, "child span"), 0)
        Task.await(task)
      end

    assert result == :it_works

    assert_receive {:span, span(name: "root span", trace_id: root_span_trace_id)}
    assert_receive {:span, span(name: "child span", trace_id: implicit_child_trace_id)}
    assert root_span_trace_id == implicit_child_trace_id
  end

  @tag :capture_log
  test "sets span status to error on exception" do
    Process.flag(:trap_exit, true)

    fun = fn ->
      raise "some exception"
    end

    OpenTelemetry.Tracer.with_span "root span" do
      task = async(OpentelemetryFunction.wrap(fun, "child span"), 0)

      assert {{%RuntimeError{message: "some exception"}, _}, {Task, :await, _}} =
               catch_exit(Task.await(task))
    end

    assert_receive {:span, span(name: "root span", trace_id: root_span_trace_id)}

    expected_status = OpenTelemetry.status(:error, "")

    assert_receive {:span,
                    span(
                      name: "child span",
                      status: ^expected_status,
                      trace_id: implicit_child_trace_id,
                      events: events
                    )}

    [event(name: "exception", attributes: event_attributes)] = :otel_events.list(events)

    assert %{
             "exception.type" => "Elixir.RuntimeError",
             "exception.message" => "some exception",
             "exception.stacktrace" => _stacktrace
           } = :otel_attributes.map(event_attributes)

    assert root_span_trace_id == implicit_child_trace_id
  end

  defp async(fun, args_count) do
    args = for count <- 1..args_count, args_count > 0, do: :"arg#{count}"

    Task.async(:erlang, :apply, [fun, args])
  end
end
