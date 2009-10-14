#!/usr/bin/ruby

require 'optparse' 
require 'ostruct'
require 'date'
require 'pp'

class Script
	
	def initialize(arguments, stdin)
		@arguments = arguments
		@stdin = stdin		
		
		@converter = Converter.new
		@options = OpenStruct.new
		@options.max_video_bitrate = 24000
	end
	
	def run
		
		if parsed_options? && !@arguments.empty?
			@arguments.each do |file|
				if File.exist?(file) && File.readable?(file)
					
					@media_info = @converter.identify(file)
					
					@length = @media_info["ID_LENGTH"].to_f
					@audio_size = @converter.audio_size(@length, @options.audio_bitrate)
					@avg_bitrate = @converter.avg_bitrate(@length, @audio_size, @options.media_type)
					
					@avg_bitrate = case
						when @avg_bitrate <= @options.max_video_bitrate: @avg_bitrate
						else @options.max_video_bitrate
					end
					
					if @avg_bitrate > 16000 then @avg_bitrate *= 1000 end
					
					@mpegopts = {
						"format"=>"dvd",
						"tsaf"=>"",
						"vaspect"=>"16/9",
						"muxrate"=>"131072",
						"vbitrate"=>@avg_bitrate
					}
					
					@lavcopts = {
						"threads"=>"4",
						"vcodec"=>"mpeg2video",
						"vbitrate"=>@avg_bitrate,
						"vrc_maxrate"=>@options.max_video_bitrate,
						"vrc_buf_size"=>"2867",
						"aspect"=>"16/9",
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
						"-ovc lavc -oac lavc -of mpeg -vf harddup,scale=1280:720",
						"-mpegopts #{hash_to_params(@mpegopts)}",
						"-lavcopts #{hash_to_params(@lavcopts)}",
						"-o '#{file}.mpg'"						
					]
					
					if @options.test_run
						@mencoder.insert(@mencoder.length, "-endpos 30")
					end
					
					system(@mencoder.join(" "))
					puts $?
				else
					puts "#{file} does not exist or is not readable."
				end
			end

		else
			# TODO Display usage
			p "No dice."
		end
	end
	
	protected
		def parsed_options?
			
			opts = OptionParser.new
			
			opts.on('-t', '--test') do |t|
				@options.test_run = true
			end
			
			opts.on('-m', '--media-size [MEDIA]', @converter.media.keys) do |m|
		  	@options.media_type = m
	  	end
	  	
	  	opts.on('-a', '--audio-bitrate BITRATE', Integer) do |a|
	  		@options.audio_bitrate = a
  		end
  		
  		opts.on('-b', '--max-video-bitrate BITRATE', Integer) do |b|
  			@options.max_video_bitrate = case
  				when b < @options.max_video_bitrate : b
  				else @options.max_video_bitrate
				end
			end
			
			opts.on('-h', '--help') do
				puts opts
				exit
			end
			
			opts.parse!(@arguments) rescue return false
			
			true
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

class Converter

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
		ident = %x[ mplayer #{file} -identify -nosound -vc dummy -vo null 2>&1 ]
		return Hash[*ident.scan(/(\w+)=(.*)/).flatten]
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


#identValues = Hash[*ident.scan(/(\w+)=(.*)/).flatten]
