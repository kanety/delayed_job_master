# frozen_string_literal: true

require_relative 'master/core'

module Delayed
  module Master
    class << self
      def new(argv)
        Core.new(argv)
      end
    end
  end
end
