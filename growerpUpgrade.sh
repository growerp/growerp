#!/bin/bash
# Guided GrowERP release (growerpUpgrade.md, section Automated)
# Usage: ./growerpUpgrade.sh [-n|--dry-run] [command]   (no command: menu)
#
#   -n, --dry-run   walk through all steps and prompts, only show the workflows and
#                   the GitHub release instead of starting them
#
#   production review   the versions the stores approved (when a review exists):
#                       update production, release the approved store submissions
#   production staging  new release of what staging runs now (when no review exists):
#                       GitHub release, update production
#   review   new review: update staging from master, GitHub release, freeze for
#            review (when review is empty) and create the review branch (1.22) at the
#            frozen version, prepare, publish binary to stores and publish metadata
#            (opt) from that branch, merge it back into master (opt)
#   prepare  create store screenshots when screens changed since the last screenshots
#            run or its artifact (used by the Windows binary and publish metadata,
#            kept 7 days) expired
#   staging  update staging from master, or from the review branch for a fix of the
#            version in review (new version: patch, minor or major)
#   release  GitHub release of a version tag: Claude (claude -p) writes title and notes
#            from the commits in the form of the previous release, checked before publish
#   status   last run of every release workflow
#
# Dispatches the GitHub workflows with gh, waits for each run and stops on a failure.
# The workflows keep their own guards (freeze refuses while review is not empty,
# update production refuses source staging while store review routing is on).

set -e

REPO="growerp/growerp"
PROD_HOST="growerp.com" # the swarm manager, as in update-production.yml
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STORE_APPS=(admin hotel freelance support agents rental marketing academy insurance)
STORES=(ios macos android windows snap)
WORKFLOWS=(update-staging.yml screenshots.yml freeze-review.yml publish-metadata.yml
    publish-binary.yml update-production.yml release-approved.yml)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
DIM='\033[2m'
REVIEW_OPEN="" # true/false once show_versions ran
REVIEW_APPS="" # "app review-version (production version)" lines still in review
REVIEW_BRANCH="" # set by cut_review_branch

