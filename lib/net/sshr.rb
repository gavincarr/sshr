
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
  #   sshr_exec(%w{ host1 host2 }, 'uptime') do |result|
  #     puts "#{result.host}: #{result.exit_code}"
  #     puts #{result.stdout}
  #   end
  #
  module SSHR
    # Run the given cmd on the given hosts, executing block with each host's results
    # (a Net::SSHR::Result object).
    def sshr_exec(hosts, cmd, options = {}, &block)             # yields: result
      raise ArgumentError, "Required block argument missing" if not block

      hosts = [ hosts ] unless hosts.is_a? Array

      # result_data is a hash keyed by hostname of Net::SSH::Result objects
      result_data = {}

      Net::SSH::Multi.start(:on_error => :warn) do |session|
        # Define users and servers to connect to, and initialise result_data
        hosts.each do |host|
          # TODO: figure how to do user + ssh options stuff properly
          if (host =~ /@/):
            session_host = host
            hostname = host.sub(/^.*@/, '')
          else
            session_host = "root@#{host}"
            hostname = host
          end
          session.use(session_host)
          result_data[hostname] = Net::SSHR::Result.new(hostname)
        end

        # Execute cmd on all servers
        session.open_channel do |channel|
          # Callbacks to capture stdout and stderr
          channel.on_data do |channel, data|
            host = channel[:host]
            result_data[host].stdout << data
          end
          channel.on_extended_data do |channel, type, data|
            host = channel[:host]
            result_data[host].stderr << data
          end

          # Callback to capture exit status
          channel.on_request("exit-status") do |channel, data|
            host = channel[:host]
            result_data[host].exit_code = data.read_long
          end

          # Callback on channel close, yielding results
          channel.on_close do |channel|
            host = channel[:host]
            if options[:verbose]:
              $stderr.puts "+ channel close for host #{host}, yielding results"
            end
            yield result_data[host]
          end

          # Exec cmd on current channel
          channel.exec cmd do |channel, success|
            host = channel[:host]
            if not success:
              result_data[host].stderr << "exec on #{host} failed!"
              result_data[host].exit_status ||= 255
              yield result_data[host]
            elsif options[:verbose]:
              $stderr.puts "+ exec on host #{host} begun"
            end
          end
        end

        # Run the event loop
        session.loop
      end
    end

    # Run the given list of host/command pairs, executing block with each result
    def sshr_exec_list(host_cmd_list, options = {}, &block)             # yields: result
      raise ArgumentError, "Argument host_cmd_list must be array" unless host_cmd_list.is_a? Array
      raise ArgumentError, "Required block argument missing" if not block

      # cmd_data is a hash of cmds to be executed, keyed by server.hash
      cmd_data = {}
      # result_data is a hash of Net::SSH::Result objects, keyed by server.hash
      result_data = {}

      Net::SSH::Multi.start(:on_error => :warn) do |session|
        # Define users and servers to connect to
        host_cmd_list.each do |host_cmd|
          raise ArgumentError, "Invalid entry '" + host_cmd.join(',') + "' in host_cmd_list" \
            unless host_cmd.is_a? Array and host_cmd.length == 2
          (host, cmd) = host_cmd

          # TODO: figure how to do user + ssh options stuff properly
          if (host =~ /@/):
            session_host = host
            hostname = host.sub(/^.*@/, '')
          else
            session_host = "root@#{host}"
            hostname = host
          end
          server = session.use(session_host)
          cmd_data[server.hash] = cmd
          result_data[server.hash] = Net::SSHR::Result.new(hostname)
          if options[:verbose]:
            $stderr.puts "+ host: #{host}"
            $stderr.puts "+ cmd: #{cmd}"
            $stderr.puts "+ session_host: #{session_host}"
            $stderr.puts "+ server.hash: #{server.hash}"
          end
        end

        session.open_channel do |channel|
          # Callbacks to capture stdout and stderr
          channel.on_data do |channel, data|
            server = channel[:server]
            result_data[server.hash].stdout << data
          end
          channel.on_extended_data do |channel, type, data|
            server = channel[:server]
            result_data[server.hash].stderr << data
          end

          # Callback to capture exit status
          channel.on_request("exit-status") do |channel, data|
            server = channel[:server]
            result_data[server.hash].exit_code = data.read_long
          end

          # Callback on channel close, yielding results
          channel.on_close do |channel|
            server = channel[:server]
            if options[:verbose]:
              $stderr.puts "+ channel close for host #{server.user}@#{server.host} => #{cmd_data[server.hash]}, yielding results"
              $stderr.puts "+ stdout: #{result_data[server.hash].stdout}"
            end
            yield result_data[server.hash]
          end

          # Exec cmd on current channel
          server = channel[:server]
          cmd = cmd_data[server.hash]
          channel.exec cmd do |channel, success|
            server = channel[:server]
            if not success:
              result_data[server.hash].stderr << "exec on #{server.host} failed!"
              result_data[server.hash].exit_status ||= 255
              yield result_data[server.hash]
            elsif options[:verbose]:
              $stderr.puts "+ exec #{server.user}@#{server.host} => #{cmd} begun"
            end
          end
        end

        # Run the event loop
        session.loop
      end
    end
  end
end

