#!/usr/bin/ruby
# csv2spicetb.rb
# 
## This script processes the mt/MT csv file from hspice/adit for parameter sweeping 
## It is also used for general csv file processing
## Default csv file consists of header(1st row) and content (other rows)
##                      first_name, last_name, SSN, phone
##                      Allen,Lu,2323423,234-234423
##                      Bob,Ka,23423,234423-234423 ext23
## To remove repeated header from mt/MT csv file: use -r option, and header as column index
## For csv file without header: use -h option, and 0,1,2,3 as column index

require 'rubygems'
require 'fastercsv'
require 'optparse'
require 'gnuplot'

class CSV2SpiceTb

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
    @debug = true
    puts "Input csv file => #{filename}" if @debug; print "\n"
    @filename = filename
  end
  
  def CSV2table(header, remove)
    if !header  ## No header
      @table = FCSV.read(@filename, :headers => false, :return_headers => false, :header_converters => :symbol)
    elsif remove   ## remove repeat headers 
      @table = FCSV.read(@filename, :headers => :first_row, :return_headers => true, :header_converters => :symbol)
      self.delete_repeat_header
    else  ## normal header
      #@table = FCSV.read(@filename, :headers => true, :return_headers => false, :header_converters => :symbol)
      @table = FCSV.read(@filename, :headers => true, :return_headers => false, 
                         :header_converters => lambda {|h| h.gsub(/ /,"").gsub(/\(/, "__").gsub(/\)/,"") })
    end
  end
  
  def delete_repeat_header
    header_row = @table[0]  ## get header row
    @table.delete_if { |row| row == header_row }  ## delete repeat header row
  end
  
  def headers
    ## return header and convert from symbol to string
    return @table.headers.collect {|e| e.to_s}
  end
  
  ## make testbench directory based on headers[0]. 
  ## The tbname is headers[0] <col[0]>_headers[1]<col[1]>_.... 
  def mk_tbdir(short, makefile)
    word_replace_hash =    {
      'ff=360x' => 'ff=400x'
      #'tsim=20u' => 'tsim=40u'
    }

    if !@table.headers  ## no header
      puts "ERROR => Need header information!"
      return 
    end
    
    ## parsing each row of csv to (i) create folder
    ## (ii) generate testbench
    tb_hsh = {}
    tb_arr = []
    @table.each do |row|
      
      ## step 1: create testbench hash
      name_arr = []
      p @table.headers
      @table.headers.each do |hh|
        if hh =~ /(\S+)__(\S+)/
          comp = $1
          unit = $2
          name_arr << (comp+row[hh]+unit)
        else
          name_arr << (hh+row[hh])
        end
      end

      if short
        tbname = name_arr[0]
      else
        tbname = name_arr.join("_")
      end
      tb_arr << tbname
      tb_hsh[tbname] = row
    end
    
    puts "WARNING => Exist null testbench!" if tb_arr.compact!
    puts "WARNING => Exist duplicate testbench!" if tb_arr.uniq!
    
    ## create test bench directory
    tb_hsh.each do |tbname, tb_row|
      puts tbname + " => " + tb_row.to_s if @debug
      ## create tb directory based on tbname
      tb_dir = Dir::pwd + "/" + tbname
      if ! FileTest::directory?(tb_dir)
        Dir::mkdir(tb_dir)
      end
    end

    ## create makefile
    if makefile
      mkFile = File.open("Makefile", "w") 
        ## print comment info
      mkFile.print("DIRS = \\\n")
      tb_arr.each do |tbname|
        mkFile.print("#{tbname} \\\n")
      end
      mkFile.print("\n\n")
      mkFile.print("catmt:\n")
      mkFile.print("\t./runcatmt\n")

      mkFile.print("\n\n")
      mkFile.print("all:\n")
      mkFile.print("\techo running all in .\n")
      mkFile.print("\t-for d in $(DIRS); do (cd $$d; make all); done")

      mkFile.print("\n\n")
      mkFile.print("clean:\n")
      mkFile.print("\techo running all in .\n")
      mkFile.print("\t-for d in $(DIRS); do (cd $$d; make clean); done")
      mkFile.close()
    end

    ## open input template file for testbnech generation
    file_arr = get_lines("template.sp")
    file_str = file_arr.to_s        


    ### Step 2: Parsing each line and processing
    regexp_hsh = {}
    @table.headers.each_with_index do |hh, col_no|
      next if col_no == 0  ## skip the first tb column
      if hh =~ /(\S+)__(\S+)/   ## extract unit
        var = $1
        unit = $2
        @table[hh] = @table[hh].map {|element| element+unit} ## []= to assign value
      else
        var = hh
      end
      regexp_var = Regexp.new(/(^\s*#{var}\s+\S+\s+\S+\s+)\S+(\s*.*\b)/i)
      regexp_hsh[hh] = regexp_var
    end
    p regexp_hsh
    self.table_print

    ## create test bench file
    tb_hsh.each do |tbname, tb_row|
      
      ### create testbench file
      tb_file = Dir::pwd + "/" + tbname + "/" + @table.headers[0].to_s + ".sp"
      spi_out = File.open(tb_file, "w")
      
      ## step 2: read template file and do global string replacement
      word_replace_hash.each do |old_str, new_str|
        file_str.gsub!(/#{old_str}/i, new_str) 
      end

      file_arr = file_str.split("\n")

      ## line base regular expression replacement
      file_arr.each_with_index do |line, line_no|  ## row_no starts from 0
        regexp_hsh.each do |regexp_key, regexp_var|
          if regexp_var.match(line)
            prefix_str = $1
            suffix_str = $2
            line.gsub!(regexp_var, "#{prefix_str}#{tb_row[regexp_key]}#{suffix_str}")
          end 
        end ## regexp_var
        spi_out.print(line + "\n")
      end ## file_arr
      spi_out.close()    
      
    end
    
  end
  
  def compact_table_by_var(var_arr)
    #self.table_print
    table_by_col = @table.by_col     ## duplicate table by col
    table_by_col.delete_if {|col| !var_arr.include?(col[0].to_s) }  ## remove col not include in var array
    if (@debug)
      @table.each do |col|
      #table_by_col.each do |col|
        #p col
      end
    end
    #self.table_print
    return table_by_col
  end
  
  # how to do a friend fucntion - print
  #def print(table)
  #  table.each do |row_or_col|
  #    p row_or_col
  #  end
  #end

  def table_print
    @table.each do |row|
      p row
    end
  end

  def CSV_print
    @csv_infile = FCSV.read(@filename)
    puts @csv_infile.inspect
  end

  def column(col_var)  ## return one column (as one array)
    return @table[col_var.to_sym]
  end
 
  def columns(col_var) ## return one or multiple columns (as a array of array)
    #table_print
    columns_arr_arr = []
    col_var.each do |var|
      columns_arr_arr << @table[var.to_sym]
      #p columns_arr_arr
    end
    return columns_arr_arr
  end

  def plot(arr)
    Gnuplot.open do |gp|
      Gnuplot::Plot.new( gp ) do |plot|
        plot.title @filename
        #plot.yrange  "[0:3000]"
        plot.data = [
                     Gnuplot::DataSet.new( arr ) { |ds|
                       ds.with = "lines"
                       ds.linewidth = 3
                     },
                     
                     Gnuplot::DataSet.new( arr ) { |ds|
                       ds.with = "points"
                       ds.linewidth = 3
                     }
                    ]
      end ## plot
    end  ## open
  end

end


#### main starts here

if __FILE__ == $0

debug = true
  
def get_lines(filename)
  return File.open(filename, 'r').readlines
end
  
  options = {}
  optparse = OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options] <csv>"
    
    options[:header] = true
    opts.on( '-h', '--header', 'NO header indication!' ) do
      options[:header] = false
    end
    
    options[:remove] = false
    opts.on( '-r', '--remove', 'Keep first header and remove repeat headers' ) do
      options[:remove] = true
    end
    
    options[:short] = false
    opts.on( '-s', '--short', 'Short directory' ) do
      options[:short] = true
    end
    
    options[:makefile] = false
    opts.on( '-m', '--makefile', 'create Makefile' ) do
      options[:makefile] = true
    end
    
    options[:plot] = nil
    opts.on( '-p', '--plot x,<y>', Array, 'Plot x or x,<y>' ) do |xy|
      options[:plot] = xy
    end
    
    options[:title] = false
    opts.on( '-t', '--title', 'Print csv file header' ) do
      options[:title] = true
    end
    
    options[:outfile] = nil
    opts.on( '-o', '--outfile FILE', 'Output csv; default <cdl>.csv' ) do |file|
    options[:outfile] = file
    end
    
    options[:line] = 1
    opts.on( '-l', '--line Num', Integer, 'Variable takes how many line; default 1' ) do |ln|
      options[:line] = ln
    end
    
    options[:variable] = nil
    opts.on( '-v', '--variable x,y,z', Array, 'Variable to save. Default all variables' ) do |var|
      options[:variable] = var
    end
    
    # This displays the help screen, all programs are
    # assumed to have this option.
    opts.on( '-i', '--info', 'Display this screen' ) do
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
  
  puts "Output File => #{options[:outfile]}\n" if options[:outfile]
  print "Save Variable => "; p options[:variable] if options[:variable]; print "\n"
  print "Plot Variable => "; p options[:plot] if options[:plot]; print "\n"
  puts "No Header" if !options[:header]
  puts "Remove Repeat Header!" if options[:remove]
  #puts "Variable line block.: #{options[:line]}" 
  
  ## input csv filename
  in_csv = ARGV[0]  
  
  ## output csv filename
  out_csv = options[:outfile] ? options[:outfile] : in_csv + ".csv"
  #csv_file = File.new(out_csv, "w")
  
  ## Initialize and option -h -r
  c1 = CSV2SpiceTb.new(in_csv)
  c1.CSV2table(options[:header], options[:remove])
  c1.table_print if (debug)

  ## option -t, print csv header
  header_arr = c1.headers
  p header_arr if (options[:title])  ## print csv header if option -t
  
  c1.mk_tbdir(options[:short], options[:makefile])

end