# the header comment, up to the first line that is not a comment
show_help() {
    awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

step() { echo -e "\n${GREEN}== $1${NC}"; }
warn() { echo -e "${YELLOW}$1${NC}"; }
die() { echo -e "${RED}$1${NC}"; exit 1; }

confirm() {
    local answer
    read -r -p "$1 [y/N] " answer
    [[ "$answer" =~ ^[Yy] ]]
}

# a step only a human can do: Enter continues, q quits
pause() {
    local answer
    warn "$1"
    read -r -p "Enter when done, q to quit: " answer
    [[ "$answer" != "q" ]] || exit 0
}

# ask "prompt" default -> REPLY
ask() {
    read -r -p "$1 [$2]: " REPLY
    REPLY="${REPLY:-$2}"
}

# ask_list "prompt" default allowed... -> REPLY (all, or a comma list of allowed)
ask_list() {
    local prompt="$1" default="$2"
    shift 2
    while true; do
        ask "$prompt (all or comma list of: $(IFS=,; echo "$*"))" "$default"
        REPLY="${REPLY// /}"
        [[ "$REPLY" == "all" ]] && return
        local name ok=true
        for name in ${REPLY//,/ }; do
            [[ " $* " == *" $name "* ]] || { echo -e "${RED}unknown '$name'${NC}"; ok=false; }
        done
        [[ -n "$REPLY" ]] && $ok && return
    done
}

ask_apps() { ask_list "Apps" "${1:-all}" "${STORE_APPS[@]}"; }
ask_apps_moqui() { ask_list "Apps" "${1:-all}" "${STORE_APPS[@]}" moqui; }
ask_stores() { ask_list "Stores" all "${STORES[@]}"; }

# createdAt of the last successful run of a workflow (empty when none)
last_success() {
    gh run list -R "$REPO" -w "$1" --status success -L1 --json createdAt -q '.[0].createdAt'
}

# start_at default "step"...: a restart skips the steps already done -> START
start_at() {
    local default="$1" i=1 name
    shift
    for name in "$@"; do
        echo "  $i  $name"
        i=$((i + 1))
    done
    ask "Start at step (restarted: skip the steps done)" "$default"
    [[ "$REPLY" =~ ^[0-9]+$ ]] && ((REPLY >= 1 && REPLY <= $#)) || die "no step $REPLY"
    START=$REPLY
}

# run_workflow file.yml [--ref branch] [-f key=value ...]: dispatch, wait, stop on failure
run_workflow() {
    local workflow="$1"
    shift
    local since id
    since=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    echo "gh workflow run $workflow $*"
    if $DRY_RUN; then
        warn "dry run: not started"
        return
    fi
    gh workflow run "$workflow" -R "$REPO" "$@"
    echo -n "waiting for the run to start"
    for _ in $(seq 60); do
        id=$(gh run list -R "$REPO" -w "$workflow" -e workflow_dispatch -L1 \
            --json databaseId,createdAt -q ".[] | select(.createdAt >= \"$since\") | .databaseId")
        [[ -n "$id" ]] && break
        echo -n "."
        sleep 5
    done
    echo
    [[ -n "$id" ]] || die "no run of $workflow started, check https://github.com/$REPO/actions"
    if ! gh run watch "$id" -R "$REPO" --exit-status; then
        gh run view "$id" -R "$REPO" --log-failed | tail -40 || true
        die "$workflow failed: https://github.com/$REPO/actions/runs/$id"
    fi
    echo -e "${GREEN}$workflow succeeded${NC}"
}

# changed_screen_apps branch: store apps whose screens changed on the branch since the
# last successful screenshots run
changed_screen_apps() {
    local base files app block
    base=$(gh run list -R "$REPO" -w screenshots.yml --status success -L1 \
        --json headSha -q '.[0].headSha')
    git -C "$SCRIPT_DIR" fetch -q origin "$1"
    if [[ -z "$base" ]]; then
        warn "no successful screenshots run yet" >&2
        echo "${STORE_APPS[@]}"
        return
    fi
    files=$(git -C "$SCRIPT_DIR" diff --name-only "$base" "origin/$1" -- flutter/packages |
        grep -E '^flutter/packages/[^/]+/lib/.*\.(dart|arb)$' |
        grep -vE '/blocs/|/integration_test/|\.g\.dart$|\.freezed\.dart$' || true)
    echo "Screen files changed since screenshots run ${base:0:8}: $(grep -c . <<<"$files")" >&2
    head -20 <<<"$files" | sed 's/^/  /' >&2
    for app in "${STORE_APPS[@]}"; do
        for block in $(sed -E 's#^flutter/packages/([^/]+)/.*#\1#' <<<"$files" | sort -u); do
            if [[ "$block" == "$app" ]] ||
                grep -qE "^\s+$block:" "$SCRIPT_DIR/flutter/packages/$app/pubspec.yaml"; then
                echo -n "$app "
                break
            fi
        done
    done
}

# cmd_prepare [apps] [branch]: the Windows binary and publish metadata upload the
# framed-screenshots artifact of the last screenshots run (kept 7 days, only the apps
# of that run), so create new ones for the apps when screens changed or it expired
cmd_prepare() {
    step "Store screenshots when screens changed"
    local changed last available=false branch="${2:-master}"
    changed=$(changed_screen_apps "$branch")
    last=$(last_success screenshots.yml)
    [[ -n "$last" && "$last" > "$(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%SZ)" ]] && available=true
    if [[ -n "$changed" ]]; then
        echo "Apps with changed screens since the last screenshots: $(tr ' ' ',' <<<"${changed% }")"
        $available && echo "The screenshots of $last are still available: N skips and uses them."
    elif $available; then
        echo "Screens unchanged, screenshots of $last still available."
        return
    else
        echo "Screens unchanged, but the screenshots artifact expired (last run: ${last:-none})."
    fi
    if confirm "Create new store screenshots?"; then
        ask_apps "${1:-all}"
        run_workflow screenshots.yml --ref "$branch" -f apps="$REPLY"
    fi
}

# backend version in review (review-versions.conf), set by the freeze
review_version() {
    server_file review-versions.conf | grep -o '"moqui:[^"]*"' | tr -d '"' | cut -d: -f2
}

# branch of the version in review (1.21), cut from master at the freeze and never
# deleted; empty when it does not exist
review_branch() {
    local version
    version=$(review_version)
    [[ -n "$version" ]] || return 0
    git -C "$SCRIPT_DIR" rev-parse -q --verify "refs/remotes/origin/${version%.*}" >/dev/null &&
        echo "${version%.*}"
    return 0
}

# newest version tag on a branch of origin
branch_tag() {
    git -C "$SCRIPT_DIR" tag --merged "origin/$1" -l '[0-9]*.[0-9]*.[0-9]*' --sort=-v:refname |
        head -1
}

# cmd_staging [branch]: update-staging runs on and commits to that branch: master, or
# the review branch for a fix of the version in review (patch only)
cmd_staging() {
    step "Update staging"
    local ref="$1" review
    git -C "$SCRIPT_DIR" fetch -q --tags origin
    review=$(review_branch)
    if [[ -z "$ref" ]]; then
        ask "Branch (master, or review branch $review for a fix)" master
        ref="${REPLY:-master}"
    fi
    local frozen published
    frozen=$(last_success freeze-review.yml)
    published=$(last_success publish-binary.yml)
    if [[ -n "$frozen" && "$frozen" > "${published:-}" ]]; then
        warn "Frozen for review on $frozen, binaries not published since."
        warn "The binaries must be the frozen version: publish them first."
        confirm "Update staging anyway?" || return
    fi
    local current default=patch
    if [[ "$ref" == master ]]; then
        # the patch versions of the review minor belong to the review branch
        current=$(branch_tag master)
        if [[ -n "$review" && "${current%.*}" == "$review" ]]; then
            warn "master is on $current, review branch $review has the $review.N versions: bump minor."
            default=minor
        fi
        ask_list "Bump" "$default" patch minor major
        [[ "$REPLY" == patch && "$default" == minor ]] &&
            { confirm "Patch collides with the versions of $review. Anyway?" || return; }
    else
        echo "Fix of the version in review on $ref: patch bump."
        REPLY=patch
    fi
    local bump="$REPLY"
    ask_apps_moqui
    local apps="$REPLY"
    read -r -p "Comment (optional): " comment
    run_workflow update-staging.yml --ref "$ref" -f bump="$bump" -f apps="$apps" \
        -f comment="$comment"
}

# the review branch (1.21) at the frozen backend version, so the store submissions and
# fixes of the version in review do not get the development on master; after a
# re-freeze of a fix the branch has the version already
cut_review_branch() {
    local tag branch
    git -C "$SCRIPT_DIR" fetch -q --tags origin
    tag=$(review_version)
    [[ -n "$tag" ]] || die "no moqui version in review-versions.conf"
    branch="${tag%.*}"
    # a branch needs the commit, not the annotated tag
    echo "git push origin $tag^{commit}:refs/heads/$branch"
    if $DRY_RUN; then
        warn "dry run: review branch $branch not created"
        REVIEW_BRANCH="$branch"
        return
    fi
    git -C "$SCRIPT_DIR" push origin "$(git -C "$SCRIPT_DIR" rev-parse "$tag^{commit}"):refs/heads/$branch" ||
        die "review branch $branch does not end in $tag: check origin/$branch"
    git -C "$SCRIPT_DIR" fetch -q origin "$branch"
    REVIEW_BRANCH="$branch"
    echo -e "${GREEN}review branch $branch at $tag${NC}"
}

cmd_prod_review() {
    start_at 1 "Store approvals" "Update production from review" \
        "Release approved store submissions"
    # after promoting everything no review is open, a restart at 3 still releases
    ((START > 2)) || require_review true
    local apps=all
    if ((START <= 1)); then
        step "1. Store approvals"
        echo "Approval taking too long? See 'When a store approval takes too long' in growerpUpgrade.md."
        list_review_apps
        pause "Wait until the stores approved the apps to promote (per app is fine)."
    fi
    if ((START <= 2)); then
        step "2. Update production from review"
        ask_apps_moqui
        apps="$REPLY"
        run_workflow update-production.yml -f source=review -f apps="$apps"
    fi
    step "3. Release approved store submissions"
    [[ "$apps" == "all" ]] || apps=$(tr ',' '\n' <<<"$apps" | grep -vx moqui | paste -sd,)
    if [[ -z "$apps" ]]; then
        echo "Only moqui promoted, no store submissions to release."
        return
    fi
    if confirm "Release the approved store submissions?"; then
        ask_apps "$apps"
        apps="$REPLY"
        ask_stores
        run_workflow release-approved.yml -f apps="$apps" -f stores="$REPLY"
    fi
}

# release notes: feat/fix/docs/ci commits since the previous release, grouped
release_notes() {
    local type heading
    for type in feat fix docs ci; do
        case $type in
            feat) heading="### ✨ Features" ;;
            fix) heading="### 🔒 Fixes" ;;
            docs) heading="### 📖 Docs" ;;
            ci) heading="### 🛠 CI/CD & Store Publishing" ;;
        esac
        git -C "$SCRIPT_DIR" log --no-merges --format='%s' "$1..$2" |
            grep -E "^$type(\([^)]*\))?: " | grep -vE '^ci\(release\)' |
            sed -E "s/^$type\(([^)]*)\): (.*)/*   **\1**: \2/; s/^$type: (.*)/*   \1/" |
            awk -v h="$heading" 'NR == 1 { print h } { print } END { if (NR) print "" }'
    done
}

