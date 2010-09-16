# Net::SSHR::Merger class, collating and merging result sets

class Net::SSHR::Merger < Array
  def merge(res)
    res[:stdout] ||= ''
    res[:stdout].chomp!
    res[:stderr] ||= ''
    res[:stderr].chomp!

    added = false
    self.each do |merged|
      if merged[:stdout] == res[:stdout] and merged[:stderr] == res[:stderr]:
        merged[:host] += " #{res[:host]}"
        added = true
        break
      end
    end

    self.push res if not added
  end
end

