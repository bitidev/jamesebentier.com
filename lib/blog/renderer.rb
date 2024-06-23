# frozen_string_literal: true

module Blog
  class Renderer < Redcarpet::Render::HTML # rubocop:disable Style/Documentation
    HEADER_LEVEL_CLASSES = {
      1 => 'text-3xl font-bold mb-4',
      2 => 'text-2xl font-semibold mt-6',
      3 => 'text-xl font-semibold mt-4',
      4 => 'text-lg font-semibold mt-4',
    }.freeze

    def header(text, header_level)
      "<h#{header_level + 1} class='#{HEADER_LEVEL_CLASSES[header_level + 1]}'>#{text}</h#{header_level + 1}>"
    end

    def paragraph(text)
      "<p class='my-2'>#{text}</p>"
    end

    def list(contents, list_type)
      if list_type == :unordered
        "<ul class='list-disc pl-5 mt-2'>#{contents}</ul>"
      else
        "<ol class='list-decimal list-inside mb-4'>#{contents}</ol>"
      end
    end
  end
end
