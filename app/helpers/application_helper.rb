# frozen_string_literal: true

module ApplicationHelper # rubocop:disable Style/Documentation
  # Terminal-identity redesign (#1226): the full multi-column footer (identity/sitemap/
  # newsletter) now renders on Home only -- interior pages end at the statusline. Kept
  # as a named predicate (rather than an inline current_page? in the layout) so its
  # intent reads at the call site and any future "which pages get the full footer"
  # change has one place to update.
  def show_full_footer?
    current_page?(root_path)
  end

  # Terminal-identity redesign (#1226): dropped the per-network hardcoded brand hex
  # (LinkedIn blue / Twitter blue) that used to color these icons regardless of theme --
  # this helper's only remaining caller (the Home-only footer) already wraps each icon
  # in a themed text-base-content/70 (hover:text-primary) link, and an <i> with no
  # explicit color of its own simply inherits that, so every icon re-themes across all
  # six bundled palettes with no per-network special-casing.
  ICON_TITLES = { linkedin: "LinkedIn" }.freeze

  def social_profile_icon(network, classes: nil, **)
    title = ICON_TITLES.fetch(network.to_sym, network.to_s.capitalize)
    tag.i class: "fa-brands fa-#{network} text-base #{classes}".strip, title: title, **
  end
end
