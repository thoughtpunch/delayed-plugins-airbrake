require 'airbrake'
require 'delayed/performable_method'
require 'delayed/plugin'

require 'delayed-plugins-airbrake/version'

module Delayed::Plugins::Airbrake
  class Plugin < ::Delayed::Plugin
    module Notify
      def error(job, error)
        ::Airbrake.notify_or_ignore(
          :error_class   => error.class.name,
          :error_message => "#{error.class.name}: #{error.message}",
          :parameters    => {
            :id => job.id,
            :queue => job.queue,
            :handler => job.handler,
            :payload_object => job.payload_object.object rescue "",
            :payload_method => job.payload_object.method_name rescue "",
            :payload_args => job.payload_object.args rescue [],
            :last_error => job.last_error,
            :locked_by => job.locked_by,
            :failed_at => job.failed_at,
            :created_at => job.created_at
            }
        )
        super if defined?(super)
      end
    end

    callbacks do |lifecycle|
      lifecycle.before(:invoke_job) do |job|
        payload = job.payload_object
        payload = payload.object if payload.is_a? Delayed::PerformableMethod
        payload.extend Notify
      end
    end
  end

  # This can be used to test that the plugin is working
  class Bomb
    def self.blow_up
      raise 'Test from Delayed::Plugins::Airbrake::Bomb'
    end
  end
end