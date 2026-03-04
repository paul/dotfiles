# frozen_string_literal: true

module Components
  class Base < Phlex::HTML
    extend Dry::Initializer[undefined: false]

    module Types
      include Dry.Types()
    end

    # Include any helpers you want to be available across all components
    # Keep them alphabetized so we can see if its already been added
    include Phlex::Rails::Helpers::ButtonTo
    include Phlex::Rails::Helpers::DOMID
    include Phlex::Rails::Helpers::DOMClass
    include Phlex::Rails::Helpers::FormAuthenticityToken
    include Phlex::Rails::Helpers::ImageTag
    include Phlex::Rails::Helpers::L
    include Phlex::Rails::Helpers::LinkTo
    include Phlex::Rails::Helpers::Routes
    include Phlex::Rails::Helpers::TurboStreamFrom
    include Phlex::Rails::Helpers::TurboFrameTag
    include Phlex::Rails::Helpers::URLFor

    register_element :turbo_frame

    # Uncomment if using lucide-rails:
    # register_output_helper :lucide_icon

    if Rails.env.development?
      def before_template
        comment { "Before #{self.class.name}" }
        super
      end

      def after_template
        comment { "End #{self.class.name}" }
        super
      end
    end

    # Override to set a default of `reader: false`. This will avoid defining accessor methods,
    # that might conflict with Phlex html helper methods.
    def self.param(*, **, &)
      super(*, reader: false, **, &)
    end

    def self.option(*, **, &)
      super(*, reader: false, **, &)
    end

    def initialize(*, **kwargs)
      super
      # The Base component takes every extra kwargs it gets and assigns it to @user_attrs, so it
      # can set it as arbitrary HTML attributes. Dry::Initializer ignores kwargs that aren't
      # defined, and does nothing with them. This takes everything the Dry::Initializer didn't
      # handle, and sets it as @user_attrs, so we can keep using that if needed.
      @user_attrs = kwargs.except(*self.class.dry_initializer.options.map(&:target))
    end

    def default_attrs
      {}
    end

    def attrs
      @attrs ||=
        mix(default_attrs, @user_attrs)
    end

    private

    # Does mostly what you'd expect, to combine lists HTML classes or ids as
    # Strings or Arrays or Hashes (where the value indicates if the key gets included or not)
    #
    # tokens(
    #   "foo bar",
    #   :baz,
    #   ["qux", "quux"],
    #   {active: true, special: false},
    # ) #=> "foo bar baz qux quux active"
    #
    def tokens(*args)
      [].tap do |attrs|
        args.each do |val|
          case val
          when String
            attrs << val.split
          when Symbol
            attrs << val
          when Array
            attrs << tokens(*val).presence
          when Hash
            val.each do |key, val|
              attrs << key if val
            end
          end

          attrs.flatten!
          attrs.compact!
          attrs.uniq!
        end
      end.join(" ")
    end
  end
end
