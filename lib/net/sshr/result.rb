
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
    #   # constructor
    #   result = Net::SSHR::Result.new('myhost', 'some_cmd')
    #   result = Net::SSHR::Result.new('user@myhost', 'some_other_cmd')
    #
    #   # accessors
    #   puts result.host_string # original user@hostname string
    #   puts result.host        # bare hostname from host_string
    #   puts result.user        # username from host_string (if any)
    #   puts result.cmd         # original cmd
    #   puts result.exit_code   # exit_code from cmd
    #   puts result.stdout      # stdout stream from execution of cmd (if any)
    #   puts result.stderr      # stderr stream from execution of cmd (if any)
    #
    class Result
      attr_accessor :host_string, :cmd, :host, :user, :stdout, :stderr, :exit_code

      def initialize(host_string, cmd, stdout = '', stderr = '', exit_code = nil)
        @host_string = host_string
        @cmd = cmd
        @stdout = stdout
        @stderr = stderr
        @exit_code = exit_code
        if (m = @host_string.match /^([-\w]+)@(.*)$/)
          @user = m[0]
          @host = m[1]
        else
          @user = ''
          @host = @host_string
        end
      end

      # Stringify to @stdout
      def to_s
        @stdout
      end

      # Return current result data as a serialised json hash, with hash members
      # named after attributes
      def to_json(*a)
        {
          'json_class'  => self.class.name,
          'host_string' => @host_string,
          'host'        => @host,
          'user'        => @user,
          'cmd'         => @cmd,
          'stdout'      => @stdout,
          'stderr'      => @stderr,
          'exit_code'   => @exit_code,
        }.to_json(*a)
      end
    end
  end
end

