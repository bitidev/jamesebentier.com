// SEARCH mode's content index (spec R7, architecture plan Decision 3): a lazily-fetched,
// tab-session-cached JSON array of { title, url, excerpt, tags, type } items (R9), plus
// the pure substring/title>tag>excerpt ranking over it. rankSearchResults has zero
// DOM/fetch access (Decision 1's testability seam, mirrors commands.js' rankCommands);
// fetchSearchIndex is the thin fetch/cache wrapper named in the architecture plan's
// file-layout table.
//
// The cache lives at MODULE scope, deliberately not on the keyboard-nav controller
// instance: standard Turbo Drive visits disconnect/reconnect that controller on every
// navigation (see keyboard_nav_controller.js's own Turbo lifecycle note), so a
// per-instance cache would be wiped on every navigation -- contradicting spec R7's "cached
// for the rest of the tab session ... never re-fetched on a second `/` open in the same
// tab session." Turbo does NOT reload the page or re-evaluate this module on same-origin
// visits, so a module-level variable is what actually delivers "tab session" persistence
// across Turbo-driven navigations, not just within one page's lifetime.
let cachedIndexPromise = null

export const SEARCH_INDEX_URL = "/search-index.json"

// fetchImpl is injectable (defaults to the global fetch) purely for testability --
// mirrors resolveNavTarget's injectable `root` parameter (Decision 1/§10's seam).
export function fetchSearchIndex(fetchImpl = fetch) {
  if (!cachedIndexPromise) {
    cachedIndexPromise = fetchImpl(SEARCH_INDEX_URL).then((response) => response.json())
  }

  return cachedIndexPromise
}

// Test-only escape hatch: resets the module-level cache so one test's fetch mock never
// leaks into the next. Never called from production code.
export function resetSearchIndexCacheForTests() {
  cachedIndexPromise = null
}

const RANK_TITLE = 0
const RANK_TAG = 1
const RANK_EXCERPT = 2

function rankOf(query, item) {
  const title = (item.title || "").toLowerCase()
  const tags = (item.tags || []).map((tag) => tag.toLowerCase())
  const excerpt = (item.excerpt || "").toLowerCase()

  if (title.includes(query)) return RANK_TITLE
  if (tags.some((tag) => tag.includes(query))) return RANK_TAG
  if (excerpt.includes(query)) return RANK_EXCERPT

  return null
}

// rankSearchResults(query, index) -> index items matching `query`, ordered title-match >
// tag-match > excerpt-match (substring only -- no fuzzy-match library, per Decision 3's
// explicit v1 simplification). An empty/whitespace-only query returns the full index
// unranked (nothing typed yet), mirroring rankCommands' own empty-query convention --
// SEARCH shows its full result set immediately once the index has loaded, narrowing as
// the visitor types.
export function rankSearchResults(query, index) {
  const trimmed = (query || "").trim().toLowerCase()
  if (!trimmed) return index.slice()

  return index
    .map((item) => ({ item, rank: rankOf(trimmed, item) }))
    .filter((entry) => entry.rank !== null)
    .sort((a, b) => a.rank - b.rank)
    .map((entry) => entry.item)
}
