# frozen_string_literal: true

require 'rails_helper'
require 'nokogiri'

# components/_card.html.erb -- shared card (R5). The card wraps its block content plus a
# "stretched link" overlay <a>, rather than wrapping the whole card in an <a>, precisely so
# callers can put their own interactive elements (e.g. cta_button, itself an <a>) inside the
# block without producing invalid <a>-in-<a> markup -- the regression these specs guard against.
#
# Note on how the regression guard below is shaped: a spec-compliant HTML5 parser (what
# browsers and Nokogiri::HTML5 both implement) never actually lets an <a> survive as a literal
# descendant of another <a> -- the "adoption agency algorithm" auto-closes the outer <a> the
# moment an inner one opens, then reconstructs it, splitting one wrapping anchor into multiple
# orphaned/blank sibling anchors instead. Verified empirically (temporarily reintroducing an
# outer-<a>-wraps-the-card regression here and running this file): a literal
# `expect(doc.css("a a")).to be_empty` assertion still passes even with the bug present, so it
# would be theatre. The anchor *count* below is what actually catches the corruption (4 anchors
# instead of 2), because the parser's auto-correction manifests as extra anchors, not nesting.
RSpec.describe 'components/_card' do
  def rendered_doc
    Nokogiri::HTML5.fragment(rendered)
  end

  it 'renders the block content inside the card body' do
    render(layout: 'components/card', locals: { href: '/projects/demo' }) { content_tag(:h2, 'Demo Project') }

    expect(rendered).to include('Demo Project')
  end

  it 'points the stretched-link overlay at the given href' do
    render(layout: 'components/card', locals: { href: '/projects/demo' }) { content_tag(:h2, 'Demo Project') }

    expect(rendered_doc.at_css('a.absolute')['href']).to eq('/projects/demo')
  end

  it 'hides the stretched-link overlay from assistive tech' do
    render(layout: 'components/card', locals: { href: '/projects/demo' }) { content_tag(:h2, 'Demo Project') }

    expect(rendered_doc.at_css('a.absolute')['aria-hidden']).to eq('true')
  end

  it 'renders exactly two anchors -- the block\'s own link and the stretched-link overlay -- ' \
     'not an outer <a> wrapping the card (regression guard, see note above)' do
    render(layout: 'components/card', locals: { href: '/projects/demo' }) { link_to('View Project', '/projects/demo') }

    expect(rendered_doc.css('a').size).to eq(2)
  end

  it 'renders the image with an empty alt (decorative) when image_url is given' do
    render(layout: 'components/card', locals: { href: '/x', image_url: 'https://example.com/demo.png' }) do
      content_tag(:h2, 'Demo')
    end

    expect(rendered_doc.at_css('figure img')['alt']).to eq('')
  end

  it 'omits the figure entirely when no image_url is given' do
    render(layout: 'components/card', locals: { href: '/x' }) { content_tag(:h2, 'Demo') }

    expect(rendered_doc.css('figure')).to be_empty
  end
end
