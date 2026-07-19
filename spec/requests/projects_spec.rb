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

      # R5.1 -- table-wide empty: brand-new database, nothing to filter, no filter row shown.
      it 'renders the table-wide coming-soon message' do
        get projects_path

        expect(response.body).to include('Projects are coming soon')
      end

      it 'renders no status-filter row' do
        get projects_path

        expect(response.parsed_body.at_css("nav[aria-label='Filter projects by status']")).to be_nil
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

    # R3 -- responsive card grid.
    context 'when rendering the populated card grid' do
      before { create(:project, slug: 'solo-project') }

      it 'renders the grid using the responsive one-to-three column layout' do
        get projects_path

        grid = response.parsed_body.at_css('div.grid')

        expect(grid.classes).to include('grid-cols-1', 'md:grid-cols-3')
      end
    end

    # R3 -- triple-link CTAs (read -> demo -> source), conditional on presence. Demo (project.url)
    # is the one required, always-present leg; Read/Source are optional and nullable (R1).
    context 'when a project has all three triple-links set' do
      let!(:project) do
        create(:project, slug: 'triple-link-project', url: 'https://demo.example.com',
                         read_url: 'https://example.com/writeup', source_url: 'https://github.com/example/repo')
      end

      it 'renders exactly three CTAs, in read -> demo -> source order' do
        get projects_path

        ctas = response.parsed_body.css('.card-actions a.btn')

        expect(ctas.map(&:text)).to eq(%w[Read Demo Source])
      end

      it 'links each CTA to its own project link, not a shared/duplicated one' do
        get projects_path

        ctas = response.parsed_body.css('.card-actions a.btn')

        expect(ctas.pluck('href')).to eq([project.read_url, project.url, project.source_url])
      end

      it 'styles Demo as the primary CTA and Read/Source as secondary (ghost)' do # rubocop:disable RSpec/MultipleExpectations
        get projects_path

        ctas = response.parsed_body.css('.card-actions a.btn')

        expect(ctas.map { |cta| cta.classes.include?('btn-primary') }).to eq([false, true, false])
        expect(ctas.map { |cta| cta.classes.include?('btn-ghost') }).to eq([true, false, true])
      end
    end

    context 'when a project has only the required url (demo) leg set' do
      let!(:project) { create(:project, slug: 'demo-only-project', url: 'https://demo.example.com') }

      it 'renders exactly one CTA -- Demo -- styled as primary' do # rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength
        get projects_path

        ctas = response.parsed_body.css('.card-actions a.btn')

        expect(ctas.size).to eq(1)
        expect(ctas.first.text).to eq('Demo')
        expect(ctas.first.classes).to include('btn-primary')
        expect(ctas.first['href']).to eq(project.url)
      end

      it 'never renders Read or Source CTAs when their URLs are nil' do
        get projects_path

        cta_labels = response.parsed_body.css('.card-actions a.btn').map(&:text)

        expect(cta_labels).not_to include('Read', 'Source')
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

      # R4 -- server-rendered status filter, driven by Project.by_status.
      it 'renders only the projects matching the selected status' do
        get projects_path(status: 'Live')

        titles = response.parsed_body.css('.card-title').map(&:text)

        expect(titles).to contain_exactly(live.title)
      end

      it 'renders every project when no status filter is applied (default/All view)' do
        get projects_path

        titles = response.parsed_body.css('.card-title').map(&:text)

        expect(titles).to contain_exactly(pre_launch.title, beta.title, live.title)
      end

      it 'renders no projects (not an error) for an unrecognized status value' do # rubocop:disable RSpec/MultipleExpectations
        get projects_path(status: 'Nonexistent')

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.css('.card')).to be_empty
      end

      it 'marks the selected status link active and every other status/"All" link inactive' do # rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength
        get projects_path(status: 'Live')

        filter_nav = response.parsed_body.at_css("nav[aria-label='Filter projects by status']")
        live_link = filter_nav.css('a').find { |link| link.text == 'Live' }
        all_link = filter_nav.css('a').find { |link| link.text == 'All' }

        expect(live_link.classes).to include('text-primary', 'cursor-default')
        expect(all_link.classes).to include('link', 'link-hover')
      end

      it '"All" is active and every status link is inactive when no filter is applied' do # rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength
        get projects_path

        filter_nav = response.parsed_body.at_css("nav[aria-label='Filter projects by status']")
        all_link = filter_nav.css('a').find { |link| link.text == 'All' }
        status_links = filter_nav.css('a').reject { |link| link.text == 'All' }

        expect(all_link.classes).to include('text-primary', 'cursor-default')
        expect(status_links).to all(satisfy { |link| link.classes.include?('link-hover') })
      end
    end

    # R5.2 -- filtered-empty: rows exist, but none match the selected status.
    context 'when projects exist but none match the selected status filter' do
      before { create(:project, slug: 'beta-only-project', status: 'Beta') }

      it 'renders the filtered-empty message' do
        get projects_path(status: 'Live')

        expect(response.body).to include('No Live projects yet')
      end

      it 'keeps the filter row -- including a working "All" link -- visible' do # rubocop:disable RSpec/MultipleExpectations
        get projects_path(status: 'Live')

        filter_nav = response.parsed_body.at_css("nav[aria-label='Filter projects by status']")
        all_link = filter_nav&.css('a')&.find { |link| link.text == 'All' }

        expect(all_link).to be_present
        expect(URI.parse(all_link['href']).path).to eq(projects_path)
      end
    end
  end

  # New coverage -- GET /projects/:slug had zero request-spec coverage before this issue
  # (see docs/specs/1182-projects-page-redesign.md Current State). Rewritten onto the P1.1
  # components (R6): same conditional triple-links as the index card, retired
  # text-[#999]/badge-accent literal-color markup removed.
  describe 'GET /projects/:slug' do
    context 'when the project has only the required url (demo) leg set' do
      let!(:project) do
        create(:project, slug: 'show-page-project', title: 'Show Page Project', status: 'Live',
                         url: 'https://demo.example.com')
      end

      it 'returns a successful response' do
        get project_path(slug: project.slug)

        expect(response).to have_http_status(:ok)
      end

      it "renders the project's status pill, mapped to the correct badge role via the pill component" do
        get project_path(slug: project.slug)

        expect(response.parsed_body.at_css('.badge').classes).to include('badge-success')
      end

      it "renders the project's markdown content" do
        get project_path(slug: project.slug)

        expect(response.parsed_body.at_css('.prose').text).to include('Project Details Coming Soon')
      end

      it 'no longer renders the retired text-[#999] literal-color utility (R6)' do
        get project_path(slug: project.slug)

        expect(response.body).not_to include('text-[#999]')
      end

      it 'no longer renders the retired badge-accent class (R6)' do
        get project_path(slug: project.slug)

        expect(response.parsed_body.css('.badge-accent')).to be_empty
      end

      it 'renders exactly one CTA -- Demo -- styled as primary (R6)' do # rubocop:disable RSpec/MultipleExpectations
        get project_path(slug: project.slug)

        ctas = response.parsed_body.css('.card-actions a.btn')

        expect(ctas.size).to eq(1)
        expect(ctas.first.text).to eq('Demo')
        expect(ctas.first.classes).to include('btn-primary')
      end

      it 'never renders Read or Source CTAs when their URLs are nil (R6)' do
        get project_path(slug: project.slug)

        cta_labels = response.parsed_body.css('.card-actions a.btn').map(&:text)

        expect(cta_labels).not_to include('Read', 'Source')
      end
    end

    context 'when the project has all three triple-links set' do
      let!(:project) do
        create(:project, slug: 'triple-link-show-project', url: 'https://demo.example.com',
                         read_url: 'https://example.com/writeup', source_url: 'https://github.com/example/repo')
      end

      it 'renders exactly three CTAs, in read -> demo -> source order (R6)' do
        get project_path(slug: project.slug)

        ctas = response.parsed_body.css('.card-actions a.btn')

        expect(ctas.map(&:text)).to eq(%w[Read Demo Source])
      end
    end
  end
end
