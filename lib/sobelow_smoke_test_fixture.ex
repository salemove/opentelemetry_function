defmodule OpentelemetryFunction.SobelowSmokeTestFixture do
  @moduledoc """
  DO NOT MERGE. Temporary fixture confirming the Sobelow check runs here.

  Deliberately unsafe and deliberately unreachable — nothing calls this module.
  This repository is otherwise clean, and a clean scan posts no comment, so a
  planted finding is the only way to see the whole path work end to end.
  """

  # Expected finding: RCE.CodeModule
  def unsafe_eval(input) do
    Code.eval_string(input)
  end
end
