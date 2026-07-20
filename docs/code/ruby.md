# Ruby Best Practices

This checklist covers Ruby-specific best practices for the core language. For the Rails
framework, see [Rails Best Practices](rails.md), which builds on this file.

**See also:** [Universal Programming Best Practices](universal.md) - language-agnostic principles that apply to all code.

## Style and Naming (Ruby-Specific)

Beyond the [universal code clarity practices](universal.md#code-clarity-and-readability):

- [ ] Community style guide / RuboCop conventions followed (2-space indent, no tabs)
- [ ] `snake_case` for methods and variables, `CamelCase` for classes/modules, `SCREAMING_SNAKE_CASE` for constants
- [ ] Predicate methods end in `?` (`empty?`, `valid?`); mutating/dangerous methods end in `!` (`save!`, `gsub!`)
- [ ] A `!` method exists only alongside a safer non-`!` counterpart (don't add `!` just for emphasis)
- [ ] Methods kept short; favor expressing intent through well-named private methods
- [ ] Implicit returns used idiomatically (no needless trailing `return`)
- [ ] Endless (one-line) method definitions (`def area = width * height`, Ruby 3.0+) reserved for trivial single-expression methods; anything with a multi-line body uses the standard `def...end`

## Nil Safety and Truthiness

- [ ] Only `nil` and `false` are falsy — guard accordingly (`0`, `""`, `[]` are all truthy)
- [ ] Safe navigation operator `&.` used for possibly-nil receivers instead of nested `nil?` checks
- [ ] `Hash#fetch` used (with default or block) where a missing key is a real error, instead of `[]` returning `nil`
- [ ] `Hash#dig` / `Array#dig` used for nested access that may be absent
- [ ] `Array()` / `Array.wrap` (Rails) used to normalize nil-or-scalar-or-array inputs
- [ ] No silent `nil` propagation masking bugs (fail fast where a value is required)

## Blocks, Procs, and Lambdas

- [ ] Single-line blocks use `{ }`; multi-line blocks use `do...end`
- [ ] Blocks passed to enumerable methods rather than manual index loops
- [ ] `yield` / `block_given?` used for simple block APIs; explicit `&block` only when the block is stored or forwarded
- [ ] Lambda vs proc semantics understood (lambdas check arity and `return` locally; procs do not)
- [ ] Symbol-to-proc shorthand (`map(&:name)`) used for simple method calls
- [ ] `it` implicit block parameter (Ruby 3.4+) used only for a single, trivial argument (`map { it.name }`); prefer `&:name` or a named parameter where it reads clearer, and never mix `it` with the numbered params (`_1`, `_2`) in the same block
- [ ] Resource-managing methods accept a block and guarantee cleanup (`File.open(path) { |f| ... }`)

## Enumerable and Collections

- [ ] The right `Enumerable` method chosen for intent (`map`, `select`/`reject`, `find`, `each_with_object`, `reduce`, `group_by`, `partition`, `flat_map`, `tally`)
- [ ] No manual accumulator loops where an `Enumerable` method expresses it clearly
- [ ] `each_with_object` preferred over `reduce` when building a mutable collection
- [ ] Lazy enumerators (`.lazy`) used for large or infinite sequences to avoid intermediate arrays
- [ ] `Set` used when membership/uniqueness is the point, not `Array#include?` in a loop (O(n) per lookup)
- [ ] Frozen string literals enabled (`# frozen_string_literal: true`) to avoid needless allocations — in brownfield code, verify the magic comment **per file**; don't assume it's applied universally (through Ruby 3.4 it is still opt-in, not a global default), and don't mutate a literal that a given file has frozen

## Exception Handling (Ruby-Specific)

Beyond the [universal error handling practices](universal.md#error-handling):

- [ ] `rescue` targets specific subclasses, never a bare `rescue` (which catches `StandardError`) without intent
- [ ] `Exception` is never rescued directly (it traps `SignalException`, `NoMemoryError`, etc.)
- [ ] Custom errors inherit from `StandardError` (not `Exception`) and form a small domain hierarchy
- [ ] `ensure` used for cleanup that must always run
- [ ] `raise` used to re-raise; original backtrace/cause preserved (don't swallow with `rescue => e; nil`)
- [ ] Exceptions used for exceptional cases, not control flow (`catch`/`throw` only for rare non-local exits)
- [ ] `retry` bounded with a counter; never an unconditional `retry`

## Objects, Modules, and Mixins

- [ ] Composition / mixins (`include`, `extend`, `prepend`) preferred over deep inheritance
- [ ] `Comparable` / `Enumerable` mixed in (with `<=>` / `each`) instead of reimplementing comparison or iteration
- [ ] Modules used as namespaces and for shared behavior; god-modules avoided
- [ ] `attr_reader`/`attr_accessor` used instead of hand-written trivial accessors
- [ ] Public interface kept minimal; helpers marked `private`/`protected`
- [ ] `Data.define` (Ruby 3.2+) preferred for immutable value objects, `Struct` where mutability or `Enumerable`/`[]` behavior is genuinely needed — either instead of a bespoke class (`Point = Data.define(:x, :y)`; copy-with-changes via `#with`)
- [ ] Keyword arguments used for methods with several optional parameters (clarity over positional/`Hash`)
- [ ] Duck typing favored; explicit `is_a?`/`respond_to?` checks used sparingly and deliberately

## Metaprogramming

- [ ] Metaprogramming (`define_method`, `method_missing`, `send`) used only when it clearly reduces real duplication
- [ ] `method_missing` always paired with a matching `respond_to_missing?`
- [ ] `public_send` preferred over `send` when the receiver/method may be externally influenced (respects privacy)
- [ ] Dynamically defined behavior remains greppable/discoverable (documented or constrained to a known set)
- [ ] No monkey-patching of core/stdlib classes in library code; use refinements (`using`) if truly needed

## Dependencies and Tooling

- [ ] Dependencies managed with Bundler; `Gemfile.lock` committed for applications
- [ ] Gem version constraints intentional (pessimistic `~>` where appropriate)
- [ ] RuboCop (and RuboCop extensions) configured and passing in CI
- [ ] Ruby version pinned (`.ruby-version` / `Gemfile`) and consistent across environments
- [ ] Standard library reached for before adding a gem (`set`, `json`, `securerandom`, `forwardable`, etc.)
- [ ] Ruby 3.4 default-gem removals recognized — `csv`, `reline`, `mutex_m`, `bigdecimal`, and `benchmark` are no longer *default* gems, so they now appear as explicit (often "LOCKED"-commented) `Gemfile`/`Gemfile.lock` entries. These are stdlib libraries that moved to bundled gems, **not** third-party dependencies to prune; a "why are stdlib libs in the Gemfile?" reading is a false alarm. Add the matching `gem` line when a `require` of one starts warning under 3.4+

## Concurrency

- [ ] GIL/GVL implications understood (threads help I/O-bound work, not CPU-bound on MRI)
- [ ] Shared mutable state across threads protected (`Mutex`, `Queue`, or avoided via immutability)
- [ ] Background/CPU-bound work offloaded to a job system or processes rather than ad-hoc threads
- [ ] Frozen, immutable data shared across threads where possible
- [ ] Background-processing DSLs recognized as async even without an explicit enqueue call — `handle_asynchronously`/`delay` (delayed_job), `perform_async` (Sidekiq), and similar move a method off the request path silently. Keep async boundaries explicit and cross-reference the [Background Jobs and Async](rails.md#background-jobs-and-async) practices in Rails apps

## Testing (Ruby-Specific)

Beyond the [universal testing practices](universal.md#testing):

- [ ] A single framework chosen and used consistently (RSpec or Minitest), matching project convention
- [ ] Tests describe behavior, not implementation; example/test names read as sentences
- [ ] Real objects or lightweight fakes preferred over heavy mocking (see [universal testing](universal.md#testing))
- [ ] `let`/`before` (RSpec) or `setup` (Minitest) keep setup minimal and intention-revealing
- [ ] Test data built with factories or plain builders, not large shared fixtures with hidden coupling
- [ ] Edge cases for `nil`, empty collections, and error paths covered
