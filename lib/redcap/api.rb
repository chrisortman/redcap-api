require_relative '../redcap'

require 'active_support/json'
require 'active_support/core_ext'
require 'faraday'
require 'logger'
module RedCAP
  class API

    INCOMPLETE_CODE = 0
    UNVERIFIED_CODE = 1
    COMPLETE_CODE   = 2

    def initialize(url:, token:)
      @redcap_api_token = token
      @api_url = url
      @logger = ::Logger.new(STDOUT)
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

    def import_repeating(record_id, records, instrument)
      raise "Instrument names should be lower case: #{instrument}" if instrument =~ /[A-Z]+/
      existing = export_records([record_id], fields: ["record_id"], forms: Array(instrument))

      instance_num = existing.select{ |r|
        r["redcap_repeat_instrument"] == instrument
      }.map{ |r|
        r["redcap_repeat_instance"]
      }.max || 0

      records = Array(records)
      data = Array(records).map do |r|


        if r.is_a?(Hash)
          r.extend HashRecordAccessors
        end
        r.record_id = record_id
        r.instrument = instrument

        # Allows updating existing or creating new
        if r.instance.nil?
          instance_num += 1
          r.instance = instance_num
        end

        r.redcap_hash
      end

      options = {
        :token => redcap_api_token,
        :content => 'record',
        :format => 'json',
        :type => 'flat',
        :overwriteBehavior => 'normal',
        :forceAutoNumber => 'false',
        :data => data.to_json,
        :returnContent => 'count',
        :returnFormat => 'json'
      }

      resp = redcap_post('/', body: options)
      raise "Error importing repeating  record\n#{format_response_error(resp)}" unless resp.success?

      # Because this API is implemented in singular
      # fashion, it can only handle 1 record import
      # and so only return 1 ID.
      # That's why we assume a single element array
      # and extract it for the caller
      JSON.parse(resp.body)["count"].to_i # I suspect this count value is not accurate
    end

    def raw_import(data_as_json, options)
      merged_options = {
        :token => redcap_api_token,
        :content => 'record',
        :format => 'json',
        :type => 'flat',
        :overwriteBehavior => 'normal',
        :forceAutoNumber => 'false',
        :data => data_as_json,
        :returnContent => 'count',
        :returnFormat => 'json'
      }.merge(options)

      resp = redcap_post('/', body: merged_options)
      raise "Error importing repeating  record\n#{format_response_error(resp)}" unless resp.success?

      # Because this API is implemented in singular
      # fashion, it can only handle 1 record import
      # and so only return 1 ID.
      # That's why we assume a single element array
      # and extract it for the caller
      JSON.parse(resp.body)["count"].to_i # I suspect this count value is not accurate
    end

    def import_file(record_id, field_name, file:, file_name: nil, content_type: nil, event: nil, repeat_instance: nil)

      file = Faraday::FilePart.new(file, content_type, file_name)

      options = {
        :token => redcap_api_token,
        :content => 'file',
        :action => 'import',
        :record => record_id,
        :field => field_name,
        :file => file,
        :event => '',
        :returnFormat => 'json'
      }

      options[:event] = event unless event.nil?
      options[:repeat_instance] = repeat_instance unless repeat_instance.nil?

      resp = redcap_post('/', body: options)


      raise "Error importing file\n#{format_response_error(resp)}" unless resp.success?
      puts resp.body
      #returning something useful because otherwise respons is empty / nil
      true
    end
    def format_response_error(resp)
      resp.body
    end

    def export_records(records = nil, fields: ["record_id"], forms: [], options: {})

      if !records.nil?
        records = Array(records)
      end

      if !forms.kind_of?(Enumerable) && forms.present?
        forms = Array(forms)
      end

      merged_options = {
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
      }.merge(options)

      records.each_with_index do |record,i|
        merged_options["records[#{i}]"] = record.to_s
      end unless records.nil? || records.empty?

      fields.each_with_index do |field,i|
        merged_options["fields[#{i}]"] = field.to_s
      end unless fields.nil? || fields.empty?

      forms.each_with_index do |form,i|
        merged_options["forms[#{i}]"] = form.to_s
      end unless forms.nil? || forms.empty?

      resp = redcap_post( body: merged_options)
      raise "Error exporting records\n#{format_response_error(resp)}" unless resp.success?
      parsed = JSON.parse(resp.body)

      parsed
    end

    def delete_records(record_ids)
      raise "Must give record ids" if record_ids.nil?

      record_ids = Array(record_ids)

      options = {
        :token => redcap_api_token,
        :content => 'record',
        :action => 'delete',
        :records => record_ids
      }

      resp = redcap_post(body: options)
      raise "Error deleting records\n#{format_response_error(resp)}" unless resp.success?
      count = resp.body.to_i
      count
    end

    def redcap_post(path="/", body:)

      conn = Faraday.new(url: @api_url) do |conn|
        conn.response :logger, nil, { headers: true, bodies: true }

        # POST/PUT params encoders:
        conn.request :multipart
        conn.request :url_encoded

        # Last middleware must be the adapter:
        conn.adapter :net_http
      end
      conn.post("/redcap/api/", body)
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
