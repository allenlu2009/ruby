# Example 3 - Read File with Exception Handling
counter = 1
begin
  file = File.new("c:/emacs/ruby/readfile.rb", "r")
  while (line = file.gets)
    puts "#{counter}: #{line}"
    counter = counter + 1
  end
  file.close
rescue => err
  puts "Exception: #{err}"
  err
end
