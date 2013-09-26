#!/usr/bin/env ruby

out = File.new('temp2.txt','w') 
out.puts("This is a test") 
out.puts("another?line?of?text...") 
out.close 
 
open('temp2.txt') do |fd| 
  fd.each do |line| 
     puts line 
  end 
end 
 
#File.delete('temp2.txt')
