#!/bin/bash

# ============================================================================
# app-clone-kit - Build Runner
# ============================================================================
# Runs the automated build phases (4-6) as separate Claude Code sessions.
# Feature discovery and planning phases (1-3) are handled by the /clone slash command.
#
# Usage:
#   ./.clone-kit/pipeline.sh              Run or resume
#   ./.clone-kit/pipeline.sh status       Show progress
#   ./.clone-kit/pipeline.sh phase N      Run specific phase (scaffold, 0-N, integration)
#   ./.clone-kit/pipeline.sh reset        Reset build progress (keeps research)
# ============================================================================

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

# Project root is parent of .clone-kit/
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PROGRESS="$PROJECT_DIR/progress.json"
BUILD_QUEUE="$PROJECT_DIR/build-queue.json"
TEST_RESULTS="$PROJECT_DIR/test-results.json"
PHASES_DIR="$SCRIPT_DIR/phases"

info()    { echo -e "${BLUE}  ℹ${NC} $1"; }
success() { echo -e "${GREEN}  ✓${NC} $1"; }
warn()    { echo -e "${YELLOW}  ⚠${NC} $1"; }
err()     { echo -e "${RED}  ✗${NC} $1"; }

header() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

check_prereqs() {
    local ok=true
    command -v claude &>/dev/null || { err "Claude Code required: npm install -g @anthropic-ai/claude-code"; ok=false; }
    [ -f "$PROJECT_DIR/config.json" ] || { err "config.json not found. Run /clone first."; ok=false; }
    [ -f "$BUILD_QUEUE" ] || { err "build-queue.json not found. Run /clone through Phase 3 first."; ok=false; }
    [ "$ok" = false ] && exit 1
}

py() { python3 -c "$1" 2>/dev/null; }

app_name()       { py "import json; print(json.load(open('$PROJECT_DIR/config.json'))['target_app']['name'])"; }
total_phases()   { py "import json; print(len(json.load(open('$BUILD_QUEUE')).get('phases',[])))"; }
last_completed() { py "import json; print(json.load(open('$PROGRESS')).get('last_build_phase_completed',-1))" 2>/dev/null || echo "-1"; }
scaffold_done()  { py "import json; print(json.load(open('$PROGRESS')).get('scaffold_status',''))" 2>/dev/null || echo ""; }
integration_done() { py "import json; print(json.load(open('$PROGRESS')).get('integration_status',''))" 2>/dev/null || echo ""; }

update_progress() {
    py "
import json, datetime
p = {}
try:
    with open('$PROGRESS') as f: p = json.load(f)
except: pass
p['$1'] = $2
p['last_updated'] = datetime.datetime.now().isoformat()
with open('$PROGRESS','w') as f: json.dump(p, f, indent=2)
"
}

run_session() {
    local prompt="$1" label="$2"
    echo -e "  ${BOLD}$label${NC}"
    echo -e "  ${DIM}$(echo "$prompt" | head -1 | cut -c1-80)...${NC}"
    echo ""

    mkdir -p "$PROJECT_DIR/.session-logs"
    local log="$PROJECT_DIR/.session-logs/$(date +%Y%m%d-%H%M%S)-${label// /-}.txt"

    cd "$PROJECT_DIR"
    if claude -p "$prompt" --verbose 2>&1 | tee "$log"; then
        success "Session complete."
        return 0
    else
        warn "Session exited with errors. Log: $log"
        return 1
    fi
}

# ---- Stages ----

do_scaffold() {
    [ "$(scaffold_done)" = "complete" ] && { success "Scaffold done. Skipping."; return 0; }
    header "Phase 4: Scaffold"

    run_session \
        "Read .clone-kit/phases/04-scaffold.md and execute it. Use feature-map.json, build-queue.json, and config.json. Verify on emulator with mobile MCP. Update progress.json with scaffold_status when complete." \
        "Scaffolding project"

    update_progress "scaffold_status" '"complete"'
}

