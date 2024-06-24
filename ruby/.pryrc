# frozen_string_literal: true

Pry.config.prompt = Pry::Prompt[:default]

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

  def my_methods
    (methods - Object.methods).sort
  end
end

# Editors
Pry.config.editor = "nvim"

# Sort hash keys by name, instead of string length
module PpSortHash
  def pretty_print(q)
    q.group(1, '{', '}') {
      q.seplist(self.sort_by {|k, _| k.to_s } , nil, :each) {|k, v|
        q.group {
          q.pp k
          q.text '=>'
          q.group(1) {
            q.breakable ''
            q.pp v
          }
        }
      }
    }
  end
end

class Hash
  prepend PpSortHash
end