# claude_notes previous tag: Claude writes the notes in the form of the newest release
# with written notes (not the template); first line "TITLE: ...", then the notes
claude_notes() {
    local example name
    command -v claude >/dev/null || return 1
    for name in $(gh release list -R "$REPO" -L10 --exclude-drafts --json tagName -q '.[].tagName'); do
        example=$(gh release view "$name" -R "$REPO" --json name,body -q '"TITLE: \(.name)\n\n\(.body)"')
        [[ "$example" == *"<one paragraph summary"* ]] || break
    done
    {
        echo "EXAMPLE RELEASE:"
        echo "$example"
        echo
        echo "COMMITS $1..$2:"
        git -C "$SCRIPT_DIR" log --no-merges --format='- %s' "$1..$2"
    } | claude -p "Write the GitHub release notes of GrowERP $2 from the commits on stdin, \
in exactly the form and style of the example release. Output: a first line \
'TITLE: <a few words naming the main themes, without version number>', a blank line, \
one summary paragraph with the highlights in **bold**, then '### <emoji> <Theme>' \
sections grouped by product area (not by commit type), each with '*   **Label**: \
sentence' bullets that merge related commits into user-facing wording. Fixes, \
Infrastructure & Code and CI/CD & Store Publishing sections come last, as in the \
example. Leave out merges, version bumps, screenshot refreshes and trivial chores. \
No Full Changelog line, nothing before TITLE or after the notes." 2>/dev/null
}

