// Single source-of-truth nav-target lookup (architecture plan Decision 6). The site's
// canonical URLs are declared exactly once, server-side, via Rails route helpers in
// _header.html.erb (root_url/posts_url/projects_url/resume_path) -- this helper never
// holds a literal path string. Both the `g`-prefix sequence handler
// (keyboard_nav_controller.js) and the COMMAND registry's navigate commands (a later
// increment) call this one function and `.click()` the result; a key with no matching
// `data-nav-target` (e.g. "lab", which has no /lab route yet) resolves to `null` -- a
// documented no-op, not a broken link.
//
// `root` defaults to `document` but is injectable so this stays testable with a plain
// fake object exposing `querySelector` -- no jsdom/DOM environment required for the
// unit tests (Decision 1/§10's testability seam).
export function resolveNavTarget(key, root = document) {
  return root.querySelector(`[data-nav-target="${key}"]`) || null
}
