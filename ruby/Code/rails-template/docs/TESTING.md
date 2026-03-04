- RSpec is the test framework; keep specs under `spec/`
- Favor system specs for HTTP behavior
- Do not create controller specs. Any complicated controller behavior worthy of a test must be
  extracted to a service object and tested independently
- Do not create model specs. Any complicated model behavior worthy of a test must be
  extracted to a service object and tested independently
- Run targeted specs during development and the full suite before PRs

## Prefer Dependency Injection Over Mocks

There is a **strong preference for dependency injection** over RSpec mocks and stubs
(`allow(...).to receive(...)`, `expect(...).to receive(...)`). The architecture provides DI seams
so tests can inject real collaborators, fakes, or lambdas instead of mocking.

Why:

- Mocks couple tests to implementation details. DI tests couple to the interface contract.
- Mocks silently pass when the real implementation changes. Injected fakes break visibly.
- Mocks can't verify that collaborators are wired together correctly. DI tests exercise real wiring.

## Transaction Step Injection

`Dry::Transaction` accepts step overrides as keyword arguments to `new`. Inject a lambda that
returns the `Success`/`Failure` you want:

```ruby
# Override a single step to force a failure path:
let(:transaction) do
  Models::RenderSTL.new(
    render: ->(**) { Failure("Render failed") }
  )
end

# Override a step to simulate a specific success:
let(:transaction) do
  Models::RenderSTL.new(
    render: lambda { |workdir:, **|
      workdir.join("output.stl").write(stl_content)
      Dry::Monads::Success(output_path: workdir.join("output.stl"))
    },
  )
end
```

Use the shared context for ergonomic setup:

```ruby
include_context "with transaction"

let(:initializer_args) { { some_step: ->(**) { Failure("boom") } } }

it { is_expected.to be_failure }
```

## Transaction Specs

Test the full pipeline. Every transaction test should start with a `it { is_expected.to be_success
}` example, as a basic sanity check to confirm the transaction is working at all, before
investigating test implementation issues.

Assert on `be_success`/`be_failure`:

```ruby
describe Plans::Create do
  subject { described_class.call(name: "Test", summary: "A plan", file: uploaded_file, images: [img]) }

  it { is_expected.to be_success }

  context "when name is missing" do
    subject { described_class.call(name: "", summary: "A plan", file: uploaded_file, images: [img]) }

    it { is_expected.to be_failure }
    it { is_expected.to have_errors_on(:name) }
  end
end
```

## Fake Objects Over Mock Expectations

When an external collaborator is used in many tests, write a dedicated fake class rather than
repeating mock setups. Fakes implement the same interface with in-memory behavior:

```ruby
class FakeOpenSCADCommand
  attr_reader :invocations

  def initialize(**) = @invocations = []

  def call(**args)
    @invocations.push(args)
    Dry::Monads::Success(output_path: args[:workdir].join("output.stl"))
  end
end
```
