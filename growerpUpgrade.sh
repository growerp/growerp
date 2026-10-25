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
#   review   new review (when review is empty): GitHub release, freeze for review,
#            publish metadata (opt, after prepare), publish binary to stores
#   prepare  create store screenshots when screens changed since the last screenshots
#            run or its artifact (used by publish metadata, kept 7 days) expired
#   staging  update staging (new version: patch, minor or major)
#   release  GitHub release of a version tag, notes: a summary paragraph and the
#            feat/fix/docs/ci commits since the previous release, edited before publish
#   status   last run of every release workflow
#
# Dispatches the GitHub workflows with gh, waits for each run and stops on a failure.
# The workflows keep their own guards (freeze refuses while review is not empty,
# update production refuses source staging while store review routing is on).

set -e

REPO="growerp/growerp"
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

# run_workflow file.yml [-f key=value ...]: dispatch, wait, stop on failure
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

# store apps whose screens changed since the last successful screenshots run
changed_screen_apps() {
    local base files app block
    base=$(gh run list -R "$REPO" -w screenshots.yml --status success -L1 \
        --json headSha -q '.[0].headSha')
    git -C "$SCRIPT_DIR" fetch -q origin master
    if [[ -z "$base" ]]; then
        warn "no successful screenshots run yet" >&2
        echo "${STORE_APPS[@]}"
        return
    fi
    files=$(git -C "$SCRIPT_DIR" diff --name-only "$base" origin/master -- flutter/packages |
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

# cmd_prepare [apps]: publish metadata uploads the framed-screenshots artifact of the
# last screenshots run (kept 7 days, only the apps of that run), so create new ones
# for the metadata apps when screens changed or the artifact expired
cmd_prepare() {
    step "Store screenshots when screens changed"
    local changed last
    changed=$(changed_screen_apps)
    last=$(last_success screenshots.yml)
    if [[ -n "$changed" ]]; then
        echo "Apps with changed screens: $(tr ' ' ',' <<<"${changed% }")"
    elif [[ -n "$last" && "$last" > "$(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%SZ)" ]]; then
        echo "Screens unchanged, screenshots of $last still available."
        return
    else
        echo "Screens unchanged, but the screenshots artifact expired (last run: ${last:-none})."
    fi
    if confirm "Create store screenshots?"; then
        ask_apps "${1:-all}"
        run_workflow screenshots.yml -f apps="$REPLY"
    fi
}

cmd_staging() {
    step "Update staging"
    local frozen published
    frozen=$(last_success freeze-review.yml)
    published=$(last_success publish-binary.yml)
    if [[ -n "$frozen" && "$frozen" > "${published:-}" ]]; then
        warn "Frozen for review on $frozen, binaries not published since."
        warn "The binaries must be the frozen version: publish them first."
        confirm "Update staging anyway?" || return
    fi
    ask_list "Bump" patch patch minor major
    local bump="$REPLY"
    ask_apps_moqui
    local apps="$REPLY"
    read -r -p "Comment (optional): " comment
    run_workflow update-staging.yml -f bump="$bump" -f apps="$apps" -f comment="$comment"
}

cmd_prod_review() {
    require_review true
    step "1. Store approvals"
    echo "Approval taking too long? See 'When a store approval takes too long' in growerpUpgrade.md."
    pause "Wait until the stores approved the apps to promote (per app is fine)."
    step "2. Update production from review"
    ask_apps_moqui
    local apps="$REPLY"
    run_workflow update-production.yml -f source=review -f apps="$apps"
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
    read -r -p "Title (after '$tag '): " title
    notes=$(mktemp --suffix=.md)
    {
        echo "<one paragraph summary of this release>"
        echo
        release_notes "$previous" "$tag"
        echo "**Full Changelog**: https://github.com/$REPO/compare/$previous...$tag"
    } >"$notes"
    pause "Edit the release notes (summary paragraph, group/reword lines): $notes"
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

cmd_review() {
    require_review false
    step "1. Version to submit"
    pause "The last 'update staging' run is the version to submit. Create the userid/password for the store reviewers on staging."
    step "2. GitHub release"
    confirm "Create a GitHub release for the version to submit?" && cmd_release
    step "3. Freeze for review"
    echo "Freeze refuses until every version in review is on production."
    confirm "Freeze for review?" || return
    run_workflow freeze-review.yml
    warn "No 'update staging' until the binaries are published: they must be the frozen version."
    step "4. Submit for review"
    if confirm "Publish metadata to stores?"; then
        ask_apps
        local apps="$REPLY"
        ask_stores
        local stores="$REPLY"
        cmd_prepare "$apps"
        run_workflow publish-metadata.yml -f apps="$apps" -f stores="$stores"
    fi
    confirm "Publish binary to stores?" || return
    ask_apps
    local apps="$REPLY"
    ask_stores
    local stores="$REPLY"
    ask_list "Track (stable = submit for review, beta = TestFlight only)" stable stable beta
    run_workflow publish-binary.yml -f apps="$apps" -f stores="$stores" -f track="$REPLY" \
        -f android_release_status=auto
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

# a file of the server repo, where the server commits its production pins and the
# versions frozen into review
server_file() {
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
        [[ -n "$rv" && "$rv" != "$pv" ]] && REVIEW_OPEN=true
    done
    local staging
    staging=$(newest_tag)
    echo "  staging $(minor_dated "${staging%.*}" <<<"$staging")" \
        " ·  review $(minor_dated "$rminors" <<<"$rall")" \
        " ·  production $(minor_dated "$pminors" <<<"$pall")"
    if $REVIEW_OPEN; then
        warn "  Review open: waiting for store approvals -> 1a"
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
    echo -e "${off}  2  New review         GitHub release, freeze, submit   (when no review is open)${NC}"
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
