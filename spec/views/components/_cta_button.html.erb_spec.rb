# frozen_string_literal: true

require 'rails_helper'
require 'nokogiri'

# components/_cta_button.html.erb -- shared CTA button (R5). style: :primary always renders
# on the DaisyUI `primary` role (never a hardcoded hex) so the button re-themes correctly
# across all six bundled themes (R2/R4) with no per-theme special-casing in the partial itself.
RSpec.describe 'components/_cta_button' do
  def rendered_link(locals)
    render('components/cta_button', locals)
    Nokogiri::HTML5.fragment(rendered).at_css('a')
  end

  it 'defaults to the primary style when style is omitted' do
    expect(rendered_link(label: 'Go', href: '/x').classes).to include('btn-primary')
  end

  it 'renders the ghost style when style: :ghost is given' do
    expect(rendered_link(label: 'Go', href: '/x', style: :ghost).classes).to include('btn-ghost')
  end

  it 'links to the given href' do
    expect(rendered_link(label: 'View Project', href: '/projects/demo')['href']).to eq('/projects/demo')
  end

  it 'renders the given label as the link text' do
    expect(rendered_link(label: 'View Project', href: '/x').text).to eq('View Project')
  end
end
