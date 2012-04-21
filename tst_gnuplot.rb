require 'rubygems.rb'
require 'gnuplot.rb'
Gnuplot.open { |gp|
  Gnuplot::Plot.new( gp ) { |plot|
#    plot.output "testgnu.gif"
#    plot.terminal "gif"
    plot.xrange "[-10:10]"
    plot.title  "Sin Wave Example"
    plot.ylabel "x"
    plot.xlabel "sin(x)"
    
    plot.data << Gnuplot::DataSet.new( "sin(x)" ) { |ds|
      ds.with = "linespoints"
      ds.linewidth = 3
    }
    plot.data << Gnuplot::DataSet.new( "cos(x)" ) { |ds|
      ds.with = "impulses"
      ds.linewidth = 3
    }
  }
}
