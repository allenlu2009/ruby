#!/usr/bin/env ruby
## pipo.rb is used with cadence Virtuoso
## to stream in and out GDS and layout database
## Make sure to source cadence license file beforehand

require 'optparse'
require 'pp'
require 'pipo.rb'

class DummyPipo130nm
  
  def self.parse(args)
    # The options specified on the command line will be collected in *options*.
    # We set default values here.
    
    options = {}

    optparse = OptionParser.new do |opts|
      opts.banner = "Usage: dummypipo130nm.rb -t topcell [options]"
      
      options[:top] = nil
      opts.on("-t", "--top CellName", "GDS top cell. Must provide") do |top|
        options[:top] = top
      end
      
      options[:path] = "./"
      opts.on("--path DummyGDS_path", "Dummy GDS path. Default \"./\"") do |path|
        options[:path] = path
      end

      options[:tf] = "/home/atd/tech/130nm/umc/tf/virtuoso/umc13logicmm.tf"
      opts.on("-f", "--file techfile", "Technology File. Default umc130nm") do |tf|
        options[:tf] = tf
      end
      
      options[:runpipo] = "runpipo"
      opts.on("-s", "--strmin runpipo", "Ouput PIPO shell command. Default \"runpipo\"") do |pp|
        options[:runpipo] = pp
      end
      
      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end
      
    end
    
    optparse.parse!(args)
    pp args if @debug
    if options[:top] == nil
      puts optparse
      exit
    end
    return options
  end  # parse()
  
  
  ####################################################################
  #### main starts here

  @debug = false

  
  #### option parse
  options = DummyPipo130nm.parse(ARGV)
  pp options if @debug


  ## INPUT dummy GDS path (default ./)
  dummyGDSDir = options[:path]

  ## INPUT dummy GDS top cell name (Change based on design)
  topCellName = options[:top]

  ## INPUT technology file including path (Do NOT change)
  tfFileName = options[:tf]

  ## dummy GDS (m1-m6, poly, diffusion) with path and top cell name
  dummyGDSHash = {
    "m1dmy" => "#{dummyGDSDir}#{topCellName}_m1dmy.gds",
    "m2dmy" => "#{dummyGDSDir}#{topCellName}_m2dmy.gds",
    "m3dmy" => "#{dummyGDSDir}#{topCellName}_m3dmy.gds",
    "m4dmy" => "#{dummyGDSDir}#{topCellName}_m4dmy.gds",
    "m5dmy" => "#{dummyGDSDir}#{topCellName}_m5dmy.gds",
    "m6dmy" => "#{dummyGDSDir}#{topCellName}_m6dmy.gds",
    "m7dmy" => "#{dummyGDSDir}#{topCellName}_m7dmy.gds",
    "polydmy" => "#{dummyGDSDir}#{topCellName}_polydmy.gds"
  }
  ## dummy gds stream in virtuoso library names
  dummyLibHash = {
    "m1dmy" => "#{topCellName}_m1dmy_lay",
    "m2dmy" => "#{topCellName}_m2dmy_lay",
    "m3dmy" => "#{topCellName}_m3dmy_lay",
    "m4dmy" => "#{topCellName}_m4dmy_lay",
    "m5dmy" => "#{topCellName}_m5dmy_lay",
    "m6dmy" => "#{topCellName}_m6dmy_lay",
    "m7dmy" => "#{topCellName}_m7dmy_lay",
    "polydmy" => "#{topCellName}_polydmy_lay"
  }


  dummyPipoArr = []
  ## dummyGDSHash iterates and sorted by key
  dummyGDSHash.sort.map do |key, gds|
    puts "\n#{key} Start Here ...." if @debug

    keyHash = {}
    keyHash[:inFile]      = gds
    keyHash[:libName]     = dummyLibHash[key]
    keyHash[:primaryCell] = topCellName
    keyHash[:techfileName]= tfFileName
    keyHash[:errFile]     = "PIPO_#{key}.LOG"

    aPipo = Pipo.new("strmin")  ## stream in GDS
    aPipo.updateSetupFileHash(keyHash)
    aPipo.printSetupFileHash() if @debug
    aPipo.saveSetupFile("setup_strmin_#{key}") ## save setup file

    dummyPipoArr << aPipo
  end
  
  ## Generate runpipo script for dummy GDS stream-in
  runPipoFile = File.new(options[:runpipo], "w")
  dummyPipoArr.each do |apipo|
    runPipoFile.print("pipo strmin #{apipo.getSetupFile}\n")
  end
  

end # class
