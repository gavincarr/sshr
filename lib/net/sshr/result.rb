# Net::SSHR::Result class, modelling an individual host result

module Net
  class SSHR
    class Result
      attr_accessor :host, :stdout, :stderr, :exit_code
      def initialize(host, stdout = '', stderr = '', exit_code = '')
        @host = host
        @stdout = stdout
        @stderr = stderr
        @exit_code = exit_code
      end
      def append_stdout(string)
        @stdout += string
      end
      def append_stderr(string)
        @stderr += string
      end
    end
  end
end

