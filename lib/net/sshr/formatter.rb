# Net::SSHR::Formatter class

class Net::SSHR::Formatter
  def initialize(options)
    @options = options
  end

  # Render the given result
  def render(res)
    res[:stdout] ||= ''
    res[:stdout].chomp!
    res[:stderr] ||= ''
    res[:stderr].chomp!

    # Smart default formatter: use short for single lines, otherwise long
    @options[:fmt] ||= res[:stdout] =~ /\n/ ? 'long' : 'short'

    self.method(@options[:fmt]).call(res)
  end

  # Long output renderer
  def long(res)
    puts "[#{res[:host]}]"
    puts res[:stdout] if res[:stdout] != ''
    puts if res[:stdout] != '' and res[:stderr] != ''
    puts res[:stderr] if res[:stderr] != ''
    puts
  end

  # Short output renderer
  def short(res)
    format = "%-20.20s %s\n"
    printf format, res[:host] + ':', res[:stdout] if res[:stdout] != ''
  end
end

