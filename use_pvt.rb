#!/usr/bin/ruby
# use_cli.rb

=begin rdoc
Please refer to the SimpleCLI Class for documentation.
=end

require 'pvt'

pvt = Pvt.new()
pvt.parse_opts(ARGV)
