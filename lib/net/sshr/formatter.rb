
module Net
  class SSHR

    # Net::SSHR::Formatter class, handling formatting of Net::SSHR::Results
    class Formatter
      def initialize(format = nil, out_err_selector = nil, annotate_flag = false, hostwidth = 20)
        @format = format
        @out_err_selector = out_err_selector
        @annotate_flag = annotate_flag
        @hostwidth = hostwidth
      end

      # Render the given result
      def render(result)
        result.stdout.chomp!
        result.stderr.chomp!

        # Default formatter: use short for single lines, otherwise long
        @format ||= result.stdout =~ /\n/ ? :long : :short

        # Default out_err_selector: stdout xor stderr in 'short' mode, otherwise both
        @out_err_selector ||= (@format == :short ? :oe_xor : :oe_both)

        method(@format).call(result)
      end

      # Render the given set of results
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
        result_set.each { |result| render(result) }
      end

      def display_stdout(stdout)
        return false if not stdout
        return false if @out_err_selector == :oe_err
        return true
      end

      def display_stderr(stderr, stdout)
        return false if not stderr
        return false if @out_err_selector == :oe_out
        return false if @out_err_selector == :oe_xor and stdout
        return true
      end

      private

      # Long output renderer
      def long(result)
        display_stdout = display_stdout(result.stdout)
        display_stderr = display_stderr(result.stderr, result.stdout)

        puts "[#{result.host}]"
        puts result.stdout if display_stdout
        if display_stdout and display_stderr:
          puts 
          puts '** STDERR **' if @annotate_flag
        end
        puts result.stderr if display_stderr
        puts
      end

      # Short output renderer
      def short(result)
        fmt = "%-#{@hostwidth}s %s%s\n"
        if display_stdout(result.stdout):
          stdout = result.stdout.sub(/\n.*/m, '')
          printf fmt, result.host + ':', @annotate_flag ? '[O] ' : '', stdout
        end
        if display_stderr(result.stderr, result.stdout):
          stderr = result.stderr.sub(/\n.*/m, '')
          printf fmt, result.host + ':', @annotate_flag ? '[E] ' : '', stderr
        end
      end

      # JSON renderer
      def json(result)
        require 'json'
        puts result.to_json
      end
    end
  end
end

