
module Net
  module SSHR

    # Net::SSHR::Merger class, merging and tracking distinct result sets with their hosts
    class Merger < Array

      # Merge the given result into our current set of results: 
      # if it matches an existing result, we append result.host to match.host;
      # if it matches no existing result, we append it to our result set.
      def merge(result)
        stdout = result.stdout
        stderr = result.stderr

        added = false
        each do |merged|
          if merged.stdout == stdout and merged.stderr == stderr:
            merged.host += ' ' + result.host
            added = true
            break
          end
        end

        push result if not added
      end
    end
  end
end

