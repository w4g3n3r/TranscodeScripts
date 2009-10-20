#!/usr/bin/ruby

require 'optparse' 
require 'ostruct'
require 'date'
require 'pp'

class Script
	
	def initialize(arguments, stdin)
		@arguments = arguments
		@stdin = stdin		
		
		@calc = Calculator.new
		@options = OpenStruct.new
		@options.max_video_bitrate = 9800
		@options.audio_bitrate = 384
		@options.media_type = "DVD5"
		@options.scale = "1280:720"
		@options.aspect = "16/9"
		@options.threads = "4"
	end
	
	def run
	
		parse_options		
		
		if !@arguments.empty?
			@arguments.each do |file|
				if File.exist?(file) && File.readable?(file)
					
					@media_info = @calc.identify(file)
					
					@length = @media_info["ID_LENGTH"].to_f
					@audio_size = @calc.audio_size(@length, @options.audio_bitrate)
					@avg_bitrate = @calc.avg_bitrate(@length, @audio_size, @options.media_type)
					
					if @avg_bitrate > 24000 then @avg_bitrate = 24000 end
					
					@avg_bitrate = case
						when @avg_bitrate <= @options.max_video_bitrate: @avg_bitrate
						else @options.max_video_bitrate
					end
					
					if @avg_bitrate > 16000 then @avg_bitrate *= 1000 end
					
					@mpegopts = {
						"format"=>"dvd",
						"tsaf"=>"",
						"vaspect"=>@options.aspect,
						"muxrate"=>"131072",
						"vbitrate"=>@avg_bitrate
					}
					
					@lavcopts = {
						"threads"=>@options.threads,
						"vcodec"=>"mpeg2video",
						"vbitrate"=>@avg_bitrate,
						"vrc_maxrate"=>@options.max_video_bitrate,
						"vrc_buf_size"=>"2867",
						"aspect"=>@options.aspect,
						"vb_strategy"=>"0",
						"vratetol"=>"1000",
						"keyint"=>"18",
						"sc_threshold"=>"500000000",
						"sc_factor"=>"4",
						"trell"=>"",
						"dia"=>"-10",
						"predia"=>"-10",
						"mv0"=>"",
						"vqmin"=>"1",
						"lmin"=>"1",
						"cbp"=>"",
						"dc"=>"10",
						"acodec"=>"ac3",
						"abitrate"=>@options.audio_bitrate
					}
					
					@mencoder = [
						"mencoder",
						"'#{file}'",
						"-ofps 30000/1001",
						"-ovc lavc -oac lavc -of mpeg",
						"-vf harddup,scale=#{@options.scale}",
						"-mpegopts #{hash_to_params(@mpegopts)}",
						"-lavcopts #{hash_to_params(@lavcopts)}",
						"-o '#{file}.mpg'"						
					]
					
					if @media_info["ID_AUDIO_NCH"].to_i == 6
						@mencoder.insert(@mencoder.length, "-channels 6")
						if @media_info["ID_DEMUXER"] == "mkv"
							@mencoder.insert(@mencoder.length, 
								"-af channels=6:6:0:0:4:1:1:2:2:3:3:4:5:5")
						end
					end
					
					if @options.test_run
						@mencoder.insert(@mencoder.length, "-endpos 30")
					end				
					
					#pp @media_info
					#puts @mencoder.join(" ")
					system(@mencoder.join(" "))
					puts $?
				else
					puts "#{file} does not exist or is not readable."
				end
			end
		end
	end
	
	protected
		def parse_options
			
			opts = OptionParser.new
			opts.banner = "Usage: enchddvd.rb [options] files"
			
			opts.on('-m', '--media-type [MEDIA]', @calc.media.keys,
				"The media the encode should fit on (ex. DVD5, DVD9, HDDVD).") do |m|
		  	@options.media_type = m
	  	end
	  	
	  	opts.on('-a', '--audio-bitrate BITRATE', Integer) do |a|
	  		@options.audio_bitrate = a
  		end
  		
  		opts.on('-b', '--max-video-bitrate BITRATE', Integer) do |b|
  			@options.max_video_bitrate = b
			end
			
			opts.on('-p', '--threads COUNT',
				"The number of threads to spawn durring encoding.") do |count|
				@options.threads = count
			end
			
			opts.on('-r', '--aspect-ratio RATIO',
				"The aspect ratio of the output (ex. 16/9)") do |ratio|
				@options.aspect = ratio
			end
			
			opts.on('-s', '--scale SCALE', 
				"The width:height of the output (ex. 720:480)") do |scale|
				@options.scale = scale
			end
			
			opts.on('-t', '--test-run',
				"Encode the first 30 seconds of the input file for testing.") do |t|
				@options.test_run = true
			end
			
			opts.on('-h', '--help', "This screen.") do
				puts opts
				exit
			end
			
			opts.parse!(@arguments) 
			
			if @arguments.empty?
				puts opts
			end
			
			rescue
				puts opts
				exit
		end
		
		def hash_to_params(hash)
			@params = @set = ""
			hash.each_pair do |key, value|
				@set = case
					when value.to_s.empty? : key
					else key.to_s + "=" + value.to_s
				end
				
				@params = case
					when @params.empty? : @params += @set
					else @params += ":" + @set
				end
			end
			return @params
		end
		
end

class Calculator

	attr_accessor :media
	
	def initialize()
		@media = {
			"CD650"=>650,
			"CD700"=>700,
			"CD800"=>800,
			"CD900"=>900,
			"MiniDVD"=>1362,
			"DVD4"=>3710,
			"DVD5"=>4482,
			"MiniBD"=>7320,
			"DVD9"=>8147,
			"HDDVD"=>14645,
			"BD"=>23840,
			"HDDVDDL"=>29295,
			"BDDL"=>48825}
	end
	
	def identify(file)
		ident = %x[ mplayer #{file} -identify -frames 0 2>&1 ]
		# The important values are output first. Reverse the array
		# so the important values overwrite the less important dupes.
		return Hash[*ident.scan(/(\w+)=(.*)/).reverse.flatten]
	end
	
	def audio_size(length, bitrate)
		return (length * (bitrate/8.192)).to_i
	end
	
	def avg_bitrate(length, audio_size, media_type)
		@free_space = @media[media_type]
		return ((((@free_space * 1024) - audio_size) * 8) / length / 1.04).to_i
	end
end

script = Script.new(ARGV, STDIN)
script.run

