import { describe, expect, it, vi } from "vitest"
import { COMMAND_REGISTRY, findCommand, formatCommandInvocation, parseCommand, rankCommands, willCommandApply } from "./commands"

describe("parseCommand", () => {
  it("parses a bare name with no args", () => {
    expect(parseCommand("projects")).toEqual({ name: "projects", args: "" })
  })

  it("splits the first whitespace-delimited token as the name, the rest as raw args", () => {
    expect(parseCommand("theme dracula")).toEqual({ name: "theme", args: "dracula" })
  })

  it("trims surrounding whitespace from both the input and the args remainder", () => {
    expect(parseCommand("  theme   dracula  ")).toEqual({ name: "theme", args: "dracula" })
  })

  it("preserves internal whitespace within the args string itself", () => {
    expect(parseCommand("stats views --last 7d")).toEqual({ name: "stats", args: "views --last 7d" })
  })

  it("parses an empty/whitespace-only input to an empty name and empty args", () => {
    expect(parseCommand("")).toEqual({ name: "", args: "" })
    expect(parseCommand("   ")).toEqual({ name: "", args: "" })
  })
})

// A small fake registry (not COMMAND_REGISTRY) so findCommand/rankCommands' ranking
// logic is exercised independently of the real v1 command set -- these two functions'
// contracts don't depend on what's actually registered.
const fakeRegistry = [
  { name: "projects", aliases: ["p"], description: "Go to the projects page", run: vi.fn() },
  { name: "profile", aliases: [], description: "Go to the profile page", run: vi.fn() },
  { name: "home", aliases: ["h"], description: "Go to the home page", run: vi.fn() },
]

describe("findCommand", () => {
  it("finds an exact name match", () => {
    expect(findCommand("home", fakeRegistry)).toBe(fakeRegistry[2])
  })

  it("finds an exact alias match", () => {
    expect(findCommand("p", fakeRegistry)).toBe(fakeRegistry[0])
  })

  it("is case-insensitive", () => {
    expect(findCommand("HOME", fakeRegistry)).toBe(fakeRegistry[2])
  })

  it("resolves an unambiguous name prefix", () => {
    expect(findCommand("hom", fakeRegistry)).toBe(fakeRegistry[2])
  })

  it("returns null for an ambiguous prefix matching more than one command name", () => {
    expect(findCommand("pro", fakeRegistry)).toBeNull()
  })

  it("returns null for a name that matches nothing", () => {
    expect(findCommand("bogus", fakeRegistry)).toBeNull()
  })

  it("returns null for an empty/whitespace-only name", () => {
    expect(findCommand("", fakeRegistry)).toBeNull()
    expect(findCommand("   ", fakeRegistry)).toBeNull()
  })
})

describe("rankCommands", () => {
  it("ranks an exact name match above an alias/prefix/substring match", () => {
    const registry = [
      { name: "home", aliases: [], description: "", run: vi.fn() },
      { name: "homepage", aliases: [], description: "", run: vi.fn() },
    ]

    expect(rankCommands("home", registry)).toEqual([registry[0], registry[1]])
  })

  it("ranks an exact alias match above a name-prefix match", () => {
    const registry = [
      { name: "projects", aliases: [], description: "", run: vi.fn() },
      { name: "profile", aliases: ["pro"], description: "", run: vi.fn() },
    ]

    expect(rankCommands("pro", registry)).toEqual([registry[1], registry[0]])
  })

  it("ranks a name-prefix match above a bare substring match", () => {
    const registry = [
      { name: "atheme", aliases: [], description: "", run: vi.fn() }, // "theme" substring, not prefix
      { name: "theme", aliases: [], description: "", run: vi.fn() },
    ]

    expect(rankCommands("theme", registry)).toEqual([registry[1], registry[0]])
  })

  it("excludes commands that don't match at all", () => {
    expect(rankCommands("zzz", fakeRegistry)).toEqual([])
  })

  it("returns the full registry, unranked, for an empty/whitespace-only query", () => {
    expect(rankCommands("", fakeRegistry)).toEqual(fakeRegistry)
    expect(rankCommands("   ", fakeRegistry)).toEqual(fakeRegistry)
  })

  it("is case-insensitive", () => {
    expect(rankCommands("HOME", fakeRegistry)).toEqual([fakeRegistry[2]])
  })
})

describe("formatCommandInvocation (Increment 6, spec R10 -- ? guide overlay)", () => {
  it("formats a command with no aliases as a bare :name", () => {
    expect(formatCommandInvocation({ name: "home", aliases: [] })).toBe(":home")
  })

  it("omits aliases entirely when the aliases array is absent", () => {
    expect(formatCommandInvocation({ name: "home" })).toBe(":home")
  })

  it("appends a single alias, itself colon-prefixed, in parens", () => {
    expect(formatCommandInvocation({ name: "projects", aliases: ["p"] })).toBe(":projects (:p)")
  })

  it("comma-joins multiple aliases", () => {
    expect(formatCommandInvocation({ name: "home", aliases: ["h", "hm"] })).toBe(":home (:h, :hm)")
  })
})

describe("COMMAND_REGISTRY (v1 command set, spec R6)", () => {
  it("registers exactly the v1 nav/theme/help commands", () => {
    expect(COMMAND_REGISTRY.map((command) => command.name).sort()).toEqual(
      ["help", "home", "projects", "resume", "theme", "writing"].sort()
    )
  })

  it.each(["home", "writing", "projects", "resume"])("%s navigates via context.navigateTo with its own name", (name) => {
    const context = { navigateTo: vi.fn(), setTheme: vi.fn(), openGuideDialog: vi.fn() }

    findCommand(name, COMMAND_REGISTRY).run("", context)

    expect(context.navigateTo).toHaveBeenCalledWith(name)
  })

  it("help opens the guide dialog via context.openGuideDialog", () => {
    const context = { navigateTo: vi.fn(), setTheme: vi.fn(), openGuideDialog: vi.fn() }

    findCommand("help", COMMAND_REGISTRY).run("", context)

    expect(context.openGuideDialog).toHaveBeenCalled()
  })

  it("theme sets a recognized theme via context.setTheme and returns a non-false result", () => {
    const context = { navigateTo: vi.fn(), setTheme: vi.fn(), openGuideDialog: vi.fn() }

    const result = findCommand("theme", COMMAND_REGISTRY).run("dracula", context)

    expect(context.setTheme).toHaveBeenCalledWith("dracula")
    expect(result).not.toBe(false)
  })

  it("theme returns false and never calls context.setTheme for an unrecognized theme name", () => {
    const context = { navigateTo: vi.fn(), setTheme: vi.fn(), openGuideDialog: vi.fn() }

    const result = findCommand("theme", COMMAND_REGISTRY).run("not-a-real-theme", context)

    expect(context.setTheme).not.toHaveBeenCalled()
    expect(result).toBe(false)
  })
})

describe("willCommandApply", () => {
  it("accepts every v1 command except theme with bad args", () => {
    const theme = findCommand("theme", COMMAND_REGISTRY)

    expect(willCommandApply(findCommand("help", COMMAND_REGISTRY), "")).toBe(true)
    expect(willCommandApply(theme, "dracula")).toBe(true)
    expect(willCommandApply(theme, "not-a-real-theme")).toBe(false)
  })
})
