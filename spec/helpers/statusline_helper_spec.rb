# frozen_string_literal: true

require 'rails_helper'

# app/helpers/statusline_helper.rb -- path + keybind-hint copy for the terminal statusline
# (app/views/layouts/components/_keyboard_status_line.html.erb), keyed on the current
# controller/action (terminal-identity redesign #1226 design doc's "Statusline" section).
# `controller_name`/`action_name`/`params` are real ActionView::Helpers::ControllerHelper
# delegates (to the view's controller) -- stubbed here only to set the contextual "which
# page is this" input the helper itself branches on, not to fake the helper's own logic.
RSpec.describe StatuslineHelper do
  def set_page(controller:, action:, params: {})
    allow(helper).to receive_messages(controller_name: controller, action_name: action, params: params)
  end

  describe '#statusline_path' do
    it "maps welcome#index to '~/home'" do
      set_page(controller: 'welcome', action: 'index')

      expect(helper.statusline_path).to eq('~/home')
    end

    it "maps writing#index to '~/writing'" do
      set_page(controller: 'writing', action: 'index')

      expect(helper.statusline_path).to eq('~/writing')
    end

    it "maps projects#index to '~/projects'" do
      set_page(controller: 'projects', action: 'index')

      expect(helper.statusline_path).to eq('~/projects')
    end

    it "maps welcome#about to '~/about'" do
      set_page(controller: 'welcome', action: 'about')

      expect(helper.statusline_path).to eq('~/about')
    end

    it "maps welcome#resume to '~/resume'" do
      set_page(controller: 'welcome', action: 'resume')

      expect(helper.statusline_path).to eq('~/resume')
    end

    it "maps writing#show to '~/writing/<slug>.md', reading the real slug param" do
      set_page(controller: 'writing', action: 'show', params: { slug: 'my-real-post' })

      expect(helper.statusline_path).to eq('~/writing/my-real-post.md')
    end

    it "maps projects#show to '~/projects/<slug>', reading the real slug param" do
      set_page(controller: 'projects', action: 'show', params: { slug: 'my-real-project' })

      expect(helper.statusline_path).to eq('~/projects/my-real-project')
    end

    it "falls back to '~/' for an unmapped controller/action (e.g. welcome#privacy) rather than raising" do
      set_page(controller: 'welcome', action: 'privacy')

      expect(helper.statusline_path).to eq('~/')
    end
  end

  describe '#statusline_hints' do
    it 'gives welcome#index the shared primary-page hint set (: / t ?)' do
      set_page(controller: 'welcome', action: 'index')

      expect(helper.statusline_hints).to eq([[':', 'command'], ['/', 'search'], ['t', 'theme'], ['?', 'help']])
    end

    it 'gives welcome#about the same shared primary-page hint set' do
      set_page(controller: 'welcome', action: 'about')

      expect(helper.statusline_hints).to eq([[':', 'command'], ['/', 'search'], ['t', 'theme'], ['?', 'help']])
    end

    it 'gives welcome#resume the same shared primary-page hint set' do
      set_page(controller: 'welcome', action: 'resume')

      expect(helper.statusline_hints).to eq([[':', 'command'], ['/', 'search'], ['t', 'theme'], ['?', 'help']])
    end

    it 'gives writing#index its own search/scroll/jump hint set' do
      set_page(controller: 'writing', action: 'index')

      expect(helper.statusline_hints).to eq([['/', 'search posts'], ['j k', 'scroll'], ['f', 'jump to link']])
    end

    it 'gives projects#index its own command/search/jump hint set' do
      set_page(controller: 'projects', action: 'index')

      expect(helper.statusline_hints).to eq([[':', 'command'], ['/', 'search'], ['f', 'jump to link']])
    end

    it 'gives writing#show its own scroll/top/theme hint set' do
      set_page(controller: 'writing', action: 'show', params: { slug: 'my-real-post' })

      expect(helper.statusline_hints).to eq([['j k', 'scroll'], ['gg', 'top'], ['t', 'theme']])
    end

    it 'gives projects#show (mapped for path, but not in the HINTS table) an empty hint set rather than raising' do
      set_page(controller: 'projects', action: 'show', params: { slug: 'my-real-project' })

      expect(helper.statusline_hints).to eq([])
    end

    it "gives a wholly unmapped controller/action (e.g. welcome#privacy) an empty hint set rather than raising" do
      set_page(controller: 'welcome', action: 'privacy')

      expect(helper.statusline_hints).to eq([])
    end
  end
end
