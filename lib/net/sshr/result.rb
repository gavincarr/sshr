
module Net
  module SSHR

    # = ABSTRACT
    #
    # Net::SSHR::Result class, encapsulating the result data from an individual host
    #
    # = SYNOPSIS
    #
    #   require 'net/sshr/result'
    #
    #   result = Net::SSHR::Result.new('myhost')
    #   result.stdout << "Hello World!\n"
    #
    #   puts "#{result.host}: #{result.exit_code}"
    #   puts result.to_json
    #
    class Result
      attr_accessor :host, :stdout, :stderr, :exit_code

      def initialize(host, stdout = '', stderr = '', exit_code = nil)
        @host = host
        @stdout = stdout
        @stderr = stderr
        @exit_code = exit_code
      end

      # Return current result data as a serialised json hash, with hash members
      # named after attributes
      def to_json(*a)
        {
          'json_class'  => self.class.name,
          'host'        => @host,
          'stdout'      => @stdout,
          'stderr'      => @stderr,
          'exit_code'   => @exit_code,
        }.to_json(*a)
      end
    end
  end
end

