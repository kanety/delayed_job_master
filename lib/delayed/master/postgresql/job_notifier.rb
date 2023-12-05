# frozen_string_literal: true

module Delayed
  module Master
    module Postgresql
      class << self
        def notify(model)
          identity = "#{model.connection.shard}.delayed_job_master"
          model.connection.execute "NOTIFY #{quote(identity)}"
        end

        private

        def quote(identity)
          ActiveRecord::Base.connection.quote_column_name(identity)
        end
      end

      module JobNotifier
        extend ActiveSupport::Concern

        included do
          after_create :notify_to_delayed_job_master
        end

        private

        def notify_to_delayed_job_master
          if run_at && run_at < Time.zone.now
            Delayed::Master::Postgresql.notify(self.class)
          end
        end
      end

      module BulkJobNotifier
        extend ActiveSupport::Concern

        included do
          after_enqueue :notify_to_delayed_job_master
        end

        private

        def notify_to_delayed_job_master
          if @jobs.any? { |job| job.run_at && job.run_at < Time.zone.now }
            Delayed::Master::Postgresql.notify(@jobs.first.class)
          end
        end
      end
    end
  end
end
