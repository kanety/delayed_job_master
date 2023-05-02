# frozen_string_literal: true

require 'optparse'
require_relative 'config'

module Delayed
  class Master
    class Command
      attr_reader :config

      def initialize(args)
        @config = Config.new

        OptionParser.new { |opt|
          opt.banner = <<-EOS
            #{File.basename($PROGRAM_NAME)} #{Delayed::Master::VERSION}
            Usage: #{File.basename($PROGRAM_NAME)} [options]
          EOS

          opt.on('-h', '--help', '-v', '--version', 'Show this message') do |boolean|
            puts opt
            exit
          end
          opt.on('-D', '--daemon', 'Start master as a daemon') do |boolean|
            @config.daemon(boolean)
          end
          opt.on('-c', '--config=FILE', 'Specify config file') do |file|
            @config.read(file)
          end
        }.parse(args)
      end
    end
  end
end
