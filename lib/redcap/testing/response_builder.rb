# frozen_string_literal: true

require "active_support/core_ext/hash"

module RedCAP
  module Testing
    class ResponseBuilder
      attr_accessor :example, :repeating, :repeating_example, :events, :record_id, :event_name

      def initialize
        @instance_counts = Hash.new(1)
        @record_id = nil
      end

      # TODO: I think values are always strings. Should I enforce this somehow?
      def record
        data = {}
        if @record_id.nil?
          data[:record_id] = self.example[:record_id]
        else
          data[:record_id] = @record_id
        end

        if self.repeating
          data[:redcap_repeat_instrument] = ""
          data[:redcap_repeat_instance] = ""
        end

        if self.events
          if @event_name.nil?
            data[:redcap_event_name] = "baseline_arm_1"
          else
            data[:redcap_event_name] = @event_name
          end
        end

        self.example.keys.each do |f|
          unless f == :record_id
            data[f] = self.example[f]
          end
        end

        self.repeating_example&.each do |example_instrument, example_data|
          example_data.keys.each { |f| data[f] = "" }
        end

        data.stringify_keys
      end

      def repeat_record(instrument, instance)

        data = {}

        if @record_id.nil?
          data[:record_id] = self.example[:record_id]
        else
          data[:record_id] = @record_id
        end

        data[:redcap_repeat_instrument] = instrument
        if instance == :auto
          data[:redcap_repeat_instance] = @instance_counts[instrument]
          @instance_counts[instrument] += 1
        else
          data[:redcap_repeat_instance] = instance
        end

        if self.events
          if @event_name.nil?
            data[:redcap_event_name] = "baseline_arm_1"
          else
            data[:redcap_event_name] = @event_name
          end
        end

        self.example.keys.each do |f|
          unless f == :record_id
            data[f] = ""
          end
        end

        self.repeating_example.each do |example_instrument, example_data|
          if instrument.to_sym == example_instrument.to_sym
            example_data.each { |k,v| data[k] = v }
          else
            example_data.keys.each { |f| data[f] = "" }
          end
        end
        data.stringify_keys
      end

      private
        def repeating_keys
          built_ins = {
            :redcap_repeat_instrument => "",
            :redcap_repeat_instance => ""
          }

        end

        def event_keys
          {:redcap_event_name => "baseline_arm_1"}
        end

        def add_repeating_fields(hash)
          hash.merge!(repeating_keys)
          if self.repeating_example
            self.repeating_example.each do |instrument, example|
              example.keys.each do |f|
                hash[f] = ""
              end
            end
          end
          hash
        end
    end
  end
end
