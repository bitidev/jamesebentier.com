# frozen_string_literal: true

module Favicon
  # Assembles a multi-size favicon.ico from single-size PNGs via ImageMagick (the
  # `mini_magick` gem) -- the one step only a real image tool does cleanly. Ferrum
  # (lib/favicon/generator.rb, its sole caller) renders the source PNGs; this class
  # just shells out to `magick` to combine them into the ICO container format.
  class IcoAssembler
    def self.call(png_paths, ico_path)
      require "mini_magick"

      MiniMagick.convert do |convert|
        convert.merge!(png_paths.map(&:to_s))
        convert << ico_path.to_s
      end

      ico_path
    end
  end
end
