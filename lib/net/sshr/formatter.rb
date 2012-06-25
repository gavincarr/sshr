
module Net
  module SSHR

    # Net::SSHR::Formatter class, handling formatting of Net::SSHR::Result objects
    class Formatter

      # Format, one of: 
      # - :long  (full multi-line output)
      # - :short (show only the first line of output)
      # - :json  (format result as a serialised json hash)
      # - :list  (report hosts that produce output, and nothing else)
      attr_accessor :format

      # Output/Error Selector, one of the following:
      # - :oe_out  - to display only the stdout stream
      # - :oe_err  - to display only the stderr stream
      # - :oe_both - to display both the stdout and stderr streams
      # - :oe_xor  - to display the stdout stream if set, otherwise stderr
      # Default is +xor+ for :short format, and +both+ otherwise
      attr_accessor :out_err_selector

      # Whether to show the hostname in the output (boolean)
      # Default is +true+.
      attr_accessor :show_hostname

      # Whether to prefix the hostname to all output lines in :long mode (boolean)
      # Default is +false+.
      attr_accessor :prefix_hostname

      # Whether to show hosts that produce no output (boolean)
      # Default is +false+ i.e. show hosts that produce no output
      attr_accessor :quiet

      # Whether to explicitly annotate the output and error streams
      attr_accessor :annotate_flag

      # Width (characters) to use for hostname field (if :show_hostname is true)
      attr_accessor :hostname_width

      # Number of hosts to be formatted (mostly useful for N == 1)
      attr_accessor :host_count

      # Create a new formatter instance.
      def initialize(options = {})
        @format = nil
        @out_err_selector = nil
        @show_hostname = true
        @prefix_hostname = false
        @quiet = false
        @annotate_flag = false
        @hostname_width = 20
        @host_count = 0

        options.each{|opt, val| send("#{opt}=", val) if val != nil }
      end

      # Returns a formatted output string for the given result
      def render(result)
        raise ArgumentError, "Argument '#{result}' not a Net::SSHR::Result" unless result.is_a? Net::SSHR::Result
        result.stdout.chomp!
        result.stderr.chomp!

        return '' if @quiet and result.stdout == '' and result.stderr == ''

        # Default formatter: use short for single lines, otherwise long
        @format ||= result.stdout =~ /\n/ ? :long : :short

        # Default out_err_selector if not set: stdout xor stderr in 'short' mode, otherwise both
        @out_err_selector ||= (@format == :short ? :oe_xor : :oe_both)

        # Process result output
        stdout = result.stdout
        stderr = result.stderr
        if @format == :short
          # Truncate short output to initial line
          stdout = result.stdout.sub(/\n.*/m, "\n")
          stderr = result.stderr.sub(/\n.*/m, "\n")
        end

        # Use short formatter in @prefix_hostname mode
        formatter = (@format == :long and @prefix_hostname) ? 'short' : @format

        # Call specified formatter
        method(formatter).call(result.host, stdout, stderr) || ''
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
      def long(hostname, stdout, stderr)
        display_stdout = display_stdout(stdout)
        display_stderr = display_stderr(stderr, stdout)

        out = ''
        out << "[#{hostname}]\n" if @show_hostname
        out << stdout + "\n" if display_stdout
        if display_stdout and display_stderr:
          out << "\n" 
          out << "** STDERR **\n" if @annotate_flag
        end
        out << stderr + "\n" if display_stderr
        out << "\n" if @host_count >= 1 and @show_hostname
        return out
      end

      # Short output renderer
      def short(hostname, stdout, stderr)
        display_stdout = display_stdout(stdout)
        display_stderr = display_stderr(stderr, stdout)

        out = ''
        hostname_prefix = ''
        if @show_hostname
          hostname_prefix = sprintf("%-#{@hostname_width}s ", hostname)
        end
        if display_stdout
          stdout.split(/\n/).each do |line|
            out << hostname_prefix
            out << (@annotate_flag ? '[O] ' : '')
            out << line + "\n"
          end
        end
        if display_stderr
          stderr.split(/\n/).each do |line|
            out << hostname_prefix
            out << (@annotate_flag ? '[E] ' : '')
            out << line + "\n"
          end
        end
        return out
      end

      # JSON renderer
      def json(result)
        require 'json'
        return result.to_json + "\n"
      end

      # List hosts renderer
      def list(result)
        return "#{result.host}\n" if result.stdout != ''
      end
    end
  end
end

