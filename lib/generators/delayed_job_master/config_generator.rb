# frozen_string_literal: true

require 'rails/generators'

module DelayedJobMaster
  class ConfigGenerator < Rails::Generators::Base
    source_root File.join(File.dirname(__FILE__), 'templates')

    def create_script_file
      template 'script', 'bin/delayed_job_master'
      chmod 'bin/delayed_job_master', 0o755
    end

    def create_config_file
      template 'config.rb', 'config/delayed_job_master.rb'
    end
  end
end
