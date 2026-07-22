# frozen_string_literal: true

# Path + keybind-hint copy for the terminal statusline (app/views/layouts/components/
# _keyboard_status_line.html.erb), keyed on the current controller/action -- see the
# terminal-identity redesign design doc's "Statusline" section (#1226). Both lookups
# fall back to a safe default (path "~/", no hints) for any controller/action not named
# below (e.g. welcome#privacy, the newsletter confirm/unsubscribe pages) rather than
# raising, so a future page never breaks the statusline just by existing. writing#show
# and projects#show are not in PATHS but are handled explicitly in statusline_path below.
module StatuslineHelper
  PATHS = {
    "welcome#index" => "~/home",
    "welcome#about" => "~/about",
    "welcome#resume" => "~/resume",
    "writing#index" => "~/writing",
    "projects#index" => "~/projects"
  }.freeze

  # home/about/resume share one hint set per the design doc's Statusline section.
  PRIMARY_PAGE_HINTS = [[":", "command"], ["/", "search"], ["t", "theme"], ["?", "help"]].freeze

  HINTS = {
    "welcome#index" => PRIMARY_PAGE_HINTS,
    "welcome#about" => PRIMARY_PAGE_HINTS,
    "welcome#resume" => PRIMARY_PAGE_HINTS,
    "writing#index" => [["/", "search posts"], ["j k", "scroll"], ["f", "jump to link"]],
    "projects#index" => [[":", "command"], ["/", "search"], ["f", "jump to link"]],
    "writing#show" => [["j k", "scroll"], ["gg", "top"], ["t", "theme"]]
  }.freeze

  def statusline_path
    case "#{controller_name}##{action_name}"
    when "writing#show" then "~/writing/#{params[:slug]}.md"
    when "projects#show" then "~/projects/#{params[:slug]}"
    else PATHS.fetch("#{controller_name}##{action_name}", "~/")
    end
  end

  def statusline_hints
    HINTS.fetch("#{controller_name}##{action_name}", [])
  end
end
