# frozen_string_literal: true

module Favicon
  # Renders the site's `>` terminal-prompt mark (2026 terminal-identity redesign, epic
  # #1179 / #1235 design doc) to every browser/app icon size and writes them to
  # `public/`. Invoked exclusively by `rake favicon:generate` (lib/tasks/favicon.rake)
  # -- never hand-edit the committed public/favicon.ico, public/favicon-*.png,
  # public/apple-touch-icon*.png, or public/logo*.png: change this generator and
  # re-run the task, exactly like public/og-default.png (lib/og_image/generator.rb).
  #
  # Renders a self-contained HTML/SVG document (no external fonts/images/network) with
  # headless Chrome via Ferrum, already a dependency (Cuprite's driver, see
  # spec/support/capybara.rb), so no new gem is needed for rasterization. The
  # multi-size favicon.ico is then assembled from the rendered 16/32/48 PNGs with
  # ImageMagick via mini_magick -- see the design doc for why that stays a
  # build-time-only dependency (Dockerfile build stage + local install), never CI/prod.
  class Generator
    # Defined once in a 100x100 SVG viewBox and scaled via <svg> width/height below,
    # so the same relative geometry stays crisp at every target resolution.
    CANVAS = 100

    # Matches the OG card's palette exactly (lib/og_image/generator.rb).
    BASE_COLOR = "#0d1117"
    CHEVRON_COLOR = "#fab73a"

    # The `>` chevron as an SVG <path>, NOT the "❯" Unicode glyph the OG card uses --
    # that glyph's font coverage varies across machines (tofu on Liberation Mono at
    # favicon sizes), unacceptable at 16px. A path renders deterministically anywhere.
    # Round caps/joins on a 3-point stroke give the OG card's chevron shape; its
    # bounding box (with the caps'/joins' bulge) is ~36% wide x 58% tall of the
    # canvas, centered, leaving padding for iOS rounding and the PWA maskable zone.
    CHEVRON_PATH = "M 38 27 L 62 50 L 38 73"
    CHEVRON_STROKE_WIDTH = 12

    # Pixel size => public/ filenames rendered at that size. 48 has no standalone
    # public file -- it exists only to be combined into favicon.ico below.
    PNG_TARGETS = {
      16 => %w[favicon-16x16.png],
      32 => %w[favicon-32x32.png],
      48 => [],
      180 => %w[apple-touch-icon.png apple-touch-icon-precomposed.png],
      192 => %w[logo192.png],
      512 => %w[logo512.png logo.png]
    }.freeze

    ICO_SIZES = [16, 32, 48].freeze

    def self.call(public_path: Rails.public_path)
      new(public_path).call
    end

    def initialize(public_path)
      @public_path = Pathname.new(public_path)
    end

    def call
      require "ferrum"
      require "tmpdir"

      Dir.mktmpdir("favicon") do |tmp_dir|
        rendered = render_all_sizes(tmp_dir)
        write_pngs(rendered)
        assemble_ico(rendered)
      end

      written_paths
    end

    private

    def render_all_sizes(tmp_dir)
      browser = launch_browser
      PNG_TARGETS.each_key.with_object({}) do |size, sizes|
        sizes[size] = render_png(browser, size, tmp_dir)
      end
    ensure
      browser&.quit
    end

    def launch_browser
      Ferrum::Browser.new(
        headless: true,
        window_size: [CANVAS, CANVAS],
        browser_options: { "no-sandbox" => nil, "disable-gpu" => nil }
      )
    end

    # See lib/og_image/generator.rb -- `window_size:` sets the OS window, not the CSS
    # viewport, so resize explicitly to capture exactly size x size.
    def render_png(browser, size, tmp_dir)
      html_path = File.join(tmp_dir, "favicon-#{size}.html")
      File.write(html_path, svg_html(size))
      browser.resize(width: size, height: size)
      browser.goto("file://#{html_path}")

      png_path = File.join(tmp_dir, "favicon-#{size}.png")
      browser.screenshot(path: png_path, encoding: :binary)
      png_path
    end

    def svg_html(size)
      <<~HTML
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="utf-8">
            <style>
              * { margin: 0; padding: 0; }
              html, body { width: #{size}px; height: #{size}px; overflow: hidden; }
            </style>
          </head>
          <body>
            <svg xmlns="http://www.w3.org/2000/svg" width="#{size}" height="#{size}"
                 viewBox="0 0 #{CANVAS} #{CANVAS}">
              <rect width="#{CANVAS}" height="#{CANVAS}" fill="#{BASE_COLOR}" />
              <path d="#{CHEVRON_PATH}" fill="none" stroke="#{CHEVRON_COLOR}"
                    stroke-width="#{CHEVRON_STROKE_WIDTH}"
                    stroke-linecap="round" stroke-linejoin="round" />
            </svg>
          </body>
        </html>
      HTML
    end

    def write_pngs(rendered)
      PNG_TARGETS.each do |size, filenames|
        filenames.each { |filename| FileUtils.cp(rendered.fetch(size), @public_path.join(filename)) }
      end
    end

    def assemble_ico(rendered)
      png_paths = ICO_SIZES.map { |size| rendered.fetch(size) }
      IcoAssembler.call(png_paths, @public_path.join("favicon.ico"))
    end

    def written_paths
      paths = PNG_TARGETS.values.flatten.map { |filename| @public_path.join(filename) }
      paths << @public_path.join("favicon.ico")
    end
  end
end
