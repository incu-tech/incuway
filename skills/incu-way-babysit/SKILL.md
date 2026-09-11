---
name: incu-way-babysit
version: 0.1.0
description: Watches an existing, already-open PR (yours) until it's ready to merge — new bot (CodeRabbit, etc.) or human reviewer comments, unresolved review threads, and CI checks — and drafts a fix on the PR's branch when something is actionable. Self-contained single-invocation watch, polling runs in a background script so idle cycles cost no LLM turns — no `/loop` needed. Trigger on "babysit this PR", "watch this PR until it's mergeable", "keep an eye on PR #N", or `/incu-way-babysit <pr> <repo>`. Do not trigger for reviewing a PR yourself, opening/merging a PR, or watching a PR you don't own.
---

# PR Babysitting

Single-invocation, self-contained watch over one PR — no `/loop`, no repeated
slash commands, and no agentic poll-sleep-repeat loop burning a turn on every
cycle. All polling (comments, reviews, unresolved review threads, CI checks)
happens inside one plain bash script run through the `Monitor` tool: it costs
zero LLM tokens while idle and only produces a chat message — one real turn —
the moment something actually changes. That's the fix for the token-burn
pattern in poll-in-the-conversation designs (e.g. thedotmack's `babysit`
skill, which re-runs `gh pr view` as literal agent steps every 30-60s).

This is a monitor, not a document-gated workflow — it keeps no
`.ways/state.json` (nothing here is a gated work item) and, unlike the other
flows, never creates a new branch — it attaches to a PR's branch that
already exists.

**Deviation from thedotmack's `babysit`:** that skill fixes issues, commits,
and pushes autonomously inside the loop. This skill never does — it drafts a
fix and stops for approval, then hands commit/push to `incu-way-prepare-pr`.
That's this repo's no-auto-commit convention, not a missing feature.

## Invocation

```
/incu-way-babysit <pr-number> <owner/repo>
```

`<owner/repo>` is optional — if omitted, resolve it from the current
checkout's remote. `<pr-number>` is optional too — if omitted, resolve it
from the current branch via `gh pr view --json number`.

## Phase 0 — Resolve the PR

```bash
gh pr view <pr-number> --repo <owner/repo> --json number,headRefName,baseRefName,url,author,state
```

If `state` isn't `OPEN`, say so and stop — nothing to babysit.

If `author.login` isn't the current user (`gh api user -q .login`), tell the
user and ask for confirmation before continuing — this skill is meant for
your own PRs.

## Isolation setup

Before touching the working tree, ask:

> Do you want me to work in the PR's branch in the current checkout, or check
> it out into a separate git worktree?

Use the user's answer exactly. Stop after asking; do not check anything out
until the user chooses.

If the current checkout has uncommitted changes, stop and ask before
switching branches or creating a worktree.

### Option A — Branch in current checkout
```bash
git fetch origin <headRefName>
git checkout <headRefName>
git pull --ff-only
```

### Option B — Separate worktree
```bash
git fetch origin <headRefName>
mkdir -p .worktrees
git worktree add .worktrees/babysit-<pr-number> <headRefName>
```
All drafted fixes happen inside `.worktrees/babysit-<pr-number>` if this
option is chosen.

(Unlike the gated flows' isolation step, there's no `git switch develop` here
— the PR's branch already exists, it's just being checked out.)

## Phase 1 — Start the watch

Everything below runs as **one** `Monitor` invocation
(`description: "PR #<pr> status"`, `persistent: true` — it needs to outlive
the default 5-minute timeout; it exits on its own, or `TaskStop` ends it
early). Each `echo` line is one notification; the loop between them costs
nothing.

