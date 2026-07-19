# frozen_string_literal: true

require 'rails_helper'
require 'nokogiri'

# components/_pill.html.erb -- shared tag/status pill (R5). variant: :status maps a
# Project#status value to a DaisyUI badge role -- the contract R9's projects#index migration
# and later pages (P1.3) build against. An unrecognized value falls back to badge-neutral
# rather than raising; that fallback can never be reached through a real request spec because
# Project#status is DB-validated to only ever be Pre-Launch/Beta/Live (see spec/models/project_spec.rb),
# so it is asserted here directly against the partial's documented label:/variant: contract,
# which is independent of the Project model.
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

  it 'renders the given label as its text' do
    render('components/pill', label: 'Live', variant: :status)

    expect(rendered).to include('Live')
  end
end
