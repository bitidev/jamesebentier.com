# frozen_string_literal: true

require 'rails_helper'

# GET /resume -- terminal-identity redesign (#1226) restyled the existing resume partials
# (app/views/welcome/resume.html.erb + welcome/resume/_*.html.erb) over the real
# resume/resume.yml data (ResumeHelper#resume_data); no request-spec coverage existed for
# this route before this issue. Operator decision #2 (design doc): the handoff's own
# placeholder roles/skills/education are not used -- the page renders the real resume data,
# just restyled, so these specs assert against resume.yml itself rather than hardcoded
# copies of it (never goes stale as resume.yml changes).
RSpec.describe "Resume page" do
  let(:resume_data) { YAML.safe_load_file(Rails.root.join("resume/resume.yml"), symbolize_names: true) }

  it "returns a successful response" do
    get resume_path

    expect(response).to have_http_status(:ok)
  end

  it "renders the real name from resume.yml" do
    get resume_path

    expect(response.body).to include(resume_data[:basics][:name])
  end

  it "renders a real Invoca role/company from resume.yml's work history" do
    get resume_path

    invoca_entry = resume_data[:work].find { |entry| entry[:company] == "Invoca" }

    expect(response.body).to include(invoca_entry[:company], invoca_entry[:position])
  end

  it "renders the real UCSB education entry from resume.yml" do
    get resume_path

    ucsb_entry = resume_data[:education].find { |entry| entry[:institution].include?("Santa Barbara") }

    expect(response.body).to include(ucsb_entry[:institution])
  end

  it "renders a real skill keyword from resume.yml" do
    get resume_path

    expected_keyword = resume_data[:skills].first[:keywords].first

    expect(response.body).to include(expected_keyword)
  end

  it "computes the subtitle's years-of-experience from the earliest work entry's startDate, not a hardcoded number" do
    get resume_path

    earliest_year = resume_data[:work].map { |entry| Date.parse(entry[:startDate]).year }.min
    expected_years = Date.current.year - earliest_year

    expect(response.body).to include("#{expected_years}+ yrs")
  end

  it "does not render the retired 'Fractional' framing anywhere on the page" do
    get resume_path

    expect(response.body).not_to include("Fractional")
  end

  it "does not render 'CTO' anywhere on the page" do
    get resume_path

    expect(response.body).not_to include("CTO")
  end

  it "renders no footer -- interior pages end at the statusline (Home-only footer, #1226)" do
    get resume_path

    expect(response.parsed_body.at_css("footer")).to be_nil
  end

  it "renders the resume statusline path (~/resume)" do
    get resume_path

    statusline = response.parsed_body.at_css("#keyboard-status-line")

    expect(statusline.text).to include("~/resume")
  end
end
