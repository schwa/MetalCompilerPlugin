#!/bin/bash
# Checks that the plugin selects debug or release flags correctly when an Xcode app
# depends on a package that uses it. Not part of `swift test`.
# Requires xcodegen and xcb. Usage: Tests/Integration/matrix.sh
set -u
FIXTURE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$FIXTURE/../.." && pwd)"
WORK="${TMPDIR:-/tmp}"; WORK="${WORK%/}/mcp-integration/mcp host" # The space is intentional.
DD="$WORK/dd"
LOG="$WORK/logs"
FAILURES=0

rm -rf "$WORK"; mkdir -p "$WORK" "$LOG"
cp -R "$FIXTURE/App" "$FIXTURE/HostShaders" "$FIXTURE/project.yml" "$WORK/"
ln -s "$REPO" "$WORK/MetalCompilerPlugin"
cd "$WORK"
xcodegen generate --quiet || exit 1
echo "Work directory: $WORK"

# describe <metallib> -> "src=yes|no cfg=debug|release|none"
describe() {
    local f="$1"
    [ -f "$f" ] || { echo "MISSING"; return; }
    local src=no cfg=none fns
    xcrun metal-readobj --sections "$f" 2>/dev/null | grep -q 'Name: SOURCES' && src=yes
    fns=$(xcrun metal-nm "$f" 2>/dev/null)
    grep -q configurationDebug <<<"$fns" && cfg=debug
    grep -q configurationRelease <<<"$fns" && cfg=release
    echo "src=$src cfg=$cfg"
}

# check <label> <search dir> <expected A> <expected B>
check() {
    local label="$1" dir="$2" a b status=PASS
    a=$(describe "$(find "$dir" -path '*ShadersA.bundle*default.metallib' | head -1)")
    b=$(describe "$(find "$dir" -path '*ShadersB.bundle*default.metallib' | head -1)")
    if [ "$a" != "$3" ] || [ "$b" != "$4" ]; then status=FAIL; FAILURES=$((FAILURES + 1)); fi
    printf '%-4s %-36s A[%s] B[%s]\n' "$status" "$label" "$a" "$b"
}

# app <log> <xcb args...>
app() {
    local log="$1"; shift
    xcb "$@" --raw Host -- -derivedDataPath "$DD" >"$LOG/$log.log" 2>&1 \
        || echo "BUILD FAILED: $log (see $LOG/$log.log)"
}

# cli <log> <env...> -- <xcb args...>
cli() {
    local log="$1"; shift
    local env=()
    while [ "$1" != "--" ]; do env+=("$1"); shift; done; shift
    ( cd HostShaders && rm -rf .build && env ${env[@]+"${env[@]}"} xcb build --raw "$@" >"$LOG/$log.log" 2>&1 ) \
        || echo "BUILD FAILED: $log (see $LOG/$log.log)"
}

DBG_A="src=yes cfg=debug"; REL_A="src=no cfg=release"
DBG_B="src=yes cfg=none";  REL_B="src=no cfg=none"

echo "== Xcode: switch configurations without cleaning =="
app 1-debug build -c Debug;     check "1 Debug (fresh)"         "$DD/Build/Products/Debug"   "$DBG_A" "$DBG_B"
app 2-release build -c Release; check "2 Release (after Debug)" "$DD/Build/Products/Release" "$REL_A" "$REL_B"
app 3-debug build -c Debug;     check "3 Debug (after Release)" "$DD/Build/Products/Debug"   "$DBG_A" "$DBG_B"
app 4-release build -c Release; check "4 Release (again)"       "$DD/Build/Products/Release" "$REL_A" "$REL_B"

echo "== Xcode: custom configuration =="
app 5-staging build -c Staging; check "5 Staging (expect release)" "$DD/Build/Products/Staging" "$REL_A" "$REL_B"

echo "== Xcode: archive =="
app 6-archive archive --archive-path "$WORK/Host.xcarchive"
check "6 Archive" "$WORK/Host.xcarchive" "$REL_A" "$REL_B"

echo "== SwiftPM =="
cli 7-cli-debug --;               check "7 swift build debug"   "HostShaders/.build" "$DBG_A" "$DBG_B"
cli 8-cli-release -- -c release;  check "8 swift build release" "HostShaders/.build" "$REL_A" "$REL_B"

echo "== SwiftPM: stray \$CONFIGURATION in the environment =="
cli 9-cli-stray CONFIGURATION=Debug -- -c release; check "9 CONFIGURATION=Debug, release" "HostShaders/.build" "$REL_A" "$REL_B"
cli 10-cli-stray CONFIGURATION=Release --;         check "10 CONFIGURATION=Release, debug" "HostShaders/.build" "$DBG_A" "$DBG_B"

echo
[ "$FAILURES" -eq 0 ] && echo "All checks passed." || echo "$FAILURES check(s) failed."
exit "$FAILURES"
