
module Net
  module SSHR

    # = ABSTRACT
    #
    # Net::SSHR::Result class, encapsulating command result data from an individual host
    #
    # = SYNOPSIS
    #
    #   require 'net/sshr/result'
    #
    #   result = Net::SSHR::Result.new('myhost', 'some_cmd')
    #   result.stdout << "Hello World!\n"
    #
    #   puts "#{result.host} #{result.cmd}: #{result.exit_code}"
    #   puts result.to_json
    #
    class Result
      attr_accessor :host, :cmd, :stdout, :stderr, :exit_code

      def initialize(host, cmd, stdout = '', stderr = '', exit_code = nil)
        @host = host
        @cmd = cmd
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
          'cmd'         => @cmd,
          'stdout'      => @stdout,
          'stderr'      => @stderr,
          'exit_code'   => @exit_code,
        }.to_json(*a)
      end
    end
  end
end