cmd_release() {
    step "Create GitHub release"
    git -C "$SCRIPT_DIR" fetch -q --tags origin
    local previous tag notes
    previous=$(gh release list -R "$REPO" -L1 --exclude-drafts --json tagName -q '.[0].tagName')
    ask "Version to release (the version to submit for review)" \
        "$(newest_tag)"
    tag="$REPLY"
    git -C "$SCRIPT_DIR" rev-parse -q --verify "refs/tags/$tag" >/dev/null || die "no tag $tag"
    gh release view "$tag" -R "$REPO" >/dev/null 2>&1 && die "release $tag exists already"
    ask "Previous release" "$previous"
    previous="$REPLY"
    notes=$(mktemp --suffix=.md)
    local written="" title=""
    echo "Claude writes the release notes..."
    if written=$(claude_notes "$previous" "$tag") && [[ "$written" == TITLE:* ]]; then
        title=$(head -1 <<<"$written" | sed 's/^TITLE:[[:space:]]*//')
        tail -n +2 <<<"$written" | sed '/./,$!d' >"$notes"
    else
        warn "Claude did not write the notes: template with the commits per type."
        {
            echo "<one paragraph summary of this release>"
            echo
            release_notes "$previous" "$tag"
        } >"$notes"
    fi
    echo "**Full Changelog**: https://github.com/$REPO/compare/$previous...$tag" >>"$notes"
    ask "Title (after '$tag ')" "$title"
    title="$REPLY"
    pause "Check the release notes: $notes"
    "${EDITOR:-nano}" "$notes"
    cat "$notes"
    if confirm "Publish release '$tag $title' as Latest?"; then
        if $DRY_RUN; then
            warn "dry run: gh release create $tag --title \"$tag $title\" --latest not run"
        else
            gh release create "$tag" -R "$REPO" --title "$tag $title" --notes-file "$notes" --latest
        fi
    fi
    rm -f "$notes"
}

# production gets what staging runs now: web apps and backend, no store review
cmd_prod_staging() {
    require_review false
    step "1. GitHub release"
    echo "Update production refuses source staging while store review routing is on."
    confirm "Create a GitHub release for the version staging runs?" && cmd_release
    step "2. Update production from staging"
    ask_apps_moqui
    run_workflow update-production.yml -f source=staging -f apps="$REPLY"
}

