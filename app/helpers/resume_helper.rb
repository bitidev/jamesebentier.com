# frozen_string_literal: true

module ResumeHelper # rubocop:disable Style/Documentation
  def resume_data
    @resume_data ||= YAML.safe_load_file(Rails.root.join("resume/resume.yml"), symbolize_names: true)
  end
end
