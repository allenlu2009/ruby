#!/usr/bin/ruby
# reg2i2c.rb  by Allen Lu 2010_01_19
# ruby reg2i2c.rb reg.in i2c.pat

def get_lines(filename)
  return File.open(filename, 'r').readlines
end

# to_i(16) works in 1.8.6; need other way to work in 1.6.8
#def hex2bin(hexcode)
#  return hexcode.to_i(16).to_s(2).rjust(8, "0")  ## 8-bit with leading 0
#end


def hex2bin(hexcode)
  code_arr = hexcode.split("")

  bin_str = ""   ### final bin string
  code_arr.each do |code|
    case code
    when "0"
      bin_str = bin_str + "0000"
    when "1"
      bin_str = bin_str + "0001"
    when "2"
      bin_str = bin_str + "0010"
    when "3"
      bin_str = bin_str + "0011"
    when "4"
      bin_str = bin_str + "0100"
    when "5"
      bin_str = bin_str + "0101"
    when "6"
      bin_str = bin_str + "0110"
    when "7"
      bin_str = bin_str + "0111"
    when "8"
      bin_str = bin_str + "1000"
    when "9"
      bin_str = bin_str + "1001"
    when "A", "a"
      bin_str = bin_str + "1010"
    when "B", "b"
      bin_str = bin_str + "1011"
    when "C", "c"
      bin_str = bin_str + "1100"
    when "D", "d"
      bin_str = bin_str + "1101"
    when "E", "e"
      bin_str = bin_str + "1110"
    when "F", "f"
      bin_str = bin_str + "1111"
    else
      puts "Unknown code: "+code
    end
  end
  #p bin_str
  return bin_str
end


i2c_addr_wrt = "9e"
i2c_addr_rd  = "9f"

i2c_str_arr = []
#### Step 2: read input translated i2c command pattern
reg = get_lines(ARGV[0])
reg.each do |row|
  if (row =~ /^wt\s+(\S+.*)/i)   ### i2c write command with wt, write i2c register
    row_dig = $1
    pat_arr = row_dig.split(" ")
    print "wt "+ i2c_addr_wrt + " "
    p pat_arr
    ## translate command into i2c code
    i2c_str = "S" + hex2bin(i2c_addr_wrt) + "A"
    pat_arr.each do |hexword|
      i2c_str = i2c_str + hex2bin(hexword) + "A"
    end
    i2c_str = i2c_str + "P"
    i2c_str_arr << i2c_str
    p i2c_str
    next
  elsif (row =~ /^rt\s+(\S+.*)/i)  ### i2c read command with rd; write i2c first, then read
    row_dig = $1
    pat_arr = row_dig.split(" ")

    if (pat_arr.size <= 2)
      rd_count = 1
    else
      rd_count = pat_arr.pop.to_i   ### read count is the last number, default 1
    end

    print "rt "+ i2c_addr_rd + " " + rd_count.to_s + " "
    p pat_arr
    ## translate command into i2c code
    i2c_str = "S" + hex2bin(i2c_addr_wrt) + "A"   ## first write
    pat_arr.each do |hexword|
      i2c_str = i2c_str + hex2bin(hexword) + "A"
    end
    i2c_str = i2c_str + "P" 

    read_pat = "ARRRRRRRR"
    i2c_str = i2c_str + "S" + hex2bin(i2c_addr_rd) + read_pat*rd_count + "NP"  ## then read
    i2c_str_arr << i2c_str
    p i2c_str
    next
  elsif (row =~ /^delay\s+(\d*)/i)  ### delay
    row_dig = $1
    print "delay "+ $1 + "\n"
    i2c_str = "D" * row_dig.to_i
    i2c_str_arr << i2c_str
    p i2c_str
    next
  else                   ### else ignore
    puts "IGNORE ==> " + row
    next
  end
end

### Step 3: Write into output file
patfile = File.new(ARGV[1], "w")
i2c_str_arr.each do |row|
  patfile << row
  patfile << "\n"
end
patfile.close()
