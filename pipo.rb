#!/usr/bin/ruby
## pipo.rb is used with cadence Virtuoso
## to stream in and out GDS and layout database
## Make sure to source cadence license file beforehand

require 'optparse'
require 'pp'

class Pipo
  
  def self.parse(args)
    # The options specified on the command line will be collected in *options*.
    # We set default values here.
    
    options = {}

    optparse = OptionParser.new do |opts|
      opts.banner = "Usage: pipo.rb --<translator> [options] in/out.gds"
      
      options[:strmin] = false
      opts.on("--strmin", "Stream-In GDS translator") do |v|
        options[:strmin] = true
      end

      options[:strmout] = false
      opts.on("--strmout", "Stream-Out GDS translator") do |v|
        options[:strmout] = true
      end

      options[:strmtechgen] = false
      opts.on("--strmtechgen", "Stream-In Techfile translator") do |v|
        options[:strmtechgen] = true
      end

      options[:top] = nil   ## How about nil vs. "" (if I don't know the top?)
      opts.on("-t", "--top CellName", "GDS top cell. Default GDS") do |top|
        options[:top] = top
      end
      
      options[:lib] = nil   ## How about nil vs. "" (if I don't know the top?)
      opts.on("-l", "--lib LayoutLib", "Layout Lib Name. Default same as GDS_lay") do |lib|
        options[:lib] = lib
      end
      
      options[:tf] = "/home/atd/tech/110nm/umc/tf/virtuoso/umc110nm.tf"
      opts.on("--techfile techfile", "Technology File. Default UMC110nm") do |tf|
        options[:tf] = tf
      end
      
      options[:run] = false
      opts.on("-r", "--run", "Run pipo. Default generate setup file only") do |v|
        options[:run] = true
      end

      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end
      
    end
    
    optparse.parse!(args)

    options[:translator] = nil
    if options[:strmin]
      options[:translator] = "strmin"
    elsif options[:strmout]
      options[:translator] = "strmout"
    elsif options[:strmtechgen]
      options[:translator] = "strmtechgen"
    else
    end

    if (args.length == 0) || (options[:translator] == nil ) 
      puts optparse
      exit
    else
      options[:inGDS] = args[0]  ## remaining args[0] is path/input.gds
    end
    return options

  end  # parse()
  
  
  def initialize(translator)

    @translator = translator
    @setupFile = "setup_#{translator}"

    ## Based cadence pipo usage: pipo Translator SetupFile
    ## Six different types of translator: gds in; gds out; cif in; cif out
    @setupFileHash = 
      case translator 
      when "strmin" then {
        :runDir			 => ".",
        :inFile			 => "in.gds",
        :primaryCell		 => "TOP",
        :libName		 => "in.lib",
        :techfileName		 => "umc130nm.tf",
        :scale			 => 0.001000,
        :units			 => "micron",
        :errFile		 => "PIPO_#{@translator}.LOG",
        :refLib			 => nil,
        :hierDepth		 => 32,
        :maxVertices		 => 1024,
        :checkPolygon		 => nil,
        :snapToGrid		 => nil,
        :arrayToSimMosaic	 => true,
        :caseSensitivity	 => "preserve",
        :textCaseSensitivity	 => "preserve",
        :zeroPathToLine		 => "lines",
        :convertNode		 => "ignore",
        :keepPcell	         => nil,
        :replaceBusBitChar	 => nil,
        :skipUndefinedLPP	 => nil,
        :ignoreBox		 => nil,
        :mergeUndefPurposToDrawing => nil,
        :reportPrecision	 => nil,
        :keepStreamCells	 => nil,
        :attachTechfileOfLib	 => "",
        :runQuiet		 => nil,
        :noWriteExistCell	 => nil,
        :NOUnmappingLayerWarning => nil,
        :comprehensiveLog	 => nil,
        :ignorePcellEvalFail	 => nil,
        :appendDB		 => nil,
        :genListHier		 => nil,
        :skipDbLocking		 => nil,
        :skipPcDbGen		 => nil,
        :cellMapTable		 => "",
        :layerTable		 => "",
        :textFontTable		 => "",
        :restorePin		 => 0,
        :propMapTable		 => "",
        :propSeparator		 => ",",
        :userSkillFile		 => "",
        :rodDir			 => "",
        :refLibOrder		 => ""
      }

      when "strmout" then {
        :runDir			 => ".",
        :inFile			 => "in.gds",
        :primaryCell		 => "TOP",
        :libName		 => "in.lib",
        :techfileName		 => "umc130nm.tf",
        :scale			 => 0.001000,
        :units			 => "micron",
        :errFile		 => "PIPO_#{@translator}.LOG",
        :refLib			 => nil,
        :hierDepth		 => 32,
        :maxVertices		 => 1024,
        :checkPolygon		 => nil,
        :snapToGrid		 => nil,
        :arrayToSimMosaic	 => true,
        :caseSensitivity	 => "preserve",
        :textCaseSensitivity	 => "preserve",
        :zeroPathToLine		 => "lines",
        :convertNode		 => "ignore",
        :keepPcell	         => nil,
        :replaceBusBitChar	 => nil,
        :skipUndefinedLPP	 => nil,
        :ignoreBox		 => nil,
        :mergeUndefPurposToDrawing => nil,
        :reportPrecision	 => nil,
        :keepStreamCells	 => nil,
        :attachTechfileOfLib	 => "",
        :runQuiet		 => nil,
        :noWriteExistCell	 => nil,
        :NOUnmappingLayerWarning => nil,
        :comprehensiveLog	 => nil,
        :ignorePcellEvalFail	 => nil,
        :appendDB		 => nil,
        :genListHier		 => nil,
        :skipDbLocking		 => nil,
        :skipPcDbGen		 => nil,
        :cellMapTable		 => "",
        :layerTable		 => "",
        :textFontTable		 => "",
        :restorePin		 => 0,
        :propMapTable		 => "",
        :propSeparator		 => ",",
        :userSkillFile		 => "",
        :rodDir			 => "",
        :refLibOrder		 => ""
      }

      when "strmtechgen" then {}
      when "cifin" then {}
      when "cifout" then {}
      when "ciftechgen" then {}
      else nil
      end
    
  end # initialize()

  def getTranslator
    return @translator 
  end # getTranslator

  def getSetupFile
    return @setupFile 
  end # getSetupFile

  def getSetupFileHash
    return @setupFileHash 
  end # getSetupFileHash

  def updateSetupFileHash(inHash)
    inHash.each do |key, val|
      if @setupFileHash.has_key?(key)
        @setupFileHash[key] = val
      else
        p "Warning: #{key} => #{val} key NOT found!"
      end
    end
    p @setupFileHash if @debug
  end # updateSetupFileHash()

  def printSetupFileHash()  ## in Skill format
    @setupFileHash.each do |key, val|
      if val == nil
        puts "#{key.to_s}   =>   nil"
      elsif val.is_a?(String)
        puts "#{key.to_s}   =>   \"#{val.to_s}\""
      elsif val.is_a?(TrueClass)
        puts "#{key.to_s}   =>   t"
      elsif val.is_a?(FalseClass)
        puts "#{key.to_s}   =>   f"
      else
        puts "#{key.to_s}   =>   #{val.to_s}"
      end
    end

  end # printSetupFileHash()

  def saveSetupFile(setupFile=@setupFile)  ## use setup_"translator" as default 
    @setupFile = setupFile  
    File.open(@setupFile, 'w') do |f|
      f.puts "streamInKeys = list(nil"
      
      @setupFileHash.each do |key, val|
        if val == nil
          f.puts "'#{key.to_s}   \t\t   nil"
        elsif val.is_a?(String)
          f.puts "'#{key.to_s}   \t\t   \"#{val.to_s}\""
        elsif val.is_a?(TrueClass)
          f.puts "'#{key.to_s}   \t\t   t"
        elsif val.is_a?(FalseClass)
          f.puts "'#{key.to_s}   \t\t   f"
        else
          f.puts "'#{key.to_s}   \t\t   #{val.to_s}"
        end
      end

      f.puts ")"
    end # open
    
  end # saveSetupFile()
  

  def runpipo
    msg = %x[pipo #{@translator} #{@setupFile}]
    if msg == ""
      puts "Source Virtuoso License File First!!"
    else
      puts msg
    end
  end # runpipo
  


  #### main starts here

  if __FILE__ == $0
    @debug = false
    puts __FILE__ if @debug
    puts $0 if @debug
    
    #### option parse
    options = Pipo.parse(ARGV)
    pp options if @debug

    #### INPUT GDS file (Change based on design)
    inGDS = options[:inGDS]

    #### INPUT GDS top cell name (Change based on design)
    if options[:top] == nil
      topCellName = File.basename(inGDS, File.extname(inGDS))
    else
      topCellName = options[:top]
    end
    pp topCellName if @debug
    
    ##### INPUT layout lib name (Change based on design)
    if options[:lib] == nil
      libName = File.basename(inGDS, File.extname(inGDS)) + "_lay"
    else
      libName = options[:lib]
    end
    pp libName if @debug
    
    ## INPUT technology file including path (Do NOT change)
    tfFileName = options[:tf]
    
    ## Starts hash
    keyHash = {}
    keyHash[:inFile]      = inGDS
    keyHash[:libName]     = libName
    keyHash[:primaryCell] = topCellName
    keyHash[:techfileName]= tfFileName

    aPipo = Pipo.new(options[:translator])
    aPipo.updateSetupFileHash(keyHash)
    aPipo.printSetupFileHash() if @debug
    aPipo.saveSetupFile()

    if options[:run]
      aPipo.runpipo
    end

  end

end
