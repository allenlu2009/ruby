#!/usr/bin/ruby
# mt2csv.rb
# 
### this script works for tran/ac analysis with sweeping case

require 'optparse'

class CDL_atd  # CDL of atd

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

  
  def str_replace(old_str, new_str,option="")
    @file_arr.each_with_index do |line, line_no|
      line.gsub!( /#{old_str}/i, "#{new_str}" ) 
    end
  end

  
  def str_delete(old_str, option="")
    @file_arr.each_with_index do |line, line_no|
      line.gsub!( /#{old_str}/i, "" ) 
    end
  end
  

  def word_replace(old_word, new_word,option="")
    @file_arr.each_with_index do |line, line_no|
      line.gsub!( /\b#{old_word}\b/i, "#{new_word}" ) 
    end
  end
  

  def word_delete(old_word, option="")
    @file_arr.each_with_index do |line, line_no|
      line.gsub!( /\b#{old_word}\b/i, "" ) 
    end
  end
  

  def regex_replace(regex_str, new_str,option="")
    regex = eval(regex_str) # convert string to regex
    @file_arr.each_with_index do |line, line_no|
      #if line =~ regex
        line.gsub!( regex, "#{new_str}" )
      #end 
    end
  end
  
  def regex_delete(regex_str)
    regex = eval(regex_str) # convert string to regex
    @file_arr.delete_if { |line| line =~ regex}
  end
  


  def print_cdl(outcdl=nil)
    @file_arr.each_with_index do |line, line_no|
      if outcdl
        outcdl.print(line)
      else
        puts line
      end
    end
  end


  def cap_filter(cap_val)

    si_unit = {
      'm' => 1.0e-3, 
      'u' => 1.0e-6, 
      'n' => 1.0e-9, 
      'p' => 1.0e-12, 
      'f' => 1.0e-15 
    }

    # C1 n1 n2 3.44f
    regex1 = /^\s*(C\S+)\s+(\S+)\s+(\S+)\s+(\S+)([m|u|n|p|f])$/i
    # C1 n1 n2 3.44e-15
    regex2 = /^\s*(C\S+)\s+(\S+)\s+(\S+)\s+(\d.*\d*)$/i   

    @file_arr.delete_if { |line| line =~ regex1 and 
      ($4.to_f*si_unit[$5] < cap_val*1.0e-15) }
    
    @file_arr.delete_if { |line| line =~ regex2 and 
      ($4.to_f < cap_val*1.0e-15) }
    
  end
  
  
  def add_header(header_arr)
    @file_arr = header_arr + @file_arr
  end

  
  def add_tail(tail_arr)
    @file_arr = @file_arr + tail_arr
  end


  def add_sysinfo(cc='#', argstr=ARGV)
    sysinfo_arr = []
    date = `date`.chomp
    pwd  = `pwd`.chomp
    hostname = `hostname`.chomp
    user = `whoami`.chomp
    sysinfo_arr << "#{cc} Generated #{date} by #{user}\n"
    sysinfo_arr << "#{cc} #{hostname}:#{pwd}\n"
    sysinfo_arr << "#{cc} #{$0} #{argstr}\n\n"

    @file_arr = sysinfo_arr + @file_arr
  end
  
  
end  # class


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
    opts.on( '-o', '--outfile FILE', 'Output cdl; default <cdl>.cdl' ) do |file|
      options[:outfile] = file
    end
    
    options[:cap] = nil
    opts.on( '--cap val', Float, 'ignore smaller cap in fF' ) do |cap|
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
    

    # This displays the help screen, all programs are
    # assumed to have this option.
    opts.on( '-h', '--help', 'Display this screen' ) do
      puts opts
      exit
    end
  end

  argstr = ARGV.join(" ")

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
  
  debug = options[:debug] 
  puts __FILE__ if debug
  puts $0 if debug
  
  ## input file
  in_cdl = ARGV[0]  
  
  f1 = CDL_atd.new(in_cdl)
  
  f1.cap_filter(options[:cap]) if options[:cap]

  f1.add_sysinfo("*", argstr)

  f1.print_cdl if debug

  ## output cdl file
  out_cdl = options[:outfile] ? options[:outfile] : in_cdl + ".cdl"
  cdl_file = File.new(out_cdl, "w")
  
  f1.print_cdl(cdl_file)

end
