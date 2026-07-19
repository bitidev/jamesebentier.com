# frozen_string_literal: true

require 'rails_helper'
require 'nokogiri'

# components/_section.html.erb -- shared section wrapper (R5). Rendered as a layout so the
# caller's block becomes the section body; eyebrow/title are optional locals (Component API).
RSpec.describe 'components/_section' do
  def rendered_doc
    Nokogiri::HTML5.fragment(rendered)
  end

  it 'renders the block content as the section body' do
    render(layout: 'components/section') { content_tag(:p, 'Body content') }

    expect(rendered).to include('Body content')
  end

  it 'omits the eyebrow paragraph when none is given' do
    render(layout: 'components/section') { content_tag(:p, 'Body') }

    expect(rendered_doc.css('p.uppercase')).to be_empty
  end

  it 'renders the eyebrow label when given' do
    render(layout: 'components/section', locals: { eyebrow: 'Featured' }) { content_tag(:p, 'Body') }

    expect(rendered).to include('Featured')
  end

  it 'renders the title as a heading when given' do
    render(layout: 'components/section', locals: { title: 'Recent Projects' }) { content_tag(:p, 'Body') }

    expect(rendered_doc.at_css('h2').text).to eq('Recent Projects')
  end

  it 'wires the section into the scroll motion system (R7)' do
    render(layout: 'components/section') { content_tag(:p, 'Body') }

    expect(rendered_doc.at_css("section[data-controller='motion']")).to be_present
  end
end
