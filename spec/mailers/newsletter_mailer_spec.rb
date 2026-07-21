# frozen_string_literal: true

require "rails_helper"

RSpec.describe NewsletterMailer do
  describe "#confirmation" do
    before { ActionMailer::Base.default_url_options[:host] = "www.example.com" }

    let(:subscriber) { build(:subscriber, :pending, email: "reader@example.com") }
    let(:mail) { described_class.confirmation(subscriber) }

    it "addresses the email to the subscriber" do
      expect(mail.to).to eq(["reader@example.com"])
    end

    it "sends from the configured from address" do
      expect(mail.from).to eq(["james@jamesebentier.com"])
    end

    it "has the newsletter confirmation subject" do
      expect(mail.subject).to eq("Confirm your subscription to James Ebentier's newsletter")
    end

    it "includes the confirm URL in the HTML body" do
      expect(mail.html_part.body.to_s).to include("/newsletter/confirm?token=#{subscriber.confirmation_token}")
    end

    it "includes the confirm URL in the plain text body" do
      expect(mail.text_part.body.to_s).to include("/newsletter/confirm?token=#{subscriber.confirmation_token}")
    end

    it "includes an unsubscribe URL in the HTML body" do
      expect(mail.html_part.body.to_s).to include("/newsletter/unsubscribe?token=#{subscriber.confirmation_token}")
    end

    it "delivers to ActionMailer::Base.deliveries when delivered now" do
      expect { mail.deliver_now }.to change(ActionMailer::Base.deliveries, :size).by(1)
    end
  end
end
