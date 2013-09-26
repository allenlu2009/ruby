#!/usr/bin/env ruby

#spice.rb
#Just for fun 
#- one 
#- two 
#- three 
#[cat] small domestic animal 
# 
#<em>Italic</em> <b>Bold</b> 
# 
#-- 
#Hi, dont doc me please! 
#++ 
#Author:: hihi(http:blog.hihi.com) 
#
#=Name
#
#   spice - interface calls for parsing spice netlst.
#
#=SYNOPSIS
#
#   use spice ;
#   spiceInit ( $file ) ;
#      #returns 0 if initilization is successful and >0 otherwise.
#      #check $spice::error in case of failure.
#
#=DESCRIPTION
#
#==CALLING spice.pm ROUTINES
#
#   This package only cares about m, R, C, X, and subckts.
#   spice-decks are ignored.
#
#   This priliminary version of spice supports following subroutine
#   calls-
#
#   @subckt = getTopSubckts ( ) ;
#      returns a list of subckts, top in the hierarchy.
#
#   @subcktList = getSubcktList ( ) ;
#      returns a list of subckts present in the netlist.
#
#   $subcktDefn = getSubckt ( $subckt ) ;
#      returns a string containing the definition of subckt.
#
#   getResistors ( $subckt ) ;
#      returns a hash containing the name and value of Resistors.
#
#   getCapacitors ( $subckt ) ;
#      returns a hash containing the name and value of capacitors.
#
#   getTransistors ( $subckt ) ;
#      returns a hash of transitor names and their types. i.e. n or p.
#
#   getInstances ( $subckt ) ;
#      returns a hash of instantion name and their subckt names.
#

# parameter:subckt (String), return: list (Hash), name and cap value

=begin
=end