```bash
REPO=<owner/repo>
PR=<pr-number>
ME=$(gh api user -q .login)
owner=${REPO%%/*}
repo=${REPO##*/}
STATE=$(mktemp -d)
: > "$STATE/checks"    # "<name>\t<conclusion>" already reported
: > "$STATE/threads"   # thread ids already reported as unresolved
since=$(date -u +%Y-%m-%dT%H:%M:%SZ)
last_activity=$(date +%s)

thread_query='query($owner:String!,$repo:String!,$number:Int!,$cursor:String){repository(owner:$owner,name:$repo){pullRequest(number:$number){reviewThreads(first:100,after:$cursor){pageInfo{hasNextPage endCursor}nodes{id,isResolved,path,line,comments(last:1){nodes{author{login},body}}}}}}}'

fetch_unresolved_threads() {
  cursor_args=()
  while :; do
    page=$(gh api graphql -f query="$thread_query" -f owner="$owner" -f repo="$repo" -F number="$PR" "${cursor_args[@]}" 2>/dev/null) || return
    jq -r '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved==false) | [.id,.path,(.line//""),(.comments.nodes[-1].author.login//""),(.comments.nodes[-1].body|gsub("\n";" ")|.[0:160])] | @tsv' <<<"$page"
    jq -e '.data.repository.pullRequest.reviewThreads.pageInfo.hasNextPage' >/dev/null <<<"$page" || break
    cursor=$(jq -r '.data.repository.pullRequest.reviewThreads.pageInfo.endCursor' <<<"$page")
    cursor_args=(-f cursor="$cursor")
  done
}

while true; do
  now_iso=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  activity=0

  # new comments / reviews
  new=$( {
    gh api "repos/$REPO/issues/$PR/comments?since=$since" \
      --jq ".[] | select(.user.login != \"$ME\") | \"comment #\(.id) by \(.user.login): \(.body|.[0:200])\"" 2>/dev/null || true
    gh api "repos/$REPO/pulls/$PR/comments?since=$since" \
      --jq ".[] | select(.user.login != \"$ME\") | \"review-comment #\(.id) by \(.user.login) on \(.path):\(.line): \(.body|.[0:200])\"" 2>/dev/null || true
    gh api "repos/$REPO/pulls/$PR/reviews" \
      --jq ".[] | select(.user.login != \"$ME\" and .submitted_at > \"$since\") | \"review #\(.id) by \(.user.login) (\(.state)): \(.body|.[0:200])\"" 2>/dev/null || true
  } )
  if [ -n "$new" ]; then echo "$new"; activity=1; fi

  # CI checks that just reached a terminal state
  pr_json=$(gh pr view "$PR" --repo "$REPO" --json mergeable,mergeStateStatus,reviewDecision,statusCheckRollup 2>/dev/null)
  while IFS=$'\t' read -r name conclusion; do
    [ -z "$name" ] && continue
    case "$conclusion" in ""|PENDING|IN_PROGRESS|QUEUED) continue ;; esac
    if ! grep -qF "$(printf '%s\t%s' "$name" "$conclusion")" "$STATE/checks"; then
      echo "check $name finished: $conclusion"
      printf '%s\t%s\n' "$name" "$conclusion" >> "$STATE/checks"
      activity=1
    fi
  done < <(jq -r '.statusCheckRollup[]? | [(.name // .context), (.conclusion // .state // "")] | @tsv' <<<"$pr_json")

  # unresolved review threads not seen before
  while IFS=$'\t' read -r id path line author body; do
    [ -z "$id" ] && continue
    if ! grep -qF "$id" "$STATE/threads"; then
      echo "unresolved thread on $path:$line by $author: $body"
      echo "$id" >> "$STATE/threads"
      activity=1
    fi
  done < <(fetch_unresolved_threads)

  [ "$activity" = "1" ] && last_activity=$(date +%s)
  since="$now_iso"

  pending=$(jq -r '[.statusCheckRollup[]? | (.conclusion // .state // "PENDING")] | map(select(.=="" or .=="PENDING" or .=="IN_PROGRESS" or .=="QUEUED")) | length' <<<"$pr_json")
  review_decision=$(jq -r '.reviewDecision' <<<"$pr_json")
  unresolved_count=$(wc -l < "$STATE/threads")
  if [ "${pending:-1}" = "0" ] && [ "$review_decision" != "CHANGES_REQUESTED" ] && [ "$unresolved_count" -eq 0 ]; then
    echo "PR #$PR looks ready to merge: checks done, review decision $review_decision, no unresolved threads."
    break
  fi

  if [ $(( $(date +%s) - last_activity )) -ge 1800 ]; then
    echo "No new activity on PR #$PR in 30 minutes — stopping the watch."
    break
  fi
  sleep 60
done
```

## Phase 2 — On each notification

For every new comment/review-comment/review reported:

1. Read the full comment (`gh api repos/$REPO/issues/comments/{id}` or
   `.../pulls/comments/{id}`) and the file/line or diff context it refers to.
2. If it's actionable (a concrete code suggestion — including a fenced
   ` ```suggestion ` block, or a human reviewer's requested change with a
   clear ask): edit the file(s) in the working tree from the isolation step
   above. **Do not commit, push, resolve, or reply yet.**
3. If it isn't actionable (an approval, a question, an FYI): leave it — don't
   invent a fix for a comment that isn't asking for one.

For a `check ... finished: FAILURE` notification: read the check's log/output
and treat it the same as an actionable comment — draft a fix, don't push it.

For an `unresolved thread` notification: same triage as a review comment.

Then post one summary:

> "PR #{pr} — {N} new item(s). Drafted fixes for: {list}. Left as-is: {list, if any}.
> Review with `git diff`. Say the word and I'll run `incu-way-prepare-pr` to commit
> and push, reply to the addressed comments, and resolve their threads."

## Phase 3 — Applying: reply + resolve

Only after explicit approval, and only for items the user asked to be
addressed:

> "About to push via `incu-way-prepare-pr`, reply to comment(s) {ids}, and
> resolve thread(s) {ids}. Confirm before I do."

**Stop. Do not post replies, resolve threads, or push until the user
confirms.**

```bash
gh api repos/$REPO/issues/$PR/comments -f body="{reply}"           # general comment
gh api repos/$REPO/pulls/comments/{id}/replies -f body="{reply}"   # inline review comment
gh api graphql -f query='mutation($threadId:ID!){resolveReviewThread(input:{threadId:$threadId}){thread{id,isResolved}}}' -f threadId="{thread-id}"
```

Resolve a thread only after the fix addressing it is pushed — never resolve
on the strength of a local, unpushed draft.

## What NOT to do

- Never run `git add`, `git commit`, `git push`, or `gh pr create` from this
  skill — that's `incu-way-prepare-pr`'s job, and only on the user's explicit
  ask.
- Do not check out the PR branch over uncommitted local changes.
- Do not fabricate a fix for a comment/check/thread that isn't requesting one.
- Do not reply to a comment, resolve a thread, or push before the user
  confirms in Phase 3.
- Do not resolve a thread before its fix is actually pushed.
- Do not babysit a PR that isn't the user's without explicit confirmation.
- Do not poll from inside the conversation loop (repeated `gh pr view` +
  `sleep` as agent turns) — that's the token-burn pattern this skill exists
  to avoid. All polling belongs inside the one `Monitor` script.
