# frozen_string_literal: true

require "erb"

module Blog
  class Renderer < Redcarpet::Render::HTML # rubocop:disable Style/Documentation
    # Terminal-identity redesign (#1226): article headings render in the site's mono chrome
    # font at the design doc's literal type scale, matching every other heading/label/prompt
    # on the redesigned pages. The rendered element is demoted one level below the markdown
    # source (H1 is rendered by the view itself, writing/show.html.erb, not by markdown
    # content -- so a body "#" becomes an <h2>, "##" an <h3>, etc), but the CSS class is
    # keyed on the ORIGINAL markdown header_level so the type scale still lines up with the
    # design doc's "article H2/H3/..." sizes regardless of the element demotion.
    HEADER_LEVEL_CLASSES = {
      1 => 'font-mono text-[36px] font-bold mb-4',
      2 => 'font-mono text-[24px] font-bold mt-8 mb-4',
      3 => 'font-mono text-[19px] font-bold mt-6 mb-3',
      4 => 'font-mono text-lg font-semibold mt-4',
    }.freeze

    def header(text, header_level)
      "<h#{header_level + 1} class='#{HEADER_LEVEL_CLASSES[header_level]}'>#{text}</h#{header_level + 1}>"
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

    # Inline "code chip" styling (design doc's Post-detail section) -- DaisyUI
    # base-200/base-300 tokens only, no hardcoded hex. Unlike header/paragraph/block_quote
    # (which receive already-rendered inline HTML from Redcarpet and must stay raw), `code`
    # here is the raw span between backticks and has NOT been escaped upstream, so it must
    # be escaped here -- otherwise a post body containing backtick-wrapped HTML/script would
    # render (rather than display) it once render_markdown marks the output html_safe.
    def codespan(code)
      "<code class='bg-base-200 border border-base-300 rounded px-1.5 py-0.5 text-[0.9em]'>#{ERB::Util.html_escape(code)}</code>"
    end

    # Aside/blockquote styling (design doc's Post-detail section): a left hairline
    # rather than the browser default indent-and-italicize.
    def block_quote(quote)
      "<blockquote class='border-l-2 border-base-300 pl-4 my-4 text-base-content/80'>#{quote}</blockquote>"
    end
  end
end
