# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Welcomes" do
  describe "GET /" do
    it "returns a successful response" do
      get root_path

      expect(response).to have_http_status(:ok)
    end

    it "retires all six rainbow hero utilities in favor of the single amber accent (R10)" do
      get root_path

      expect(response.body).not_to match(/text-(green-500|purple-500|orange-500|pink-500|yellow-600|fuchsia-500)/)
    end

    it "carries the single amber accent token on the emphasized name (R10)" do
      get root_path

      expect(response.parsed_body.at_css("strong.text-primary")).to be_present
    end
  end

  describe "the theme picker (R4/R6)" do
    it "lists exactly the six approved themes, in R4's documented order" do
      get root_path
      option_values = response.parsed_body.css("#theme-picker-select option").pluck("value")

      expect(option_values).to eq(%w[light dark dracula nord gruvbox catppuccin])
    end
  end
end
