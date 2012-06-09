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

class Cdl2cdl

  def get_lines(filename)
    return File.open(filename, 'r').readlines
  end
 

  def print_sysinfo(outfile, cc='#', argstr=ARGV)
    date = `date`.chomp
    pwd  = `pwd`.chomp
    hostname = `hostname`.chomp
    user = `whoami`.chomp
    outfile.print("#{cc} Generated #{date} by #{user}\n")
    outfile.print("#{cc} #{hostname}:#{pwd}\n")
    outfile.print("#{cc} #{$0} #{argstr}\n\n")
  end

  

end # class Cdl2cdl


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

  if (ARGV.length < 1 || options[:csv] == nil)
    puts optparse
    exit
  end

  puts "OPTION:"
  puts "Enable Debug" if options[:debug]  
  puts "Calibre lvs cdl" if options[:lvs]
  puts "Calibre lpe cdl" if options[:lpe]
  puts "Hspice cdl" if options[:hsp]
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
  f1 = CDL_atd.new(in_cdl)

  ## Second, read csv file 
  c1 = CSV_atd.new(in_csv, false, true, false, debug)
  
  header_arr = []
  tail_arr = []

  table_out = c1.table
  table_out.each do |row|
    p row if debug

    next if row[:mode] =~ /^\s*#/    ## ignore comment row

    puts options[:lvs] if debug
    puts row[:option]!=nil if debug
    puts !(row[:option]=~/lvs/) if debug

    ## for lvs mode, skip when option is NOT empty and NOT include lvs
    next if options[:lvs] && (row[:option]!=nil) && !(row[:option]=~/lvs/)
    ## for lpe mode, skip when option is NOT empty and NOT include lpe
    next if options[:lpe] && (row[:option]!=nil) && !(row[:option]=~/lpe/)
    ## for hsp mode, skip when option is NOT empty and NOT include hsp
    next if options[:hsp] && (row[:option]!=nil) && !(row[:option]=~/hsp/)

    p row if debug

    if row[:mode] == "SR"  ## String Replace
      f1.str_replace(row[:old], row[:new])
    end

    if row[:mode] == "WR"  ## String Replace
      f1.word_replace(row[:old], row[:new])
    end

    if row[:mode] == "RD"  ## Regex delete
      f1.regex_delete(row[:old])
    end

    if row[:mode] == "RR"  ## Regex delete
      f1.regex_replace(row[:old], row[:new])
    end

    if row[:mode] == "SH"  ## String header
      header_arr << row[:new] + "\n"
    end

    if row[:mode] == "ST"  ## String trailing
      tail_arr << row[:new] + "\n"
    end

  end
  c1.print_table if debug
  
  f1.add_header(header_arr)
  f1.add_tail(tail_arr)
  f1.add_sysinfo("*", argstr)
  
  ## output cdl filename
  out_cdl = options[:outfile] ? options[:outfile] : in_cdl + ".cdl"
  
  cdl_file = File.new(out_cdl, "w")
  
  f1.print_cdl(cdl_file)
  
end

