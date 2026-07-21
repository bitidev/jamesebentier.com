# frozen_string_literal: true

require "rails_helper"

RSpec.describe Subscriber do
  describe "schema" do
    it { is_expected.to have_db_column(:id).of_type(:uuid) }
    it { is_expected.to have_db_column(:email).of_type(:string).with_options(limit: 255, null: false) }
    it { is_expected.to have_db_column(:confirmation_token).of_type(:string).with_options(limit: 255, null: true) }
    it { is_expected.to have_db_column(:confirmed_at).of_type(:datetime).with_options(null: true) }
    it { is_expected.to have_db_column(:unsubscribed_at).of_type(:datetime).with_options(null: true) }
    it { is_expected.to have_db_column(:consent_at).of_type(:datetime).with_options(null: true) }
    it { is_expected.to have_db_column(:consent_source).of_type(:string).with_options(limit: 50, null: true) }
    it { is_expected.to have_db_column(:ip_hash).of_type(:string).with_options(limit: 64, null: true) }
  end

  describe "validations" do
    before { create(:subscriber, :confirmed) }

    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to allow_value("user@example.com").for(:email) }
    it { is_expected.to allow_value("User+Tag@Sub.Domain.co.uk").for(:email) }
    it { is_expected.not_to allow_value("not-an-email").for(:email) }
    it { is_expected.not_to allow_value("missing@tld").for(:email) }
    it { is_expected.not_to allow_value("@nodomain.com").for(:email) }
    it { is_expected.not_to allow_value("").for(:email) }
  end

  describe "email normalization" do
    it "downcases the email before validation" do
      subscriber = build(:subscriber, email: "User@EXAMPLE.COM")
      subscriber.valid?

      expect(subscriber.email).to eq("user@example.com")
    end

    it "strips surrounding whitespace from the email before validation" do
      subscriber = build(:subscriber, email: "  user@example.com  ")
      subscriber.valid?

      expect(subscriber.email).to eq("user@example.com")
    end
  end

  describe "#confirmed?" do
    it "returns true when confirmed_at is set" do
      subscriber = build(:subscriber, confirmed_at: Time.current)

      expect(subscriber.confirmed?).to be true
    end

    it "returns false when confirmed_at is nil" do
      subscriber = build(:subscriber, confirmed_at: nil)

      expect(subscriber.confirmed?).to be false
    end
  end

  describe "#unsubscribed?" do
    it "returns true when unsubscribed_at is set" do
      subscriber = build(:subscriber, unsubscribed_at: Time.current)

      expect(subscriber.unsubscribed?).to be true
    end

    it "returns false when unsubscribed_at is nil" do
      subscriber = build(:subscriber, unsubscribed_at: nil)

      expect(subscriber.unsubscribed?).to be false
    end
  end

  describe "#pending?" do
    it "returns true when never confirmed" do
      subscriber = build(:subscriber, confirmed_at: nil, unsubscribed_at: nil)

      expect(subscriber.pending?).to be true
    end

    it "returns true when unsubscribed (confirmed but then opted out)" do
      subscriber = build(:subscriber, confirmed_at: 1.day.ago, unsubscribed_at: Time.current)

      expect(subscriber.pending?).to be true
    end

    it "returns false when confirmed and not unsubscribed" do
      subscriber = build(:subscriber, confirmed_at: Time.current, unsubscribed_at: nil)

      expect(subscriber.pending?).to be false
    end
  end

  describe "#generate_confirmation_token!" do
    it "sets a new urlsafe_base64 token on the persisted record" do
      subscriber = create(:subscriber)

      expect { subscriber.generate_confirmation_token! }.to change { subscriber.reload.confirmation_token }.from(nil)
    end

    it "generates a token of expected length (32 bytes urlsafe_base64 → 43 chars)" do
      subscriber = create(:subscriber)
      subscriber.generate_confirmation_token!

      expect(subscriber.confirmation_token.length).to be >= 40
    end
  end

  describe ".ip_hash_for" do
    it "returns nil for a blank IP" do
      expect(described_class.ip_hash_for(nil)).to be_nil
    end

    it "returns nil for an empty string IP" do
      expect(described_class.ip_hash_for("")).to be_nil
    end

    it "returns a 64-character hex digest for a valid IP" do
      result = described_class.ip_hash_for("127.0.0.1")

      expect(result).to match(/\A[0-9a-f]{64}\z/)
    end

    it "does not include the raw IP address in the returned hash" do
      result = described_class.ip_hash_for("192.168.1.1")

      expect(result).not_to include("192.168.1.1")
    end

    it "returns the same hash for the same IP (deterministic)" do
      first  = described_class.ip_hash_for("10.0.0.1")
      second = described_class.ip_hash_for("10.0.0.1")

      expect(first).to eq(second)
    end

    it "returns different hashes for different IPs" do
      expect(described_class.ip_hash_for("1.2.3.4")).not_to eq(described_class.ip_hash_for("4.3.2.1"))
    end
  end
end
