// COMMAND-mode registry + parsing/ranking helpers (spec R6, architecture plan Decision 2
// "Command registry contract"). This is the extension point P1.9's metrics-query
// commands (`stats views --last 7d`, `top posts`) plug into later -- new entries are
// added to COMMAND_REGISTRY with no shape change required.
//
// Extension contract for a registry entry:
//   {
//     name: "projects",       // canonical invocation, typed after ":"
//     aliases: ["p"],         // optional shorthand(s)
//     description: "...",     // shown in the `?` guide overlay
//     run: (args, context) => { ... },
//   }
// `run` returns `false` to signal "did not apply" (e.g. `:theme bogus-name`) so the
// controller can show the same "not found" feedback state as an unrecognized command
// name, rather than a third, undocumented failure state. Any other return value (or
// none) is treated as success.
//
// `context` is supplied by keyboard_nav_controller.js at call time (navigateTo/setTheme/
// openGuideDialog bound to the controller's own, already-single-source-of-truth methods
// -- resolveNavTarget for nav, the existing theme-picker <select> for theme, the
// existing guide dialog for help). Registry entries never touch the DOM directly, so
// this module stays a plain-data/pure-function module for unit testing (Decision 1's
// testability seam) except for the injected `run` closures, whose *effects* are only
// ever exercised through a fake `context` in tests -- no jsdom required.
import { THEME_CYCLE_ORDER } from "./theme_cycle"

export const COMMAND_REGISTRY = [
  {
    name: "home",
    aliases: [],
    description: "Go to the home page",
    run: (_args, context) => {
      context.navigateTo("home")
    },
  },
  {
    name: "writing",
    aliases: [],
    description: "Go to the writing (blog) page",
    run: (_args, context) => {
      context.navigateTo("writing")
    },
  },
  {
    name: "projects",
    aliases: ["p"],
    description: "Go to the projects page",
    run: (_args, context) => {
      context.navigateTo("projects")
    },
  },
  {
    name: "resume",
    aliases: [],
    description: "Go to the resume page",
    run: (_args, context) => {
      context.navigateTo("resume")
    },
  },
  {
    name: "theme",
    aliases: [],
    description: `Set the theme (${THEME_CYCLE_ORDER.join("|")})`,
    run: (args, context) => {
      const requested = args.trim()
      if (!THEME_CYCLE_ORDER.includes(requested)) return false

      context.setTheme(requested)
      return true
    },
  },
  {
    name: "help",
    aliases: [],
    description: "Open the keyboard bindings guide",
    run: (_args, context) => {
      context.openGuideDialog()
    },
  },
]

// parseCommand(input) -> { name, args }. First whitespace-delimited token is the
// canonical/alias name; the remainder is a raw, untouched args string -- command
// handlers parse their own args (e.g. `:theme` just trims it). An empty/whitespace-only
// input parses to an empty name, which the controller treats as nothing-to-run rather
// than an "unrecognized command" (there's nothing to be unrecognized).
export function parseCommand(input) {
  const trimmed = (input || "").trim()

  if (!trimmed) return { name: "", args: "" }

  const spaceIndex = trimmed.indexOf(" ")
  if (spaceIndex === -1) return { name: trimmed, args: "" }

  return { name: trimmed.slice(0, spaceIndex), args: trimmed.slice(spaceIndex + 1).trim() }
}

// formatCommandInvocation(command) -> ":name" or ":name (:alias1, :alias2)" (Increment 6,
// spec R10). The `?` guide overlay renders the COMMAND registry's v1 list directly from
// COMMAND_REGISTRY (keyboard_nav_controller.js#renderGuideCommandList) rather than a
// hand-duplicated copy of this same list in ERB -- this is the one small piece of pure
// formatting logic that glue needs, kept here (not in the controller) so it stays a
// DOM-free, unit-testable function like every other helper in this module.
export function formatCommandInvocation(command) {
  const aliases = command.aliases || []
  if (aliases.length === 0) return `:${command.name}`

  return `:${command.name} (${aliases.map((alias) => `:${alias}`).join(", ")})`
}

// findCommand(name, registry) -> the single matching entry, or null. Lookup order
// (spec R6): exact name/alias match first; otherwise a name-prefix match, but only if
// exactly one entry's name starts with it (an "unambiguous prefix" -- two+ matches is
// treated the same as no match, since Enter must invoke one specific command, never
// guess between several).
// willCommandApply(command, args) -> whether run() would succeed without side effects.
// Used by commitCommand() to reject bad input before exitToNormal(), since only `:theme`
// can return false today -- every other v1 command always applies once found.
export function willCommandApply(command, args) {
  if (command.name === "theme") {
    return THEME_CYCLE_ORDER.includes(args.trim())
  }

  return true
}

export function findCommand(name, registry) {
  const query = (name || "").trim().toLowerCase()
  if (!query) return null

  const exact = registry.find(
    (command) => command.name.toLowerCase() === query || (command.aliases || []).some((alias) => alias.toLowerCase() === query)
  )
  if (exact) return exact

  const prefixMatches = registry.filter((command) => command.name.toLowerCase().startsWith(query))
  return prefixMatches.length === 1 ? prefixMatches[0] : null
}

const RANK_EXACT_NAME = 0
const RANK_EXACT_ALIAS = 1
const RANK_NAME_PREFIX = 2
const RANK_SUBSTRING = 3

function rankOf(query, command) {
  const name = command.name.toLowerCase()
  const aliases = (command.aliases || []).map((alias) => alias.toLowerCase())

  if (name === query) return RANK_EXACT_NAME
  if (aliases.includes(query)) return RANK_EXACT_ALIAS
  if (name.startsWith(query)) return RANK_NAME_PREFIX
  if (name.includes(query) || aliases.some((alias) => alias.includes(query))) return RANK_SUBSTRING

  return null
}

// rankCommands(query, registry) -> registry entries matching `query`, ordered exact
// name > exact alias > name-prefix > substring (mirrors rankSearchResults' own ranking
// discipline, spec R7). An empty/whitespace-only query returns the full registry
// unranked (nothing typed yet -- nothing to rank against), matching parseCommand's own
// "empty name" convention.
export function rankCommands(query, registry) {
  const trimmed = (query || "").trim().toLowerCase()
  if (!trimmed) return registry.slice()

  return registry
    .map((command) => ({ command, rank: rankOf(trimmed, command) }))
    .filter((entry) => entry.rank !== null)
    .sort((a, b) => a.rank - b.rank)
    .map((entry) => entry.command)
}
