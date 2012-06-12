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

class Netlist2cdl < CDL_atd

  def convert(in_csv, hsp, lvs, lpe)
    ## Second, read csv file 
    c1 = CSV_atd.new(in_csv, false, true, false, @debug)
    
    header_arr = []
    tail_arr = []
    
    table_out = c1.table
    table_out.each do |row|
      p row if @debug
      
      next if row[:mode] =~ /^\s*#/    ## ignore comment row
      
      #puts row[:option]!=nil if @debug
      #puts !(row[:option]=~/lvs/) if @debug
      
      ## for lvs mode, skip when option is NOT empty and NOT include lvs
      next if lvs && (row[:option]!=nil) && !(row[:option]=~/lvs/)
      ## for lpe mode, skip when option is NOT empty and NOT include lpe
      next if lpe && (row[:option]!=nil) && !(row[:option]=~/lpe/)
      ## for hsp mode, skip when option is NOT empty and NOT include hsp
      next if hsp && (row[:option]!=nil) && !(row[:option]=~/hsp/)
      
      #p row if @debug

      if row[:mode] == "SR"  ## String Replace
        self.str_replace(row[:old], row[:new])
      end
      
      if row[:mode] == "SD"  ## String Delete
        self.str_delete(row[:old])
      end
      
      if row[:mode] == "WR"  ## Word Replace
        self.word_replace(row[:old], row[:new])
      end
      
      if row[:mode] == "WD"  ## Word Delete
        self.word_delete(row[:old])
      end
      
      if row[:mode] == "RD"  ## Regex Delete
        self.regex_delete(row[:old])
      end
      
      if row[:mode] == "RR"  ## Regex Replace
        self.regex_replace(row[:old], row[:new])
      end
      
      if row[:mode] == "SH"  ## String Header
        header_arr << row[:new] + "\n"
      end

      if row[:mode] == "ST"  ## String Tail
        tail_arr << row[:new] + "\n"
      end
      
    end
    c1.print_table if @debug
    
    self.add_header(header_arr)
    self.add_tail(tail_arr)
    
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

  lvs = options[:lvs]
  lpe = options[:lpe]
  hsp = options[:hsp]

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
  f1 = Netlist2cdl.new(in_cdl, debug)

  ## Next, use csv file for next conversion
  f1.convert(in_csv, hsp, lvs, lpe)
 
  ## output cdl filename
  out_cdl = options[:outfile] ? options[:outfile] : in_cdl + ".cdl"
  
  cdl_file = File.new(out_cdl, "w")

  ## add sysinfo before final output file
  f1.add_sysinfo("*", argstr)
  
  f1.print_cdl(cdl_file)
  
end

