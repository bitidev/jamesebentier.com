# frozen_string_literal: true

class ProjectsController < ApplicationController # rubocop:disable Style/Documentation
  def index; end

  def show
    @project = Project.find_by(slug: params[:slug])
  end
end
