#!/usr/bin/ruby -W0
# cast2_cvt_cdl_u110nm.rb
#
# Author: Allen Lu
# 
#
# 2010/05/12: first version

## add the current directory to require search path
$: << File.dirname(__FILE__)   

#require 'rubygems'  # do "setenv RUBYOPT rubygems"
require 'fastercsv'
require 'optparse'
require 'csv_atd.rb'
require 'cdl_atd.rb'

class Tb2meas < CDL_atd

  ### remove any statement not related to hspice measurement
  ### refer hspice manual 
  def meas
    
    @title = @file_arr[0]

    ### Line based regex. Careful no support for multiple lines!!!
    meas_regex   = Regexp.new(/^\s*\.meas/i)
    para_regex   = Regexp.new(/^\s*\.para/i)
    temp_regex   = Regexp.new(/^\s*\.temp/i)
    opt_regex    = Regexp.new(/^\s*\.opt/i)
    fft_regex    = Regexp.new(/^\s*\.fft/i)
    end_regex    = Regexp.new(/^\s*\.end\b/i)
    data_regex   = Regexp.new(/^\s*\.data\b/i)
    endd_regex   = Regexp.new(/^\s*\.enddata\b/i)

    keep_regex   = Regexp.union(meas_regex, para_regex,
                                temp_regex, opt_regex,
                                fft_regex, end_regex,
                                data_regex, endd_regex)
    
    @file_arr.delete_if { |line| !(line =~ keep_regex)}

  end
  

  def add_title
    @file_arr.unshift(@title)
  end

end # class Tb2meas


#### main starts here ####

if __FILE__ == $0
  

  def get_lines(filename)
    return File.open(filename, 'r').readlines
  end
  
  options = {}
  optparse = OptionParser.new do |opts|
    
    opts.banner = "Usage: #{$0} <in.cdl> [options]"
    
    # Define the options, and what they do
    options[:debug] = false
    opts.on( '--debug', 'Debug enable' ) do
      options[:debug] = true
    end
    
    options[:outfile] = nil
    opts.on( '-o', '--outfile FILE', 'Output FILE' ) do |file|
      options[:outfile] = file
    end
    
    options[:logfile] = nil
    opts.on( '-l', '--logfile FILE', 'Write log to FILE' ) do |file|
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

  if (ARGV.length < 1 )
    puts optparse
    exit
  end

  puts "OPTION:"
  puts "Enable Debug"           if options[:debug]  
  puts "Output file #{options[:outfile]}" if options[:outfile]
  puts "Logging to file #{options[:logfile]}" if options[:logfile]
  
  debug = options[:debug] 
  puts __FILE__ if debug
  puts $0 if debug
  
  ## input cdl filename
  in_cdl = ARGV[0]  
  
  ## First, read input netlist
  f1 = Tb2meas.new(in_cdl, debug)

  ## Next, use csv file for next conversion
  f1.meas
 
  ## output cdl filename
  out_cdl = options[:outfile] ? options[:outfile] : "meas.sp"
  
  cdl_file = File.new(out_cdl, "w")

  ## add sysinfo before final output file
  f1.add_sysinfo("*", argstr)
  f1.add_title
  f1.print_cdl(cdl_file)
  
end