# store states per app from the status workflow (its status-<store>-<app> artifacts):
# "app<TAB>approved" or "app<TAB>ios 1.20.2 WAITING_FOR_REVIEW, ..." in STORE_STATES
STORE_STATES=""
store_states() {
    local id created dir
    read -r id created < <(gh run list -R "$REPO" -w status.yml -s success -L1 \
        --json databaseId,createdAt -q '.[0] | "\(.databaseId) \(.createdAt)"')
    echo "Store states of the status run of $created"
    if confirm "Refresh them (store-only status run, ~6 min)?"; then
        if [[ -n "$(gh run list -R "$REPO" -w status.yml -s in_progress -L1 --json databaseId -q '.[0].databaseId')" ]]; then
            warn "A status run is in progress: a new one cancels it."
            confirm "Start anyway?" || return
        fi
        # read-only store queries: also in a dry run
        DRY_RUN=false run_workflow status.yml -f skip_integration_tests=true
        id=$(gh run list -R "$REPO" -w status.yml -s success -L1 --json databaseId -q '.[0].databaseId')
    fi
    dir=$(mktemp -d)
    gh run download "$id" -R "$REPO" -p 'status-*-*' -D "$dir" >/dev/null 2>&1 || warn "no store states in run $id"
    STORE_STATES=$(python3 -I - "$dir" <<'PYEOF'
import json, sys
from pathlib import Path
APPLE_OK = {'READY_FOR_SALE', 'READY_FOR_DISTRIBUTION', 'PENDING_DEVELOPER_RELEASE',
            'PROCESSING_FOR_DISTRIBUTION', 'PENDING_APPLE_RELEASE'}
pending = {}
for f in sorted(Path(sys.argv[1]).glob('status-*-*/fragment.json')):
    d = json.loads(f.read_text())
    store, rows = d['store'], d.get('rows') or [{}]
    state = None
    if store in ('ios', 'macos'):
        r = rows[0]
        if r.get('state') not in APPLE_OK:
            state = f"{r.get('version')} {r.get('state')}"
    elif store == 'android':
        r = next((r for r in rows if r.get('track') == 'production'), {})
        life = r.get('lifecycle', 'unknown')
        if life not in ('waiting for developer release', 'published'):
            state = f"{r.get('version')} {life}"
    elif store == 'windows':
        r = next((r for r in rows if r.get('label') == 'pending'), None)
        if r and r.get('status') not in ('Release', 'PendingPublication', 'Publishing'):
            state = f"{r.get('version')} {r.get('status')}"
    pending.setdefault(d['app'], [])
    if state:
        pending[d['app']].append(f'{store} {state}')
for app, states in pending.items():
    print(f"{app}\t{', '.join(states) or 'approved'}")
PYEOF
)
    rm -rf "$dir"
}

# apps whose review version is not on production, with their store approvals
list_review_apps() {
    store_states
    warn "Not on production yet:"
    local name rest state
    while read -r name rest; do
        [[ -n "$name" ]] || continue
        state=$(awk -F'\t' -v a="$name" '$1 == a { print $2 }' <<<"$STORE_STATES")
        case "$state" in
            approved) state="${GREEN}approved, promote with 1a${NC}" ;;
            "") state="no store (promote with 1a)" ;;
            *) state="${YELLOW}waiting: $state${NC}" ;;
        esac
        echo -e "    $(printf '%-10s %s' "$name" "$rest")  $state"
    done <<<"$REVIEW_APPS"
}

