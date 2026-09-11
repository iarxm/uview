# Improvement backlog

This is an initial analysis, not an approved implementation roadmap.  Each
item needs a focused design and validation plan before changing `uview`.

## 1. Stabilise preview-tab identity

Priority: high.  See [issue 001](issues/001-tabbed-tab-selection.md).

Replace ordinal tab selection with a verified mapping from preview role
(`mpv`, `nvim`, `zathura`) to its embedded X window/tab.  This removes the
startup and file-type-switching race and is the prerequisite for reliable UI
tests.

## 2. Make lifecycle and cleanup reliable

Priority: high.  `_kil` assumes globally available PIDs and removes only two
sockets.  Design an idempotent cleanup path that tracks every spawned child and
cleans the Zathura, FIFO, and temporary resources it owns without touching a
pre-existing user process.

## 3. Separate dispatch from X11/process control

Priority: medium.  MIME routing, application IPC, startup, focus management,
and FIFO reading currently live in one script.  Extract small Bash functions
around explicit interfaces first, then test MIME-to-preview-role dispatch with
stub commands.

## 4. Make configuration explicit and validated

Priority: medium.  `~/.config/uview/config` is sourced directly and its
supported variables are implicit.  Document the public variables, validate
required commands and FIFO inputs early, and distinguish user configuration
errors from preview-process failures.

## 5. Add a reproducible integration harness

Priority: later.  A disposable X server plus fake FIFO, window, IPC, and D-Bus
adapters would let tests assert tab identity and dispatch without a desktop.
Build this only after the identity boundary in item 1 is designed.
