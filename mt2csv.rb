#!/usr/bin/env ruby
# mt2csv.rb
# 
### this script works for tran/ac analysis with sweeping case

require 'optparse'

class MT_atd  # mt/MT 

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
    opts.banner = "Usage: #{$0} [options] <cdl>"
    
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
  
  ## Check hspice or adit
  if (row_no == 0)   
    puts "TOOL => " + row if (debug)
    if row =~ /hspice/i
      hspice = true
      adit = false
    elsif row =~ /adit/i
      adit = true
      hspice = false
    else
      puts "Unknown format ..."
    end
    next
  end
  ## Check title
  if (row_no == 1)   ## row of title
    puts "TITLE => " + row if (debug)
    csv_arr << row if (options[:title])
    next
  end
  
  if (hspice)

    if first_alter == 1
      if row =~ /alter#/i
        line_block = row_no - 1
        first_alter = 0
      else
        line_block = row_no
      end
      puts "LINE_BLOCK => #{line_block}" if debug
    end

    next unless row.length > 0  # ignore blank lines
    next if row =~ /^\s+$/ # weed out white space line
    next if row =~ /^\s*\*/ # weed out * comment
    next if row =~ /^\s*#/  # weed out # comment
    next if row =~ /^\$DATA/ # weed out repeated $DATA ...
    next if row =~ /^\.TITLE/ # weed out repeated .TITLE ...

    puts "ROW"+row_no.to_s+" => " + row + " counter" + counter.to_s if (debug)
    
    if line_block == 1  ## one line per block 
      
      line = row
      csv_str = line.strip.gsub(/\s+/,",")   # weed out pre/trailing space and replace with comma
      puts csv_str+"\n" if (debug)
      csv_arr << csv_str

    elsif line_block > 1  ## more than one line per block
      
      if (counter == 0)
        line = row
        counter = counter + 1
      elsif ( counter == line_block-1)
        line = line + " " + row
        csv_str = line.strip.gsub(/\s+/,",")   # weed out pre/trailing space and replace with comma
        puts csv_str+"\n" if (debug)
        csv_arr << csv_str
        ## reset counter and line buffer
        counter = 0
        line = ""
      else
        line = line + " " + row
        counter = counter + 1
      end
      
    else   ## invalid option
      puts "WRONG => Invalid option -l"
    end
    
    
  elsif (adit)
    next unless row.length > 0  # ignore blank lines
    next if row =~ /^\s+$/ # weed out white space line
    next if row =~ /^\s*#/  # weed out # comment
    next if row =~ /^"\.TITLE/ # weed out repeated .TITLE ...
        
    if row =~ /^\s*\*/ # weed out * comment but keep sweep parameter/value
      if row =~ /\s+Sweep:\s*(\S+)=(\S+)/i
        sweep_par = $1
        sweep_val = $2
        puts "SWEEP => " + sweep_par + " = " + sweep_val + "\n" if (debug)
        header_coming = true
      end
      next
    end

    puts "ROW"+row_no.to_s+" => " + row + " counter" + counter.to_s if (debug)

    if line_block == 1  ## one line per block 
      
      if (header_coming)
        line = sweep_par + " " + row
        counter = counter + 1
      else
        line = sweep_val + " " + row
        counter = counter + 1
      end
      csv_str = line.strip.gsub(/\s+/,",")   # weed out pre/trailing space and replace with comma
      puts csv_str+"\n" if (debug)
      csv_arr << csv_str
      header_coming = false
      
    elsif line_block > 1  ## more than one line per block
      
      if (counter == 0)
        if (header_coming)
          line = sweep_par + " " + row
          counter = counter + 1
        else
          line = sweep_val + " " + row
          counter = counter + 1
        end
      elsif ( counter == line_block-1)
        line = line + " " + row
        csv_str = line.strip.gsub(/\s+/,",")   # weed out pre/trailing space and replace with comma
        puts csv_str+"\n" if (debug)
        csv_arr << csv_str
        ## reset counter and line buffer and turn header_coming off
        counter = 0
        line = ""
        header_coming = false
      else
        line = line + " " + row
        counter = counter + 1
      end
      
    else
      line = line + " " + row
      counter = counter + 1
    end
    

  else  ## other file format ....
    
  end
  
  
end

csv_arr.each { |line| csv_file.print(line+"\n") }

p csv_arr if (debug)

end
