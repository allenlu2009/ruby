require 'rubygems.rb'
require 'gnuplot.rb'


x = [1.0, 2.0, 3.0, 4.0, 5.0]
y = [2.1, 4.3, 5.8, 8.1, 9.9]

Gnuplot.open { |gp|
  Gnuplot::Plot.new( gp ) { |plot|
    #    plot.output "testgnu.gif"
    #    plot.terminal "gif"
    # plot.xrange "[-10:10]"
    # plot.title  "Sin Wave Example"
    # plot.ylabel "x"
    # plot.xlabel "sin(x)"
    plot.data << Gnuplot::DataSet.new( [x, y] ) { |ds|
      ds.with = "linespoints"
      ds.linewidth = 3
    }
  }
}
