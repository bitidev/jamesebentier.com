# frozen_string_literal: true

# The BlogController is used to host the blog posts for the application.
class BlogController < ApplicationController
  def index; end

  def show
    @post = Post.find_by!(slug: params[:slug].downcase)
  end
end
