#/usr/bin/ruby


##### step 1: repeat each code 4 times 
dd = File.new('OFDM_ROM.double','w') 

### add initial data if needed
data = "11111111"
dd.puts("#{data}")
dd.puts("#{data}")

flag = 0
open('OFDM_ROM.far') do |fd| 
  fd.each do |line| 
    if (flag == 0)
      dd.puts(line) 
      dd.puts(line)
      dd.puts(line) 
      dd.puts(line)
      dd.puts(line) 
      dd.puts(line)
      dd.puts(line) 
      dd.puts(line)
      flag = 1
    else
      dd.puts(line) 
      dd.puts(line)
      dd.puts(line) 
      dd.puts(line)
    end
  end 
end 
dd.close


#### step 2: generate vector file

out = File.new('OFDM_ROM.out','w') 

#### put nanosim header ###
out.puts("; Simulator : Nanosim")
out.puts(";		        ########################")
out.puts(";		        #    Vector file       #")
out.puts(";		        ########################")
out.puts(";              The input pin name :           ")
out.puts(";         TOP name :   ROM32k               ") 
out.puts("; A15,A14,A13 A12,A11,A10,A9,A8,A7,A6,A5,A4,A3,A2,A1,A0")
out.puts(";     CS  --chip select ba   : low active            ")
out.puts(";     OE  --Output Enable    : low active           ")
out.puts(";     CK  --Syn Clock        : System Clock          ")
out.puts(";       radix     1444111                             ")
out.puts(";       slope 1.0                                    ")
out.puts(";                                                    ")
out.puts("; A15,A14,A13 A12,A11,A10,A9,A8,A7,A6,A5,A4,A3,A2,A1,A0,CS,OE,CK")
out.puts(";                                                    ")
out.puts(";		AAAAAAAAAAAAACOC  ")
out.puts(";		0000000000000EE ")
out.puts(";		CBA9876543210NNK")
out.puts(";")
out.puts("type vec")
out.puts("signal A15 A14 A13 A12 A11 A10 A9 A8 A7 A6 A5 A4 A3 A2 A1 A0 CS OE CK DO7 DO6 DO5 DO4 DO3 DO2 DO1 DO0 ")
out.puts("slope 0.2")
out.puts("radix		       111111111111111111111111111")
out.puts("io		       iiiiiiiiiiiiiiiiiiioooooooo")
out.puts("")


times	= 9000   #initial start time  9ns
temp    = 9800   # period = 2 * (temp+temp_2)
temp2  = 200    # rise and fall time
cs 	= 1
oe	= 1
ck	= 0
address = 0

i = 0
## generate waveform
open('OFDM_ROM.double') do |fd| 
  fd.each do |line| 
    if (i == 0)  ## Initial condition
      puts "#{(times.to_f/1000).to_s}             #{"%016d"%address.to_s(base=2)}#{cs}#{oe}#{ck}#{line}"
      out.puts("#{(times.to_f/1000).to_s}             #{"%016d"%address.to_s(base=2)}#{cs}#{oe}#{ck}#{line}" )
    elsif (i%4 == 1)
      times += temp2
      cs 	= 1
      oe	= 1
      ck	= 1
      puts "#{(times.to_f/1000).to_s}             #{"%016d"%address.to_s(base=2)}#{cs}#{oe}#{ck}#{line}"
      out.puts("#{(times.to_f/1000).to_s}             #{"%016d"%address.to_s(base=2)}#{cs}#{oe}#{ck}#{line}" )
    elsif (i%4 == 2)
      times += temp
      cs 	= 1
      oe	= 1
      ck	= 0 
      puts "#{(times.to_f/1000).to_s}             #{"%016d"%address.to_s(base=2)}#{cs}#{oe}#{ck}#{line}"
      out.puts("#{(times.to_f/1000).to_s}             #{"%016d"%address.to_s(base=2)}#{cs}#{oe}#{ck}#{line}" )
    elsif (i%4 == 3)
      times += temp2
      cs 	= 1
      oe        = 1
      ck	= 0
      puts "#{(times.to_f/1000).to_s}             #{"%016d"%address.to_s(base=2)}#{cs}#{oe}#{ck}#{line}"
      out.puts("#{(times.to_f/1000).to_s}             #{"%016d"%address.to_s(base=2)}#{cs}#{oe}#{ck}#{line}" )
    else              ## i%4 == 0 exclude i=0
      times += temp
      cs 	= 1
      oe	= 1
      ck	= 1
      puts "#{(times.to_f/1000).to_s}             #{"%016d"%address.to_s(base=2)}#{cs}#{oe}#{ck}#{line}"
      out.puts("#{(times.to_f/1000).to_s}             #{"%016d"%address.to_s(base=2)}#{cs}#{oe}#{ck}#{line}" )
      address = address+1   ### increment module 4
    end
    i = i+1
  end 
  puts "Address is #{address-1}"
end 


out.close
