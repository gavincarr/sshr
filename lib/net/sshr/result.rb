# Net::SSHR::Result class, modelling an individual host result

class Net::SSHR::Result
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
  def to_json(*a)
    {
      'json_class'  => self.class.name,
      'host'        => @host,
      'stdout'      => @stdout,
      'stderr'      => @stderr,
      'exit_code'   => @exit_code,
    }.to_json(*a)
  end
end

