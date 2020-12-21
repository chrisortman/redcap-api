# frozen_string_literal: true

require "active_support/core_ext/hash"

module RedCAP
  module Testing
    class ResponseBuilder
      attr_accessor :example, :repeating, :repeat_instruments, :events, :record_id, :event_name, :data_access_group

      def initialize
        @instance_counts = Hash.new(1)
        @record_id = nil
        @repeat_instruments = {}
      end

      # TODO: I think values are always strings. Should I enforce this somehow?
      def record
        repeat_record("","")
      end

      def repeat_record(instrument, instance)

        instrument = instrument.to_sym
        data = {}

        if @record_id.nil?
          data[:record_id] = self.example[:record_id]
        else
          data[:record_id] = @record_id
        end

        if self.repeating
          data[:redcap_repeat_instrument] = instrument.to_s
          if instance == :auto
            data[:redcap_repeat_instance] = @instance_counts[instrument]
            @instance_counts[instrument] += 1
          else
            data[:redcap_repeat_instance] = instance
          end
        end

        if self.events
          if @event_name.nil?
            data[:redcap_event_name] = "baseline_arm_1"
          else
            data[:redcap_event_name] = @event_name
          end
        end

        unless self.data_access_group.nil?
          data[:redcap_data_access_group] = @data_access_group
        end

        self.example.keys.each do |field|

          # If field is for record id we skip
          # if field belongs to our instrument we copy
          # otherwise we set it to blank
          if field == :record_id
            next
          elsif belongs_to_instrument?(instrument, field)
            data[field] = self.example[field]
          else
            data[field] = ""
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

        # >> field belongs to our instrument if:
        # >>>> if instrument is repeat and  in field list
        # >>>> or
        # >>>> instrument is "" / main and 
        def belongs_to_instrument?(instrument, field)
          if self.repeat_instruments.has_key?(instrument) && self.repeat_instruments[instrument].include?(field)
            true
          elsif instrument.empty? && !self.repeat_instruments.values.flatten.include?(field)
            true
          else
            false
          end
        end
    end
  end
end
