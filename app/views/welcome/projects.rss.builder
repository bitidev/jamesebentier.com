# frozen_string_literal: true

xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0" do
  xml.channel do
    xml.title "Biti LLC Projects | Jamess Ebentier | RSS"
    xml.description "The current list of projects James Ebentier is building through Biti LLC."
    xml.link projects_url
    xml.image do
      xml.url "https://jamesebentier.com/logo.png"
      xml.title "Biti LLC Projects"
      xml.link projects_url
    end

    Project.find_each do |project|
      xml.item do
        xml.title project.title
        xml.description project.description
        xml.link project.url
        xml.guid project.slug
        xml.enclosure url: project.image,
                      type: Mime::Type.lookup_by_extension(File.extname(project.image).delete("."))
      end
    end
  end
end
