require "rails_helper"

RSpec.describe EventMailer, type: :mailer do
  describe "event_approved" do
    let(:mail) { EventMailer.event_approved }

    it "renders the headers" do
      expect(mail.subject).to eq("Event approved")
      expect(mail.to).to eq(["to@example.org"])
      expect(mail.from).to eq(["from@example.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end

  describe "event_rejected" do
    let(:mail) { EventMailer.event_rejected }

    it "renders the headers" do
      expect(mail.subject).to eq("Event rejected")
      expect(mail.to).to eq(["to@example.org"])
      expect(mail.from).to eq(["from@example.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end

end
