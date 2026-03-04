# frozen_string_literal: true

# Provides a couple helpers that are useful in transaction specs.
#
#  + `subject(:result)` -    the Dry::Result that responds to success? and failure?
#  + `perform_transaction` - runs the transaction, good in `before` or `expect{} change` blocks
#
# You need to provide an initial `args` that will be provided to the transaction's `call` method.
#
# Usage:
#
# let(:args) { { some: "values" } }
# include_context "with transaction"
#
# it { should be_a_success }
# it "should make a change" do
#   expect { perform_transaction }.to change { whatever }
# end
#
RSpec.shared_context "with transaction" do
  include ActiveJob::TestHelper

  let(:args) { {} }
  let(:initializer_args) { {} }
  let(:transaction) { described_class.new(**initializer_args) }
  let(:perform_transaction) do
    transaction.call(args) do |matcher|
      # rubocop:disable RSpec/InstanceVariable
      # `matcher` is in Dry::Matcher::Evaluator, which is a BasicObject, but we need to extract the
      # original result to retrieve the step name.
      matched = matcher.instance_eval { @result }
      # rubocop:enable RSpec/InstanceVariable
      # Return matched result
      matcher.failure { matched }
      matcher.success { matched }
    end
  end

  subject(:result) { perform_transaction }

  let(:value)   { result.value! }
  let(:failure) { result.failure.value }
end
