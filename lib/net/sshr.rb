# Net::SSHR class, wrapper around Net::SSH::Multi

require 'net/ssh/multi'

module Net
  class SSHR
    def initialize(options)
      @defaults = { :hosts => [] }
      @defaults.merge!(options)
      raise "Required :hosts argument missing" if @defaults[:hosts].empty?
    end

    def exec(cmd)
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
          @result_data[ch[:host]][:code] = ch[:exit_status]
          @result_set.push(@result_data[ch[:host]])
        end

        session.loop
      end

      return @result_set
    end
  end
end

