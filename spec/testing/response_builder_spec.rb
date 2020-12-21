RSpec.describe RedCAP::Testing::ResponseBuilder do

  subject { RedCAP::Testing::ResponseBuilder.new }

  before(:each) do
    subject.repeating = false
    subject.events = false
    subject.example = {
      :record_id => "XXX-001",
      :first_name => "Jean Luc",
      :last_name => "Skywalker",
    }
  end

  it "can override the record id" do
    expect(subject.record).to include("record_id" => "XXX-001")
    subject.record_id = "XXX-002"
    expect(subject.record).to include("record_id" => "XXX-002")
  end

  it "includes the data access group if it is set" do
    subject.data_access_group = "control_group"
    expect(subject.record).to include("redcap_data_access_group" => "control_group")
  end

  context "when no repeatable instruments are defined" do

    it "generates a record with only basic fields" do

      expect(subject.record).to match({
        "record_id" => "XXX-001",
        "first_name" => "Jean Luc",
        "last_name" => "Skywalker"
      })
    end

  end

  context "when some instruments repeat" do

    before(:each) do
      subject.example = {
        :record_id => "XXX-001",
        :first_name => "Jean Luc",
        :last_name => "Skywalker",
        :value => "50"
      }
      subject.repeating = true
      subject.repeat_instruments = {
        :reading => [:value]
      }

    end

    it "includes the repeating fields" do
      expect(subject.record).to match({
        "record_id" => "XXX-001",
        "redcap_repeat_instrument" => "",
        "redcap_repeat_instance" => "",
        "first_name" => "Jean Luc",
        "last_name" => "Skywalker",
        "value" => ""
      })

    end

    it "can generate repeating records" do
      expect(subject.repeat_record("reading", 2)).to match({
        "record_id" => "XXX-001",
        "redcap_repeat_instrument" => "reading",
        "redcap_repeat_instance" => 2,
        "first_name" => "",
        "last_name" => "",
        "value" => "50",
      })
    end

    it "can auto number with in an instrument" do
      expect(subject.repeat_record("reading", :auto)).to include("redcap_repeat_instance" => 1)
      expect(subject.repeat_record("reading", :auto)).to include("redcap_repeat_instance" => 2)
    end

    it "can override record id" do
      subject.record_id = "XXX-002"
      expect(subject.repeat_record("reading", :auto)).to include("record_id" => "XXX-002")
    end

    it "includes the data access group if it is set" do
      subject.data_access_group = "control_group"
      expect(subject.repeat_record("reading", :auto)).to include("redcap_data_access_group" => "control_group")
    end
  end

  context "when events are defined" do
    before(:each) do
      subject.events = true
    end

    it "includes event name field" do
      expect(subject.record).to match({
        "record_id" => "XXX-001",
        "redcap_event_name" => "baseline_arm_1",
        "first_name" => "Jean Luc",
        "last_name" => "Skywalker"

      })
    end
  end

  context "with both repeating instruments and events" do
    before(:each) do
      subject.events = true
      subject.repeating = true
      subject.repeat_instruments = {
        :reading => [:value]
      }
    end

    it "includes event name in repeating record" do
      expect(subject.repeat_record("reading", :auto)).to include("redcap_event_name" => "baseline_arm_1")
    end

    it "can scope some records to an event" do

      subject.event_name = "follow_up_arm_1"
      expect(subject.repeat_record("reading", :auto)).to include("redcap_event_name" => "follow_up_arm_1")

    end
  end
end
