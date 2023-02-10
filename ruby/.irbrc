
# frozen_string_literal: true

# ARGV << "--readline"
# IRB.conf[:USE_READLINE] = true

require "pp"
require "rubygems"

def try_require(lib, gem = lib)
  require lib
  yield if block_given?
rescue LoadError
  puts "missing #{gem} gem"
end

# try_require "wirble" do
#   Wirble.init
#   Wirble.colorize
# end

# try_require "hirb" do
#   Hirb::View.enable
# end

try_require "ap", "awesome_print"

require "irb/completion"
require "irb/ext/save-history" do
  IRB.conf[:SAVE_HISTORY] = 1000
  IRB.conf[:HISTORY_FILE] = "#{ENV['HOME']}/.irb-save-history"
end

IRB.conf[:PROMPT_MODE]  = :SIMPLE
IRB.conf[:AUTO_INDENT]  = true

class Object
  def wtf?(m)
    method(m).source_location
  end
end

if ENV["RAILS_ENV"] || defined? Rails

  env = ENV["RAILS_ENV"] || Rails.env
  # Display the RAILS ENV in the prompt
  # ie : [Development]>>
  IRB.conf[:PROMPT][:CUSTOM] = {
    PROMPT_N: "[#{env.capitalize}]>> ",
    PROMPT_I: "[#{env.capitalize}]>> ",
    PROMPT_S: nil,
    PROMPT_C: "?> ",
    RETURN: "=> %s\n"
  }
  # Set default prompt
  IRB.conf[:PROMPT_MODE] = :CUSTOM
end

# try_require 'pry' do
#   Pry.start
#   exit
# end
