# frozen_string_literal: true

module Delayed
  module Master
    class Callbacks
      def initialize(config)
        @config = config
      end

      def call(event, *args, &block)
        run(:"before_#{event}", *args)
        result = run(:"around_#{event}", *args, &block)
        run(:"after_#{event}", *args)
        result
      end

      def run(name, *args, &block)
        callbacks = get_callbacks(name)
        if block
          callbacks.reverse.reduce(block) { |ret, c| -> { c.call(*args, &ret) } }.call
        else
          callbacks.each { |c| c.call(*args) }
        end
      end

      private

      def get_callbacks(name)
        if @config.respond_to?(name)
          @config.send(name).to_a
        else
          []
        end
      end
    end
  end
end
