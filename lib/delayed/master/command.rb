# frozen_string_literal: true

require 'optparse'
require_relative 'version'
require_relative 'config'

module Delayed
  module Master
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
          opt.on('-c', '--config=FILE', 'Specify config file') do |file|
            @config.read(file)
          end
          opt.on('-D', '--daemon', 'Start master as a daemon') do |boolean|
            @config.daemon = boolean
          end
          opt.on('--working-directory=DIR', 'Path to working directory') do |dir|
            @config.working_directory = dir
          end
          opt.on('--pid-file=FILE', 'Path to pid file') do |file|
            @config.pid_file = file
          end
          opt.on('--log-file=FILE', 'Path to log file') do |file|
            @config.log_file = file
          end
          opt.on('--log-level=LEVEL', 'Log level') do |level|
            @config.log_level = level.to_sym
          end
          opt.on('--databases=DB1,DB2', Array, 'Database spec name to check delayed_jobs table') do |databases|
            @config.databases = databases.map(&:to_sym)
          end
        }.parse(args)
      end
    end
  end
end
