# frozen_string_literal: true

require "rails_helper"

RSpec.describe "First-party page view recording" do
  it "records a page view on a normal GET request" do
    expect { get root_path }.to change(PageView, :count).by(1)
  end

  it "does not record health-check requests" do
    expect { get rails_health_check_path }.not_to change(PageView, :count)
  end
end
