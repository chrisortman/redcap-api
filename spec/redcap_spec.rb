RSpec.describe Redcap do
  it "has a version number" do
    expect(Redcap::VERSION).not_to be nil
  end

  it "imports and exports a new record" do
    api = Redcap::API.new(
      url: 'https://redcap-test.icts.uiowa.edu',
      token: ENV['REDCAP_API_TOKEN']
    )

    test_record = {
      :email => 'chris@example.com'
    }

    new_record_id = api.import_record(test_record)
    expect(new_record_id).to match(/\d+/)

    exported_record = api.export_records(new_record_id, fields: %w(record_id email))
    expect(exported_record).to include('record_id' => new_record_id, 'email' => 'chris@example.com')
  end
end
