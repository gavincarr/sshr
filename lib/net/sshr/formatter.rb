
module Net
  module SSHR

    # Net::SSHR::Formatter class, handling formatting of Net::SSHR::Result objects
    class Formatter

      # Format, one of: 
      # - :long (full multi-line output)
      # - :short (show only the first line of output)
      # - :json (format result as a serialised json hash)
      attr_accessor :format

      # Output/Error Selector, one of the following:
      # - :oe_out  - to display only the stdout stream
      # - :oe_err  - to display only the stderr stream
      # - :oe_both - to display both the stdout and stderr streams
      # - :oe_xor  - to display the stdout stream if set, otherwise stderr
      # Default is +xor+ for :short format, and +both+ otherwise
      attr_accessor :out_err_selector

      # Whether to show the hostname in the output (boolean)
      # Default is +false+ for :short format, and +true+ otherwise
      attr_accessor :show_hostname

      # Whether to explicitly annotate the output and error streams
      attr_accessor :annotate_flag

      # Width (characters) to use for hostname field (if :show_hostname is true)
      attr_accessor :hostname_width

      # Create a new formatter instance.
      def initialize(options = {})
        @format = nil
        @out_err_selector = nil
        @show_hostname = nil
        @annotate_flag = false
        @hostname_width = 20

        options.each{|opt, val| send("#{opt}=", val) }
      end

      # Returns a formatted output string for the given result
      def render(result)
        raise ArgumentError, "Argument '#{result}' not a Net::SSHR::Result" unless result.is_a? Net::SSHR::Result
        result.stdout.chomp!
        result.stderr.chomp!

        # Default formatter: use short for single lines, otherwise long
        @format ||= result.stdout =~ /\n/ ? :long : :short

        # Default out_err_selector if not set: stdout xor stderr in 'short' mode, otherwise both
        # Default show_header if not set: false in 'short' mode, otherwise true
        @out_err_selector ||= (@format == :short ? :oe_xor : :oe_both)
        @show_hostname = (@format == :short ? false : true) if @show_hostname == nil

        method(@format).call(result)
      end

      # Returns a formatted output string for the given set of results
      def render_all(result_set)
        # If we're doing the whole set and :format is :short, calculate hostname_width
        @hostname_width = 1
        result_set.each do |result|
          result_hostname_width = result.host.length + 2
          if @hostname_width < result_hostname_width
             @hostname_width = result_hostname_width
          end
          break unless @show_hostname
        end

        # Render each result
        out = ''
        result_set.each { |result| out += render(result) }
        return out
      end

      private

      def display_stdout(stdout)
        return false if stdout == ''
        return false if @out_err_selector == :oe_err
        return true
      end

      def display_stderr(stderr, stdout)
        return false if stderr == ''
        return false if @out_err_selector == :oe_out
        return false if @out_err_selector == :oe_xor and stdout != ''
        return true
      end

      # Long output renderer
      def long(result)
        display_stdout = display_stdout(result.stdout)
        display_stderr = display_stderr(result.stderr, result.stdout)

        out = ''
        out << "[#{result.host}]\n" if @show_hostname
        out << result.stdout + "\n" if display_stdout
        if display_stdout and display_stderr:
          out << "\n" 
          out << "** STDERR **\n" if @annotate_flag
        end
        out << result.stderr + "\n" if display_stderr
        out << "\n"
        return out
      end

      # Short output renderer
      def short(result)
        out = ''
        hostname = ''
        fmt = "%s%s\n"
        if @show_hostname
          fmt = "%-#{@hostname_width}s " + fmt
          hostname = result.host + ':'
        else
          fmt = '%s' + fmt
        end
        if display_stdout(result.stdout):
          stdout = result.stdout.sub(/\n.*/m, '')
          out << sprintf(fmt, hostname, @annotate_flag ? '[O] ' : '', stdout)
        end
        if display_stderr(result.stderr, result.stdout):
          stderr = result.stderr.sub(/\n.*/m, '')
          out << sprintf(fmt, hostname, @annotate_flag ? '[E] ' : '', stderr)
        end
        return out
      end

      # JSON renderer
      def json(result)
        require 'json'
        return result.to_json + "\n"
      end
    end
  end
end

