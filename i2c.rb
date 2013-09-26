#/usr/bin/env ruby
# i2c.rb  by Allen Lu 2010_01_19
# ruby i2c.rb i2c.pat outfile

def get_lines(filename)
  return File.open(filename, 'r').readlines
end

### Step 1: read all tester basic code
code_0 = get_lines("./i2c/i2c_0_d15.stil")    ## 0
code_1 = get_lines("./i2c/i2c_1_d15.stil")    ## 1
code_a = get_lines("./i2c/i2c_ack_d15.stil")  ## Ack
code_n = get_lines("./i2c/i2c_nack_d15.stil") ## Nack
code_s = get_lines("./i2c/i2c_start.stil")    ## Start
code_p = get_lines("./i2c/i2c_stop.stil")     ## Stop/Pause
code_d = get_lines("./i2c/i2c_dd_d15.stil")   ## Delay
code_r = get_lines("./i2c/i2c_read_d15.stil") ## Read

#### Step 2: read input translated i2c command pattern
pat = get_lines(ARGV[0])
pat_str = pat.join("")  # join all rows into a big string
pat_str.gsub!("\n", "")  # remove \n 
code_arr = pat_str.split("")  # split the big string into each basic code
#p pat
p code_arr


##### Step 3: transform code into tester readable format
tstr_arr = []   ### final tester array
code_arr.each do |code|
  case code
  when "0"
    tstr_arr = tstr_arr + code_0
  when "1"
    tstr_arr = tstr_arr + code_1
  when "A", "a"
    tstr_arr = tstr_arr + code_a
  when "N", "n"
    tstr_arr = tstr_arr + code_n
  when "S", "s"
    tstr_arr = tstr_arr + code_s
  when "P", "p"
    tstr_arr = tstr_arr + code_p
  when "D", "d"
    tstr_arr = tstr_arr + code_d
  when "R", "r"
    tstr_arr = tstr_arr + code_r
  else
    puts "Unknown code: "+code
  end
end
#p tstr_arr

### Step 4: Write into output file
tstrfile = File.new(ARGV[1], "w")
tstr_arr.each do |row|
  tstrfile << row
end
tstrfile.close()