# preparing is fine while the previous review waits for approvals, the freeze is not
cmd_review() {
    local default=1 frozen published listed
    frozen=$(last_success freeze-review.yml)
    published=$(last_success publish-binary.yml)
    listed=$(last_success publish-metadata.yml)
    if [[ -n "$frozen" && "$frozen" > "${published:-}" ]]; then
        default=5
    elif [[ -n "$frozen" && "$published" > "$frozen" && "$published" > "${listed:-}" ]]; then
        default=6
    fi
    start_at "$default" "Update staging" "Reviewer login" "GitHub release" \
        "Freeze for review, review branch" "Publish binary (submit for review)" \
        "Publish metadata (store listing, screenshots)"
    if ((START <= 4)); then
        [[ -n "$REVIEW_OPEN" ]] || show_versions >/dev/null
        if $REVIEW_OPEN; then
            list_review_apps
            echo "Steps 1-3 can run now, the freeze (4) waits until these are promoted"
            echo "or dropped (./review.sh drop <app> --apply on the server)."
            confirm "Prepare the new review anyway?" || return
        fi
    fi
    if ((START <= 1)); then
        step "1. Update staging"
        echo "The version to submit: staging built from master (a fix: from the review branch)."
        confirm "Update staging?" && cmd_staging
    fi
    if ((START <= 2)); then
        step "2. Reviewer login"
        pause "Create the userid/password for the store reviewers on staging."
    fi
    if ((START <= 3)); then
        step "3. GitHub release"
        confirm "Create a GitHub release for the version to submit?" && cmd_release
    fi
    if ((START <= 4)); then
        step "4. Freeze for review, review branch"
        show_versions >/dev/null
        while $REVIEW_OPEN; do
            list_review_apps
            confirm "Promoted or dropped them? Check again" || return
            show_versions >/dev/null
        done
        confirm "Freeze for review?" || return
        run_workflow freeze-review.yml
        cut_review_branch
    fi
    # The binary creates the new store version, metadata writes into it (the Windows
    # binary submission carries its listing itself); both use the screenshots. They
    # run on the review branch: master has moved on since the freeze
    local apps=all stores=all branch="${REVIEW_BRANCH:-}"
    if [[ -z "$branch" ]]; then
        git -C "$SCRIPT_DIR" fetch -q origin
        branch=$(review_branch)
    fi
    [[ -n "$branch" ]] || die "no review branch: freeze for review first (step 4)"
    if ((START <= 5)); then
        step "5. Publish binary (submit for review)"
        echo "From review branch $branch"
        if confirm "Publish binary to stores?"; then
            ask_apps
            apps="$REPLY"
            ask_stores
            stores="$REPLY"
            cmd_prepare "$apps" "$branch"
            ask_list "Track (stable = submit for review, beta = TestFlight only)" stable stable beta
            run_workflow publish-binary.yml --ref "$branch" -f apps="$apps" -f stores="$stores" \
                -f track="$REPLY" -f android_release_status=auto
        fi
    fi
    step "6. Publish metadata (store listing, screenshots)"
    echo "From review branch $branch"
    echo "The binary created the store versions and took the iOS/macOS texts (not the"
    echo "screenshots), the Windows binary its whole listing. A version waiting for review"
    echo "leaves the queue for the iOS/macOS screenshots and is submitted again."
    if confirm "Publish metadata to stores?"; then
        ask_apps "$apps"
        apps="$REPLY"
        # Windows is left out: its binary submission carries the listing (a listing-only
        # update without a binary in flight can still select it)
        [[ "$stores" == all ]] && stores=$(IFS=,; echo "${STORES[*]}")
        stores=$(tr ',' '\n' <<<"$stores" | grep -vx windows | paste -sd,)
        ask_list "Stores" "${stores:-ios}" "${STORES[@]}"
        run_workflow publish-metadata.yml --ref "$branch" -f apps="$apps" -f stores="$REPLY"
    fi
}

cmd_status() {
    step "Last run per workflow"
    local workflow
    for workflow in "${WORKFLOWS[@]}"; do
        printf "%-22s %s\n" "$workflow" "$(gh run list -R "$REPO" -w "$workflow" -L1 \
            --json status,conclusion,createdAt \
            -q '.[0] | "\(.createdAt)  \(.status) \(.conclusion)"')"
    done
}

newest_tag() {
    git -C "$SCRIPT_DIR" tag -l '[0-9]*.[0-9]*.[0-9]*' --sort=-v:refname | head -1
}

# a swarm file as the production server has it (update production and freeze edit
# it there); without ssh the growerp/server repo copy, committed by hand, may be stale
server_file() {
    ssh -n -o BatchMode=yes -o ConnectTimeout=10 "$PROD_HOST" "cat server/swarm/$1" 2>/dev/null && return
    warn "  no ssh to $PROD_HOST: $1 from the growerp/server repo, may be stale" >&2
    gh api "repos/growerp/server/contents/swarm/$1" -H 'Accept: application/vnd.github.raw'
}

