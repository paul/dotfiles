# frozen_string_literal: true

# A minimal model that satisfies the form object protocol.
class TestModel
  attr_accessor :errors_hash, :attributes

  def initialize(attributes: {}, errors: {})
    @attributes = attributes.transform_keys(&:to_s)
    @errors_hash = errors
  end

  def errors
    @errors ||= ErrorsProxy.new(@errors_hash)
  end

  def model_name
    ModelName.new("test_model")
  end

  def to_key
    nil
  end

  class ErrorsProxy
    def initialize(hash)
      @hash = hash.transform_keys(&:to_s)
    end

    def [](key)
      @hash[key.to_s] || []
    end

    def any?
      @hash.values.any? { |v| !v.empty? }
    end

    def empty?
      !any?
    end
  end

  class ModelName
    attr_reader :param_key

    def initialize(param_key)
      @param_key = param_key
    end
  end
end