class Spice

  def get_lines(filename)
    return File.open(filename, 'r').readlines
  end

  def initialize(filename)
    @filename = filename
    @netlist = []
    @subckts = {}
    @cell_lib_hsh = {}
    @error = ""
    findLib()
    processSpice()
    readSpice()
  end


  def findLib()
    lineNo_mark = 0
    lib_name = ""
    get_lines(@filename).each_with_index do |line, lineNo| # starts from 0
      line.chomp!
      if line =~ /^\s*\*\s*Library\s+Name\s*:\s*(\S+)/i
        lib_name = $1
        lineNo_mark = lineNo
      elsif line =~ /^\s*\*\s*Cell\s+Name\s*:\s*(\S+)/i
        if lineNo == (lineNo_mark + 1)
          cell_name = $1
          @cell_lib_hsh[cell_name] = lib_name
        else
          next
        end
      else
        next
      end
    end
    #p @cell_lib_hsh
    return 0
  end


  def processSpice
    prevLine = ""
    get_lines(@filename).each_with_index do |line, lineNo| # starts from 0
      line.chomp!
      next unless line.length > 0  # ignore blank lines
      next if line =~ /^\s*\*/ # weed out comment
      if line =~ /^\s*\+/
        line.gsub!(/^\s*\+/, ' ') # eat up continuation character +
        prevLine = prevLine + line
      else
        @netlist << "#{prevLine}\n" if (prevLine)
        prevLine = line
      end
    end
    @netlist << "#{prevLine}\n" if (prevLine)
    #p @netlist
    return 0
  end
  


  def readSpice()
    subcktName = ""
    @netlist.each_with_index do |line, lineNo| # starts from 0
      #line.chomp!   # use chomp instead of chop
      if line =~ /^\s*\+/
        return "-1"   # self validation
      end
      next unless ( line =~ /^\s*x/i ||
                    line =~ /^\s*r/i ||
                    line =~ /^\s*c/i ||
                    line =~ /^\s*m/i ||
                    line =~ /^\s*\.subckt/i ||
                    line =~ /^\s*\.end/i )

      if ( line =~ /^\s*\.subckt\b/i ) 
        subcktName = getSubcktName( line )
        next if (subcktName == "-1")
        @subckts[subcktName] = line
        next
      elsif ( line =~ /^\s*\.ends\b/i )
        @subckts[subcktName] += line
        subcktName = ""
        next
      elsif ( line =~ /^\s*x/i )
        subcktName = @topSubckt unless ( subcktName )  # top without subckt
        @subckts[subcktName] += line
        next
      elsif ( line =~ /^\s*r/i )
        subcktName = @topSubckt unless ( subcktName )  
        @subckts[subcktName] += line
        next
      elsif ( line =~ /^\s*c/i )
        subcktName = @topSubckt unless ( subcktName )  
        @subckts[subcktName] += line
        next
      elsif ( line =~ /^\s*m/i )
        subcktName = @topSubckt unless ( subcktName )  
        @subckts[subcktName] += line
        next
      elsif ( line =~ /^\s*\.end\b/i )
      end
    end
    #p @subckts
    return 0
  end 

  def getCapacitors (subcktName)
    if (subcktName && @subckts[subcktName])
      subcktDefn = @subckts[subcktName]
    else
      @error = "Subckt definition not found in netlist"
      return "-1"
    end
    
    list = []
    subcktDefn.split(/\n/).each do |line|
      next unless (line =~ /^\s*c/i)
      retValue = getResCapName(line)
      if (retValue.length > 0)
        list.push( retValue)
      end
    end
    return  list # list is an array of array
  end
  
  def getResistors (subcktName)
    if (subcktName && @subckts[subcktName])
      subcktDefn = @subckts[subcktName]
    else
      @error = "Subckt definition not found in netlist"
      return "-1"
    end
    
    list = []
    subcktDefn.split(/\n/).each do |line|
      next unless (line =~ /^\s*r/i)
      retValue = getResCapName(line)
      if (retValue.length > 0)
        list.push( retValue)
      end
    end
    return  list # list is an array of array
  end

  def getTransistors (subcktName)
    if (subcktName && @subckts[subcktName])
      subcktDefn = @subckts[subcktName]
    else
      @error = "Subckt definition not found in netlist"
      return "-1"
    end
    
    list = []
    subcktDefn.split(/\n/).each do |line|
      next unless (line =~ /^\s*m/i)
      retValue = getResCapName(line)
      if (retValue.length > 0)
        list.push( retValue)
      end
    end
    return  list  # list is an array of array
  end
  
  def getInstances (subcktName)
    if (subcktName && @subckts[subcktName])
      subcktDefn = @subckts[subcktName]
    else
      @error = "Subckt definition not found in netlist"
      print "Subckt definition not found in netlist"
      return "-1"
    end

    list = []
    subcktDefn.split(/\n/).each do |line|
      next unless (line =~ /^\s*x/i)
      retValue = getInstName(line)
      if (retValue.length > 0)
        list.push( retValue)
      end
    end
    return list
  end
  
  def getSubcktName (stmt)
    stmt.gsub(/^\s*\.subckt\s+/i,"")
    parts = stmt.split(/\s+/)
    if parts[1]
      return parts[1]
    else
      return "-1"
    end
  end
  
  def getSubckt (subcktName)
    if (subcktName && @subckts[subcktName])
      return @subckts[subcktName]
    else
      @error = "Subckt definition not found in netlist"
      return "-1"
    end
  end
  
  def getResCapName (stmt)
    stmt.chomp!
    if (stmt !~ /^\s*[rc]/i)
      return "-1"
    else
      tmp = stmt.split(/\s+/)
      if tmp.length < 3
      return "-1"
      end
      return tmp[0], tmp[3]  # return an array of two elements
    end
  end
  
  def getInstName (stmt)
    stmt.chomp!
    if (stmt !~ /^\s*x/i )
        return "-1"
    end
    inst = stmt.split(/\s+/)

    if (stmt =~ /\=/)   # in case there is property definition
      tmp = stmt.split(/\s*\=\s*/)
      tmp = tmp[0].split(/\s+/)
      if (tmp[tmp.length-2])
        subckt = tmp[tmp.length-2]
      else
        @error = "could not find subckt name"
        return "-1"
      end
    else
      tmp = stmt.split(/\s+/)
      if (tmp[tmp.length])
        subckt = tmp[tmp.length]
      elsif (tmp[tmp.length-1])
        subckt = tmp[tmp.length-1]
      else
        @error = "could not find subckt name"
        return "-1"
      end
    end
    return inst[0], subckt
  end 
        
  def getTxName (stmt)
    stmt.chomp!
    if (stmt !~ /^\s*m/i )
        return "-1"
    end
    tx = stmt.split(/\s+/)
    return tx[0], tx[5]
  end
  
  def spiceInit (filename)
    code = processSpice()
    return -1 if code == -1
    code = readSpice()
    return -1 if code == -1
    return 0  # Initialization sucessful.
  end

  def getTopSubckts 
    node = @subckts.keys
    #p @node
    list = []
    node.each do |node1|
      top = 1
      node.each do |node2|
        next if (node2 == node1)
        tmp_arr = getInstances(node2)
        tmp_arr.flatten!    # flatten to convert array of array into one array
        #p tmp_arr
        tmp_hsh = Hash[*tmp_arr] # convert even array into hash
        #p tmp_hsh
        instances = tmp_hsh.values
        #p instances
        tmp_arr = []
        instances.each do |inst|
          if (inst == node1)
            top = 0
            break
          end
        end
        break if (top == 0)
      end
      list.push(node1 ) if (top==1)
    end
    #p list
    return list
  end

  def getSubcktList
    list = @subckts.keys
    if (list.length == -1)
      @error = "could not find subckt name"
      return "-1"
    end
    return list
  end
  
  
  def traverseHier(node, count)
    for i in 0...count do
      print "   "
    end
    count = count + 1
    print "#{count}.#{node}\n"
    subckts_arr = getInstances(node)
    if (subckts_arr == "-1")
      puts "Error #{node} not found!!"
      return
    end
    #p subckts_arr
    subckts_arr.flatten!
    subckts_hsh = Hash[*subckts_arr]
    children = subckts_hsh.values
    children = removeDup(children)
    subckts_arr = nil
    subckts_hsh = nil
    if (children.length < 0)
      return
    end
    children.each do |child|
      traverseHier(child, count)
    end
    return
  end
  
  def traverseHierLib(node, count)
    for i in 0...count do
      print "   "
    end
    count = count + 1
    print "#{count}.#{node}(#{@cell_lib_hsh[node]})\n"
    subckts_arr = getInstances(node)
    if (subckts_arr == "-1")
      puts "Error #{node} not found!!"
      return
    end
    #p subckts_arr
    subckts_arr.flatten!
    subckts_hsh = Hash[*subckts_arr]
    children = subckts_hsh.values
    children = removeDup(children)
    subckts_arr = nil
    subckts_hsh = nil
    if (children.length < 0)
      return
    end
    children.each do |child|
      traverseHierLib(child, count)
    end
    return
  end
  
  def removeDup(list)
    hash = {}
    list.each do |part|
      part.gsub!(/\s+/, "")
      hash[part] = 1 if (part.length)
    end
    list = hash.keys
    return list
  end

  
