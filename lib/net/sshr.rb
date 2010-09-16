# Net::SSHR class, wrapper around Net::SSH::Multi

require 'net/ssh/multi'

module Net
  class SSHR
    def initialize(options)
      @defaults = { :hosts => [] }
      @defaults.merge!(options)
      raise "Required :hosts argument missing" if @defaults[:hosts].empty?
    end

    # exec the given cmd on all hosts, executing block with each host's results
    def exec(cmd, &block)
      raise "Required command argument to exec missing" if not cmd
      raise "Required block argument to exec missing" if not block

      # @result_data is a hash keyed by host, where each entry is another
      # hash containing stdout, stderr, and exit_code elements
      # TODO: make the entries a proper class
      @result_data = {}

      # TODO: don't ignore errors
      Net::SSH::Multi.start(:on_error => :ignore) do |session|
        # Define users and servers to connect to, and initialise @result_data
        @defaults[:hosts].each do |host|
          session.use("root@#{host}")
          @result_data[host] = { :host => host, :stdout => '', :stderr => '' }
        end

        # Execute cmd on all servers
        session.open_channel do |channel|
          # Callbacks to capture stdout and stderr
          channel.on_data do |channel, data|
            host = channel[:host]
            @result_data[host][:stdout] += data
          end
          channel.on_extended_data do |channel, type, data|
            host = channel[:host]
            @result_data[host][:stderr] += data
          end

          # Callback to capture exit status
          channel.on_request("exit-status") do |channel, data|
            host = channel[:host]
            @result_data[host][:exit_status] = data.read_long
          end

          # Callback on channel close, yielding results
          channel.on_close do |channel|
            host = channel[:host]
            yield @result_data[host]
          end

          # Exec cmd on current channel
          channel.exec cmd do |channel, success|
            host = channel[:host]
            if not success:
              @result_data[host][:stderr] += "exec on #{host} failed!"
              @result_data[host][:exit_status] ||= 255
              yield @result_data[host]
            end
          end

          # Wait for all channels
          channel.wait
        end

        # Run the event loop
        session.loop
      end
    end
  end
end

