# Net::SSHR class, wrapper around Net::SSH::Multi

require 'net/ssh/multi'

module Net
  class SSHR
    def initialize(options)
      @defaults = { :hosts => [] }
      @defaults.merge!(options)
      raise "Required :hosts argument missing" if @defaults[:hosts].empty?
    end

    def exec(cmd, &block)
      raise "Required command argument go exec missing" if not cmd

      @result_set = []
      @result_data = {}

      Net::SSH::Multi.start(:on_error => :ignore) do |session|
        @defaults[:hosts].each do |host|
          session.use("root@#{host}")
        end

        channel = session.exec(cmd) do |ch, stream, data|
          host = ch[:host]
          @result_data[host] ||= { :host => host }
          @result_data[host][stream] ||= ''
          @result_data[host][stream] += data
        end
        channel.wait

        channel.each do |ch|
          host = ch[:host]
          @result_data[host] ||= { :host => host }
          @result_data[host][:code] = ch[:exit_status]
          if block_given?
            yield @result_data[host]
          else
            @result_set.push(@result_data[host])
          end
        end

        session.loop
      end

      return if block
      return @result_set
    end
  end
end

