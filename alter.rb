#/usr/bin/ruby
# alter.rb
# ruby alter.rb tb_pll2_vco_pvt.mt*

require "csv"


ARGV.each do |filename|
  kk = Regexp.new(/\S+\.[a-z]*(\d+)/)  ## find mt$$ and use it as vco$$
  index = kk.match(filename)
  csvfilename = "vco" + index[1] + ".csv"
  puts csvfilename
  csvfile = File.new(csvfilename, "w")
  infile = File.new(filename, "r") 
  
  ## global variables
  header = []
  val_array = []
  val_array_odd = []
  header2 = []
  val_array2 = []
  pvt = " "
  v_ratio = 1

  first_line = true
  title = true
  third = true
  fourth = true
  odd = true
  
  freq = 0.0
  volt = 0.0
  
  infile.each do |row|
    if first_line  ## ignore the 1st row
      first_line = false
      next
    elsif title  ## use regex to extract the PVT info from 2nd row
      title = false
      regex = Regexp.new(/=\s*\((\S+)\s*,\s*(\S+)\*(\S+),\s*(\S+)\s*\)/) #pvt
      matchdata = regex.match(row)
      pvt = matchdata[1] + "_V" + matchdata[3] + "_" + matchdata[4]
      p pvt
      v_ratio = matchdata[3].to_f
      puts v_ratio
      next
    elsif third  ## combine 3rd+4th row into csv header line
      third = false
      header = row.split(' ')
      #p header
      next
    elsif fourth
      fourth = false
      header = header + row.split(' ')
      #p header
      header2 = ["vctl_vdd", pvt, pvt, "vctl"]  ## frequency and Kvco
      csvfile.print(header2.join(', '))
      csvfile << "\n"
      next
    else      ## combine data row
      val_array = row.split(' ')
      val_array.collect! {|i| i.to_f }
      if odd
        odd = false
        val_array_odd = val_array
      else
        odd = true
        val_array = val_array_odd + val_array 
        #p val_array
        vctrl_pwr = 1.2*v_ratio - val_array[0]
        val_array2 = [vctrl_pwr, val_array[3], (freq-val_array[3])/(volt-vctrl_pwr), val_array[0]]

        freq = val_array[3]
        volt = vctrl_pwr

        csvfile.print(val_array2.join(', '))
        csvfile << "\n"
      end
      
    end
  end
  
  infile.close()
  csvfile.close()
end
