require 'active_support/json'
require 'active_support/core_ext'
require 'faraday'

module Redcap
  class API

    INCOMPLETE_CODE = 0
    UNVERIFIED_CODE = 1
    COMPLETE_CODE   = 2

    def initialize(url:, token:)
      @redcap_api_token = token
      @api_url = url
    end

    def redcap_api_token
      @redcap_api_token
    end

    def import_record(record)

      # Only setting the record ID in this case
      # because the only one it applies to at the moment
      # is the ConsentRecord
      if record.respond_to?(:record_id) && record.record_id.nil?
        next_id = generate_next_record_id()
        record.record_id = next_id
      elsif record.is_a?(Hash) && !record.has_key?(:record_id)
        next_id = generate_next_record_id()
        record = record.dup
        record[:record_id] = next_id
      end

      # This way I can just pass a hash if I want
      # OR I can provide a method to do the serialization
      if record.respond_to?(:redcap_hash)
        data = [record.redcap_hash].to_json
      else
        data = [record].to_json
      end

      puts "Import Record Data: #{data}"

      options = {
        :token => redcap_api_token,
        :content => 'record',
        :format => 'json',
        :type => 'flat',
        :overwriteBehavior => 'normal',
        :forceAutoNumber => 'false',
        :data => data,
        :returnContent => 'ids',
        :returnFormat => 'json'
      }

      resp = redcap_post(body: options)
      raise "Error creating record\n#{format_response_error(resp)}" unless resp.success?

      # Because this API is implemented in singular
      # fashion, it can only handle 1 record import
      # and so only return 1 ID. 
      # That's why we assume a single element array
      # and extract it for the caller
      JSON.parse(resp.body).first
    end

    def format_response_error(resp)
      resp.body
    end

    def export_records(records = nil, fields: ["record_id"], forms: [])

      if records.kind_of?(Enumerable) || records.nil?
        return_single = false
      else
        return_single = true
      end

      if !records.nil?
        records = Array(records)
      end

      #TODO: How do i get record_id in here
      options = {
        :token => redcap_api_token,
        :content => 'record',
        :format => 'json',
        :type => 'flat',
        :rawOrLabel => 'raw',
        :rawOrLabelHeaders => 'raw',
        :exportCheckboxLabel => 'false',
        :exportSurveyFields => 'false',
        :exportDataAccessGroups => 'false',
        :returnFormat => 'json'
      }

      records.each_with_index do |record,i|
        options["records[#{i}]"] = record.to_s
      end unless records.nil? || records.empty?

      fields.each_with_index do |field,i|
        options["fields[#{i}]"] = field.to_s
      end unless fields.nil? || fields.empty?

      forms.each_with_index do |form,i|
        options["forms[#{i}]"] = form.to_s
      end unless forms.nil? || forms.empty?

      resp = redcap_post( body: options)
      raise "Error exporting records\n#{format_response_error(resp)}" unless resp.success?
      parsed = JSON.parse(resp.body)

      if return_single
        parsed.first
      else
        parsed
      end
    end

    def redcap_post(body:)

      # Lot going on here.
      # URI.join is a bit particular. 
      # We have to surround redcap with / because the first
      # one makes it so we'll replace any path info on api_url
      # and the second allows api to follow
      # Our URL must end with a slash or redcap errors
      uri = URI.join(@api_url, "/redcap/","api/").to_s
      Faraday.post(uri, body)
    end

    def generate_next_record_id?(record)

      if record.respond_to?(:record_id) && record.record_id.nil?
        true
      elsif record.is_a?(Hash) && !record.has_key?(:record_id)
        true
      end
    end

    def generate_next_record_id
      start_record_no = 0
      existing_records_ids = self.export_records(fields: ['record_id']).map{ |r| r["record_id"] }

      unless existing_records_ids.empty?
        if redcap_record_prefix.nil?
          start_record_no = existing_records_ids.map{ |r| r.to_i }.max
        else
          start_record_no = existing_records_ids.map{ |r| r.gsub(/^#{redcap_record_prefix}-/,'').to_i }.max
        end
      end
      ## Really subjective here, this doesn't generalize well
      #  In this particular project I don't think we're inserting records anyway ...?

      loop do
        start_record_no += 1
        if redcap_record_prefix.nil?
          if pad_new_id?
            new_record_id = "#{start_record_no.to_s.rjust(4,"0")}"
          else
            new_record_id = start_record_no.to_s
          end
        else
          new_record_id = "#{redcap_record_prefix}-#{start_record_no.to_s.rjust(4,"0")}"
        end
        return new_record_id unless existing_records_ids.include?(new_record_id)
      end

    end

    def redcap_record_prefix
      nil
    end

    def pad_new_id?
      false
    end
  end

end
