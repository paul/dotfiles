# frozen_string_literal: true

# Example:
#
# class SearchForm < Form
#   wrap User, :name, :email
#
#   attribute :q, :string
#
#   validates :name, :email, presence: true
# end
class Form
  extend ActiveModel::Callbacks
  extend ActiveModel::Naming
  extend ActiveModel::Translation

  include ActiveModel::Attributes
  include ActiveModel::Validations
  include ActiveModel::Conversion

  include Dry::Monads[:result]

  define_model_callbacks :validation
  validate :wrapped_objects_are_valid

  def self.wrap(klass, *attributes)
    wrapped_classes << klass
    wrapped_attribute_names.concat(attributes.map(&:to_s))

    object_name = klass.model_name.singular

    attr_writer object_name

    class_eval <<-CODE, __FILE__, __LINE__ + 1 # wrap User
        def #{object_name}                     # def user
          @#{object_name} ||= #{klass}.new     #   @user ||= User.new
        end                                    # end
    CODE

    delegate_attributes(*attributes, to: object_name)
    delegate_attributes(*attributes, to: object_name, prefix: true)
  end

  # Delegates getters, setters and enquire methods
  #
  # delegate_attributes :name, to: :movie
  # defines methods name, name= and name?
  def self.delegate_attributes(*attributes, **)
    names = [
      *attributes,
      *attributes.map { "#{it}=" },
      *attributes.map { "#{it}?" },
    ]

    delegate(*names, **)
  end

  # Strip Form off the model name, eg:
  #
  # PreferencesForm -> Preferences
  # Users::Form -> User
  #
  # This makes the normal rails form builder params pretty, params[:preferences]
  # instead of params[:preferences_form]
  def self.model_name
    name = self.name.delete_suffix("Form").delete_suffix("::").singularize
    @model_name ||= ActiveModel::Name.new(self, nil, name)
  end

  def self.wrapped_classes
    @wrapped_classes ||= []
  end

  def self.wrapped_attribute_names
    @wrapped_attribute_names ||= []
  end

  def initialize(args = {})
    super() # This first, to AM::Attributes initializes itself
    merge(args)
  end

  def attributes
    base = super
    self.class.wrapped_attribute_names.each_with_object(base) do |name, hash|
      hash[name] = send(name)
    end
  end

  def merge(args = {})
    return if args.blank?

    args.each do |name, value|
      # If we got a raw params hash that this form would generate, dig into that key
      if name == self.class.model_name.param_key && value.is_a?(Hash)
        merge(value)
      elsif respond_to?("#{name}=")
        send(:"#{name}=", value)
      end
      # Ignore unknown keys
    end
  end

  def objects
    self.class.wrapped_classes.map { |klass| send(klass.model_name.singular) }
  end

  def persisted?
    objects.map(&:persisted?).all?
  end

  def save # rubocop:disable Naming/PredicateMethod
    valid? && objects.each { |obj| Rails.error.handle { obj.save! } }.all?
  end

  def save! # rubocop:disable Naming/PredicateMethod
    valid? && objects.each(&:save!).all?
  end

  def to_monad
    if valid? && save
      Success(self)
    else
      Failure[self, errors:]
    end
  end

  private

  def run_validations!
    run_callbacks :validation do
      super
    end
  end

  def wrapped_objects_are_valid
    objects.each do |object|
      object.valid? || object.errors.each do |error|
        local_field = :"#{object.class.model_name.singular}_#{error.attribute}"
        errors.add(local_field, error.message)

        # Also add under the unprefixed attribute name so that form builders
        # (e.g. TurboForm) can look up errors by field name directly.
        unless errors.added?(error.attribute, error.message)
          errors.add(error.attribute, error.message)
        end
      end
    end
  end
end
