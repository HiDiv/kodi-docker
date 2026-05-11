#!/usr/bin/env bash
# Kodi e2e test runner entrypoint.
# Waits for Kodi to be ready, then runs tests from /tests.
#
# Environment:
#   KODI_HOST       — Kodi hostname (default: kodi)
#   KODI_HTTP_PORT  — Kodi HTTP port (default: 8080)
#   KODI_WS_PORT    — Kodi WebSocket port (default: 9090)
#   TEST_FILTER     — vitest filter (optional)

set -e

KODI_HOST="${KODI_HOST:-kodi}"
KODI_HTTP_PORT="${KODI_HTTP_PORT:-8080}"
KODI_WS_PORT="${KODI_WS_PORT:-9090}"
TEST_FILTER="${TEST_FILTER:-}"

log() { echo "---> [e2e-runner] $1"; }

# Wait for Kodi JSON-RPC to respond
wait_for_kodi() {
    log "Waiting for Kodi at ${KODI_HOST}:${KODI_HTTP_PORT}..."
    local i=0
    while [ $i -lt 60 ]; do
        if curl -sf -X POST -H "Content-Type: application/json" \
            -d '{"jsonrpc":"2.0","method":"JSONRPC.Ping","id":1}' \
            "http://${KODI_HOST}:${KODI_HTTP_PORT}/jsonrpc" | grep -q pong; then
            log "Kodi is ready"
            return 0
        fi
        sleep 2
        i=$((i + 1))
    done
    log "ERROR: Kodi did not respond within 120 seconds"
    exit 1
}

# Run tests
run_tests() {
    local test_dir="/tests"
    local results_dir="/results"

    if [ ! -d "$test_dir" ] || [ -z "$(ls -A "$test_dir" 2>/dev/null)" ]; then
        log "ERROR: No tests found in /tests. Mount your test directory."
        exit 1
    fi

    mkdir -p "$results_dir"

    log "Running tests from ${test_dir}"

    # Build vitest args
    local args="run --root /opt/kodi-e2e --dir ${test_dir}"
    [ -n "$TEST_FILTER" ] && args="$args $TEST_FILTER"

    # Run vitest with user tests, KodiClient available via import
    cd /opt/kodi-e2e
    npx vitest $args \
        --reporter=default \
        --reporter=json --outputFile="${results_dir}/results.json" \
        2>&1 | tee "${results_dir}/output.log"

    local exit_code=${PIPESTATUS[0]}
    log "Tests finished (exit code: ${exit_code})"
    return $exit_code
}

wait_for_kodi
run_tests