# "1.21 (2026-10-24)": minor versions of a list of versions, dated by the tag of
# the latest patch version
minor_dated() {
    local latest
    latest=$(grep . | sort -uV | tail -1)
    echo "$(sort -uV <<<"$1" | grep . | paste -sd/)" \
        "($(git -C "$SCRIPT_DIR" for-each-ref --format='%(creatordate:short)' "refs/tags/$latest"))"
}

# minor versions of staging (newest tag), review and production; a review is open
# while an app's review version is not on production
show_versions() {
    local prod review name img rv pv rminors="" pminors="" rall="" pall=""
    REVIEW_OPEN=false
    REVIEW_APPS=""
    git -C "$SCRIPT_DIR" fetch -q --tags origin
    prod=$(server_file apps-prod.yml)
    review=$(server_file review-versions.conf)
    for name in moqui "${STORE_APPS[@]}"; do
        img=$name
        [[ "$name" == moqui ]] && img=growerp-moqui
        rv=$(grep -o "\"$name:[^\"]*\"" <<<"$review" | tr -d '"' | cut -d: -f2)
        pv=$(grep -oE "ghcr.io/growerp/$img:[0-9.]+" <<<"$prod" | head -1 | cut -d: -f2)
        [[ -n "$rv" ]] && rminors+="${rv%.*}"$'\n' && rall+="$rv"$'\n'
        [[ -n "$pv" ]] && pminors+="${pv%.*}"$'\n' && pall+="$pv"$'\n'
        if [[ -n "$rv" && "$rv" != "$pv" ]]; then
            REVIEW_OPEN=true
            REVIEW_APPS+="    $name $rv (production ${pv:-none})"$'\n'
        fi
    done
    local staging
    staging=$(newest_tag)
    echo "  staging $(minor_dated "${staging%.*}" <<<"$staging")" \
        " ·  review $(minor_dated "$rminors" <<<"$rall")" \
        " ·  production $(minor_dated "$pminors" <<<"$pall")"
    if $REVIEW_OPEN; then
        warn "  Review open: waiting for store approvals -> 1a (2 can prepare)"
    else
        echo "  No review open -> 1b or 2"
    fi
}

# require_review true|false: stop before any step when a review is (not) open
require_review() {
    [[ -n "$REVIEW_OPEN" ]] || show_versions >/dev/null
    [[ "$REVIEW_OPEN" == "$1" ]] && return
    if $REVIEW_OPEN; then
        die "Review open: promote it first (production from review) or drop the stuck apps (./review.sh drop <app> --apply on the server)."
    fi
    die "No review open: nothing to promote from review."
}

menu() {
    echo -e "\n${GREEN}GrowERP release${NC}\n"
    show_versions
    echo
    echo "  1  Production"
    local on="" off=""
    if $REVIEW_OPEN; then off="$DIM"; else on="$DIM"; fi
    echo -e "${on}     1a  from review    versions the stores approved     (when a review is open)${NC}"
    echo -e "${off}     1b  from staging   new release of staging now       (when no review is open)${NC}"
    echo    "  2  New review         staging, freeze, submit          (freeze when no review is open)"
    echo
    echo "  Other: u update staging   p screenshots   g GitHub release   t status   q quit"
    echo
    read -r -p "Choice: " choice
    case "${choice,,}" in
        1a) cmd_prod_review ;;
        1b) cmd_prod_staging ;;
        2) cmd_review ;;
        u) cmd_staging ;;
        p) cmd_prepare ;;
        g) cmd_release ;;
        t) cmd_status ;;
        *) exit 0 ;;
    esac
}

DRY_RUN=false
args=()
for arg in "$@"; do
    case "$arg" in
        -n | --dry-run) DRY_RUN=true ;;
        *) args+=("$arg") ;;
    esac
done
set -- "${args[@]}"
case "$1" in
    -h | --help | help) show_help; exit 0 ;;
esac
$DRY_RUN && warn "DRY RUN: workflows and the GitHub release are only shown, not started"
command -v gh >/dev/null || die "gh (GitHub CLI) is required"
gh auth status >/dev/null 2>&1 || die "gh is not logged in: gh auth login"

case "${1,,}" in
    production)
        case "$2" in
            review) cmd_prod_review ;;
            staging) cmd_prod_staging ;;
            *) show_help; exit 1 ;;
        esac ;;
    review) cmd_review ;;
    prepare) cmd_prepare ;;
    staging) cmd_staging ;;
    release) cmd_release ;;
    status) cmd_status ;;
    "") menu ;;
    *) show_help; exit 1 ;;
esac
