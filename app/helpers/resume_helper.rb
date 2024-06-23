# frozen_string_literal: true

module ResumeHelper # rubocop:disable Style/Documentation
  def resume_data
    @resume_data ||= YAML.safe_load_file(Rails.root.join("resume/resume.yml"), symbolize_names: true)
  end

  def style_for_level(level) # rubocop:disable Metrics/MethodLength
    case level.downcase
    when 'master', 'native-speaker'
      'after:bg-[#59C596] after:w-full'
    when 'advanced'
      'after:bg-[#5CB85C] after:w-3/4'
    when 'intermediate'
      'after:bg-[#ffdf1f] after:w-1/2'
    when 'beginner'
      'after:bg-black after:w-1/4'
    else
      'after:bg-[#9e9e9e]'
    end
  end
end
