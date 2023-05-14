# frozen_string_literal: true

module Delayed
  module Master
    module Sleep
      def loop_with_sleep(sec)
        count = [sec.to_i, 1].max
        div = sec.to_f / count
        loop do
          count.times do |i|
            yield i
            sleep div
          end
        end
      end
    end
  end
end
