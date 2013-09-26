#!/usr/bin/env ruby
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

#require 'rubygems'  # do "setenv RUBYOPT rubygems"
require 'fastercsv'
require 'optparse'
require 'gnuplot'

class CSV_atd   ## csv file for ATD post processing
  
  def initialize(filename, return_header=false, clean=true, no_header=false, debug=false)
    @debug = debug
    @filename = filename
    
    puts "open csv file => #{filename}" if @debug
    
    if no_header  ## No header
      @table = 
        FCSV.read(@filename, 
                  :headers => false, 
                  :return_headers => false)

    elsif return_header   ## return header 
      @table = 
        FCSV.read(@filename, 
                  :headers => :first_row, 
                  :return_headers => true, 
                  :header_converters => :symbol)
      
    else  ## normal header
      @table = 
        FCSV.read(@filename, 
                  :headers => :first_row, 
                  :return_headers => false,
                  :header_converters => lambda {|h| h.gsub(/ /,"").to_sym}
                  )
    end
    
    if (clean)
      @table.each do |row|       ## FIRST, delete empty field in row
        row.delete_if { |key, value| (value == nil) || (value == "\f")}
      end

      @table.delete_if {|row| row.empty?() }  ## NEXT, delete empty row

    end

  end


  def debug_msg(desc = nil)
    caller[0].rindex( /:(\d+)(:in (`.*'))?$/ )
    m = $3 ? "#{$3}, " : ""
    d = desc ? "#{desc}: m" : 'M'
    #puts "#{d}eached #{m}line #{$1} of file #{$`}"
    puts "#{d}ethod #{m}line #{$1}"
  end
  
  
  def delete_repeat_header
    header_row = @table[0]  ## get header row
    @table.delete_if { |row| row == header_row }  ## delete repeat header row
  end

  
  def headers
    ## return header and convert from symbol to string
    return @table.headers.collect {|e| e.to_s}
  end

  
  def table
    ## return header and convert from symbol to string
    return @table
  end

  
  ## remove col in var_arr
  ## legacy using compact_table_by_cols -> get_table_by_cols
  def compact_table_by_cols(var_arr)
    var_arr.each do |var|
      @table.by_col.delete(var)
    end
  end

  
  ## return table includes in var_array column
  def get_table_by_cols(var_arr)
    table_by_col = @table.by_col     ## duplicate table by col
    table_by_col.delete_if {|col| !var_arr.include?(col[0].to_s) }  
    return table_by_col
  end

  
  def add_table_by_col(header, column)
    @table[header.to_sym] = column
  end


  def print_table
    @table.each do |row|
      p row
    end
  end


  def print_CSV
    @csv_infile = FCSV.read(@filename)
    puts @csv_infile.inspect
  end


  def column(col_var)  ## return one column (as one array)
    return @table[col_var.to_sym]
  end

 
  def columns(col_var) ## return one or multiple columns (as a array of array)
    columns_arr_arr = []
    col_var.each do |var|
      columns_arr_arr << @table[var.to_sym]
      p columns_arr_arr if @debug
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

end # class CSV_atd


#### main starts here ####

if __FILE__ == $0
  
  options = {}
  optparse = OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options] <csv>"
    
    options[:debug] = false
    opts.on( '--debug', 'Debug enable' ) do
      options[:debug] = true
    end
    
    options[:no_header] = false
    opts.on( '-h', '--header', 'NO header indication!' ) do
      options[:no_header] = true
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
    
    options[:combine] = nil
    opts.on( '-c', '--combine FILE', 'Column combine another csv' ) do |file|
    options[:combine] = file
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

  puts "OPTION:"
  puts "Enable Debug" if options[:debug]  
  puts "Combine File => #{options[:combine]}" if options[:combine]
  puts "Output File => #{options[:outfile]}" if options[:outfile]
  puts "Save Variable => #{options[:variable]}" if options[:variable]
  puts "Plot Variable => #{options[:plot]}" if options[:plot]
  puts "No Header" if options[:no_header]
  puts "Remove Repeat Header!" if options[:remove]
  #puts "Variable line block.: #{options[:line]}" 

  debug = options[:debug] 
  puts __FILE__ if debug
  puts $0 if debug
  
  ## input csv filename
  in_csv = ARGV[0]  
  
  ## output csv filename
  out_csv = options[:outfile] ? options[:outfile] : in_csv + ".csv"
  
  ## Initialize and option -h -r
  if options[:remove]
    c1 = CSV_atd.new(in_csv, options[:remove], true, false, debug)
    c1.delete_repeat_header
  else
    c1 = CSV_atd.new(in_csv, options[:remove], true, false, debug)
  end

  c1.print_table if debug

  if options[:combine]
    c2 = CSV_atd.new(options[:combine], options[:remove], true, false, debug)
    c2.headers.each do |col|
      p c2.column(col) if debug
      c1.add_table_by_col(col, c2.column(col))
    end
    p c1.headers if debug
    c1.print_table if debug
  end
  
  ## option -p plotting function. Use gnuplot to plot output directly
  if (options[:plot])  
    plot_arr = c1.columns(options[:plot])
    c1.plot(plot_arr)
  end
  
  ## option -t, print csv header
  p c1.headers if (options[:title])  ## print csv header if option -t

  ## option -v, select variable array and generate a new table/csv file
  ## defaul to save all variables; or option -v variablws
  var_arr = options[:variable]? options[:variable]: c1.headers
  table_tmp = c1.get_table_by_cols(var_arr)
  csv_final = table_tmp.to_csv

  ## write to output csv file
  File.open(out_csv, 'w') {|f| f.write(csv_final)}
  
end
