# Net::SSHR class, wrapper around Net::SSH::Multi

require 'net/ssh/multi'
require 'net/sshr/result'

module Net
  class SSHR
    def initialize(options)
      @options = { :hosts => [] }
      @options.merge!(options)
      raise "Required :hosts argument missing" if @options[:hosts].empty?
    end

    def hosts
      @options[:hosts]
    end

    # exec the given cmd on all hosts, executing block with each host's results
    def exec(cmd, &block)
      raise "Required command argument to exec missing" if not cmd
      raise "Required block argument to exec missing" if not block

      # @result_data is a hash keyed by host, where each entry is another
      # hash containing stdout, stderr, and exit_code elements
      # TODO: make the entries a proper class
      @result_data = {}

      Net::SSH::Multi.start(:on_error => :warn) do |session|
        # Define users and servers to connect to, and initialise @result_data
        @options[:hosts].each do |host|
          session.use("root@#{host}")
          @result_data[host] = Net::SSHR::Result.new( host )
        end

        # Execute cmd on all servers
        session.open_channel do |channel|
          # Callbacks to capture stdout and stderr
          channel.on_data do |channel, data|
            host = channel[:host]
            @result_data[host].append_stdout(data)
          end
          channel.on_extended_data do |channel, type, data|
            host = channel[:host]
            @result_data[host].append_stderr(data)
          end

          # Callback to capture exit status
          channel.on_request("exit-status") do |channel, data|
            host = channel[:host]
            @result_data[host].exit_code = data.read_long
          end

          # Callback on channel close, yielding results
          channel.on_close do |channel|
            host = channel[:host]
            if @options[:verbose]:
              $stderr.puts "+ channel close for host #{host}, yielding results"
            end
            yield @result_data[host]
          end

          # Exec cmd on current channel
          channel.exec cmd do |channel, success|
            host = channel[:host]
            if not success:
              @result_data[host].append_stderr("exec on #{host} failed!")
              @result_data[host].exit_status ||= 255
              yield @result_data[host]
            elsif @options[:verbose]:
              $stderr.puts "+ exec on host #{host} begun"
            end
          end
        end

        # Run the event loop
        session.loop
      end
    end
  end
end

