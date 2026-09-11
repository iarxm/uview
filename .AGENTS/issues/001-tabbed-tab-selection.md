# 001: Tab selection is coupled to startup/window order

Status: open; unvalidated attempt reverted  
Priority: high  
Area: `uview` / `tabbed` XEmbed integration

## Problem

On startup, and when switching between preview file types, uview can display
the wrong tab.  The intended preview application may still receive the file,
but the visible `tabbed` page does not reliably match it.

## Evidence in the current code

- `_prg_tbd_ini` launches `mpv`, then starts `nvim` in the background and
  Zathura without waiting for each embedded client to be identified.
- `_tab_swi` calls `_tab_chg` with fixed values 1, 2, and 3; `_tab_chg` sends
  `Ctrl+<number>` to `tabbed`.
- The startup comment says tabbed uses relative tabs and `new pos = 1`, so
  insertion position is configuration-dependent rather than role-dependent.
- `_zat_ini` can open a blank PDF and then the current PDF, which can create an
  additional window/tab in some scenarios.

The defect is therefore a race/identity bug: a tab ordinal is being treated as
the stable identity of a preview role.

## Reproduction to confirm

1. Start uview from its file-manager workflow with a text file selected.
2. Quickly move among a text file, a PDF, and a media file; repeat immediately
   after uview starts.
3. Observe whether the visible tab matches the selected file's preview type.
4. Repeat with tabbed configured to insert new tabs at position 1 and with a
   PDF as the first selected file.

Record the tabbed version/configuration, selected path sequence, and the X
window tree (`xwininfo -id "$xid_tbd" -children`) if it fails.

## Proposed repair plan

An attempted implementation that discovered direct child windows and selected
them through `_TABBED_SELECT_TAB` was reverted after live use stopped all
previews.  It made an unverified assumption about the embedding/window tree
and must not be retried without observing the running instance.

## Revised repair plan

1. Capture a failing and a working session from the actual desktop: tabbed XID,
   `xwininfo -id "$xid_tbd" -tree`, and the client process tree after each
   preview role starts.
2. Verify whether the installed, locally configured tabbed handles
   `_TABBED_SELECT_TAB`; upstream support alone is insufficient evidence.
3. If the property works, identify clients using the observed hierarchy and
   verify every role before changing selection.  Do not make startup depend on
   that discovery until it has a safe fallback.
4. If it does not work, patch the locally built tabbed with a minimal,
   reviewable role-to-client selection interface, then target that pinned local
   build explicitly.
5. Only then replace ordinal selection, retaining the current startup behavior
   until the replacement passes the live matrix below.

The remaining work is live X11 investigation across the matrix below.

| First selected type | Next selected types |
| --- | --- |
| text or directory | PDF, image, audio, video |
| PDF | text, image, audio, video |
| image, audio, or video | text, directory, PDF |

Run each row with the current relative new-tab position and with position 1.

## Acceptance criteria

- The visible tab always corresponds to the MIME-dispatched preview role after
  startup and after every supported file-type change.
- Results do not depend on application launch order, sleep duration, or
  tabbed's new-tab insertion setting.
- PDF initialization cannot cause selection of an unintended tab.
- Failure to embed a client times out with a useful diagnostic and leaves
  cleanup safe.
