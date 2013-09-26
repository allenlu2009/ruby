#/usr/bin/env ruby
# csv2hash.rb

require "csv"
require "faster_csv"
require 'rubygems'

class <<Hash
  def create(keys, values)
    self[*keys.zip(values).flatten]
  end
end

sp_array = Array.new

first = true
first_row = []

CSV.open("abc.csv","r"){|row|
  if first
    first = false
    first_row = row.to_a
  else
    result = Hash.create(first_row,row.to_a)
    sp_array <<result
  end

print row

}

