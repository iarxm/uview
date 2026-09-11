# uview agent workspace

`uview` is a small Bash preview bridge for file managers that expose a FIFO
(principally nnn).  It owns one `tabbed` XEmbed window and keeps specialised
preview applications alive inside it:

- `mpv` for audio, image, video, and generic binary previews via its IPC socket;
- `nvim` in an embedded terminal for text and directories via its server socket;
- `zathura` for PDFs via D-Bus.

The program reads paths from `NNN_FIFO` (or its first argument), determines
their MIME type with `file`, selects a preview application, and sends that
application the next file.  Runtime behavior depends on an X11 session,
`tabbed` configuration, and the installed preview applications; no GUI
behavior is currently covered by automated tests.

## Source of truth

- `uview` contains all runtime behavior.
- `README` is the short user-facing description.
- `Makefile` installs only `uview`.
- `.test/xenv` is a lightweight development environment helper, not a test
  suite.
- `.AGENTS/issues/` holds local, repository-scoped issue records; its index is
  `.AGENTS/issues/README.md`.

## Working agreement

1. Start with `README`, `uview`, and the relevant issue or plan in this
   directory.
2. Preserve the existing Bash structure and make focused diffs.  Do not
   reformat unrelated code.
3. Treat X11 window creation, `tabbed` settings, and D-Bus/IPC behavior as
   integration boundaries.  State assumptions and verify them manually where
   possible.
4. Prefer deterministic process/window discovery and explicit identities over
   sleeps, job-control output, window order, or tab positions.
5. Run `bash -n uview` for every script change.  Add a shell-level regression
   test when behavior can be isolated without a live X server; otherwise record
   exact manual reproduction and acceptance checks in the issue.

See [WORKFLOW.md](WORKFLOW.md) for the current improvement backlog and
[issues/001-tabbed-tab-selection.md](issues/001-tabbed-tab-selection.md) for
the active tabbed defect.