end



#if __FILE__ == $PROGRAM_NAME
if __FILE__ == $0
  #  require "rubygems"
  #  require "active_support"
  require 'optparse'
  require "test/unit"
  
  class TestSpice < Test::Unit::TestCase
    def setup

      # This hash will hold all of the options
      # parsed from the command-line by
      # OptionParser.
      options = {}
      
      optparse = OptionParser.new do |opts|
        # Set a banner, displayed at the top
        # of the help screen.
        opts.banner = "Usage: #{$0} [options] <in.cdl> <out.cdl>"
        
        # Define the options, and what they do
        options[:force] = false
        opts.on( '-f', '--force', 'Force to overwrite output file' ) do
          options[:force] = true
        end
        
        options[:cap] = 1.0
        opts.on( '-c', '--cap val', Float, 'cap threshold in fF' ) do |cap|
          options[:cap] = cap
        end
        
        options[:bracket] = false
        opts.on( '-b', '--bracket', 'Bracket <> -> []' ) do
          options[:bracket] = true
        end
  
        options[:dummy] = false
        opts.on( '-d', '--dummy', 'Dummy cap and resistor removal' ) do
          options[:dummy] = true
        end
        
        options[:logfile] = nil
        opts.on( '-l', '--logfile FILE', 'Write log to FILE' ) do|file|
          options[:logfile] = file
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
      
      begin optparse.parse! ARGV
      rescue OptionParser::InvalidOption => err
        puts err
        puts optparse
        exit 
      end
      
      #if (ARGV.length < 2)
      #  puts optparse
      #  exit
      #end
      
      puts "Remove cap less than #{options[:cap]} fF"
      #puts "Force to overwrite output file" if options[:force]
      #puts "Bracket <> -> []" if options[:bracket]
      #puts "Dummy cap & resistor removal" if options[:dummy]
      puts "Logging to file #{options[:logfile]}" if options[:logfile]
      
      @spice = Spice.new("netlist")
    end
    
    def test_get_res_name
      assert_equal ['r234a','100.3MEG'],@spice.getResCapName("r234a sdf\\23 32f323 100.3MEG\n")
    end

    def test_get_tx_name
      assert_equal ['MPM', 'NMOS'],@spice.getTxName("MPM s g d bulk NMOS\n")
    end

    def test_get_tx_name_with_property
      assert_equal ['MNM2','NM'],@spice.getTxName("MNM2 HFVDD PD net17 VSA NM W=500e-9 L=20u M=1.0 NF=1\n")
    end

    def test_get_inst_name
      assert_equal ['XI15', 'Half_VDD'],@spice.getInstName("XI15 HF PD VDA VSA / Half_VDD\n")
    end

    def test_get_inst_name_with_property
      assert_equal ['XI10', 'inv_h'], @spice.getInstName("XI10 PWROFF XPWROFF VSA VDA / inv_h lp=340.00n wp=2.5u mm=1 ln=340.00n wn=1u\n")
    end

    def test_get_subckt_name
      assert_equal "XDsf", @spice.getSubcktName(".SUBCKT XDsf sdfsd sdfsd sdf\n")
    end

    def test_get_subckt
      #assert_equal "", @spice.getSubckt("Level1V2to3V3_test_rb")
    end

    def test_get_cap
      #assert_equal [["Ctt", "12f"]], @spice.getCapacitors("Level1V2to3V3_test_rb")
    end

    def test_get_instance
      #assert_equal [["XI2", "inv_h_schematic"],["XI1","inv_LV"]], @spice.getInstances("Level1V2to3V3_test_rb")
    end

    def test_get_top
      assert_equal ["AFA6011v2"], @spice.getTopSubckts()
    end

    def test_traversehierLib
      print "\n"
      @spice.traverseHierLib("AFA6011v2", 0)
    end

    def test_findLib
      print "\n"
      @spice.findLib()
    end

  end

end

