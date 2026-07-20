# Call-Site Wiring Verification

**Code-quality rule — subset-scoped.** Loaded by the code-quality agents (builder, test, planner, reviewer) through their own definitions, not by a universal set.

## Priority

**HIGH** — New code that is never called is worse than no code at all. It creates false confidence that a feature works.

## The Problem

When a new capability is added to a service or module, it is common for tests to verify the capability in isolation — calling the method directly with all required parameters. But the actual production call site may not pass those parameters, making the new code unreachable. The tests pass, the reviewer sees green, and the feature ships dead.

This is especially dangerous with optional parameters, dependency injection, and resolver/callback patterns where the new code is gated behind a null check (e.g., `if (resolver && ...)`).

## The Rule

**Every new code path must have at least one test that exercises it through the actual call chain — not just the unit in isolation.**

When you add a new method, parameter, or code branch to a service:

1. **Identify all production call sites** that invoke the method. Use grep/search — do not assume there is only one.
2. **Verify each call site passes the required arguments.** If a call site omits an optional parameter that gates your new code, your new code is dead at that call site.
3. **Write at least one integration-level test** that starts from the call site (or as close to it as possible) and verifies the new behavior is reachable end-to-end.
4. **Apply the "dead code" test**: If you removed the new code entirely, would any test fail? If not, you haven't tested the wiring — only the logic.

## Examples

### Bad: Unit test only

```typescript
// Tests the resolver directly — proves the algorithm works
it('resolves transitive path A -> B -> C', async () => {
  const path = await service.resolveTransitivePath('A', 'C', defA, resolver);
  expect(path).toEqual(['A', 'B', 'C']);
});
// But the call site never passes `resolver`, so this code is unreachable in production
```

### Good: Integration test through call site

```typescript
// Tests through the actual call chain — proves the feature is wired up
it('transitive delegation resolves when called from finalizeResponse', async () => {
  // Set up agents where A delegates to B, B delegates to C
  // Call the method that production actually calls
  const decision = await chatService.processInference(/* ... */);
  expect(decision.transitivePath).toEqual(['A', 'B', 'C']);
});
```

## Applies To

- **builder agent**: Must verify wiring when implementing new features
- **test agent**: Must verify call-site reachability when writing tests
- **reviewer agent**: Must check that new code paths are exercised through production call sites, not just in isolation

## Enforcement

During code review, the reviewer MUST check:
1. For every new method/parameter/branch: is there a test that reaches it through the production call path?
2. Are there multiple call sites? Are they all wired correctly?
3. Would deleting the new code cause a test failure?

If any answer is "no", the review is **MAJOR** — the feature is not verified as reachable.
