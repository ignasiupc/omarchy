#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

run_node_test <<'JS'
const osd = requireFromRoot('shell/plugins/osd/OsdModel.js')

assertEqual(osd.iconFor('', 0), osd.iconFor('volume-low', 50), 'osd falls back to low icon at zero percent')
assert(osd.iconFor('', 0) !== osd.iconFor('muted', 0), 'osd distinguishes zero percent from mute')
assertEqual(osd.iconFor('volume-high', 1), osd.iconFor('', 100), 'osd maps high volume aliases')

// Keep the same Font Awesome speaker family used by the audio bar and panel,
// so the icon does not change shape when the OSD appears.
assertEqual(osd.iconFor('volume-low', 20), '', 'osd shows the low volume speaker')
assertEqual(osd.iconFor('volume-medium', 50), '', 'osd shows the medium volume speaker')
assertEqual(osd.iconFor('volume-high', 80), '', 'osd shows the high volume speaker')
assertEqual(osd.iconFor('volume-muted', 20), '', 'osd shows the crossed speaker when muted')

// Percentage-only callers must land on the same speakers as named levels.
assertEqual(osd.iconFor('', 20), osd.iconFor('volume-low', 20), 'osd fallback matches low')
assertEqual(osd.iconFor('', 50), osd.iconFor('volume-medium', 50), 'osd fallback matches medium')
assertEqual(osd.iconFor('', 80), osd.iconFor('volume-high', 80), 'osd fallback matches high')
assertEqual(osd.iconFor('logout', 50), '󰍃', 'osd maps logout icon')
assertEqual(osd.iconFor('custom-symbol', 50), 'custom-symbol', 'osd preserves unknown explicit icons')
assertEqual(osd.widestIcon, osd.iconFor('volume-high', 100), 'osd sizes the icon column to a glyph it can show')

assertDeepEqual(
  osd.stateForShow('volume', '', '75', '100', '', '800'),
  {
    iconKey: 'volume',
    maxValue: 100,
    hasProgress: true,
    value: 75,
    message: '75%',
    icon: osd.iconFor('volume', 75),
    duration: 800
  },
  'osd builds progress state'
)

assertDeepEqual(
  osd.stateForShow('media-pause', 'Paused', '', '100', '', 'nope'),
  {
    iconKey: 'media-pause',
    maxValue: 100,
    hasProgress: false,
    value: 0,
    message: 'Paused',
    icon: osd.iconFor('media-pause', -1),
    duration: 1200
  },
  'osd builds message state'
)
JS
