# frozen_string_literal: true

class ChangelogController < ApplicationController # rubocop:disable Style/Documentation
  def index
    @releases = Changelog.releases
  end
end
