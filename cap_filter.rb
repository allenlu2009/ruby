#!/usr/bin/env ruby -W0
# cast2_cvt_cdl_u110nm.rb
#
# Author: Allen Lu
# 
#
# 2010/05/12: first version


def get_lines(filename)
  return File.open(filename, 'r').readlines
end


require 'optparse'

# This hash will hold all of the options
# parsed from the command-line by
# OptionParser.
options = {}

optparse = OptionParser.new do |opts|
  # Set a banner, displayed at the top
  # of the help screen.
  opts.banner = "Usage: #{$0} [options] <in.cdl> <out.cdl>"
 
  # Define the options, and what they do
  options[:force] = false
  opts.on( '-f', '--force', 'Force to overwrite output file' ) do
    options[:force] = true
  end
  
  options[:cap] = 1.0
  opts.on( '-c', '--cap val', Float, 'cap threshold in fF' ) do |cap|
    options[:cap] = cap
  end
  
  options[:bracket] = false
  opts.on( '-b', '--bracket', 'Bracket <> -> []' ) do
    options[:bracket] = true
  end
  
  options[:dummy] = false
  opts.on( '-d', '--dummy', 'Dummy cap and resistor removal' ) do
    options[:dummy] = true
  end
  
  options[:logfile] = nil
  opts.on( '-l', '--logfile FILE', 'Write log to FILE' ) do|file|
    options[:logfile] = file
  end
  
  # This displays the help screen, all programs are
  # assumed to have this option.
  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end

# Parse the command-line. Remember there are two forms
# of the parse method. The 'parse' method simply parses
# ARGV, while the 'parse!' method parses ARGV and removes
# any options found there, as well as any parameters for
# the options. What's left is the list of files to resize.
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

puts "Remove cap less than #{options[:cap]} fF"
#puts "Force to overwrite output file" if options[:force]
#puts "Bracket <> -> []" if options[:bracket]
#puts "Dummy cap & resistor removal" if options[:dummy]
#puts "Logging to file #{options[:logfile]}" if options[:logfile]


cdl_out_file = File.new(ARGV[1], "w")

###### print header to output cdl file #################
date = `date`.chop
pwd  = `pwd`.chop
hostname = `hostname`.chop
user = `whoami`.chop

cdl_out_file.print(
"* cap_filter.rb filter cap value less than xxx fF
* generated #{date} by #{user}
* #{$0} #{argstr}
* #{hostname}:#{pwd}
\n")
########################################################


####################################################################

get_lines(ARGV[0]).each_with_index do |line, line_no|  ## row_no starts from 0
  
  ### find and replace using regex, with argument
  if options[:cap]
    regex = /^(C\S+)\s+(\S+)\s+(\S+)\s+(.*)f$/i   # C1 n1 n2 3.44f
    if (line =~ regex)
      if ($4.to_f < options[:cap])
        next
      end
    end

    regex = /^(C\S+)\s+(\S+)\s+(\S+)\s+(\d.*\d)$/i  # C1 n1 n2 3.44e-15
    if (line =~ regex)
      if ($4.to_f < options[:cap])
        next
      end
    end
  end
  
  cdl_out_file.print(line)
  
  
end ## get_lines



########################################################
cdl_out_file.close()
