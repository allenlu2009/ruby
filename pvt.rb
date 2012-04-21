#!/usr/bin/ruby
# simple_cli.rb

=begin rdoc
Generate process, voltage, and temperature conditions for hspice
=end

class Pvt
  
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
  def initialize()
    @nmos_core = ['S', 'T', 'F']
    @pmos_core = ['S', 'T', 'F']
    @nmos_io = ['S', 'T', 'F']
    @pmos_io = ['S', 'T', 'F']
    
    @volt_ratio = {'S' => 0.9, 'T' => 1.0, 'F' => 1.1}
    @temperature = {'S' => 125, 'T' => 30, 'F' => -20}
  end

  def go_pvt()
    @nmos_core.each { |nmos| puts nmos}
    @pmos_core.each { |nmos| puts nmos}
    @nmos_io.each { |nmos| puts nmos}
    @pmos_io.each { |nmos| puts nmos}
  end
  

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

