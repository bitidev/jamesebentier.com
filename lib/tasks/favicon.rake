# frozen_string_literal: true

# Regenerates the site's browser/app icon set from the `>` terminal mark (#1235). See
# lib/favicon/generator.rb for the render itself and provenance notes -- this task is
# its only intended caller. Never hand-edit public/favicon.ico, public/favicon-*.png,
# public/apple-touch-icon*.png, or public/logo*.png: change the generator and re-run
# this task instead.
namespace :favicon do
  desc "Regenerate public/favicon.ico + all favicon/app-icon PNGs from the terminal mark"
  task generate: :environment do
    Favicon::Generator.call.each do |path|
      puts "Wrote #{path} (#{File.size(path)} bytes)"
    end
  end
end
