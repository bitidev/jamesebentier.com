# frozen_string_literal: true

require 'rails_helper'

# GET /projects (R9), GET /projects/:slug -- terminal-identity redesign (#1226) replaced the
# card-grid index with a 2-column grid of terminal "window panes" (app/views/projects/
# index.html.erb) -- traffic-light dots, `~/projects/<slug>` title bar, a colored `●
# <status>` dot (Project#status_color_class), and bracket "commands" (`[demo ↗]` always,
# `[read]`/`[source]` conditional on presence) in demo -> read -> source order. The show
# page (app/views/projects/show.html.erb) is a reading column with the same status dot and
# bracket commands. No more `.card`/`.badge`/`.card-actions`/`.btn` markup anywhere on
# either page.
RSpec.describe 'Projects' do
  describe 'GET /projects' do
    # Each project pane is a direct child of the 2-column grid -- the one stable structural
    # hook for "how many/which projects rendered" (no `.card` class exists anymore).
    def project_panes
      response.parsed_body.css('div.grid.gap-6 > div')
    end

    # The bracket "commands" (`[demo ↗]`, `[read]`, `[source]`) are the real, load-bearing
    # visual/textual contract (design doc's Projects section) -- located by their own
    # bracketed text rather than by a retired `.card-actions`/`.btn` class combo.
    def bracket_links(scope)
      scope.css('a').select { |link| link.text.strip.start_with?('[') }
    end

    context 'when there are no projects' do
      it 'returns a successful response' do
        get projects_path

        expect(response).to have_http_status(:ok)
      end

      it 'renders no project panes' do
        get projects_path

        expect(project_panes).to be_empty
      end

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

      it 'renders exactly one project pane' do
        get projects_path

        expect(project_panes.size).to eq(1)
      end

      it "renders the project's title" do
        get projects_path

        expect(response.body).to include('Solo Project')
      end

      it "maps its Live status to the success status-dot color (R5)" do # rubocop:disable RSpec/MultipleExpectations
        get projects_path

        status_span = project_panes.first.css('span').find { |span| span.text.strip.start_with?('●') }

        expect(status_span.classes).to include('text-success')
        expect(status_span.text).to include('live')
      end

      it "links the pane title to the project's own show page" do
        get projects_path
        title_link = project_panes.first.at_css('h2 a')

        expect(URI.parse(title_link['href']).path).to eq(project_path(slug: project.slug))
      end

      it "renders the project's slug in the pane's title-bar path" do
        get projects_path

        expect(project_panes.first.text).to include("~/projects/#{project.slug}")
      end
    end

    context 'when rendering the populated pane grid' do
      before { create(:project, slug: 'solo-project') }

      it 'renders the grid using the responsive one-to-two column layout' do
        get projects_path

        grid = response.parsed_body.at_css('div.grid.gap-6')

        expect(grid.classes).to include('md:grid-cols-2')
      end
    end

    # Bracket-link CTAs, demo -> read -> source (design doc's Projects section): demo
    # (project.url) is the one required, always-present leg; read/source are optional and
    # nullable (R1).
    context 'when a project has all three triple-links set' do
      let!(:project) do
        create(:project, slug: 'triple-link-project', url: 'https://demo.example.com',
                         read_url: 'https://example.com/writeup', source_url: 'https://github.com/example/repo')
      end

      it 'renders exactly three bracket CTAs, in demo -> read -> source order' do
        get projects_path

        ctas = bracket_links(project_panes.first)

        expect(ctas.map(&:text)).to eq(['[demo ↗]', '[read]', '[source]'])
      end

      it 'links each CTA to its own project link, not a shared/duplicated one' do
        get projects_path

        ctas = bracket_links(project_panes.first)

        expect(ctas.pluck('href')).to eq([project.url, project.read_url, project.source_url])
      end

      it 'styles Demo as the primary bracket link and Read/Source as muted/secondary' do # rubocop:disable RSpec/MultipleExpectations
        get projects_path

        ctas = bracket_links(project_panes.first)

        expect(ctas.map { |cta| cta.classes.include?('text-primary') }).to eq([true, false, false])
        expect(ctas.map { |cta| cta.classes.include?('text-base-content/50') }).to eq([false, true, true])
      end
    end

    context 'when a project has only the required url (demo) leg set' do
      let!(:project) { create(:project, slug: 'demo-only-project', url: 'https://demo.example.com') }

      it 'renders exactly one bracket CTA -- [demo ↗] -- styled as primary' do # rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength
        get projects_path

        ctas = bracket_links(project_panes.first)

        expect(ctas.size).to eq(1)
        expect(ctas.first.text).to eq('[demo ↗]')
        expect(ctas.first.classes).to include('text-primary')
        expect(ctas.first['href']).to eq(project.url)
      end

      it 'never renders [read] or [source] CTAs when their URLs are nil' do
        get projects_path

        cta_labels = bracket_links(project_panes.first).map(&:text)

        expect(cta_labels).not_to include('[read]', '[source]')
      end
    end

    context 'when there are multiple projects' do
      let!(:pre_launch) { create(:project, slug: 'alpha-proj', status: 'Pre-Launch') }
      let!(:beta) { create(:project, slug: 'beta-proj', status: 'Beta') }
      let!(:live) { create(:project, slug: 'live-proj', status: 'Live') }

      it 'renders one pane per project' do
        get projects_path

        expect(project_panes.size).to eq(3)
      end

      it "maps each project's own status to its own status-dot color, independently" do # rubocop:disable RSpec/ExampleLength
        get projects_path
        colors = project_panes.map do |pane|
          status_span = pane.css('span').find { |span| span.text.strip.start_with?('●') }
          status_span.classes.find { |css_class| css_class.start_with?('text-') }
        end

        expect(colors).to contain_exactly('text-warning', 'text-info', 'text-success')
      end

      it "links each project's pane title to its own show page, not a shared/duplicated one" do
        get projects_path
        hrefs = project_panes.map { |pane| URI.parse(pane.at_css('h2 a')['href']).path }
        expected = [pre_launch, beta, live].map { |proj| project_path(slug: proj.slug) }

        expect(hrefs).to match_array(expected)
      end

      # R4 -- server-rendered status filter, driven by Project.by_status.
      it 'renders only the projects matching the selected status' do # rubocop:disable RSpec/MultipleExpectations
        get projects_path(status: 'Live')

        expect(project_panes.map(&:text).join).to include(live.title)
        expect(project_panes.size).to eq(1)
      end

      it 'renders every project when no status filter is applied (default/All view)' do
        get projects_path

        titles = project_panes.map { |pane| pane.at_css('h2 a').text }

        expect(titles).to contain_exactly(pre_launch.title, beta.title, live.title)
      end

      it 'renders no projects (not an error) for an unrecognized status value' do # rubocop:disable RSpec/MultipleExpectations
        get projects_path(status: 'Nonexistent')

        expect(response).to have_http_status(:ok)
        expect(project_panes).to be_empty
      end

      it 'marks the selected status link active and every other status/"--all" link inactive' do # rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength
        get projects_path(status: 'Live')

        filter_nav = response.parsed_body.at_css("nav[aria-label='Filter projects by status']")
        live_link = filter_nav.css('a').find { |link| link.text == '--live' }
        all_link = filter_nav.css('a').find { |link| link.text == '--all' }

        expect(live_link.classes).to include('bg-primary', 'text-primary-content')
        expect(all_link.classes).to include('border-base-300')
        expect(all_link.classes).not_to include('bg-primary')
      end

      it '"--all" is active and every status link is inactive when no filter is applied' do # rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength
        get projects_path

        filter_nav = response.parsed_body.at_css("nav[aria-label='Filter projects by status']")
        all_link = filter_nav.css('a').find { |link| link.text == '--all' }
        status_links = filter_nav.css('a').reject { |link| link.text == '--all' }

        expect(all_link.classes).to include('bg-primary', 'text-primary-content')
        expect(status_links).to all(satisfy { |link| link.classes.include?('border-base-300') })
      end
    end

    # R5.2 -- filtered-empty: rows exist, but none match the selected status.
    context 'when projects exist but none match the selected status filter' do
      before { create(:project, slug: 'beta-only-project', status: 'Beta') }

      it 'renders the filtered-empty message' do
        get projects_path(status: 'Live')

        expect(response.body).to include('No Live projects yet')
      end

      it 'keeps the filter row -- including a working "--all" link -- visible' do # rubocop:disable RSpec/MultipleExpectations
        get projects_path(status: 'Live')

        filter_nav = response.parsed_body.at_css("nav[aria-label='Filter projects by status']")
        all_link = filter_nav&.css('a')&.find { |link| link.text == '--all' }

        expect(all_link).to be_present
        expect(URI.parse(all_link['href']).path).to eq(projects_path)
      end
    end
  end

  # GET /projects/:slug -- same conditional bracket-link CTAs as the index pane, restyled
  # into the reading-column layout (app/views/projects/show.html.erb).
  describe 'GET /projects/:slug' do
    def bracket_links(scope)
      scope.css('a').select { |link| link.text.strip.start_with?('[') }
    end

    context 'when the project has only the required url (demo) leg set' do
      let!(:project) do
        create(:project, slug: 'show-page-project', title: 'Show Page Project', status: 'Live',
                         url: 'https://demo.example.com')
      end

      it 'returns a successful response' do
        get project_path(slug: project.slug)

        expect(response).to have_http_status(:ok)
      end

      it "renders the project's status via a colored ● dot, mapped to the correct status color" do # rubocop:disable RSpec/MultipleExpectations
        get project_path(slug: project.slug)
        article = response.parsed_body.at_css('article')
        status_span = article.css('span').find { |span| span.text.strip.start_with?('●') }

        expect(status_span.classes).to include('text-success')
        expect(status_span.text).to include(project.status)
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

      it 'renders exactly one bracket CTA -- [demo ↗] -- styled as primary (R6)' do # rubocop:disable RSpec/MultipleExpectations
        get project_path(slug: project.slug)

        ctas = bracket_links(response.parsed_body.at_css('article'))

        expect(ctas.size).to eq(1)
        expect(ctas.first.text).to eq('[demo ↗]')
        expect(ctas.first.classes).to include('text-primary')
      end

      it 'never renders [read] or [source] CTAs when their URLs are nil (R6)' do
        get project_path(slug: project.slug)

        cta_labels = bracket_links(response.parsed_body.at_css('article')).map(&:text)

        expect(cta_labels).not_to include('[read]', '[source]')
      end

      it 'renders a back link to the projects index' do
        get project_path(slug: project.slug)

        back_link = response.parsed_body.at_css('article a')

        expect(back_link['href']).to eq(projects_path)
      end
    end

    context 'when the project has all three triple-links set' do
      let!(:project) do
        create(:project, slug: 'triple-link-show-project', url: 'https://demo.example.com',
                         read_url: 'https://example.com/writeup', source_url: 'https://github.com/example/repo')
      end

      it 'renders exactly three bracket CTAs, in demo -> read -> source order (R6)' do
        get project_path(slug: project.slug)

        ctas = bracket_links(response.parsed_body.at_css('article'))

        expect(ctas.map(&:text)).to eq(['[demo ↗]', '[read]', '[source]'])
      end
    end
  end
end
