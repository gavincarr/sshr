# Net::SSHR::Formatter class

class Net::SSHR::Formatter
  def initialize(options)
    @options = { :hostwidth => 20 }     # defaults
    @options.merge!(options)
  end

  # Render the given result
  def render(res)
    res.stdout.chomp!
    res.stderr.chomp!

    # Default formatter: use short for single lines, otherwise long
    @options[:fmt] ||= res.stdout =~ /\n/ ? :long : :short

    # Default oe_selector: both stdout/stderr in long mode, stdout or stderr in short
    @options[:oe_selector] ||= @options[:fmt] == :long ? :oe_b : :oe_x; 

    method(@options[:fmt]).call(res)
  end

  # Render the given set of results
  def render_all(res_set)
    # If we're doing the whole set and :fmt is :short, adapt hostwidth
    @options[:hostwidth] = 1
    res_set.each do |res|
      res_hostwidth = res.host.length + 2
      if @options[:hostwidth] < res_hostwidth
         @options[:hostwidth] = res_hostwidth
      end
    end

    # Render each res
    res_set.each { |res| render(res) }
  end

  def display_stdout(stdout)
    return false if stdout == ''
    return false if @options[:oe_selector] == :oe_e
    return true
  end

  def display_stderr(stderr, stdout)
    return false if stderr == ''
    return false if @options[:oe_selector] == :oe_o
    return false if @options[:oe_selector] == :oe_x and stdout != ''
    return true
  end

  private

  # Long output renderer
  def long(res)
    display_stdout = display_stdout(res.stdout)
    display_stderr = display_stderr(res.stderr, res.stdout)

    puts "[#{res.host}]"
    puts res.stdout if display_stdout
    if display_stdout and display_stderr:
      puts 
      puts '** STDERR **' if @options[:stream]
    end
    puts res.stderr if display_stderr
    puts
  end

  # Short output renderer
  def short(res)
    fmt = "%-#{@options[:hostwidth]}s %s%s\n"
    if display_stdout(res.stdout):
      stdout = res.stdout.sub(/\n.*/m, '')
      printf fmt, res.host + ':', @options[:stream] ? '[O] ' : '', stdout
    end
    if display_stderr(res.stderr, res.stdout):
      stderr = res.stderr.sub(/\n.*/m, '')
      printf fmt, res.host + ':', @options[:stream] ? '[E] ' : '', stderr
    end
  end
end

