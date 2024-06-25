# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

Project.find_or_initialize_by(slug: "not-my-real-email").update!(
  title: "NotMyRealEmail.com - Secure Email Aliasing and Forwarding Service",
  status: "Pre-Launch",
  url: "https://notmyrealemail.com",
  image: "https://notmyrealemail.com/logo-120.png",
  description: <<~DESC.chomp
    Not My Real Email offers users a secure and convenient solution to protect their online privacy by
    creating email aliases or masks over their existing email addresses, perfect for those seeking heightened
    anonymity and safety in their online activities.
  DESC
)
Project.find_or_initialize_by(slug: "the-game-about-people").update!(
  title: "The Game About People",
  status: "Live",
  url: "https://thegameaboutpeople.com",
  image: "https://biti.dev/images/Biti-Site.gif",
  description: <<~DESC.chomp
    The Game About People is where we first debuted BiTi to the world.
    The focus of this game is to get to know your friends better, and get to know which of your friends knows you best.
    The Game About People is a fun multiplayer game and is a hit at parties where you want to see just how well you all know each other.
  DESC
)

Dir[File.expand_path('../public/blog/*.md', __dir__)].each do |file|
  data = YAML.safe_load_file(file, symbolize_names: true, permitted_classes: [Date])

  Post.find_or_initialize_by(slug: data[:slug] || data[:title].parameterize).update!(
    file_path: File.basename(file),
    **data
  )
end
