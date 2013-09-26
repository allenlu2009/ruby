#!/usr/bin/env ruby -W0
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
#require 'csv_atd.rb'
require 'cdl_atd.rb'

class CDLcheck < CDL_atd
  
  def check
    ## Second, read csv file 
    
    regex_str_hsh = {
      'DIODE' => '/^\s*D\S+\s+\S+\s+\S+\s+(\S+)/i',
      'BIPOLAR' => '/^\s*Q\S+\s+\S+\s+\S+\s+\S+\s+(\S+)/i',
      'MOS' => '/^\s*M\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+(\S+)/i',
      'SUBCKT' => '/^\s*\.SUBCKT\s+(\S+)/i'
      
    }
    
    
    regex_str_hsh.each do |key, val|
      p val if @debug
      match_arr = self.regex_search(val)
      puts "=========== #{key} ===================="
      h = Hash.new(0)
      match_arr.each { |v| h.store(v, h[v]+1) }
      h.each do |element, count|
        puts "#{element} ==> #{count}"
      end
    end
    
  end

end # class CDLcheck


#### main starts here ####

if __FILE__ == $0
  

  def get_lines(filename)
    return File.open(filename, 'r').readlines
  end
  
  options = {}
  optparse = OptionParser.new do |opts|
    
    opts.banner = "Usage: #{$0} <in.cdl> -c <in.csv> [options]"
    
    # Define the options, and what they do
    options[:debug] = false
    opts.on( '--debug', 'Debug enable' ) do
      options[:debug] = true
    end
    
    options[:hsp] = false
    opts.on( '-h', '--hsp', 'Output hspice cdl' ) do
      options[:hsp] = true
    end
    
    options[:lvs] = false
    opts.on( '-v', '--lvs', 'Output calibre lvs cdl' ) do
      options[:lvs] = true
    end
    
    options[:lpe] = false
    opts.on( '-p', '--lpe', 'Output calibre lpe cdl' ) do
      options[:lpe] = true
    end
    
    options[:csv] = nil
    opts.on( '-c', '--csv FILE', 'Input csv FILE' ) do |file|
      options[:csv] = file
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

  if  ARGV.length < 1
    puts optparse
    exit
  end

  puts "OPTION:"
  puts "Enable Debug"           if options[:debug]  
  puts "Output Calibre lvs cdl" if options[:lvs]
  puts "Output Calibre lpe cdl" if options[:lpe]
  puts "Output Hspice cdl"      if options[:hsp]
  puts "Csv file #{options[:csv]}" if options[:csv]
  puts "Output file #{options[:outfile]}" if options[:outfile]
  puts "Logging to file #{options[:logfile]}" if options[:logfile]
  
  debug = options[:debug] 
  puts __FILE__ if debug
  puts $0 if debug
  
  ## input cdl filename
  in_cdl = ARGV[0]  
  
  ## input csv filename
  in_csv = options[:csv]  
  
  ## First, read input netlist
  f1 = CDLcheck.new(in_cdl, debug)

  ## Next, use csv file for next conversion
  f1.check
 
  ## output cdl filename
  out_cdl = options[:logfile] ? options[:logfile] : in_cdl + ".log"
  
  #cdl_file = File.new(out_cdl, "w")

  #f1.print_cdl(cdl_file)
  
end

