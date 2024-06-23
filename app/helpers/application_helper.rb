# frozen_string_literal: true

module ApplicationHelper # rubocop:disable Style/Documentation
  def social_profile_icon(network, classes: nil, **)
    case network.to_sym
    when :linkedin
      tag.i class: "fa-brands fa-linkedin text-base text-[#0072b1] #{classes}", title: "LinkedIn", **
    when :twitter
      tag.i class: "fa-brands fa-twitter text-base text-[#1da1f2] #{classes}", title: "Twitter", **
    else
      tag.i class: "fa-brands fa-#{network} text-base #{classes}", title: network.capitalize, **
    end
  end
end
