#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

stub_bin="$test_tmp/bin"
log="$test_tmp/calls"
mkdir -p "$stub_bin"

cat >"$stub_bin/omarchy-audio-tuning" <<'STUB'
#!/bin/bash
exit 0
STUB

cat >"$stub_bin/omarchy-audio-output-sink" <<'STUB'
#!/bin/bash
printf 'stub_sink\n'
STUB

cat >"$stub_bin/omarchy-audio-output-set-default" <<'STUB'
#!/bin/bash
exit 0
STUB

cat >"$stub_bin/pactl" <<'STUB'
#!/bin/bash
if [[ $1 == "-f" ]]; then
  printf '[{"index":1,"name":"stub_sink","description":"Stub output","ports":[],"volume":{"front-left":{"value_percent":"%s%%"}}}]\n' "${STUB_PERCENT:-50}"
  exit 0
fi

case "$1" in
  get-default-sink) printf 'stub_sink\n' ;;
  get-sink-volume) printf 'Volume: front-left: 0 / %s%% / 0.00 dB\n' "${STUB_PERCENT:-50}" ;;
  get-sink-mute) printf 'Mute: %s\n' "${STUB_MUTED:-no}" ;;
esac
STUB

cat >"$stub_bin/omarchy-osd" <<'STUB'
#!/bin/bash
printf 'omarchy-osd %s\n' "$*" >>"$TEST_LOG"
STUB

chmod +x "$stub_bin"/*

icon_for_percent() {
  : >"$log"
  STUB_PERCENT="$1" \
    STUB_MUTED="${2:-no}" \
    TEST_LOG="$log" \
    PATH="$stub_bin:$PATH" \
    bash "$ROOT/bin/omarchy-audio-output-switch" >/dev/null

  sed -n 's/.*-i volume-\([^ ]*\).*/\1/p' "$log"
}

assert_icon() {
  local percent="$1" expected="$2" muted="${3:-no}" actual
  actual=$(icon_for_percent "$percent" "$muted")

  if [[ $actual == "$expected" ]]; then
    pass "output switch at $percent% muted=$muted shows $expected"
  else
    fail "output switch at $percent% muted=$muted shows $expected" \
      "expected: $expected
actual:   $actual"
  fi
}

assert_icon 0 low
assert_icon 0 muted yes
assert_icon 33 low
assert_icon 34 medium
assert_icon 66 medium
assert_icon 67 high
