#!/usr/bin/env ruby
# ft2csv.rb
# 
### this script works for YiChang to convert ft log to csv
### only extract the register value

require 'optparse'

class FT_atd  # mt/MT 

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

  
 def initialize(filename)
   @debug = false
   @filename = filename
   @file_arr = get_lines(@filename)
 end
  
end  # class

  def get_lines(filename)
    return File.open(filename, 'r').readlines
  end

#### main starts here ####

if __FILE__ == $0
  
  options = {}
  optparse = OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options] <ft_log>"
    
    options[:debug] = false
    opts.on( '--debug', 'Debug enable' ) do
      options[:debug] = true
    end
    
    options[:outfile] = nil
    opts.on( '-o', '--outfile FILE', 'Output csv; default <cdl>.csv' ) do |file|
      options[:outfile] = file
    end
    
    options[:line] = 1
    opts.on( '-l', '--line Num', Integer, 'Variable takes how many line; default 1' ) do |ln|
      options[:line] = ln
    end
    
    #options[:parameter] = []
    #opts.on( '-v', '--variable a,b,c', Array, 'Variable to save' ) do |par|
    #  options[:parameter] = par
    #end
    
    # This displays the help screen, all programs are
    # assumed to have this option.
    opts.on( '-h', '--help', 'Display this screen' ) do
      puts opts
      exit
    end
  end


  begin optparse.parse! ARGV
  rescue OptionParser::InvalidOption => err
    puts err
    puts optparse
    exit 
  end

  if (ARGV.length < 1)
    puts optparse
    exit
  end
  
  puts "OPTION:"
  puts "Enable debug" if options[:debug]
  puts "Output file: #{options[:outfile]}" if options[:outfile]
  #puts "Variables: #{options[:parameter]}" if options[:parameter]
  puts "Variable line block.: #{options[:line]}" 
  
  debug = options[:debug] 
  puts __FILE__ if debug
  puts $0 if debug
  
  ## input file
  incdl = ARGV[0]  
  
  ## output csv file
  out_csv = options[:outfile] ? options[:outfile] : incdl + ".csv"
  csv_file = File.new(out_csv, "w")
  
  
  ### Step1: read final.mt and separate into multiple files
  #file_arr = get_lines(incdl)  ## read file as an array
  #file_str = file_arr.to_s     ## convert it into string
  
  line_block = options[:line]
  #p line_block if (debug)
  
  counter = 0
  hspice = false
  adit = false
  line = ""
  sweep_par = ""
  sweep_val = ""
  header_coming = false
  csv_arr = []
  
  first_alter = 1
  
  get_lines(incdl).each_with_index do |row, row_no|  ## row_no starts from 0
  row.chomp!
    
    if row_no == 0
      csv_str = "Addr(dec),Val(hex)"
      csv_arr << csv_str
    end

    if (row =~ /^\s*addr\S*\s+0x(\S+)\s+0x(\S+)\s+/i)
      #csv_str = $1.to_i(16).to_s + "," + $3.to_i(16).to_s
      csv_str = $1.to_i(16).to_s + "," + $2.downcase
      csv_arr << csv_str
    end

  end
  
  csv_arr.uniq!
  csv_arr.each { |line| csv_file.print(line+"\n") }
  
  p csv_arr if (debug)
  
end
