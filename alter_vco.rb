#/usr/bin/env ruby
# alter_adit.rb
# ruby alter_adit.rb *.MT
### this script works for tran/ac analysis with sweeping case

def get_lines(filename)
  return File.open(filename, 'r').readlines
end

require 'rubygems'
require 'linefit'
require 'gnuplot.rb'


vth_arr = []
kvco_mean_arr = []  
vth_arr1 = []
kvco_mean_arr1 = []  

ARGV.each do |filename|
  p filename
  ###############################################################  
  ### Processing hspice.mt file and convert file into data array
  ###############################################################  
  
  ### data array of each file
  keys_arr = []   
  fout_arr = []   
  
  val_arr = []
  val_arr_part = []
  
  get_lines(filename).each_with_index do |row, row_no|  ## row_no starts from 0
    if (row_no < 4)  
      next
    elsif (row_no%2 == 0)     ## first data row
      val_arr_part = row.split(' ')
      val_arr = val_arr + val_arr_part
      next
    elsif (row_no%2 == 1) 
      val_arr_part = row.split(' ')
      val_arr = val_arr + val_arr_part
      # p val_arr
      
      keys_arr << val_arr[0]
      fout_arr << val_arr[3]
      
      val_arr = []  ## reset val_arr
      val_arr_part = [] 
      next
    else
      next
    end
  end

  ### processing within the current input file
  keys_arr.collect! {|x| x.to_f}
  fout_arr.collect! {|x| x.to_f}

  ## Step 1: keys_arr changed to reference to power
  v_ratio = 1.0
  keys_arr.collect! {|x| 1.2*v_ratio-x}

  fout_arr_remove0 = []
  keys_arr_remove0 = []

  for ss in (0...keys_arr.length)
    if (fout_arr[ss] == 0)
      next
    end
    if (keys_arr[ss] > 1.0)
      next
    end
    
    fout_arr_remove0 <<  fout_arr[ss]
    keys_arr_remove0 <<  keys_arr[ss]
  end

  p keys_arr
  p fout_arr
  p keys_arr_remove0
  p fout_arr_remove0


  lineFit = LineFit.new
  lineFit.setData(keys_arr_remove0, fout_arr_remove0)
  intercept, slope = lineFit.coefficients
  p intercept/slope * -1
  p slope

  vth_arr1 <<  intercept/slope*-1
  kvco_mean_arr1 << slope


  ##### Use gnuplot to plot output directly
  gnuopt = 0
  if (gnuopt == 1)
    Gnuplot.open do |gp|
      Gnuplot::Plot.new( gp ) do |plot|
        plot.title  filename
        plot.yrange  "[0:3000]"
        x = [0, 1.2]
        y = [intercept, 1.2*slope+intercept]
        plot.data = [
                     Gnuplot::DataSet.new( [x, y] ) { |ds|
                       ds.with = "lines"
                       ds.linewidth = 3
                     },

                     Gnuplot::DataSet.new( [keys_arr, fout_arr] ) { |ds|
                       ds.with = "points"
                       ds.linewidth = 3
                     }
                    ]
        
      end ## plot
    end  ## open

  end


  ## Step 2: find ring oscillator turn on voltage, vth 
  for ss in (0...keys_arr.length)
    if (fout_arr[ss] == 0)
      vth = keys_arr[ss]
      break
    end
  end
  
  ## Step 3: compute kvco data array
  fout_arr_shift = Array.new(fout_arr) ## copy fout_arr into fout_arr_shift
  fout_arr_shift.shift  ## remove the first element
  keys_arr_shift = Array.new(keys_arr) ## copy keys_arr into keys_arr_shift
  keys_arr_shift.shift  ## remove the first element
  kvco_arr = []
  for ss in (0...keys_arr_shift.length)
    kvco_arr << (fout_arr[ss] - fout_arr_shift[ss]) / (keys_arr[ss] - keys_arr_shift[ss])
  end
  kvco_arr << 0.0 ## append one more zero
  
  ## Step 4: remove unreasonable kvco value and compute average kvco
  kvco_threshold = fout_arr[0]/keys_arr[0]  ## use max ring osc frequency / max control voltage as threshold

  kvco_arr_remove_odd_val = Array.new(kvco_arr)
  for ss in (0...kvco_arr_remove_odd_val.length)
    if keys_arr[ss] > 1.0   ### remove kvco when cntrol voltage reference to power > 1.0V
      kvco_arr_remove_odd_val[ss] = 0.0
    end
  end
  
  kvco_arr_remove_odd_val.delete_if {|x| x < kvco_threshold}
  #p kvco_arr_remove_odd_val.reverse
  
  ## find kvco mean
  sum = 0
  kvco_arr_remove_odd_val.each { |x| sum = x+sum}
  kvco_mean = sum / kvco_arr_remove_odd_val.length  
  
  vth_arr <<  vth
  kvco_mean_arr << kvco_mean

end

p vth_arr
p vth_arr1
p kvco_mean_arr
p kvco_mean_arr1

###### Write into files for postprocessing
csvopt = 0
if (csvopt == 1)
  csvfile = File.new("tb_dcxo_impedance_110nm.csv", "w")

  title = ["110nm", "R10M", "R20M", "R40M", "R80M", "C10M", "C20M", "C40M", "C80M"]
  csvfile.print( title.join(', '))
  csvfile << "\n"
  
  header = ["ssss000","ssss200","ssss3ff","tttt000","tttt200","tttt3ff","ffff000","ffff200","ffff3ff"] 
  for ind in (0...keys_arr.length)
    row = [header[ind], r10m_arr[ind], r20m_arr[ind], r40m_arr[ind], r80m_arr[ind], c10m_arr[ind], c20m_arr[ind], c40m_arr[ind], c80m_arr[ind]]
  csvfile.print( row.join(', '))
    csvfile << "\n"
  end
  
  csvfile.close()
end
#########################################



##### Use gnuplot to plot output directly
gnuopt = 1
if (gnuopt == 1)
  kkk = [1, 2, 3]
  ggg = [3, 3, 8]

  Gnuplot.open { |gp|
    Gnuplot::Plot.new( gp ) { |plot|
      plot.xrange "[0:20]"
      plot.title  "Sin Wave Example"
      plot.ylabel "x"
      plot.xlabel "sin(x)"
      
      plot.data << Gnuplot::DataSet.new( [vth_arr]) { |ds|
        ds.with = "linespoints"
        ds.linewidth = 3
      }
      
      #plot.data << Gnuplot::DataSet.new( [vth_arr1]) { |ds|
      #  ds.with = "linespoints"
      #  ds.linewidth = 3
      #}
    }
  }
  
end ## if
