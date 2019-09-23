# frozen_string_literal: true

rails_info = "#{Rails.application.class.module_parent_name.downcase}|#{Rails.env}" if defined?(Rails)

# Prompt
Pry.config.prompt = [
  proc do |conf|
    tree = conf.binding_stack.map { |stack| Pry.view_clip stack.eval("self") } * " / "
    info = [rails_info, tree].compact * "|"
    "[#{info}]> "
  end
]

# History
Pry.config.history.file = %(#{ENV['HOME']}/.irb-save-history) # Keep IRB and Pry history the same.

# Aliases
Pry.commands.alias_command "w", "whereami"

# Hit Enter to repeat last command
Pry::Commands.command /^$/, "repeat last command" do
  _pry_.run_command Pry.history.to_a.last
end

if defined?(PryByebug)
  # Pry.commands.alias_command "c", "continue"
  # Pry.commands.alias_command "s", "step"
  # Pry.commands.alias_command "n", "next"
  # Pry.commands.alias_command "f", "finish"
  # Pry.commands.alias_command "bp", "break"
  # Pry.commands.alias_command "bpe", "break --enable"
  # Pry.commands.alias_command "bpd", "break --disable"
  # Pry.commands.alias_command "bpD", "break --delete"
  # Pry.commands.alias_command "bpc", "break --disable-all"
  # Pry.commands.alias_command "bpC", "break --delete-all"
  # Pry.commands.alias_command "bph", "break --help"
end

class Object
  def wtf?(m)
    method(m).source_location
  end
end

# Editors
Pry.config.editor = "nvim"

