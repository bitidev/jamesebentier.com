# frozen_string_literal: true

require 'rails_helper'

# WCAG AA (4.5:1) contrast is a hard acceptance-criteria gate for every bundled theme's
# base-content-on-base-100 and primary-content-on-primary pair -- R2/R4: "Hard gate, all six
# bundled themes ... This is checked as part of Acceptance Criteria, not left to a future
# pass." The Acceptance Criteria list itself only says "spot-checked with a contrast
# calculator per theme before merge," which is a manual step -- unlike the genuinely
# JS/browser-dependent checks it was grouped with (theme persistence, reduced-motion, which
# really do need a browser and are out of scope per the spec), contrast is pure arithmetic
# over already-declared CSS custom properties. This spec makes it a real, automated
# regression gate instead of a one-time manual spot-check.
#
# Two sources of truth, mirroring exactly what cascades in the browser:
# - `application.tailwind.css` (regex-read directly, same approach as
#   spec/lib/daisyui_theme_registry_spec.rb) is authoritative for anything the project
#   defines or overrides: light/dark's amber primary+accent tokens and dark's base tokens
#   (both unlayered, so they always win over DaisyUI's own layered stock rules -- see that
#   file's "Dark theme base tokens" comment), plus gruvbox/catppuccin's fully custom
#   `@plugin "daisyui/theme"` blocks.
# - The installed `daisyui` package's own per-theme CSS (`node_modules/daisyui/theme/*.css`)
#   is authoritative for whatever the project deliberately leaves unmodified: dracula and
#   nord in full (D1/R4: "using their stock definitions unmodified is acceptable"), and
#   light's base-100/base-content (R2: "light theme keeps DaisyUI's stock base-* ... roles").
#   Reading the real installed package -- rather than hand-copying its numbers here -- means
#   a future daisyui version bump that quietly shifts a stock theme's contrast gets caught by
#   this gate too, not just the palettes this project authors by hand.
#
# DaisyUI declares its own theme colors as `oklch(L% C H)`; `oklch_to_srgb` below implements
# the standard OKLab conversion (Bjorn Ottosson's published matrices -- the same ones behind
# CSS Color 4 / browser implementations) down to gamma-encoded sRGB, so hex- and oklch()
# sourced colors are then scored by the identical WCAG relative-luminance formula.
RSpec.describe 'WCAG AA contrast regression gate' do # rubocop:disable RSpec/DescribeClass
  let(:css) { Rails.root.join('app/assets/stylesheets/application.tailwind.css').read }

  # ---- theme color resolution --------------------------------------------------------

  def colors_for(theme)
    return extract_properties(custom_theme_block(theme)) if %w[gruvbox catppuccin].include?(theme)

    stock_theme_colors(theme).merge(override_theme_colors(theme))
  end

  # DaisyUI's own stock definition for a built-in theme, read from the installed package
  # rather than hand-copied (R4: dracula/nord ship "unmodified"; light's base tokens are
  # also stock -- see the file-level comment above).
  def stock_theme_colors(theme)
    extract_properties(Rails.root.join("node_modules/daisyui/theme/#{theme}.css").read)
  end

  # Every unlayered `[data-theme="theme"] { ... }` block in application.tailwind.css (there
  # can be more than one -- e.g. dark's amber tokens and its base tokens are declared in two
  # separate blocks), merged in source order so later declarations win, matching the real CSS
  # cascade for same-layer/same-specificity rules.
  def override_theme_colors(theme)
    css.scan(/\[data-theme="#{theme}"\]\s*\{([^}]*)\}/m).flatten.each_with_object({}) do |block, acc|
      acc.merge!(extract_properties(block))
    end
  end

  # gruvbox/catppuccin aren't built into DaisyUI 5 -- each is a full custom
  # `@plugin "daisyui/theme" { name: "..."; ... }` block, entirely inline in
  # application.tailwind.css.
  def custom_theme_block(theme)
    css[%r{@plugin "daisyui/theme" \{\s*name: "#{theme}";.*?\n\}}m]
  end

  def extract_properties(text)
    text.to_s.scan(/--color-([\w-]+):\s*([^;]+);/).to_h { |role, value| [role, value.strip] }
  end

  # ---- WCAG relative-luminance contrast -----------------------------------------------

  def contrast_ratio(foreground, background)
    l_fg = relative_luminance(parse_color(foreground))
    l_bg = relative_luminance(parse_color(background))
    lighter = [l_fg, l_bg].max
    darker = [l_fg, l_bg].min
    (lighter + 0.05) / (darker + 0.05)
  end

  def parse_color(value)
    case value
    when /\A#[0-9a-fA-F]{6}\z/
      value.delete('#').scan(/../).map { |byte| byte.to_i(16) / 255.0 }
    when /\Aoklch\(/
      lightness, chroma, hue = value.match(/oklch\(\s*([\d.]+)%\s+([\d.]+)\s+([\d.]+)\s*\)/).captures.map(&:to_f)
      oklch_to_srgb(lightness / 100.0, chroma, hue)
    else
      raise "contrast_spec: unrecognized color value #{value.inspect}"
    end
  end

  # OKLCH -> OKLab -> LMS -> linear sRGB -> gamma-encoded sRGB (Bjorn Ottosson's published
  # OKLab matrices; the same conversion CSS Color 4 / browsers use).
  def oklch_to_srgb(lightness, chroma, hue_degrees) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    hue = hue_degrees * Math::PI / 180.0
    a = chroma * Math.cos(hue)
    b = chroma * Math.sin(hue)

    l_ = lightness + (0.3963377774 * a) + (0.2158037573 * b)
    m_ = lightness - (0.1055613458 * a) - (0.0638541728 * b)
    s_ = lightness - (0.0894841775 * a) - (1.2914855480 * b)
    l = l_**3
    m = m_**3
    s = s_**3

    r_lin = (4.0767416621 * l) - (3.3077115913 * m) + (0.2309699292 * s)
    g_lin = (-1.2684380046 * l) + (2.6097574011 * m) - (0.3413193965 * s)
    b_lin = (-0.0041960863 * l) - (0.7034186147 * m) + (1.7076147010 * s)

    [r_lin, g_lin, b_lin].map { |channel| gamma_encode(channel.clamp(0.0, 1.0)) }
  end

  def gamma_encode(linear)
    linear <= 0.0031308 ? linear * 12.92 : (1.055 * (linear**(1 / 2.4))) - 0.055
  end

  # WCAG 2.x relative luminance: https://www.w3.org/TR/WCAG20/#relativeluminancedef
  def relative_luminance(srgb)
    r, g, b = srgb.map { |c| c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055)**2.4 }
    (0.2126 * r) + (0.7152 * g) + (0.0722 * b)
  end

  # ---- the gate: every bundled theme, base + primary (R2/R4) --------------------------

  %w[light dark dracula nord gruvbox catppuccin].each do |theme|
    it "meets WCAG AA 4.5:1 for base-content on base-100 in the #{theme} theme (R2/R4)" do
      colors = colors_for(theme)
      expect(contrast_ratio(colors['base-content'], colors['base-100'])).to be >= 4.5
    end

    it "meets WCAG AA 4.5:1 for primary-content on primary in the #{theme} theme (R2/R4)" do
      colors = colors_for(theme)
      expect(contrast_ratio(colors['primary-content'], colors['primary'])).to be >= 4.5
    end
  end

  # ---- the extra sweep: every remaining role pair on the 2 custom themes --------------
  #
  # gruvbox/catppuccin are explicitly flagged as needing post-merge visual-QA polish (Open
  # Question 4: "expected to need minor visual-QA polish ... as long as the 4.5:1 gate holds
  # throughout") -- exactly where a silent contrast regression could creep in unnoticed.
  # base/primary are already covered above; this sweeps the remaining DaisyUI role set.
  remaining_role_pairs = %w[secondary accent neutral info success warning error]
  %w[gruvbox catppuccin].each do |theme|
    remaining_role_pairs.each do |role|
      it "meets WCAG AA 4.5:1 for #{role}-content on #{role} in the custom #{theme} theme (D1/R4)" do
        colors = colors_for(theme)
        expect(contrast_ratio(colors["#{role}-content"], colors[role])).to be >= 4.5
      end
    end
  end
end
