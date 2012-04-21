#!/usr/bin/ruby
# csv2csv.rb
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

class CSV_processing
  
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
      @table = FCSV.read(@filename, :headers => true, :return_headers => false, :header_converters => :symbol)
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

  debug = true   ## true: print debug message
  
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
  c1 = CSV_processing.new(in_csv)
  c1.CSV2table(options[:header], options[:remove])
  #c1.table_print if (debug)

  ## option -p plotting function. Use gnuplot to plot output directly
  if (options[:plot])  
    #c1.CSV2table(options[:header], options[:remove]) ## need do it again if after -v option, compact_table_by_var change @table 
    plot_arr = c1.columns(options[:plot])
    #p plot_arr if debug
    c1.plot(plot_arr)
  end

  ## option -t, print csv header
  header_arr = c1.headers
  p header_arr if (options[:title])  ## print csv header if option -t

  ## option -v, select variable array and generate a new table/csv file
  ## defaul to save all variables; or option -v variablws
  var_arr = options[:variable]? options[:variable]: header_arr
  table_tmp = c1.compact_table_by_var(var_arr)
  csv_final = table_tmp.to_csv
  #p csv_final

  ## write to output csv file
  File.open(out_csv, 'w') {|f| f.write(csv_final)}



  #options[:variable].each do |var|
  #  puts c1.column(var)
  #end
  #puts table[tt]
  #c1.CSV_print
  #c1.CSV_transpose
  #c1.CSV_column(1)
  
end
