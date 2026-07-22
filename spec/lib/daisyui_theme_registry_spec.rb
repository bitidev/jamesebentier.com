# frozen_string_literal: true

require 'rails_helper'

# application.tailwind.css's `@plugin "daisyui" { themes: ... }` line is the actual DaisyUI
# theme-registration source of truth (R4/D1) -- the picker markup in
# layouts/components/_header.html.erb (covered by spec/requests/welcome_spec.rb's "theme
# picker" examples) is a separately-maintained list that must stay in sync with it. Read
# directly here rather than re-implemented, since the real value comes from asserting against
# the actual compiled-from source, not a copy of the expected list.
RSpec.describe 'application.tailwind.css DaisyUI theme registry' do # rubocop:disable RSpec/DescribeClass
  let(:css) { Rails.root.join('app/assets/stylesheets/application.tailwind.css').read }
  let(:themes_declaration) { css[/@plugin "daisyui" \{.*?themes:\s*([^;]+);/m, 1] }
  let(:registered_themes) { themes_declaration.split(',').map { |entry| entry.strip.split(/\s+/).first } }

  it 'bundles exactly the six curated themes (D1/R4), no more' do
    expect(registered_themes).to eq(%w[light dark dracula nord gruvbox catppuccin])
  end

  it 'marks gruvbox as the DaisyUI --default theme, matching first-time-visitor behavior (R6)' do
    expect(themes_declaration).to match(/\bgruvbox\s+--default\b/)
  end

  it 'defines a custom daisyui/theme block for gruvbox, which DaisyUI 5 does not ship built in' do
    expect(css).to match(%r{@plugin "daisyui/theme" \{\s*name: "gruvbox"})
  end

  it 'defines a custom daisyui/theme block for catppuccin, which DaisyUI 5 does not ship built in' do
    expect(css).to match(%r{@plugin "daisyui/theme" \{\s*name: "catppuccin"})
  end
end
