# frozen_string_literal: true

require "rails_helper"

RSpec.describe Analytics::PageViewRecorder do
  def blank_headers
    instance_double(ActionDispatch::Http::Headers, '[]': nil)
  end

  def html_get_request(**overrides)
    defaults = { get?: true, xhr?: false, path: "/writing", referer: nil, params: {}, user_agent: "Mozilla/5.0", headers: blank_headers }
    instance_double(ActionDispatch::Request, **defaults, **overrides)
  end

  describe ".record_from_request!" do
    it "creates a page view for a normal HTML GET" do
      request = html_get_request(referer: "https://google.com/search?q=foo")

      expect { described_class.record_from_request!(request) }.to change(PageView, :count).by(1)
    end

    it "skips Turbo Drive visits so the client beacon records them instead" do
      headers = instance_double(ActionDispatch::Http::Headers)
      allow(headers).to receive(:[]).with("Turbo-Frame").and_return(nil)
      allow(headers).to receive(:[]).with("Turbo-Visit").and_return("true")
      request = html_get_request(headers: headers)

      expect { described_class.record_from_request!(request) }.not_to change(PageView, :count)
    end

    it "captures UTM params from the request" do
      params = { utm_source: "newsletter", utm_medium: "email", utm_campaign: "launch" }
      request = html_get_request(path: "/", params: params)

      described_class.record_from_request!(request)

      expect(PageView.last.utm_source).to eq("newsletter")
    end
  end

  describe ".record_beacon!" do
    it "creates a page view from the Turbo beacon payload" do
      expect do
        described_class.record_beacon!(path: "/projects", referrer: "https://jamesebentier.com/", user_agent: "Mozilla/5.0")
      end.to change(PageView, :count).by(1)
    end
  end
end
