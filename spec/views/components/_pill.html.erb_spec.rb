# frozen_string_literal: true

require 'rails_helper'
require 'nokogiri'

# components/_pill.html.erb -- shared tag/status/kind pill (R5, plus P1.4/#1183's D7
# amendment). variant: :status maps a Project#status value to a DaisyUI badge role -- the
# contract R9's projects#index migration and later pages (P1.3) build against. variant: :kind
# maps a Post#kind_label value the same way (D7). Both variants' unrecognized-value fallback
# to badge-neutral rather than raising can never be reached through a real request spec,
# because both Project#status and Post#kind are DB-validated to only ever hold their own
# whitelisted values (see spec/models/project_spec.rb, spec/models/post_spec.rb) -- so both
# fallbacks are asserted here directly against the partial's documented label:/variant:
# contract, independent of either model.
RSpec.describe 'components/_pill' do
  def badge_classes(locals)
    render('components/pill', locals)
    Nokogiri::HTML5.fragment(rendered).at_css('.badge').classes
  end

  it 'maps Pre-Launch to badge-warning' do
    expect(badge_classes(label: 'Pre-Launch', variant: :status)).to include('badge-warning')
  end

  it 'maps Beta to badge-info' do
    expect(badge_classes(label: 'Beta', variant: :status)).to include('badge-info')
  end

  it 'maps Live to badge-success' do
    expect(badge_classes(label: 'Live', variant: :status)).to include('badge-success')
  end

  it 'falls back to badge-neutral for an unrecognized status instead of raising' do
    expect(badge_classes(label: 'Archived', variant: :status)).to include('badge-neutral')
  end

  it 'renders a neutral outline badge for variant: :tag' do
    expect(badge_classes(label: 'ruby', variant: :tag)).to include('badge-outline')
  end

  it 'defaults to the :tag outline style when variant is omitted' do
    expect(badge_classes(label: 'ruby')).to include('badge-outline')
  end

  # variant: :kind (P1.4/#1183 D7) -- the one additive amendment this issue makes to the
  # partial. Note -> badge-info, Deep Dive -> badge-accent; both real, themed DaisyUI roles.
  it 'maps Note to badge-info' do
    expect(badge_classes(label: 'Note', variant: :kind)).to include('badge-info')
  end

  it 'maps Deep Dive to badge-accent' do
    expect(badge_classes(label: 'Deep Dive', variant: :kind)).to include('badge-accent')
  end

  it 'falls back to badge-neutral for an unrecognized kind label instead of raising' do
    expect(badge_classes(label: 'Something Else', variant: :kind)).to include('badge-neutral')
  end

  it 'renders the given label as its text' do
    render('components/pill', label: 'Live', variant: :status)

    expect(rendered).to include('Live')
  end
end
