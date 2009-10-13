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
	end
	
	def run
		
		if parsed_options? && !@options.file.empty?
			pp @options
			@metaData = @converter.identify(@options.file)

		else
			# TODO Display usage
			p "No dice."
		end
	end
	
	protected
		def parsed_options?
			
			opts = OptionParser.new
			opts.on('-f', '--file VIDEO', "The VIDEO file to transcode.") do |f|
				@options.file = f
			end
			
			opts.on('-m', '--media-size [MEDIA]', @converter.media.keys) do |m|
		  	@options.mediaType = m
	  	end
			
			opts.parse!(@arguments) rescue return false
			
			true
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
	
	def get_bitrate(length, size)
	
	end
end

script = Script.new(ARGV, STDIN)
script.run


#identValues = Hash[*ident.scan(/(\w+)=(.*)/).flatten]
