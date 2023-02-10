# frozen_string_literal: true

class Object
  def wtf?(m)
    method(m).source_location
  end

  def my_methods
    (methods - Object.methods).sort
  end
end

