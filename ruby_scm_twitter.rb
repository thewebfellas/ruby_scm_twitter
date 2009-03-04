#!/usr/bin/env ruby 

require 'optparse' 
require 'rdoc/usage'
require 'ostruct'
require 'date'
require 'twitter'

class Application
  VERSION = '0.0.1'
  
  attr_reader :options

  def initialize(arguments, stdin)
    @arguments = arguments
    @stdin = stdin
    
    # Set defaults
    @options = OpenStruct.new
    @options.scm = :svn
    @options.verbose = false
  end

  # Parse options, check arguments, then process the command
  def run
    if parsed_options? && arguments_valid? 
      puts "Start at #{DateTime.now}\n\n" if @options.verbose
      output_options if @options.verbose # [Optional]
      
      process_command
      
      puts "\nFinished at #{DateTime.now}" if @options.verbose
    else
      output_usage
    end
  end
  
  protected
  
    def parsed_options?
      # Specify options
      opts = OptionParser.new 
      opts.on('-v', '--version')           { output_version ; exit 0 }
      opts.on('-h', '--help')              { output_help }
      opts.on('-V', '--verbose')           { @options.verbose = true }
      opts.on('-u', '--username USER')     { |username| @options.username = username }
      opts.on('-p', '--password PASSWORD') { |password| @options.password = password }
      opts.on('-f', '--file FILE')         { |file| @options.file = file }
      opts.on('-r', '--revision REVISION') { |revision| @options.revision = revision }
      opts.on('-s', '--scm SCM')           { |scm| @options.scm = scm.downcase.to_sym }
      
      opts.parse!(@arguments) rescue return false
    
      true      
    end

    def output_options
      puts "Options:\n"
      
      @options.marshal_dump.each do |name, val|        
        puts "  #{name} = #{val}"
      end
    end

    # True if required arguments were provided
    def arguments_valid?
      !@options.username.nil? && 
        !@options.password.nil? && 
        !@options.file.nil? &&
        !@options.revision.nil? &&
        !@options.username.empty? && 
        !@options.password.empty? && 
        !@options.file.empty? &&
        !@options.revision.empty? &&
        [:svn].include?(@options.scm)
    end
    
    def output_help
      output_version
      RDoc::usage() #exits app
    end
    
    def output_usage
      RDoc::usage('usage') # gets usage from comments above
    end
    
    def output_version
      puts "#{File.basename(__FILE__)} version #{VERSION}"
    end
    
    def process_command
      case @options.scm
      when :svn, 'svn' : Twitter::SCM::SVN.new(@options).run
      end
    end
end

module Twitter
  module SCM
    class SVN
      attr_reader :options
      
      def initialize(options)
        @options = options
      end
      
      def log
        `svnlook log #{options.file} -r #{options.revision}`.strip
      end
      
      def author
        `svnlook author #{options.file} -r #{options.revision}`.strip
      end
      
      def message
        log_length = 140 - (author.length + 2)
        "#{author}: #{log.slice(0, log_length - 3).strip}#{'..' if ((log_length - 3) < log.length)}"
      end
      
      def run
        Twitter::Base.new(@options.user, @options.password).update(message)
      end
    end
  end
end

# Create and run the application
app = Application.new(ARGV, STDIN).run
