
module Net
  module SSHR

    # Net::SSHR::Formatter class, handling formatting of Net::SSHR::Result objects
    class Formatter

      # Create a new formatter instance. 
      # @format may be one of :long (full multi-line output), :short (show only the
      # first line of output), or :json (format result as a serialised json hash).
      # @out_err_selector may be one of the following:
      # - :oe_out  - to display only the stdout stream
      # - :oe_err  - to display only the stderr stream
      # - :oe_both - to display both the stdout and stderr streams
      # - :oe_xor  - to display the stdout stream if set, otherwise stderr
      # The @annotate_flag is used to indicate whether to explicitly annotate the streams.
      # The @hostwidth parameter indicates the length to use for the hostname field
      # when @format == :short.
      def initialize(format = nil, out_err_selector = nil, annotate_flag = false, hostwidth = 20)
        @format = format
        @out_err_selector = out_err_selector
        @annotate_flag = annotate_flag
        @hostwidth = hostwidth
      end

      # Returns a formatted output string for the given result
      def render(result)
        raise ArgumentError, "Argument '#{result}' not a Net::SSHR::Result" unless result.is_a? Net::SSHR::Result
        result.stdout.chomp!
        result.stderr.chomp!

        # Default formatter: use short for single lines, otherwise long
        @format ||= result.stdout =~ /\n/ ? :long : :short

        # Default out_err_selector: stdout xor stderr in 'short' mode, otherwise both
        @out_err_selector ||= (@format == :short ? :oe_xor : :oe_both)

        method(@format).call(result)
      end

      # Returns a formatted output string for the given set of results
      def render_all(result_set)
        # If we're doing the whole set and :format is :short, adapt hostwidth
        @hostwidth = 1
        result_set.each do |result|
          result_hostwidth = result.host.length + 2
          if @hostwidth < result_hostwidth
             @hostwidth = result_hostwidth
          end
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
        out << "[#{result.host}]\n"
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
        fmt = "%-#{@hostwidth}s %s%s\n"
        if display_stdout(result.stdout):
          stdout = result.stdout.sub(/\n.*/m, '')
          out << sprintf(fmt, result.host + ':', @annotate_flag ? '[O] ' : '', stdout)
        end
        if display_stderr(result.stderr, result.stdout):
          stderr = result.stderr.sub(/\n.*/m, '')
          out << sprintf(fmt, result.host + ':', @annotate_flag ? '[E] ' : '', stderr)
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

