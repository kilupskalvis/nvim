# Diffview file history: yield to the editor while parsing a commit

## Problem

`:DiffviewFileHistory` streams one `git log --numstat --raw` job and parses it
on the file-history worker coroutine. The worker yields to the editor only
between commits. Inside one commit `parse_fh_data` builds a `FileEntry` per
changed file without yielding, so a commit touching tens of thousands of files
freezes Neovim for the whole parse.

Measured on munin-ai (392 commits, 96k file entries, one commit with 28,817):

| | before lazy layouts | after lazy layouts (89b5a59) |
|---|---|---|
| load complete | 53-65s | 16-23s |
| main loop blocked | 44s | 9-13s |
| longest stall | 13.4s | 3.0-3.5s |

The remaining stalls are the per-file loop in `parse_fh_data`.

## Design

Add a periodic yield inside the `FileEntry.with_layout` override that already
exists in `lua/plugins/diffview.lua`. `parse_fh_data` calls it once per file,
on the worker coroutine, so suspending there suspends the parse. No further
upstream code is copied.

Rules:

- Yield at most every 16ms (one frame), tracked with `uv.hrtime()`.
- Yield through a 1ms `vim.defer_fn` timer wrapped with `async.wrap`.
  Rejected alternatives, both tested: `async.scheduler()` returns immediately
  when the API is available; `async.schedule_now()` (plain `vim.schedule`)
  did suspend 694 times but the longest stall stayed at 3.8s, because Neovim
  drains the entire scheduled-event queue before returning to the event loop,
  so chained schedules never let input or redraw through. A timer forces a
  full loop iteration, and `defer_fn` resumes via `vim.schedule`, outside the
  fast-event context.
- Only when `coroutine.running()` is non-nil. On the main thread `await`
  falls into a busy-wait `toplevel_await`.
- Only for history entries, identified by `opt.commit ~= nil`. `parse_fh_data`
  passes the `GitCommit`; `tracked_files` for DiffView passes none.
  `DiffView.update_files` compares old and new entry lists after building
  them, and suspending inside that build would let a second debounced update
  interleave.

While suspended: git keeps writing into the stream buffer, the panel is not
touched until the commit's `LogEntry` is pushed, and pushing to a closed
stream is a no-op, so closing the view mid-parse is safe.

## Non-goals

- `structure_fh_data` and the job line splitter run in the stdout callback,
  outside the coroutine, and cannot yield. Estimated 100-300ms on the largest
  commit. Left alone; replacing them means copying upstream internals.
- Total load time. Unchanged; this only redistributes the work.

## Verification

Ad hoc headless scripts in gitignored `.repro/`, deleted afterwards:

1. Profiler in munin-ai: 10ms timer measuring main-loop gaps during load,
   count of layouts built, open three entries, close.
   Pass: longest gap under 300ms, layouts built during load still 2, entries
   open and diff windows appear, close under 1s, no errors.
2. Seven cleanup scenarios (basic, preexisting, unrelated, gf, overlap, gd,
   moddel) on a throwaway repo. Pass: all PASS.

## Rollback

Delete the yield block at the top of the `with_layout` override. Nothing else
depends on it.

## Result (2026-09-03)

munin-ai, headless, two runs each:

| | before | after |
|---|---|---|
| load complete | 16-23s | 14.5-15.3s |
| main loop blocked | 9-13s | 0.6-0.7s |
| longest stall | 3.0-4.1s | 168-227ms |
| layouts built during load | 2 | 2 |

Opening three entries and closing the view behaved as before. All seven
cleanup scenarios pass. The remaining stalls are the stdout callback
(`structure_fh_data`, measured 14ms max) plus panel render, and rare
larger gaps that were not attributed; all under the 300ms target.
