#!/usr/bin/ruby
# simple_cli.rb

=begin rdoc
Parses command line options.
=end

class SimpleCLI

# CONSTANTS

  OPTIONS = {
    :version => ['-v', '--version'],
    :help    => ['-h', '--help'],
    :reset   => ['-r', '--reset']
  }

  USAGE =<<END_OF_USAGE
  
  This program understands the following options:
    -v, --version: displays
    -h, --help   : displays a message
    -r, --reset  : reset program
  With no command-line
  
END_OF_USAGE


  VERSION = 'Some project version'


# method

  def parse_opts(args)
    return option_by_args(args[0]) if understand_args?(args)
    display(USAGE)
  end

  private

  def display(content)
    puts content
  end
  
  def do_default()
    puts 'Default'
  end

  def option_by_args(arg)
    return display(VERSION) if OPTIONS[:version].include?(arg)
    return display(USAGE) if OPTIONS[:help].include?(arg)
    return reset() if OPTIONS[:reset].include?(arg)
    do_default()
  end

  def reset()
    puts 'reset'
  end
  
  def understand_args?(args)
    OPTIONS.keys.any? { |key| OPTIONS[key].include?(args[0]) }
  end

end

