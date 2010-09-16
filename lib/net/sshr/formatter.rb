# Net::SSHR::Formatter class

class Net::SSHR::Formatter
  def initialize(options)
    @options = { :hostwidth => 20 } # defaults
    @options.merge!(options)
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

  # Render the given set of results
  def render_all(res_set)
    # If we're doing the whole set and :fmt is 'short', adapt hostwidth
    @options[:hostwidth] = 1
    res_set.each do |res|
      res_hostwidth = res[:host].length + 2
      if @options[:hostwidth] < res_hostwidth
         @options[:hostwidth] = res_hostwidth
      end
    end

    # Render each res
    res_set.each { |res| self.render(res) }
  end

  private

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
    printf "%-#{@options[:hostwidth]}s %s\n", res[:host] + ':', res[:stdout] if res[:stdout] != ''
  end
end

