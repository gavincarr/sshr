
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
      raise ArgumentError, "Required block argument missing" unless block

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
          result_data[hostname] = Net::SSHR::Result.new(hostname, cmd)
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
      raise ArgumentError, "Required block argument missing" unless block

      # result_data is a hash of Net::SSH::Result objects, keyed by server.hash
      result_data = {}

      Net::SSH::Multi.start(:on_error => :warn) do |session|
        # Setup server connections and result objects
        host_cmd_list.each do |host_cmd|
          if not host_cmd.is_a? Array:
            raise ArgumentError, "Invalid entry '#{host_cmd}' in host_cmd_list"
          elsif host_cmd.length != 2:
            raise ArgumentError, "Invalid entry '" + host_cmd.join(',') + "' in host_cmd_list"
          end

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

          # Setup result objects to capture results, one per cmd per server
          result_data[server.hash] ||= []
          result_data[server.hash].push Net::SSHR::Result.new(hostname, cmd)
          $stderr.puts "+ [#{server.hash}] #{session_host} => #{cmd}" if options[:verbose]
        end

        session.open_channel do |channel|
          server = channel[:server]
          server_channel_count = 0

          result_data[server.hash].each do |result|
            cmd = result.cmd
            label = "#{server.user}@#{server.host} => #{cmd}"
            $stderr.puts "+ prep #{label}" if options[:verbose]
            server_channel_count += 1

            # open_channel only gives us one channel per server
            # if we have more than that, we need to open additional channels manually
            if server_channel_count > 1:
              $stderr.puts "+ open new channel please for #{label}"
              channel = server.session.open_channel do |channel|
                channel.exec cmd do |channel, success|
                  if not success:
                    result.stderr << "exec on #{label} failed!"
                    result.exit_code ||= 255
                    yield result
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
#                     $stderr.puts "+ channel close for #{label}, yielding results"
                      $stderr.puts "+ stdout: #{result.stdout}"
                    end
                    yield result
                  end
                end
              end

            # Setup exec on current channel
            else
              channel.exec cmd do |channel, success|
                if not success:
                  result.stderr << "exec on #{label} failed!"
                  result.exit_code ||= 255
                  yield result
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
  #                 $stderr.puts "+ channel close for #{label}, yielding results"
                    $stderr.puts "+ stdout: #{result.stdout}"
                  end
                  yield result
                end
              end
            end
          end
        end

        # Run the event loop
        session.loop
      end
    end
  end
end

