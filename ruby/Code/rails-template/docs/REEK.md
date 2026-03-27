# Reek Smell Reference

This file documents every smell Reek detects, with examples and concrete fix strategies.
When Reek flags something in this codebase, look it up here and fix the underlying issue
rather than suppressing the warning.

---

## Smell: Attribute

### Cause

A class publishes a setter (`attr_writer`, `attr_accessor`) for an instance variable. Writable
public attributes invite callers to reach into an object's internal state, creating tight
coupling between the object and its consumers.

### Example

```ruby
class Klass
  attr_accessor :dummy  # writable attribute — Reek warns here
end
```

### Possible Solutions

- Make the attribute read-only with `attr_reader` and set it only in `initialize`.
- If the value genuinely needs to change after construction, expose a purpose-named
  method that performs the update (e.g., `def activate; @active = true; end`).
- In this project, prefer `Dry::Initializer` `option` declarations over `attr_accessor`.
  Options are set at construction time and accessed via generated readers.

---

## Smell: BooleanParameter

### Cause

A method parameter defaults to `true` or `false`. This is a special case of
[ControlParameter](#smell-controlparameter): the caller decides which execution path to
take, which makes the method do two different things depending on a flag.

### Example

```ruby
class Dummy
  def hit_the_switch(switch = true)
    if switch
      puts 'Hitting the switch'
    else
      puts 'Not hitting the switch'
    end
  end
end
# Reek: Dummy#hit_the_switch has boolean parameter 'switch' (BooleanParameter)
```

### Possible Solutions

- Split into two separate, well-named methods and let the caller choose which to call.
- Move the conditional logic to the caller.
- Note: `BooleanParameter` is disabled in `app/components` and `app/views` because Phlex
  components legitimately use boolean keyword arguments (e.g., `active:`, `selected:`,
  `disabled:`) as rendering hints. Outside of those directories, prefer splitting methods.

---

## Smell: ClassVariable

### Cause

A class uses `@@variable`. Class variables are shared across the entire inheritance
hierarchy (including subclasses) and form part of the global runtime state, making the
system fragile and difficult to test.

### Example

```ruby
class Dummy
  @@class_variable = :whatever
end
# Reek: Dummy declares the class variable @@class_variable (ClassVariable)
```

### Possible Solutions

- Replace `@@variable` with a class-instance variable (`@variable` on the class itself).
  This scopes the value to the specific class rather than the whole hierarchy.
- If the value is truly shared configuration, use a `Dry::Container` or a dedicated
  configuration object instead.

---

## Smell: ControlParameter

### Cause

A method parameter (not a boolean default, but any value) is used directly as the tested
expression in a conditional. The caller controls which branch runs, violating the
"tell, don't ask" principle and creating hidden coupling.

### Example

```ruby
def write(quoted)
  if quoted          # ← parameter used as condition
    write_quoted @value
  else
    write_unquoted @value
  end
end
# Reek: write is controlled by argument 'quoted' (ControlParameter)
```

### Possible Solutions

- Split into two focused methods (`write_quoted` and `write_unquoted`) and remove the
  wrapper method, pushing the decision to the caller.
- Use a strategy or policy object to encapsulate the variation.
- If the parameter is boolean, see also [BooleanParameter](#smell-booleanparameter).

---

## Smell: DataClump

### Cause

The same two or more parameters appear together across three or more methods. This
recurrence suggests a missing abstraction — the items conceptually belong together and
should probably be a single object.

### Example

```ruby
class Dummy
  def x(y1, y2); end
  def y(y1, y2); end
  def z(y1, y2); end
end
# Reek: Dummy takes parameters [y1, y2] to 3 methods (DataClump)
```

### Possible Solutions

- Introduce a parameter object. Prefer `Data.define` for simple value containers or a
  `Dry::Struct` if you need type coercion.
- Once you have the object, look for behavior that naturally belongs on it and move those
  methods closer to the data.

---

## Smell: DuplicateMethodCall

### Cause

A method calls the same method chain more than once. This is inefficient (the call runs
multiple times) and reduces clarity (the reader must trace the same chain repeatedly to
understand what it does).

### Example

```ruby
def double_thing
  @other.thing + @other.thing  # ← called twice
end
# Reek: double_thing calls @other.thing 2 times (DuplicateMethodCall)
```

### Possible Solutions

- Extract the repeated call to a local variable:
  ```ruby
  def double_thing
    thing = @other.thing
    thing + thing
  end
  ```
- If the call is repeated across multiple methods, extract a private reader method.
- The project-level `.reek.yml` whitelists certain patterns that are idiomatic in Rails
  (`flash.now`, `self.class`). Outside those patterns, always extract.

---

## Smell: FeatureEnvy

### Cause

A method references another object more than it references `self`. This suggests the
method belongs on the other object — it is "envious" of that object's data.

### Example

```ruby
class Warehouse
  def sale_price(item)
    (item.price - item.rebate) * @vat  # ← more calls to item than self
  end
end
# Reek: Warehouse#sale_price refers to item more than self (FeatureEnvy)
```

### Possible Solutions

- Move the method to the class it references most (`Item` in the example above).
- If you can't move the method, extract the envious logic into a helper method on the
  other object and call that instead.
- This detector is disabled in `app/components` and `app/views` for Phlex rendering
  methods. Outside those directories, treat this warning seriously.

---

## Smell: InstanceVariableAssumption

### Cause

A method reads an instance variable that is not guaranteed to be set — it is not
initialized in `initialize`, and there is no memoizing accessor that initializes it
lazily. This creates invisible dependencies between methods.

### Example

```ruby
class Foo
  def go_foo!
    @bar = :foo          # sets it here...
  end

  def foo?
    @bar == :foo         # ...but @bar might be nil if go_foo! was never called
  end
end
# Reek: Foo assumes too much for instance variable @bar (InstanceVariableAssumption)
```

### Possible Solutions

- Initialize the variable in `initialize`.
- Add a memoizing accessor: `def bar; @bar ||= compute_bar; end` and use the method
  rather than the ivar.
- Expose it via `attr_reader` (private if internal) and call the method rather than `@var`
  directly.
- Note: `Dry::Initializer` sets ivars without an explicit `initialize`, so this detector
  is disabled in `app/components` and `app/views`. Outside those directories, follow the
  guidance above.

---

## Smell: IrresponsibleModule

### Cause

A class or module has no descriptive comment explaining its responsibilities. Without
documentation, readers (and agents) must reverse-engineer intent from implementation.

> Note: This detector is currently disabled project-wide in `.reek.yml`.

### Example

```ruby
class Dummy
  # no comment — Reek warns here
end
# Reek: Dummy has no descriptive comment (IrresponsibleModule)
```

### Possible Solutions

- Add a one-sentence class-level comment explaining what the class is responsible for:
  ```ruby
  # Calculates sale prices for warehouse items, applying rebates and VAT.
  class Warehouse
  ```
- The comment should explain *what* and *why*, not just restate the class name.

---

## Smell: LongParameterList

### Cause

A method accepts more than three parameters. Long parameter lists are hard to read, easy
to call in the wrong order, and often a sign that some parameters belong together as an
object.

### Example

```ruby
class Dummy
  def long_list(foo, bar, baz, fling, flung)
    puts foo, bar, baz, fling, flung
  end
end
# Reek: Dummy#long_list has 5 parameters (LongParameterList)
```

### Possible Solutions

- Introduce a parameter object. Prefer `Data.define` or `Dry::Struct` for simple cases,
  or a `Dry::Schema` Params contract when the parameters come from external input.
- Use keyword arguments to remove ordering ambiguity, then group related keywords into an
  options hash or struct.
- `initialize` is excluded from this check by default in the project config.

---

## Smell: LongYieldList

### Cause

A method yields more than three arguments to its block. This is the block equivalent of
[LongParameterList](#smell-longparameterlist): callers must accept many positional
arguments, which is fragile and hard to read.

### Example

```ruby
class Dummy
  def yields_a_lot(foo, bar, baz, fling, flung)
    yield foo, bar, baz, fling, flung
  end
end
# Reek: Dummy#yields_a_lot yields 5 parameters (LongYieldList)
```

### Possible Solutions

- Yield a single object (a struct, a hash, or a purpose-built value object) instead of
  many individual arguments.
- Prefer `Data.define` for lightweight value containers yielded to blocks.

---

## Smell: ManualDispatch

### Cause

Code checks whether an object responds to a method before calling it (`respond_to?`).
This is a form of simulated polymorphism — you are conditionally dispatching by probing
the object rather than relying on a shared interface or duck type.

### Example

```ruby
def call
  foo.bar if foo.respond_to?(:bar)  # ← manual dispatch
end
# Reek: MyManualDispatcher manually dispatches method call (ManualDispatch)
```

### Possible Solutions

- Define a common interface (e.g., a module) that all collaborators implement, including
  a no-op version where needed, so the `respond_to?` check becomes unnecessary.
- Use the Null Object pattern: create a stub class that responds to `bar` with a safe
  default, so callers never need to guard.
- Use polymorphism: if two objects differ in behavior, make that difference explicit
  through separate classes or modules rather than run-time probing.

---

## Smell: MissingSafeMethod

### Cause

A method whose name ends with `!` (a "dangerous" method) exists in a class, but the
non-bang counterpart does not. By Ruby convention, `foo!` should be the dangerous version
of `foo`, not a standalone method. A lone `!` method confuses readers about what the
danger is relative to.

### Example

```ruby
class C
  def foo; end
  def foo!; end   # fine — foo exists
  def bar!; end   # ← missing safe bar — Reek warns here
end
# Reek: C has missing safe method 'bar!' (MissingSafeMethod)
```

### Possible Solutions

- Add a non-bang version of the method that performs the same operation without the
  "dangerous" side-effects (e.g., returns a new object instead of mutating in place).
- Rename `bar!` to `bar` if there is no meaningfully safer alternative to provide.

---

## Smell: ModuleInitialize

### Cause

A module defines an `initialize` method. Modules are typically mixed into classes, and
defining `initialize` in a module makes initialization order unpredictable and can
silently override the including class's own `initialize`.

### Example

```ruby
module Foo
  def initialize(foo)   # ← defining initialize in a module
    @foo = foo
  end
end
# Reek: Foo has initialize in module (ModuleInitialize)
```

### Possible Solutions

- Rename the initializer to a descriptively named setup method (e.g.,
  `setup_foo_module(foo)`) and call it explicitly from the including class's
  `initialize`.
- Prefer `Dry::Initializer` in this project, which handles mixin-safe initialization
  through `option` and `param` declarations rather than overriding `initialize`.

---

## Smell: NestedIterators

### Cause

A block contains another block, creating nesting that is hard to read and follow.
Deeply nested iterators obscure intent and often indicate a missing abstraction.

### Example

```ruby
def duck_names
  %i[tick trick track].each do |surname|
    %i[duck].each do |last_name|          # ← nested block
      puts "#{surname} #{last_name}"
    end
  end
end
# Reek: duck_names contains iterators nested 2 deep (NestedIterators)
```

### Possible Solutions

- Extract the inner block into a private method with a descriptive name.
- Use `flat_map`, `product`, or other higher-order combinators to flatten the iteration.
- The project allows up to 3 levels of nesting globally (to accommodate dry-monads result
  pattern blocks). Beyond that, extract.

---

## Smell: NilCheck

### Cause

Code tests whether a value is `nil` before using it. Nil checks violate the "tell, don't
ask" principle and often mask a missing polymorphic abstraction — if a value might be nil,
the design usually has a seam where a Null Object should go.

### Example

```ruby
def nil_checker(argument)
  if argument.nil?     # ← nil check
    puts "argument is nil!"
  end
end
# Reek: nil_checker performs a nil-check. (NilCheck)
```

### Possible Solutions

- Use the Null Object pattern: return a safe-default object instead of `nil` at the
  source, so callers never need to guard.
- Use safe navigation (`&.`) for simple optional chaining where a nil Null Object is
  overkill.
- Ensure the value is never nil by using `Dry::Types` with strict types or `fetch`
  instead of `[]` for hash access.
- Avoid `value == nil` — use `value.nil?` at minimum, but prefer eliminating the check
  entirely.

---

## Smell: RepeatedConditional

### Cause

A class tests the same condition in three or more methods. Repeated conditionals on the
same value are a classic sign of simulated polymorphism: the class is doing dispatch by
hand where a proper polymorphic design would dispatch automatically.

### Example

```ruby
class RepeatedConditionals
  attr_accessor :switch

  def repeat_1 = puts "Repeat 1!" if switch
  def repeat_2 = puts "Repeat 2!" if switch
  def repeat_3 = puts "Repeat 3!" if switch
end
# Reek: RepeatedConditionals tests switch at least 3 times (RepeatedConditional)
```

### Possible Solutions

- Extract the varying behavior into separate classes and use polymorphism to dispatch.
- Use a `Dry::Container` strategy registry: register strategy objects keyed by the
  condition value and call the right one rather than checking everywhere.
- If the condition is an enum-like value, consider `StringEnum` (already used in this
  project) plus polymorphic dispatch.

---

## Smell: SubclassedFromCoreClass

### Cause

A class inherits from a Ruby core class (`Array`, `Hash`, `String`, etc.). Core class
subclasses behave unexpectedly because many core methods return instances of the core
class rather than the subclass, making the hierarchy unreliable.

### Example

```ruby
class List < Array; end   # ← inheriting from core class
l = List.new << 1 << 2
l.reverse.class           # => Array, not List — surprising!
# Reek: List is a subclass of Array (SubclassedFromCoreClass)
```

### Possible Solutions

- Use composition with delegation instead. Wrap the core class in a plain Ruby object and
  delegate only the methods you need via `Forwardable`:
  ```ruby
  class List
    extend Forwardable
    def_delegators :@list, :<<, :length, :each
    def initialize(list = []) = @list = list
    def reverse = List.new(@list.reverse)
  end
  ```
- Prefer `Dry::Struct` for structured data with type coercion, or `Data.define` for
  simple immutable value objects.

---

## Smell: TooManyConstants

### Cause

A class or module defines more than five constants. This is a symptom of a large class —
the class has too many responsibilities or is being used as a dumping ground for related
values.

### Example

```ruby
class Smelly
  CONST_1 = :a; CONST_2 = :b; CONST_3 = :c
  CONST_4 = :d; CONST_5 = :e; CONST_6 = :f   # ← over limit
end
# Reek: Smelly has 6 constants (TooManyConstants)
```

### Possible Solutions

- Group related constants into a dedicated module or a `Dry::Struct`/`Data.define` value
  object.
- If the constants represent configuration, move them to a config file or a dedicated
  config object.
- If the constants represent an enum, use `StringEnum` (project pattern) or a proper
  type definition.

---

## Smell: TooManyInstanceVariables

### Cause

A class sets more than four instance variables. This is a symptom of a large class — the
object is tracking too much state and likely has too many responsibilities.

### Example

```ruby
class Smelly
  def initialize
    @a = :a; @b = :b; @c = :c; @d = :d; @e = :e   # ← over limit
  end
end
# Reek: Smelly has at least 5 instance variables (TooManyInstanceVariables)
```

### Possible Solutions

- Split the class into smaller classes, each responsible for a subset of the state.
- Group related ivars into a value object (`Data.define` or `Dry::Struct`) and store that
  single object as one ivar instead.
- In Phlex components, use `Dry::Initializer` `option` declarations rather than manual
  ivar assignments. This detector is disabled in `app/components` and `app/views` for
  that reason.

---

## Smell: TooManyMethods

### Cause

A class or module has more than 15 methods (counting both instance and class methods).
This is a symptom of a large class — the class is doing too many things and should be
broken up.

### Example

```ruby
class Smelly
  def one; end; def two; end; def three; end; def four; end
  # ... 12+ more methods
end
# Reek: Smelly has at least 16 methods (TooManyMethods)
```

### Possible Solutions

- Look for clusters of methods that share a common theme and extract them into a new class
  or module.
- A view with too many rendering methods should extract sub-components (Phlex components
  in `app/components/`).
- A controller with too many actions should consider splitting into multiple controllers
  by resource or concern.
- A transaction or service with too many steps should extract a collaborator object.

---

## Smell: TooManyStatements

### Cause

A method has more than eight statements (project limit; default is 5). Each `if`, `else`,
`case`, `when`, loop, `rescue`, and assignment counts. Long methods are hard to read,
test, and reason about.

### Example

```ruby
def parse(arg, argv)
  if !(val = arg) && argv.empty?
    return nil             # +1
  end
  opt = parse_arg(val)     # +2
  val = conv_arg(*val)     # +3
  if opt && !arg
    argv.shift             # +4
  else
    val[0] = nil           # +5
  end
  val                      # +6 — and still counting...
end
# Reek: parse has at least N statements (TooManyStatements)
```

### Possible Solutions

- Extract cohesive groups of statements into well-named private methods.
- Pull complex conditional logic into a guard-clause pattern to reduce nesting and
  statement count.
- A Phlex `view_template` with too many rendering statements should extract helper
  methods or sub-components. (`TooManyStatements` is disabled in `app/components` and
  `app/views` for this reason, but the principle still applies.)
- A service or transaction method with too many steps should extract a collaborator.

---

## Smell: UncommunicativeMethodName

### Cause

A method name is a single character, ends with a number, or uses camelCase. Such names
fail to communicate intent and make code harder to search and understand.

### Example

```ruby
def x; end       # single character
def process2; end  # ends with number
def doThing; end   # camelCase
# Reek: UncommunicativeMethodName
```

### Possible Solutions

- Rename the method to a full, descriptive snake_case name that expresses what it does
  (`calculate_total`, `process_payment`, `find_by_slug`).

---

## Smell: UncommunicativeModuleName

### Cause

A class or module name is a single character or ends with a number. Short or generic
names fail to communicate the class's purpose.

### Example

```ruby
class X; end        # single character
class Handler2; end # ends with number
# Reek: UncommunicativeModuleName
```

### Possible Solutions

- Use a full, descriptive name that communicates the class's single responsibility.
- The project whitelists versioned API module names (`V1`, `V2`, `V3`) since those are
  conventional. Outside of versioned namespaces, use full names.

---

## Smell: UncommunicativeParameterName

### Cause

A method parameter is a single character, ends with a number, or uses camelCase. Poor
parameter names make method signatures hard to understand and document.

### Example

```ruby
def process(x, y2, doThing); end
# Reek: process has the parameter name 'x' (UncommunicativeParameterName)
```

### Possible Solutions

- Rename parameters to descriptive snake_case names that explain the expected value
  (`user`, `record`, `page_number`).
- The project whitelists `_` (ignored parameter). All other single-letter or numbered
  parameter names should be renamed.

---

## Smell: UncommunicativeVariableName

### Cause

A local variable is a single character, ends with a number, or uses camelCase. Opaque
variable names force readers to trace execution to understand what a variable holds.

### Example

```ruby
def calculate
  x = fetch_value   # x communicates nothing
  x * 2
end
# Reek: calculate has the variable name 'x' (UncommunicativeVariableName)
```

### Possible Solutions

- Rename to a descriptive name that reflects what the variable holds (`base_price`,
  `filtered_records`, `current_page`).
- The project whitelists `_`, and the conventional short names `i`, `c`, `k`, `v`, `h`,
  `t` for iteration variables where the meaning is obvious by context. In other cases,
  use a full name.

---

## Smell: UnusedParameters

### Cause

A method declares a parameter it never uses in the method body. Unused parameters are
dead code — they mislead callers into thinking the value influences the result.

### Example

```ruby
class Klass
  def unused_parameters(x, y, z)
    puts x, y   # z is never used
  end
end
# Reek: Klass#unused_parameters has unused parameter 'z' (UnusedParameters)
```

### Possible Solutions

- Remove the unused parameter from the method signature.
- If the method must conform to a specific interface (e.g., a callback), prefix the
  parameter name with `_` to signal intentional non-use: `_z`. Reek will not warn about
  underscore-prefixed parameters.
- If the parameter is needed for future use, add it only when you actually use it
  (YAGNI).

---

## Smell: UnusedPrivateMethod

### Cause

A class defines a private instance method that is never called. Dead code obscures the
class's behavior and increases maintenance burden.

### Example

```ruby
class Car
  private
  def drive; end   # never called — Reek warns
  def start; end   # never called — Reek warns
end
# Reek: Car has the unused private instance method 'drive' (UnusedPrivateMethod)
```

### Possible Solutions

- Delete the method if it is truly unused.
- If the method is called via dynamic dispatch (`send`, Rails callbacks, template method
  patterns), Reek cannot detect the usage. Use the `exclude` option in `.reek.yml` to
  whitelist the specific method name pattern rather than disabling the entire detector.
- Note: this detector is disabled in `app/controllers` because Rails before/after
  actions are called dynamically by the framework.

---

## Smell: UtilityFunction

### Cause

An instance method makes no reference to `self` and uses none of the object's instance
variables or instance methods. It is essentially a free function that happens to live in
a class, which reduces cohesion and makes the class harder to reason about.

> Note: This detector is currently disabled project-wide in `.reek.yml`.

### Example

```ruby
class UtilityFunction
  def showcase(argument)
    argument.to_s + argument.to_i.to_s   # no self reference
  end
end
# Reek: UtilityFunction#showcase doesn't depend on instance state (UtilityFunction)
```

### Possible Solutions

- Move the method to the class it references most (see also
  [FeatureEnvy](#smell-featureenvy)).
- Extract it into a module as a module method, or into a dedicated service/utility
  object if it is used broadly.
- In this project, transaction steps in `app/aspects` are intentionally stateless
  utility functions. The detector is disabled there. Elsewhere, ask whether the method
  should be moved or the object needs more state.
