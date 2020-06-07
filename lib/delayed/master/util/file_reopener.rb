module Delayed
  class Master
    class Util
      class FileReopener
        class << self
          def reopen
            ObjectSpace.each_object(File) do |file|
              next if file.closed? || !file.sync
              file.reopen file.path, 'a+'
              file.sync = true
              file.flush
            end
          end
        end
      end
    end
  end
end
