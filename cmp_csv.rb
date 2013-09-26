#!/usr/bin/env ruby
###!/usr/bin/env ruby  ; the above is good for rvm
# convert io csv file into verilog stub
# make sure to use bus option, otherwise the file is too long (but OK)
# io2verilog.rb input.csv -o output.v.stub

#require "spiceclass"
require 'optparse'
require 'csv'

# This hash will hold all of the options
# parsed from the command-line by
# OptionParser.
options = {}

optparse = OptionParser.new do |opts|
  # Set a banner, displayed at the top
  # of the help screen.
  opts.banner = "Usage: #{$0} [options] <cdl>"
 
  options[:top] = nil
  opts.on( '-t', '--top SUBCKT', 'Top level subckt' ) do |top|
    options[:top] = top
  end
  
  options[:pin] = false
  opts.on( '-p', '--pininfo', 'Cdl includes pininfo' ) do
    options[:pin] = true
  end
  
  options[:bus] = false
  opts.on( '-b', '--bus', 'Use bus to group pins' ) do
    options[:bus] = true
  end
  
  options[:outfile] = nil
  opts.on( '-o', '--outfile FILE', 'Output hier; default <cdl>.lib' ) do |file|
    options[:outfile] = file
  end
  
  # This displays the help screen, all programs are
  # assumed to have this option.
  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end

##### Parse the command-line #######
argstr = ARGV.join(" ")

begin optparse.parse! ARGV
rescue OptionParser::InvalidOption => err
  puts err
  puts optparse
  exit 
end

if (ARGV.length < 2)
  puts optparse
  exit
end

puts "Output file: #{options[:outfile]}" if options[:outfile]
puts "Top circuit: #{options[:top]}" if options[:top]


##### Parse input csv file and throw output to list_arr, port_arr
incsv1 = ARGV[0]
incsv2 = ARGV[1]

csv1_arr = []
csv2_arr = []

CSV.open(incsv1, 'r') do |row|
  #p row
  csv1_arr << row
end

CSV.open(incsv2, 'r') do |row|
  #p row
  csv2_arr << row
end

csv1_arr.sort!
csv2_arr.sort!

#p csv1_arr
#p csv2_arr

puts "Compare starts ..."
if csv1_arr == csv2_arr
  puts "All ports MATCH!!!!"
else
  puts "#{incsv1} remaining ports not match!!" 
  p csv1_arr - csv2_arr
  puts "#{incsv2} remaining ports not match!!" 
  p csv2_arr - csv1_arr
end
