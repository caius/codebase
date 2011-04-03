$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'json'

require 'codebase/command'

trap("INT") { puts; exit }

module Codebase
  extend self
  
  class Error < RuntimeError; end
  class NotConfiguredError < StandardError; end
  class MustBeInRepositoryError < StandardError; end
  
  VERSION = "4.0.4"
  
  def run(command, args = [])
    load_commands
    command = 'help' if command.nil?
    if @commands[command]
      options = parse_options(args)
      if args.size < @commands[command][:required_args].to_i
        puts "error: #{@commands[command][:usage]}"
        puts "See 'cb help #{command}' for usage."
        Process.exit(1)
      end
      @commands[command][:block].call(options, *args)
    else
      puts "Command not found. Check 'cb help' for full information."
    end
  end
  
  def command(command, options = {}, &block)
    @commands = Hash.new if @commands.nil?
    @commands[command] = Hash.new
    @commands[command][:description] = @next_description
    @commands[command][:usage] = @next_usage
    @commands[command][:flags] = @next_flags
    @commands[command][:required_args] = (options[:required_args] || 0)
    @commands[command][:block] = Command.new(block)
    @next_usage, @next_description, @next_flags = nil, nil, nil
  end
  
  def commands
    @commands
  end
  
  def desc(value)
    @next_description = Array.new if @next_description.nil?
    @next_description << value
  end
  
  def usage(value)
    @next_usage = value
  end
  
  def flags(key, value)
    @next_flags = Hash.new if @next_flags.nil?
    @next_flags[key] = value
  end
  
  def load_commands
    Dir[File.join(File.dirname(__FILE__), 'commands', '*.rb')].each do |path|
      Codebase.module_eval File.read(path), path
    end
  end
  
  def parse_options(args)
    idx = 0
    args.clone.inject({}) do |memo, arg|
      case arg
      when /^--(.+?)=(.*)/
        args.delete_at(idx)
        memo.merge($1.to_sym => $2)
      when /^--(.+)/
        args.delete_at(idx)
        memo.merge($1.to_sym => true)
      when "--"
        args.delete_at(idx)
        return memo
      else
        idx += 1
        memo
      end
    end
  end
  
end

Codebase.desc "Displays this help message"
Codebase.usage "cb help [command]"
Codebase.command "help" do |command|
  if command.nil?
    puts "The Codebase Gem allows you to easily access your Codebase account functions from the"
    puts "command line. The functions below outline the options which are currently available."
    puts    
    for key, command in Codebase.commands.sort_by{|k,v| k}
      puts "    #{key.ljust(15)} #{command[:description].first}"
    end
    puts
    puts "For more information see http://docs.codebasehq.com/gem"
    puts "See 'cb help [command]' for usage information."
  else
    if c = Codebase.commands[command]
      puts c[:description]
      if c[:usage]
        puts
        puts "Usage:"
        puts "     #{c[:usage]}"
      end
      if c[:flags]
        puts
        puts "Options:"
        for key, value in c[:flags]
          puts "     #{key.ljust(15)} #{value}"
        end
      end
    else
      puts "Command Not Found. Check 'point help' for a full list of commands available to you."
    end
  end
end

Codebase.desc "Displays the current version number"
Codebase.usage "cb version"
Codebase.command "version" do
  puts "Codebase Gem Version #{Codebase::VERSION}"
end
