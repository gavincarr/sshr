
module Net
  class SSHR

    # Net::SSHR::Merger class, collating and merging result sets
    class Merger < Array
      def merge(result)
        res[:stdout] ||= ''
        res[:stdout].chomp!
        res[:stderr] ||= ''
        res[:stderr].chomp!

        added = false
        each do |merged|
          if merged[:stdout] == res[:stdout] and merged[:stderr] == res[:stderr]:
            merged[:host] += " #{res[:host]}"
            added = true
            break
          end
        end

        push res if not added
      end
    end
  end
end

