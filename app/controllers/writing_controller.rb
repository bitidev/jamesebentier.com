# frozen_string_literal: true

# The WritingController is used to host the blog posts (Notes/Deep Dives) for the application.
class WritingController < ApplicationController
  def index; end

  def show
    @post = Post.find_by!(slug: params.expect(:slug).downcase)
  end
end
