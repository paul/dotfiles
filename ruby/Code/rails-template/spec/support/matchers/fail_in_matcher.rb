# frozen_string_literal: true

# Expect a txn to fail on a particular step.
#
# Example:
#
# expect { perform_transaction }.to fail_on(:validate)
RSpec::Matchers.define :fail_on do |step_name|
  supports_block_expectations

  match do |block|
    @result = block.respond_to?(:call) ? block.call : block
    @result.failure? && @result.failure.step.name == step_name
  end

  failure_message do
    msg = "Expected transaction to have failed on step #{step_name.inspect}, but it was "
    msg += if @result.success?
             "a success."
           else
             "a failure on #{@result.failure.step.name.inspect}"
           end
    msg
  end
end
