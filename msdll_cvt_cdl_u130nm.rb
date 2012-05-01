#!/usr/bin/ruby -W0
# msdll_cvt_cdl_u130nm.rb
#
# Author: Allen Lu
# 
#
# 2010/05/12: first version


def get_lines(filename)
  return File.open(filename, 'r').readlines
end


require 'optparse'

# This hash will hold all of the options
# parsed from the command-line by
# OptionParser.
options = {}

optparse = OptionParser.new do |opts|
  # Set a banner, displayed at the top
  # of the help screen.
  opts.banner = "Usage: #{$0} [options] <in.cdl> <out.cdl>"
 
  # Define the options, and what they do
  options[:lvs] = false
  opts.on( '-l', '--lvs', 'Convert cdl for lvs' ) do
    options[:lvs] = true
  end
  
  options[:spice] = false
  opts.on( '-s', '--spice', 'Convert cdl for simulation' ) do
    options[:spice] = true
  end
  
  options[:force] = false
  opts.on( '-f', '--force', 'Force to overwrite output file' ) do
    options[:force] = true
  end
  
  options[:cap] = false
  opts.on( '-c', '--cap', 'CPP -> MOMCAPS' ) do
    options[:cap] = true
  end
  
  options[:bracket] = false
  opts.on( '-b', '--bracket', 'Bracket <> -> []' ) do
    options[:bracket] = true
  end
  
  options[:dummy] = false
  opts.on( '-d', '--dummy', 'Dummy cap and resistor removal' ) do
    options[:dummy] = true
  end
  
  # This displays the help screen, all programs are
  # assumed to have this option.
  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end

# Parse the command-line. Remember there are two forms
# of the parse method. The 'parse' method simply parses
# ARGV, while the 'parse!' method parses ARGV and removes
# any options found there, as well as any parameters for
# the options. What's left is the list of files to resize.
argstr = ARGV.join(" ")

begin optparse.parse! ARGV
rescue OptionParser::InvalidOption => err
  puts err
  puts optparse
  exit 
end

if (ARGV.length < 2)
  puts optparse
  exit
end

if options[:spice]
  options[:dummy] = false
end

if options[:lvs]
  options[:dummy] = true
  options[:bracket] = true
end

puts "CDL for lvs" if options[:lvs]
puts "CDL for hspice simulation" if options[:spice]
puts "Force to overwrite output file" if options[:force]
puts "CPP -> MOMCAPS" if options[:cap]
puts "Bracket <> -> []" if options[:bracket]
puts "Dummy cap & resistor removal" if options[:dummy]

cdl_out_file = File.new(ARGV[1], "w")

###### print header to output cdl file #################
date = `date`.chop
pwd  = `pwd`.chop
hostname = `hostname`.chop
user = `whoami`.chop

