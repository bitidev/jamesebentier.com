# frozen_string_literal: true

# Regenerates the site-wide branded OG default image (#1189). See lib/og_image/generator.rb
# for the render itself and provenance notes -- this task is its only intended caller.
namespace :og do
  desc "Regenerate public/og-default.png (1200x630 branded OG default image)"
  task image: :environment do
    output_path = OgImage::Generator.call
    puts "Wrote #{output_path} (#{File.size(output_path)} bytes)"
  end
end
