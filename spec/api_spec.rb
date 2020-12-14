require 'awesome_print'

RSpec.describe RedCAP::API do

  subject {
    api = RedCAP::API.new(
      url: ENV['REDCAP_TEST_URL'] || 'https://redcap.example.com',
      token: ENV['REDCAP_API_TOKEN']
    )
  }

  let(:test_record) do

    { :email => 'chris@example.com' }

  end

  it "integrates" do

    # Reset the project, clear out any existing records
    record_ids = subject.export_records()
    count = subject.delete_records(record_ids.map{ |x| x.fetch("record_id")}) unless record_ids.empty?

    # Insert a new record and get back the record ID
    new_record_id = subject.import_record(test_record)
    expect(new_record_id).to match(/\d+/)

    records = subject.export_records(new_record_id, fields: %w(record_id email))
    expect(records).to match([
      a_hash_including('record_id' => new_record_id, 'email' => 'chris@example.com')
    ])

    # Import a couple of repeating instruments
    count = subject.import_repeating(
      new_record_id,
      [
        {'document_type' => 'DocumentA'},
        {'document_type' => 'DocumentB'},
      ],
      'medicalrelease'
    )

    # It's only 1 because it's a record count, NOT
    # a count of how many instruments we've imported
    expect(count).to eq 1

    # Did we really make them import correctly?
    records = subject.export_records(
      new_record_id,
      fields: %w(record_id document_type),
      forms: 'medicalrelease'
    )

    expect(records).to match([
      a_hash_including( {
        'record_id' => new_record_id,
        'redcap_repeat_instrument' => '',
        'redcap_repeat_instance' => '',
        'document_type' => ''
      } ),
      a_hash_including( {
        'record_id' => new_record_id,
        'redcap_repeat_instrument' => 'medicalrelease',
        'redcap_repeat_instance' => 1,
        'document_type' => 'DocumentA'
      } ),
      a_hash_including( {
        'record_id' => new_record_id,
        'redcap_repeat_instrument' => 'medicalrelease',
        'redcap_repeat_instance' => 2,
        'document_type' => 'DocumentB'
      } ),

    ])

    # Update one of these repeating records
    subject.import_repeating(
      new_record_id,
      [
        {:redcap_repeat_instance => 2, 'document_type' => 'ChangedRepeatingX'}
      ],
      'medicalrelease'
    )

    records = subject.export_records(
      new_record_id,
      fields: %w(record_id document_type),
      forms: 'medicalrelease'
    )

    expect(records).to match([
      a_hash_including( {
        'record_id' => new_record_id,
        'redcap_repeat_instrument' => '',
        'redcap_repeat_instance' => '',
        'document_type' => ''
      } ),
      a_hash_including( {
        'record_id' => new_record_id,
        'redcap_repeat_instrument' => 'medicalrelease',
        'redcap_repeat_instance' => 1,
        'document_type' => 'DocumentA'
      } ),
      a_hash_including( {
        'record_id' => new_record_id,
        'redcap_repeat_instrument' => 'medicalrelease',
        'redcap_repeat_instance' => 2,
        'document_type' => 'ChangedRepeatingX'
      } ),

    ])
    # Add a file to one of my repeat instances
    File.open(fixture_file_path('official_document.pdf')) do |file_io|
      result = subject.import_file(
        new_record_id,
        'signed_document',
        event: 'baseline',
        repeat_instance: 2,
        file: file_io,
        file_name: 'Document1.pdf',
        content_type: 'application/pdf'
      )
    end
  end

  def fixture_file_path(path)
    full_path = [File.dirname(__FILE__), 'fixtures', *path].join('/')
    full_path
  end
end