cdl_out_file.print(
"* msdll_cvt_cdl_u110nm.rb convert netlist to cdl
* generated #{date} by #{user}
* #{$0} #{argstr}
* #{hostname}:#{pwd}
* .option scale=0.9
\n")
########################################################



### It matches the whole word, don't put partial word!!
word_replace_hash =    {
#"N_12_HSL130E"    => "N_12_HSL110E",       ## core device
#"P_12_HSL130E"    => "P_12_HSL110E",
"NM"              => "N_12_HSL130E", 
"PM"              => "P_12_HSL130E",  
#"N_12_LLL130E"    => "N_12_LLL110E",
#"P_12_LLL130E"    => "P_12_LLL110E",
#"N_33_L130E"      => "N_33_L110E",         ## IO device
#"P_33_L130E"      => "P_33_L110E",
"NM3"             => "N_33_L130E",
"PM3"             => "P_33_L130E",
#"DION_L130E"      => "DION_L110E",         ## diode
#"DIOP_L130E"      => "DIOP_L110E",
"DN"              => "DION_L130E",
"DP"              => "DIOP_L130E",
#"PNP_V50X50_L130E"=> "PNP_V45X45_L110E",   ## BJT
#"RNNPO_L130E"     => "RNNPO_L110E",        ## poly resistor
#"RNPPO_L130E"     => "RNPPO_L110E",
"RNNPO_FUSION"    => "RNNPO_L130E",
"RNPPO_FUSION"    => "RNPPO_L130E"
}


### Remove or comment the following regex, line based #############
dmy_cap_regex   = Regexp.new(/^C.*dmy/i)   
dmy_res_regex   = Regexp.new(/^R.*dmy/i)
par_cap_regex   = Regexp.new(/^C.*par/i)
cc0_cap_regex   = Regexp.new(/^CC0/i)
cc2_cap_regex   = Regexp.new(/^CC2/i)
breakcell_regex = Regexp.new(/\/\s*BreakCell\S*\s*$/i)
corner_regex    = Regexp.new(/\/\s*CORNER\s*$/i)
ddionw_regex    = Regexp.new(/^DDIONW\S*/i)
rm_line_regex   = Regexp.union(dmy_cap_regex, dmy_res_regex, 
                             par_cap_regex, par_cap_regex, 
                             breakcell_regex, corner_regex, 
                             ddionw_regex, cc0_cap_regex,
                             cc2_cap_regex)
####################################################################

#p filename
file_arr = get_lines(ARGV[0])  ## read file as an array
file_str = file_arr.to_s        ## convert it into string

### Step 1:  Global replacement in replace_list, text only
word_replace_hash.each do |old_str, new_str|
  file_str.gsub!(/\b#{old_str}\b/i, new_str) 
end
#print file_str

### Step 1a: Global replacement for bracket
if options[:bracket]
  file_str.gsub!(/</, '[')
  file_str.gsub!(/>/, ']')
end

### Step 3: Parsing each line and processing
file_arr = file_str.split("\n")
file_arr.each_with_index do |line, line_no|  ## row_no starts from 0
  
  ## the following processing is line dependent
  
  ### remove line match with regex
  if options[:dummy]
    if (rm_line_regex.match(line))
      next
    end
  end
  
  ### find and replace using regex, only once and no argument
  line.gsub!(/\bgnd!/i, 'GND')                                  ### gnd! --> GND
  line.gsub!(/\$\[RNPPO_mm\]$/i, '$SUB=pwrp $[RNPPO_L130E]')    ### RNPPO_mm add $SUB
  line.gsub!(/\$\[RP\]$/i, '$SUB=pwrp $[RNPPO_L130E]')          ### RP add $SUB
  line.gsub!(/\$\[RNPPO\]$/i, '$SUB=pwrp $[RNPPO_L130E]')       ### RNPPO add $SUB
  
  #line.gsub!(/DION_L110E.*$/i, "DION_L110E pj=4.88u area=4.8u") ### DION add pj and area
  #line.gsub!(/DIOP_L110E.*$/i, "DIOP_L110E pj=4.88u area=4.8u") 

  ### special for msdll
  line.gsub!(/\bN_33_L130E\b/i, "N_HG_33_L130E")
  line.gsub!(/\bRNPPO_L130E\b/i, "RNPPO_MML130E")
  line.gsub!(/\bdion_l130e\s+0.3328p\b/i, "dion_l130e 0.3328p 2.72u")

  ### special for castor2 AFE
  #line.gsub!(/^\.INCLUDE\b/i, "*.INCLUDE")
  #line.gsub!(/^\.SUBCKT\s+pll_sdm_top\b/i, ".SUBCKT pll_sdm_top_ORG")
  #line.gsub!(/\/\s+pll_sdm_top\s*$/i, "pwrpd pwrn / pll_sdm_top")
  
  #line.gsub!(/^\.SUBCKT\s+postdiv_even_odd\b/i, ".SUBCKT postdiv_even_odd_ORG")
  #line.gsub!(/\/\s+postdiv_even_odd\s*$/i, "pwrn / divn_top")
  
  #line.gsub!(/^\.SUBCKT\s+cast2_afe_v1_\S+\b/i, ".SUBCKT cast2_afe_v1")
  
  ### find and replace using regex, with argument
  if options[:cap]
    regex = /^(X\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+\/\s*CPP\S*\s+(.*)$/i 
    if line =~ regex
      line.gsub!(regex, "#{$1} #{$3} #{$4} #{$2} / MOMCAPS_ASY_MM NF=4 NM=5 L=1.11e-5 #{$5}")
    end
  end

  ### change M1 a b c NM W=wn/1 .. ==> M1 a b c NM W=wn*1.0 ..
  regex = /^(M\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+W.*)\/(\d+)(\s+.*)$/i 
  if line =~ regex
    line.gsub!(regex, "#{$1}*#{1/$2.to_f}#{$3}")
  end

  
  cdl_out_file.print(line + "\n")
  
  
end ## file_arr



### print trailing header to output cdl file #########
#cdl_out_file.print(
#".SUBCKT MOMCAPS_ASY_MM PLUS MINUS B
#.ENDS

#.SUBCKT VARMIS_12_RF PLUS MINUS PSUB
#.ENDS
#")
########################################################
cdl_out_file.close()
