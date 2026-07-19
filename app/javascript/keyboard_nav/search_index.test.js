import { afterEach, describe, expect, it, vi } from "vitest"
import { SEARCH_INDEX_URL, fetchSearchIndex, rankSearchResults, resetSearchIndexCacheForTests } from "./search_index"

const fakeIndex = [
  { title: "Hosting on AWS S3", url: "/blog/hosting-on-aws-s3", excerpt: "A guide to static hosting", tags: ["aws", "cloud"], type: "post" },
  { title: "Learning Vim Motions", url: "/blog/learning-vim-motions", excerpt: "hjkl and beyond", tags: ["vim", "keyboard"], type: "post" },
  { title: "Vimium Clone", url: "/projects/vimium-clone", excerpt: "A hint-jump browser extension", tags: [], type: "project" },
]

describe("rankSearchResults", () => {
  it("returns the full index, unranked, for an empty/whitespace-only query", () => {
    expect(rankSearchResults("", fakeIndex)).toEqual(fakeIndex)
    expect(rankSearchResults("   ", fakeIndex)).toEqual(fakeIndex)
  })

  it("ranks a title match above a tag match", () => {
    const index = [
      { title: "Something else entirely", url: "/a", excerpt: "", tags: ["aws"], type: "post" },
      { title: "AWS Deployment Notes", url: "/b", excerpt: "", tags: [], type: "post" },
    ]

    expect(rankSearchResults("aws", index)).toEqual([index[1], index[0]])
  })

  it("ranks a tag match above an excerpt match", () => {
    const index = [
      { title: "Untitled", url: "/a", excerpt: "mentions vim in passing", tags: [], type: "post" },
      { title: "Untitled Two", url: "/b", excerpt: "", tags: ["vim"], type: "post" },
    ]

    expect(rankSearchResults("vim", index)).toEqual([index[1], index[0]])
  })

  it("matches title/tag/excerpt case-insensitively", () => {
    expect(rankSearchResults("VIM", fakeIndex)).toEqual([fakeIndex[1], fakeIndex[2]])
  })

  it("excludes items that match nothing", () => {
    expect(rankSearchResults("zzz-no-such-content-zzz", fakeIndex)).toEqual([])
  })

  it("finds a project by its title exactly like a post", () => {
    expect(rankSearchResults("vimium", fakeIndex)).toEqual([fakeIndex[2]])
  })

  it("preserves relative order (stable sort) among equally-ranked matches", () => {
    expect(rankSearchResults("vim", fakeIndex)).toEqual([fakeIndex[1], fakeIndex[2]])
  })
})

describe("fetchSearchIndex", () => {
  afterEach(() => {
    resetSearchIndexCacheForTests()
  })

  it("fetches SEARCH_INDEX_URL and resolves with the parsed JSON body", async () => {
    const fetchImpl = vi.fn().mockResolvedValue({ json: () => Promise.resolve(fakeIndex) })

    const result = await fetchSearchIndex(fetchImpl)

    expect(fetchImpl).toHaveBeenCalledWith(SEARCH_INDEX_URL)
    expect(result).toEqual(fakeIndex)
  })

  it("caches the first fetch -- a second call never invokes fetchImpl again", async () => {
    const fetchImpl = vi.fn().mockResolvedValue({ json: () => Promise.resolve(fakeIndex) })

    await fetchSearchIndex(fetchImpl)
    await fetchSearchIndex(fetchImpl)
    await fetchSearchIndex(fetchImpl)

    expect(fetchImpl).toHaveBeenCalledTimes(1)
  })

  it("resetSearchIndexCacheForTests clears the cache so the next call re-fetches", async () => {
    const fetchImpl = vi.fn().mockResolvedValue({ json: () => Promise.resolve(fakeIndex) })

    await fetchSearchIndex(fetchImpl)
    resetSearchIndexCacheForTests()
    await fetchSearchIndex(fetchImpl)

    expect(fetchImpl).toHaveBeenCalledTimes(2)
  })
})
