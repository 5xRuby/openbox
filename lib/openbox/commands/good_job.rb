# frozen_string_literal: true

module Openbox
  # :nodoc:
  module Commands
    # The GoodJob Command
    #
    # @since 0.1.0
    class GoodJob < Openbox::Command
      # Run good_job worker
      #
      # @since 0.1.0
      def execute
        Openbox.database.ensure_connection!
        exec('bundle exec good_job start')
      end
    end

    if Openbox.runtime.has?('good_job')
      Openbox::Entrypoint.register(GoodJob, 'good_job', 'good_job', 'Run good_job worker')
    end
  end
end
