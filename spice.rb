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

  
  def getCapacitors (subckt)
    regex = Regexp.New(/^\s*(C\S*)\s+(\S+)\s+(\S+)\s+(\S+)/i)
    if regex.match(subckt)
      return {$1=>$4}
    else
      return nil
    end
  end
  
  def getSubcktName (stmt)
    stmt.gsub!(/^\s*\.subckt\s+/i,"")
    parts = stmt.split(/\s+/)
    if parts[0]
      return parts[0]
    else
      return -1
    end
  end

  def getResCapName (stmt)
    stmt.chop!
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

  
  def getResistors (subckt)
  end
  
  def spiceInit (filename)
    code = processSpice(filename)
    return -1 if code == -1
    code = readSpice(filename)
    return -1 if code == -1
    return 0  # Initialization sucessful.
    
  end
  
if __FILE__ == $PROGRAM_NAME
  #  require "rubygems"
  #  require "active_support"
  require "test/unit"
  
  class TestSpice < Test::Unit::TestCase
    def setup
      $spice = "sldfjsdaf"
    end

    def test_get_cap_name
      a1, a2 = getResCapName("C234a sdf23 32f323 150f\n")
      assert_equal 'C234a', a1
      assert_equal '150f',  a2
      assert_equal 'sldfjsdaf', $spice
    end

    def test_get_res_name
      a1, a2 = getResCapName("r234a sdf\\23 32f323 100.3MEG\n")
      assert_equal 'r234a',   a1
      assert_equal '100.3MEG',a2
    end

    def test_get_subckt_name
      assert_equal "XDsf", getSubcktName(".SUBCKT XDsf sdfsd sdfsd sdf\n")
    end

  end

end

