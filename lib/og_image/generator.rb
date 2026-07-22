# frozen_string_literal: true

module OgImage
  # Renders the site-wide branded Open Graph default image (#1189 design doc, "OG image
  # strategy" open question -- operator chose the static branded default over a
  # per-post generator) and writes it to `public/og-default.png`. Invoked exclusively by
  # `rake og:image` (lib/tasks/og_image.rake) -- that task is the only intended caller,
  # and public/og-default.png should never be hand-edited: change TEMPLATE below and
  # re-run the task instead.
  #
  # Renders a self-contained HTML/CSS "terminal card" (no external fonts/images/network
  # requests -- system monospace stack only, so the render is reproducible on any
  # machine) with headless Chrome via Ferrum, already a project dependency (Capybara/
  # Cuprite's driver, see spec/support/capybara.rb) so this adds no new gem. 1200x630
  # matches the `twitter:card = summary_large_image` / og:image size Facebook and
  # Twitter/X recommend for a large-image card.
  class Generator
    WIDTH = 1200
    HEIGHT = 630

    TEMPLATE = <<~HTML.freeze
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8">
          <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            html, body {
              width: #{WIDTH}px;
              height: #{HEIGHT}px;
              background: #0d1117;
              overflow: hidden;
            }
            body {
              display: flex;
              flex-direction: column;
              justify-content: center;
              padding-left: 96px;
              font-family: "SF Mono", "Menlo", "Consolas", "Liberation Mono", monospace;
              /* Faint repeating grid -- reads as a terminal/CRT texture without any
                 external image asset. */
              background-image:
                linear-gradient(rgba(250, 183, 58, 0.05) 1px, transparent 1px),
                linear-gradient(90deg, rgba(250, 183, 58, 0.05) 1px, transparent 1px);
              background-size: 40px 40px;
            }
            .prompt {
              font-size: 26px;
              color: #8b949e;
              margin-bottom: 28px;
              letter-spacing: 0.02em;
            }
            .prompt .chevron { color: #fab73a; margin-right: 10px; }
            .name {
              font-size: 64px;
              font-weight: 700;
              color: #f0f6fc;
              letter-spacing: -0.01em;
              margin-bottom: 18px;
            }
            .subtitle {
              font-size: 30px;
              color: #fab73a;
            }
            .cursor {
              display: inline-block;
              width: 16px;
              height: 34px;
              background: #fab73a;
              margin-left: 10px;
              vertical-align: middle;
            }
          </style>
        </head>
        <body>
          <p class="prompt"><span class="chevron">&#10095;</span>james@ebentier</p>
          <p class="name">James Ebentier<span class="cursor"></span></p>
          <p class="subtitle">Software Architect &middot; Berlin</p>
        </body>
      </html>
    HTML

    def self.call(output_path: Rails.public_path.join("og-default.png"))
      new(output_path).call
    end

    def initialize(output_path)
      @output_path = output_path
    end

    def call
      require "ferrum"
      require "tempfile"

      file = Tempfile.new(["og-default", ".html"])
      file.write(TEMPLATE)
      file.flush

      screenshot(file.path)

      @output_path
    ensure
      file&.close
      file&.unlink
    end

    private

    def screenshot(html_path)
      browser = Ferrum::Browser.new(
        headless: true,
        window_size: [WIDTH, HEIGHT],
        browser_options: { "no-sandbox" => nil, "disable-gpu" => nil }
      )
      # `window_size:` above sets the OS window (which Chrome pads with its own chrome
      # even headless), not the CSS viewport -- resize explicitly so the captured
      # viewport, and therefore the screenshot, is exactly WIDTHxHEIGHT.
      browser.resize(width: WIDTH, height: HEIGHT)
      browser.goto("file://#{html_path}")
      browser.screenshot(path: @output_path.to_s, encoding: :binary)
    ensure
      browser&.quit
    end
  end
end
