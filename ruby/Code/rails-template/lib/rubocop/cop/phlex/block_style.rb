# frozen_string_literal: true

module RuboCop
  module Cop
    module Phlex
      # Enforces block delimiter style in Phlex component templates.
      #
      # Lowercase method calls (div, p, span, etc.) are treated as HTML
      # elements and must use braces `{ }`. Uppercase method calls
      # (UI::Button(), Breadcrumb(), etc.) are treated as component renders
      # and must use `do...end` for multiline blocks. Single-line component
      # blocks may use braces.
      #
      # @example
      #   # bad
      #   div do
      #     span { "hello" }
      #   end
      #
      #   # good
      #   div {
      #     span { "hello" }
      #   }
      #
      #   # bad - multiline component block with braces
      #   UI::Button("Save") {
      #     plain "Save"
      #   }
      #
      #   # good
      #   UI::Button("Save") do
      #     plain "Save"
      #   end
      #
      #   # good - single-line component block with braces is allowed
      #   Button() { "Save" }
      #
      class BlockStyle < RuboCop::Cop::Base
        extend AutoCorrector

        MSG_USE_BRACES = "Use `{ }` for Phlex HTML element `%<method>s`."
        MSG_USE_DO_END = "Use `do...end` for Phlex component `%<method>s`."

        def on_block(node)
          send_node = node.send_node

          if lowercase_call?(send_node) && node.keywords?
            register_braces_offense(node, send_node)
          elsif uppercase_call?(send_node) && node.braces? && !node.single_line?
            register_do_end_offense(node, send_node)
          end
        end

        private

        # HTML element names are lowercase, contain no underscores, and have
        # no receiver. This excludes Rails helpers like render, link_to,
        # form_with, button_to, etc.
        def lowercase_call?(send_node)
          return false unless send_node.receiver.nil?

          name = send_node.method_name
          name.match?(/\A[a-z]/) && !name.to_s.include?("_") && name != :render # rubocop:disable Rails/NegateInclude
        end

        def uppercase_call?(send_node)
          send_node.method_name.match?(/\A[A-Z]/)
        end

        def register_braces_offense(node, send_node)
          message = format(MSG_USE_BRACES, method: send_node.method_name)

          add_offense(node, message: message) do |corrector|
            corrector.replace(node.loc.begin, "{")
            corrector.replace(node.loc.end, "}")
          end
        end

        def register_do_end_offense(node, send_node)
          message = format(MSG_USE_DO_END, method: send_node.method_name)

          add_offense(node, message: message) do |corrector|
            corrector.replace(node.loc.begin, "do")
            corrector.replace(node.loc.end, "end")
          end
        end
      end
    end
  end
end
