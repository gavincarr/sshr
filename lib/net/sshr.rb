
require 'net/ssh/multi'
require 'net/sshr/result'

module Net
  # = ABSTRACT
  #
  # Net::SSHR is a simple wrapper around Net::SSH::Multi, optimised for the
  # case where you wish to run a single command on multiple hosts, or a set
  # of arbitrary host-command pairs, and then collate and report the results.
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
  #   # Trivial single-host usage
  #   result = sshr_exec('host', 'date')
  #   puts result
  #
  module SSHR
    # Run cmd on the given array of hosts. Hosts is either a single string,
    # or an array of strings, each of which is either a bare hostname 
    # ('host1') or a user@hostname combination ('user@host1').
    # Options is a hash, which can have the following keys:
    # - :default_user, which if supplied is used for any host that doesn't
    #   have an explicit user given;
    # - :concurrent_connections, which if given will limit the number of
    #   simultaneous connections used.
    # - :request_pty, to request a pseudo-tty allocation on the ssh channel
    #   (cf. ssh -t)
    # If &block is supplied, the block is executed with each host's results
    # (a Net::SSHR::Result object); if no block is given, returns the single
    # result if hosts was a scalar, and an array of results otherwise.
    def sshr_exec(hosts, cmd, options = {}, &block)             # yields: result
      hosts_scalar = true if not hosts.is_a? Array
      hosts = [ hosts ] if hosts_scalar

      # result_data is a hash keyed by hostname of Net::SSH::Result objects
      result_data = {}

      cc = options[:concurrent_connections]
      Net::SSH::Multi.start(:on_error => :warn, 
                            :default_user => options[:default_user],
                            :concurrent_connections => cc) do |session|
        # Setup server connections and result objects
        hosts.each do |host|
          server = session.use(host)
          result_data[server.object_id] = Net::SSHR::Result.new(host, cmd)
        end

        # Execute cmd on all servers
        session.open_channel do |channel|
          channel.request_pty if options[:request_pty]
          server = channel[:server]
          result = result_data[server.object_id]
          exec_block = gen_channel_exec_block(result, options, &block)
          channel.exec(cmd, &exec_block)
        end

        # Run the event loop
        session.loop
      end

      if not block
        if hosts_scalar
          return result_data[result_data.keys.first]
        else
          results = {}
          result_data.each {|k,v| results[v.host_string] = v }
          return hosts.map {|host| results[host] }
        end
      end
    end

    # Run the given list of host/command pairs ('host1', 'cmd1', 'host2',
    # 'cmd2', etc.) Each host may be a bare hostname string ('host1'), or
    # a user@hostname combination. The list of hosts and commands may
    # optionally be followed by an options hash, which can have the
    # following keys:
    # - :default_user, which if supplied is used for any host that doesn't
    #   have an explicit user given;
    # - :concurrent_connections, which if given will limit the number of
    #   simultaneous connections used.
    # - :request_pty, to request a pseudo-tty allocation on the ssh channel
    #   (cf. ssh -t)
    # sshr_exec_list requires a &block argument, which is executed for each
    # input host-cmd pair, and passed the cmd result (a Net::SSHR::Result
    # object).
    def sshr_exec_list(*args, &block)             # yields: result
      options = args.last.is_a?(Hash) ? args.pop : {}

      raise ArgumentError, "Not an even number of host-command arguments" unless args.length % 2 == 0
      raise ArgumentError, "Required block argument missing" unless block

      # result_data is a hash of Net::SSH::Result objects, keyed by server.object_id
      result_data = {}

      cc = options[:concurrent_connections]
      Net::SSH::Multi.start(:on_error => :warn, 
                            :default_user => options[:default_user],
                            :concurrent_connections => cc) do |session|
        # Setup server connections and result objects
        while args.length > 0 do
          host = args.shift
          cmd = args.shift
          server = session.use(host)

          # Setup result objects to capture results, one per cmd per server
          result_data[server.object_id] ||= []
          result_data[server.object_id].push Net::SSHR::Result.new(host, cmd)
          $stderr.puts "+ [#{server.object_id}] #{session_host} => #{cmd}" if options[:verbose]
        end

        session.open_channel do |channel|
          channel.request_pty if options[:request_pty]
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


  # Monkey-patch Net::SSH::Multi::ServerList to allow duplicate hosts
  # (tried patching upstream, but have never got a response)
  module SSH; module Multi; class ServerList
    def initialize(list=[])
      options = list.last.is_a?(Hash) ? list.pop : {}
      @list = list
    end
    def add(server)
      @list.push(server)
      server
    end
    def flatten
      result = @list.inject([]) do |aggregator, server|
        case server
        when Server then aggregator.push(server)
        when DynamicServer then aggregator.concat(server)
        else raise ArgumentError, "server list contains non-server: #{server.class}"
        end
      end
      result
    end
  end; end; end

  # Monkey-patch Net::SSH::Config#for to default options user if unset
  module SSH; class Config
    class <<self
      alias_method :old_for, :for
      def for(host, files=default_files)
        options = old_for(host, files)
        options[:user] ||= ENV['USER'] || ENV['USERNAME'] || 'unknown'
        options
      end
    end
  end; end
end

