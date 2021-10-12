ExUnit.start(
  # OpenTelemetry exporter currently runs asynchronously and default 100 ms
  # hasn't been enough.
  assert_receive_timeout: 200
)