do_build_phase() {
    local n="$1" total
    total=$(total_phases)

    local info
    info=$(py "
import json
with open('$BUILD_QUEUE') as f: q = json.load(f)
p = q['phases'][$n]
print(f\"{p['name']} ({len(p.get('features',[]))} features)\")
")
    echo -e "  ${CYAN}[$((n+1))/$total]${NC} $info"

    run_session \
        "Read .clone-kit/phases/05-build-loop.md and execute build phase $n from build-queue.json. Read ONLY phase $n features from feature-map.json. Read progress.json and test-results.json for state. Test with mobile MCP. Run regression tests. Update test-results.json and progress.json." \
        "Build phase $n"

    update_progress "last_build_phase_completed" "$n"
}

do_build_loop() {
    local total last start
    total=$(total_phases)
    last=$(last_completed)
    start=$((last + 1))

    [ "$start" -ge "$total" ] && { success "All $total build phases done."; return 0; }

    header "Phase 5: Build Loop"
    [ "$start" -gt 0 ] && info "Resuming from phase $start (0-$((start-1)) done)"

    for (( i=start; i<total; i++ )); do
        echo ""
        if ! do_build_phase "$i"; then
            warn "Phase $i had issues."
            echo -ne "  ${BOLD}Continue? [Y/n]${NC}: "
            read -r ans
            [[ "$ans" =~ ^[Nn] ]] && { info "Paused. Run again to resume."; return 0; }
        fi
    done
    success "All build phases complete!"
}

do_integration() {
    [ "$(integration_done)" = "complete" ] && { success "Integration done."; return 0; }
    header "Phase 6: Integration & Polish"

    run_session \
        "Read .clone-kit/phases/06-integration.md and execute it. Read test-results.json for deferred issues. Fix all issues, test cross-feature flows with mobile MCP, polish UI, final walkthrough. Save screenshots to screenshots/final/. Update progress.json." \
        "Integration and polish"

    update_progress "integration_status" '"complete"'

    echo ""
    header "Your Turn - Final Review"
    echo -e "  ${YELLOW}Walk through the app (~10-20 min).${NC}"
    echo -e "  Screenshots: ${DIM}screenshots/final/${NC}"
    echo ""
    echo -e "  Found issues? Start Claude Code and describe them:"
    echo -e "  ${DIM}  claude${NC}"
    echo -e "  ${DIM}  > Fix these: [describe]. Test each with mobile MCP.${NC}"
    echo ""

    update_progress "pipeline_status" '"complete"'
}

# ---- Status ----

show_status() {
    local name total last scaffold integration
    name=$(app_name)
    total=$(total_phases)
    last=$(last_completed)
    scaffold=$(scaffold_done)
    integration=$(integration_done)

    header "Status: $name"

    # Scaffold
    [ "$scaffold" = "complete" ] && echo -e "  ${GREEN}✓${NC} Scaffold" || echo -e "  ${YELLOW}▶${NC} Scaffold"

    # Build phases
    for (( i=0; i<total; i++ )); do
        local pname
        pname=$(py "import json; p=json.load(open('$BUILD_QUEUE'))['phases'][$i]; print(f\"Build {p['phase']}: {p['name']}\")")
        if [ "$i" -le "$last" ]; then
            echo -e "  ${GREEN}✓${NC} $pname"
        elif [ "$i" -eq "$((last+1))" ]; then
            echo -e "  ${YELLOW}▶${NC} $pname ${DIM}(next)${NC}"
        else
            echo -e "  ${DIM}· $pname${NC}"
        fi
    done

    # Integration
    [ "$integration" = "complete" ] && echo -e "  ${GREEN}✓${NC} Integration" || \
        { [ "$last" -ge "$((total-1))" ] && echo -e "  ${YELLOW}▶${NC} Integration ${DIM}(next)${NC}" || echo -e "  ${DIM}· Integration${NC}"; }

    # Test summary
    if [ -f "$TEST_RESULTS" ]; then
        echo ""
        py "
import json
with open('$TEST_RESULTS') as f: t = json.load(f)
r = t.get('results',[])
if r:
    p=sum(1 for x in r if x.get('status')=='pass')
    i=sum(1 for x in r if x.get('status')=='pass_with_issues')
    f=sum(1 for x in r if x.get('status')=='failed')
    print(f'  Tests: {p} passed, {i} with issues, {f} failed')
"
    fi
    echo ""
}

# ---- Main ----

case "${1:-}" in
    status|-s|--status) check_prereqs; show_status ;;
    reset)
        echo -ne "  ${BOLD}Reset build progress? (research preserved) [y/N]${NC}: "
        read -r ans
        [[ "$ans" =~ ^[Yy] ]] && {
            py "
import json
p={}
try:
    with open('$PROGRESS') as f: p=json.load(f)
except: pass
for k in list(p.keys()):
    if any(k.startswith(x) for x in ('scaffold','last_build','integration','build_phase','pipeline')): del p[k]
with open('$PROGRESS','w') as f: json.dump(p,f,indent=2)
"
            rm -f "$TEST_RESULTS"
            success "Build progress reset."
        } ;;
    phase)
        check_prereqs
        case "${2:-}" in
            scaffold|4) do_scaffold ;;
            integration|6) do_integration ;;
            [0-9]*) do_build_phase "$2" ;;
            *) err "Usage: $0 phase [scaffold|0-N|integration]" ;;
        esac ;;
    help|-h|--help)
        echo ""
        echo "  app-clone-kit build runner"
        echo ""
        echo "  Run /clone in Claude Code first (handles research + planning)."
        echo ""
        echo "  ./.clone-kit/pipeline.sh              Run or resume"
        echo "  ./.clone-kit/pipeline.sh status       Show progress"
        echo "  ./.clone-kit/pipeline.sh phase N      Run specific phase"
        echo "  ./.clone-kit/pipeline.sh reset        Reset build progress"
        echo "" ;;
    *)
        check_prereqs
        name=$(app_name)
        header "Building: $name"

        last=$(last_completed)
        scaffold=$(scaffold_done)
        if [ "$last" -ge 0 ] || [ "$scaffold" = "complete" ]; then
            show_status
            echo -ne "  ${BOLD}Resume? [Y/n]${NC}: "
            read -r ans
            [[ "$ans" =~ ^[Nn] ]] && exit 0
        fi

        do_scaffold
        do_build_loop
        do_integration

        header "Pipeline Complete!"
        show_status ;;
esac
