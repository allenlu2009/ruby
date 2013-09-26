#!/usr/bin/env ruby
# mkdir.rb
# 
### only works for no sweeping case; for sweeping case, use alter_vco.rb

def get_lines(filename)
  return File.open(filename, 'r').readlines
end

dirname = ["tb_msdll_ringosc_400x_0100", "tb_msdll_ringosc_400x_0101","tb_msdll_ringosc_400x_0110","tb_msdll_ringosc_400x_0111","tb_msdll_ringosc_400x_1000","tb_msdll_ringosc_400x_1001","tb_msdll_ringosc_400x_1010","tb_msdll_ringosc_400x_1011"]

word_replace_hash =    {
#'SSSS' => 'FFFF',
'ff=166x' => 'ff=400x',
'tsim=20u' => 'tsim=40u'
}

code_hash =    {
"0000"    => ["0", "0", "0", "0"],  
"0001"    => ["0", "0", "0", "vd12"],  
"0010"    => ["0", "0", "vd12", "0"],  
"0011"    => ["0", "0", "vd12", "vd12"],  
"0100"    => ["0", "vd12", "0", "0"],  
"0101"    => ["0", "vd12", "0", "vd12"],  
"0110"    => ["0", "vd12", "vd12", "0"],  
"0111"    => ["0", "vd12", "vd12", "vd12"],  
"1000"    => ["vd12", "0", "0", "0"],  
"1001"    => ["vd12", "0", "0", "vd12"],  
"1010"    => ["vd12", "0", "vd12", "0"],  
"1011"    => ["vd12", "0", "vd12", "vd12"],  
"1100"    => ["vd12", "vd12", "0", "0"],  
"1101"    => ["vd12", "vd12", "0", "vd12"],  
"1110"    => ["vd12", "vd12", "vd12", "0"],  
"1111"    => ["vd12", "vd12", "vd12", "vd12"]
}


dirname.each do |xdir|

  #p xdir
  ### create directory and copy template into file
  dir_name = Dir::pwd + "/" + xdir
  if ! FileTest::directory?(dir_name)
    Dir::mkdir(dir_name)
  end
  
  filename = Dir::pwd + "/" + xdir + "/" + "pre_msdll_v2c_top.sp"
  cdl_out_file = File.open(filename, "w")

  ### processing output file  
  xdir =~ /\S+_(\d\d\d\d)/i
  code = $1
  code_arr = code_hash[code]
  p code_arr
  
  file_arr = get_lines("template") 
  file_str = file_arr.to_s        
  
  ### Step 1:  Global replacement in replace_list, text only
  word_replace_hash.each do |old_str, new_str|
    file_str.gsub!(/#{old_str}/i, new_str) 
  end
  #print file_str
  
  ### Step 2: Parsing each line and processing
  file_arr = file_str.split("\n")
  file_arr.each_with_index do |line, line_no|  ## row_no starts from 0
    
    line.gsub!(/^vfr3\s+frange\[3\].*/i, "vfr3   frange\[3\] 0 #{code_arr[0]}") 
    line.gsub!(/^vfr2\s+frange\[2\].*/i, "vfr2   frange\[2\] 0 #{code_arr[1]}") 
    line.gsub!(/^vfr1\s+frange\[1\].*/i, "vfr1   frange\[1\] 0 #{code_arr[2]}") 
    line.gsub!(/^vfr0\s+frange\[0\].*/i, "vfr0   frange\[0\] 0 #{code_arr[3]}") 

    cdl_out_file.print(line + "\n")
  end ## file_arr
  cdl_out_file.close()    

end
