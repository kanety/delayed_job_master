module Delayed
  class Util
    class << self
      def reopen_files
        files = []
        ObjectSpace.each_object(File) do |file|
          next if file.closed? || !file.sync
          file.reopen file.path 
          file.sync = true
          file.flush
        end
      end
    end
  end
end
