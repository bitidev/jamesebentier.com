# frozen_string_literal: true

xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0" do
  xml.channel do
    xml.title "Blog | James Ebentier | RSS"
    xml.description "The blog of James Ebentier documenting his current leadning and what he is building through Biti LLC."
    xml.link projects_url
    xml.image do
      xml.url "https://jamesebentier.com/logo.png"
      xml.title "James Ebentier Blog"
      xml.link projects_url
    end

    Post.published.find_each do |blog|
      xml.item do
        xml.title blog.title
        xml.description blog.description
        xml.link post_path(slug: blog.slug)
        xml.guid blog.slug
        if blog.image.present?
          xml.enclosure url: blog.image,
                        type: Mime::Type.lookup_by_extension(File.extname(blog.image).delete("."))
        end
      end
    end
  end
end
