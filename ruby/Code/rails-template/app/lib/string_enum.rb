# frozen_string_literal: true

module StringEnum
  # Provides a bit of syntactic sugar around Rails' built-in enums to map
  # them to string enums which expect string values instead of integer
  # values. Basically this saves you from having to pass in:
  # {
  #   foo: "foo",
  #   bar: "bar",
  #   baz: "baz"
  # }
  # to the Rails enum DSL method.
  def string_enum(attribute, values, **)
    enum(attribute, values.to_h { |value| [value.to_sym, value.to_s] }, **)
  end
end
