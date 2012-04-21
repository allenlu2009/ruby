#/usr/bin/ruby
# i2c_d10.rb
# ruby i2c_d10.rb xxx

def get_lines(filename)
  return File.open(filename, 'r').readlines
end

require 'rubygems'
require 'linefit'
require 'gnuplot.rb'


d0 = get_lines("./i2c/i2c_0_d15.stil")
d1 = get_lines("./i2c/i2c_1_d15.stil")
da = get_lines("./i2c/i2c_ack_d15.stil")
dn = get_lines("./i2c/i2c_nack_d15.stil")
ds = get_lines("./i2c/i2c_start.stil")
dp = get_lines("./i2c/i2c_stop.stil")
dd = get_lines("./i2c/i2c_dd_d15.stil")
dr = get_lines("./i2c/i2c_read_d15.stil")

p d0
p "\n"
p d1
p "\n"
p da
p "\n"
p dn
p "\n"
p ds
p "\n"
p dp
p "\n"
p dd
p "\n"
p dr
p "\n"

