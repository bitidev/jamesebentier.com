# frozen_string_literal: true

require 'rails_helper'

# GET /projects (R9) -- migrated to the four shared components/_* partials (R5). These specs
# exercise the components through the real controller/view stack (not just in isolation --
# see adlc/methods/code-quality/call-site-wiring-verification.md), proving the migration is
# actually wired up, on top of the component-contract specs under spec/views/components/.
RSpec.describe 'Projects' do
  describe 'GET /projects' do
    context 'when there are no projects' do
      it 'returns a successful response' do
        get projects_path

        expect(response).to have_http_status(:ok)
      end

      it 'renders no project cards' do
        get projects_path

        expect(response.parsed_body.css('.card')).to be_empty
      end
    end

    context 'when there is one project' do
      let!(:project) { create(:project, slug: 'solo-project', title: 'Solo Project', status: 'Live') }

      it 'renders exactly one project card' do
        get projects_path

        expect(response.parsed_body.css('.card').size).to eq(1)
      end

      it "renders the project's title" do
        get projects_path

        expect(response.body).to include('Solo Project')
      end

      it 'maps its Live status to the badge-success role via the pill component (R5)' do
        get projects_path

        expect(response.parsed_body.at_css('.badge').classes).to include('badge-success')
      end

      it "links the card title to the project's own show page" do
        get projects_path
        title_link = response.parsed_body.at_css('.card-title a')

        expect(URI.parse(title_link['href']).path).to eq(project_path(slug: project.slug))
      end

      it 'wraps the listing in the shared section component (R5)' do
        get projects_path

        expect(response.parsed_body.at_css("section[data-controller='motion']")).to be_present
      end
    end

    context 'when there are multiple projects' do
      let!(:pre_launch) { create(:project, slug: 'alpha-proj', status: 'Pre-Launch') }
      let!(:beta) { create(:project, slug: 'beta-proj', status: 'Beta') }
      let!(:live) { create(:project, slug: 'live-proj', status: 'Live') }

      it 'renders one card per project' do
        get projects_path

        expect(response.parsed_body.css('.card').size).to eq(3)
      end

      it "maps each project's own status to its own badge role, independently" do
        get projects_path
        badges = response.parsed_body.css('.badge')
        roles = badges.map { |badge| badge.classes.find { |css_class| css_class.start_with?('badge-') } }

        expect(roles).to contain_exactly('badge-warning', 'badge-info', 'badge-success')
      end

      it "links each project's card title to its own show page, not a shared/duplicated one" do
        get projects_path
        title_links = response.parsed_body.css('.card-title a')
        hrefs = title_links.map { |link| URI.parse(link['href']).path }
        expected = [pre_launch, beta, live].map { |proj| project_path(slug: proj.slug) }

        expect(hrefs).to match_array(expected)
      end
    end
  end
end
