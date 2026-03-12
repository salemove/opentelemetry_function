# Changelog

## 0.2.0

* Start span within function, not outside. This adds support for delayed and
  repeated invocations of the wrapped function.
* Bump OpenTelemetry API dependency to 1.1.0.
* Include exception message as span error status message instead of using an
  empty message.
* Drop support for Elixir 1.11.

## 0.1.0

* Initial release
