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
## parsing sequence:
## 0. use header as symbol for all processing! Don't alter header
## 1. remove comment columns : header starts with #
## 2. put unit from header to table:  header with (pF)
## then two things: 1. create tb name and directory
##                  2. create regex for template.sp
## 3. .param  and  1*vvcc etc.



## add the current directory to require search path
$: << File.dirname(__FILE__)   

#require 'rubygems'  ## ==> setenv RUBYOPT "rubygems"
require 'fastercsv'
require 'optparse'
require 'gnuplot'
require 'csv_atd.rb'

class CSV2SpiceTb < CSV_atd  ## CSV2SpiceTb derives from CSV_atd

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


  def remove_comment_col  ## comment column header start with #
    comment_arr = []
    @table.headers.compact.each do |hh|
      comment_arr << hh  if hh.to_s =~ /^\s*#/   
    end
    self.compact_table_by_cols(comment_arr)
  end


  def add_unit_to_col   ## header with paranthesis : (pF)
    @table.headers.compact.each do |hh|
      if hh.to_s =~ /(\S+)\((\S+)\)/   ## extract unit
        var = $1
        unit = $2
        @table[hh] = @table[hh].map {|element| element+unit}
      end
    end
  end

  
  def generate_tb_item(short)

    ## check input csv has header, if NO, print ERROR message.
    if !@table.headers  ## no header
      puts "ERROR => Need header information!"
      return 
    else
      p @table.headers.compact if (@debug)
    end
    
    nzeros = case @table.length
               when 0..9 then 1
               when 10..99 then 2
               when 100..999 then 3
               when 1000..9999 then 4
               else 5
             end

    tb_hsh = {}
    tb_arr = []
    
    @table.each do |row|
      next if row.empty?()

      ## generate testbench items per row, default long format
      ## tb_dac12_res700_comp40pF => 17th row

      itemName_arr = []
      
      @table.headers.compact.each_with_index do |hh, col_no|

        if col_no == 0   ## add leading zero for easier sorting tb item
          itemName_arr << hh.to_s+row[hh].rjust(nzeros,"0")
        else
          ## the following regexp separate comp from unit
          if hh.to_s =~ /(\S+)\((\S+)\)/   
            comp = $1
            itemName_arr << comp+row[hh]
          elsif hh.to_s =~ /(\S+)\*(\S+)/
            comp = $1
            itemName_arr << comp+row[hh]
          elsif hh.to_s =~ /\.param(\S+)/i
            comp = $1
            itemName_arr << comp+row[hh]
          else
            itemName_arr << hh.to_s+row[hh]
          end
        end ## col_no

      end ## |hh, col_no|
      
      if short
        tbitem = itemName_arr[0]
      else
        tbitem = itemName_arr.join("_")
      end ## short
      
      ## check if tbitem exists
      puts "WARNING => Duplicate testbench #{tbitem}!" if tb_arr.include?(tbitem)
      tb_arr << tbitem
      tb_hsh[tbitem] = row
      
    end  ## do |row|

    ## Ruby 1.8 does not support ordered hash, return tb_arr, tb_hsh
    ## Ruby 1.9 support ordered hash, return tb_hsh, tb_arr is from tb_hsh.keys
    return tb_arr, tb_hsh  
  end


  def create_tb_directory(tb_arr, path="./")
    if ! FileTest::directory?(path)
      Dir::mkdir(path)
    end

    tb_arr.each do |tbitem|
      ## create tb directory based on tbitem
      tb_dir = path + "/" + tbitem
      p tb_dir if @debug
      if ! FileTest::directory?(tb_dir)
        Dir::mkdir(tb_dir)
      end
    end
  end


  def update_tb_table
    regexp_hsh = {}
    
    @table.headers.compact.each_with_index do |hh, col_no|

      next if col_no == 0  ## skip the first tb column

      if hh.to_s =~ /(\S+)\((\S+)\)/   ## extract unit
        var = $1
        unit = $2
        regexp_var = Regexp.new(/(^\s*#{var}\s+\S+\s+\S+\s+)\S+(\s*.*$)/i)

      elsif hh.to_s =~ /(\S+)\*(\S+)/   ## extract vvcc
        var = $1
        unit = $2
        @table[hh] = @table[hh].map {|element| element+"*"+unit} ## []= to assign value
        regexp_var = Regexp.new(/(^\s*#{var}\s+\S+\s+\S+\s+)\S+(\s*.*$)/i)

      elsif hh.to_s =~ /\.param(\S+)/   ## extract .param
        var = $1
        regexp_var = Regexp.new(/(^\s*\.param.*\s+#{var}\s*=\s*)\S+(\s*.*$)/i)
      else
        var = hh.to_s
        regexp_var = Regexp.new(/(^\s*#{var}\s+\S+\s+\S+\s+)\S+(\s*.*$)/i)
      end

      regexp_hsh[hh] = regexp_var

    end
    p regexp_hsh if @debug
    self.print_table if @debug
    
    return regexp_hsh
  end


  def create_makefile(tb_arr, path="./")
    ## First create master Makefile, then Makefile in each testbench directory
    if ! FileTest::directory?(path)
      Dir::mkdir(path)
    end
    mkfile = path + "/Makefile"
    p mkfile if @debug
    mkFile = File.open(mkfile, "w") 

    ## print comment info
    mkFile.print("PROJ = janus\n")
    mkFile.print("SCRIPT = ~/scripts\n")
    mkFile.print("PROJ_SCRIPT = ~/projects/$(PROJ)/analog/script\n")

    mkFile.print("DIRS = \\\n")
    tb_arr.each do |tbname|
      mkFile.print("#{tbname} \\\n")
    end
    mkFile.print("\n\n")
    mkFile.print("catmt:\n")
    mkFile.print("\t$(PROJ_SCRIPT)/runcatmt\n")

    mkFile.print("\n\n")
    mkFile.print("post:\n")
    mkFile.print("\t$(PROJ_SCRIPT)/mt2csv.rb final.mt -o final.mt.csv\n")
    mkFile.print("\t$(PROJ_SCRIPT)/csv_atd.rb -r final.mt.csv -o final.csv\n")
    mkFile.print("\t$(PROJ_SCRIPT)/csv_atd.rb ../tb.csv -c final.csv -o tb_final.csv\n")
    
    mkFile.print("\n\n")
    mkFile.print("all:\n")
    mkFile.print("\techo running all in .\n")
    mkFile.print("\t-for d in $(DIRS); do (cd $$d; make all); done\n")
    mkFile.print("\tmake catmt\n")
    mkFile.print("\tmake post\n")
    
    mkFile.print("\n\n")
    mkFile.print("clean:\n")
    mkFile.print("\techo running all in .\n")
    mkFile.print("\t-for d in $(DIRS); do (cd $$d; make clean); done")
    mkFile.close()

    ## create Makefile in test bench directory 
    tb_arr.each do |tbitem|
      
      ### create testbench file
      mkfile = path + "/" + tbitem + "/Makefile"
      mkFile = File.open(mkfile, "w")
      
      tbfile_prefix = @table.headers[0].to_s
      ## print comment info
      mkFile.print("all:\n")
      mkFile.print("\t hspice -i #{tbfile_prefix}.sp -o #{tbfile_prefix}.lis\n")
      
      mkFile.print("\n\n")
      mkFile.print("clean:\n")
      mkFile.print("\trm -rf *.tr* *.mt* *.cx* *.lis *.pa* *.st* *.ac* *.ic* *.ma* *.TR* *.MT*\n")

      mkFile.close()
      
    end
  end

  
  ## make testbench directory based on headers[0]. 
  ## The tbname is headers[0] <col[0]>_headers[1]<col[1]>_.... 
  def mk_testbench(short, makefile, path)
    
    ## (0) remove comment column (header starts with #)
    self.remove_comment_col
    self.add_unit_to_col
   
    # (i) create testbench items and put into tb_hsh 
    # tb_arr = tb_hsh.keys but not preserve created order
    # therefore, return both tb_arr and tb_hsh in Ruby 1.8
    # Ruby 1.9 support ordered hash, only return tb_hsh is OK
    tb_arr, tb_hsh = self.generate_tb_item(short)
    
    ## (ii) create tb items directory
    self.create_tb_directory(tb_arr, path)
    
    ## create makefile if --makefile
    self.create_makefile(tb_arr, path) if makefile
    
    ## (iii) update table based on header and return regexp hash
    regexp_hsh = self.update_tb_table
    
    ## Open input template file for testbnech file generation
    file_arr = get_lines("template.sp")
    file_str = file_arr.to_s        

    ## Parsing each line and processing
    word_replace_hash =    {
      'ff=360x' => 'ff=400x'
      #'tsim=20u' => 'tsim=40u'
    }

    ## create testbench file for each tbitem
    tb_hsh.each do |tbitem, tb_row|
      
      ### create testbench file
      #tb_file = Dir::pwd + "/" + tbitem + "/" + @table.headers[0].to_s + ".sp"
      tb_file = path + "/" + tbitem + "/" + @table.headers[0].to_s + ".sp"
      tb_sp = File.open(tb_file, "w")
      
      ## global string replacement
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
        tb_sp.print(line + "\n")
      end ## file_arr

      tb_sp.close()    

    end  ## tb_hsh
    
  end  ## mk_testbench

end # class CSV2SpiceTb


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
    
    options[:short] = false
    opts.on( '-s', '--short', 'Short directory' ) do
      options[:short] = true
    end
    
    options[:makefile] = false
    opts.on( '--makefile', 'create Makefile' ) do
      options[:makefile] = true
    end
    
    options[:path] = "./"
    opts.on( '-p', '--path PATH', 'tb directory and makefile PATH' ) do |pp|
    options[:path] = pp
    end
    
    options[:title] = false
    opts.on( '-t', '--title', 'Print csv file header' ) do
      options[:title] = true
    end
    
    #options[:outfile] = nil
    #opts.on( '-o', '--outfile FILE', 'Output csv; default <cdl>.csv' ) do |file|
    #options[:outfile] = file
    #end
    
    #options[:line] = 1
    #opts.on( '-l', '--line Num', Integer, 'Variable takes how many line; default 1' ) do |ln|
    #  options[:line] = ln
    #end
    
    #options[:variable] = nil
    #opts.on( '-v', '--variable x,y,z', Array, 'Variable to save. Default all variables' ) do |var|
    #  options[:variable] = var
    #end
    
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
  puts "PATH => #{options[:path]}\n" if options[:path]
  puts "Tb directory in short format" if options[:short]
  puts "Create Makefile!" if options[:makefile]
  
  debug = options[:debug] 
  puts __FILE__ if debug
  puts $0 if debug
  
  ## input csv filename
  in_csv = ARGV[0]  
  
  ## output csv filename
  out_csv = options[:outfile] ? options[:outfile] : in_csv + ".csv"
    
  ## Initialize and option -h -r
  c1 = CSV2SpiceTb.new(in_csv)  ## with normal header
  c1.print_table if debug

  ## option -t, print csv header
  p c1.headers if options[:title]  ## print csv header if option -t
  
  c1.mk_testbench(options[:short], options[:makefile], options[:path])
  
end
