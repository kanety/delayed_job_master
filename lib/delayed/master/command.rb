require 'optparse'

module Delayed
  class Master
    class Command
      attr_reader :configs

      def initialize(args)
        @configs = {}

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
            @configs[:daemon] = boolean
          end
          opt.on('-c', '--config=FILE', 'Specify config file') do |file|
            @configs.merge!(Delayed::Master::DSL.new(file).configs)
          end
        }.parse(args)
      end
    end
  end
end
