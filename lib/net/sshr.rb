
require 'net/ssh/multi'
require 'net/sshr/result'

module Net
  # = ABSTRACT
  #
  # Net::SSHR is a simple wrapper around Net::SSH::Multi, optimised for the
  # case where you wish to run a single command on multiple hosts, and
  # collate and report the results.
  #
  # = SYNOPSIS
  #
  #   require 'net/sshr'
  #   include SSHR
  #
  #   # Run a command on multiple hosts
  #   sshr_exec(%w{ host1 host2 }, 'uptime') do |result|
  #     puts "#{result.host}: #{result.exit_code}"
  #     puts #{result.stdout}
  #   end
  #
  #   # Run arbitrary sets of host-command pairs
  #   sshr_exec_list(
  #                   'host1', 'uptime',
  #                   'host1', 'rpm -q ruby',
  #                   'host2', 'date',
  #                   'host3', 'uname -r'
  #                 ) do |result|
  #     puts "#{result.host}: #{result.exit_code}"
  #     puts #{result.stdout}
  #   end
  #
  module SSHR
    # Run the given cmd on the given hosts, executing block with each host's results
    # (a Net::SSHR::Result object).
    def sshr_exec(hosts, cmd, options = {}, &block)             # yields: result
      options[:default_user] ||= 'root'
      hosts = [ hosts ] unless hosts.is_a? Array
      if hosts.length > 1 and not block
        raise ArgumentError, "Required block argument missing (more than one host)"
      end

      # result_data is a hash keyed by hostname of Net::SSH::Result objects
      result_data = {}

      cc = options[:concurrent_connections]
      Net::SSH::Multi.start(:on_error => :warn, 
                            :default_user => options[:default_user],
                            :allow_duplicate_servers => true, 
                            :concurrent_connections => cc) do |session|
        # Setup server connections and result objects
        hosts.each do |host|
          hostname = host.sub(/^.*@/, '')
          server = session.use(host)
          result_data[server.object_id] = Net::SSHR::Result.new(hostname, cmd)
        end

        # Execute cmd on all servers
        session.open_channel do |channel|
          server = channel[:server]
          result = result_data[server.object_id]
          exec_block = gen_channel_exec_block(result, options, &block)
          channel.exec(cmd, &exec_block)
        end

        # Run the event loop
        session.loop
      end

      return result_data[result_data.keys.first] if not block
    end

    # Run the given list of host/command pairs, executing block with each result
    def sshr_exec_list(*args, &block)             # yields: result
      options = args.last.is_a?(Hash) ? args.pop : {}
      options[:default_user] ||= 'root'

      raise ArgumentError, "Not an even number of host-command arguments" unless args.length % 2 == 0
      raise ArgumentError, "Required block argument missing" unless block

      # result_data is a hash of Net::SSH::Result objects, keyed by server.object_id
      result_data = {}

      cc = options[:concurrent_connections]
      Net::SSH::Multi.start(:on_error => :warn, 
                            :default_user => options[:default_user],
                            :allow_duplicate_servers => true, 
                            :concurrent_connections => cc) do |session|
        # Setup server connections and result objects
        while args.length > 0 do
          host = args.shift
          cmd = args.shift
          hostname = host.sub(/^.*@/, '')
          server = session.use(host)

          # Setup result objects to capture results, one per cmd per server
          result_data[server.object_id] ||= []
          result_data[server.object_id].push Net::SSHR::Result.new(hostname, cmd)
          $stderr.puts "+ [#{server.object_id}] #{session_host} => #{cmd}" if options[:verbose]
        end

        session.open_channel do |channel|
          server = channel[:server]
          result_data[server.object_id].each do |result|
            cmd = result.cmd
            exec_block = gen_channel_exec_block(result, options, &block)
            channel.exec(cmd, &exec_block)
          end
        end

        # Run the event loop
        session.loop
      end
    end

    private

    def gen_channel_exec_block(result, options, &block)
      return lambda { |channel, success|
        if not success:
          result.stderr << "exec on #{result.host} #{result.cmd} failed!"
          result.exit_code ||= 255
          yield result if block
        end

        # Callbacks to capture stdout and stderr
        channel.on_data do |channel, data|
          result.stdout << data
        end
        channel.on_extended_data do |channel, type, data|
          result.stderr << data
        end

        # Callback to capture exit status
        channel.on_request("exit-status") do |channel, data|
          result.exit_code = data.read_long
        end

        # Callback on channel close, yielding results
        channel.on_close do |channel|
          if options[:verbose]:
            $stderr.puts "+ stdout: #{result.stdout}" if options[:verbose]
          end
          yield result if block
        end
      }
    end
  end
end

