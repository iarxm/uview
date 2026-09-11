# Persistent preview host options

## Context

`uview` keeps one program per role in `tabbed`: mpv for media, an `st`/Neovim
pair for text, and historically Zathura for PDFs.  This works only when a
preview program implements XEmbed; it is not a general GUI embedding API.

Current Zathura (`2026.07.18`) is GTK4-based and has no `-e XID` XEmbed
option.  GTK4 Zathura cannot be a supported child of `tabbed`.  Do not use
`xdotool windowreparent` as a replacement: it does not make a client XEmbed
aware and failed in the real uview session.

## Directions

| Direction | Persistent state | Modern Zathura | In tabbed | Cost |
| --- | --- | --- | --- | --- |
| Pin GTK3 Zathura | One process, D-Bus `OpenDocument` | No | Yes | Low; legacy dependency |
| Render PDF into mpv | Existing mpv and IPC | Optional external opener | Yes | Low to medium |
| Run current Zathura externally | One process, D-Bus `OpenDocument` | Yes | No | Low; explicit window policy |
| Native renderer host | One host owns every surface | Optional external opener | Yes | High; new application |
| Embed arbitrary GUI apps | Varies | No guarantee | Sometimes | Reject |

The last direction is rejected: X11 reparenting is not XEmbed, and Wayland
does not allow arbitrary foreign-surface embedding.

## Staged plan

### Phase 0: preserve working behavior

1. Restore the original Zathura launch in the production checkout; do not
   ship GTK4 reparenting.
2. Keep mpv and Neovim dispatch unchanged.
3. Keep XID-selection work separate until it passes the live matrix.

### Phase 1: embedded PDF preview without Zathura

The adapter renders the selected page to a cached PNG with `pdftocairo`, then
sends it to the existing mpv IPC socket using `loadfile ... replace`.

- Cache key: absolute path, modification time, page, and render scale.
- Default: page 1.
- Configuration: `pdf_prv=image` (default), `pdf_pag=1`, and `pdf_dpi=100`.
- mpv remains the sole persistent image/media process; no PDF viewer is
  launched per selection.
- An explicit action may open the document in current external Zathura for
  navigation, search, and annotation.

Acceptance checks:

1. text -> PDF -> image -> PDF creates no new mpv process;
2. changed PDFs invalidate the cached page;
3. renderer errors are shown instead of stale output;
4. PDF startup does not delay text/media preview.

### Phase 2: choose interactive PDF policy

Choose one explicit binary; do not select between them implicitly through
`PATH`.

1. **Pinned GTK3 Zathura:** retain/build a known-good Zathura/girara pair with
   `-e`, pin exact source and hashes, and use that explicit executable from
   uview.  This preserves the existing embedded D-Bus protocol.
2. **External current Zathura:** retain D-Bus `OpenDocument`, but keep its
   window out of tabbed.  Define a deliberate tag/floating/raise policy.

### Phase 3: native host, only if required

If rich, interactive PDFs must be contained with previews, replace
app-embedding with a host that owns its own surfaces:

- media: libmpv or existing mpv IPC;
- text: Neovim RPC or terminal rendering;
- PDF: MuPDF library rendering with page/zoom IPC;
- external apps: explicit detached actions, never presumed embeddable.

This is a new application with lifecycle, caching, focus, and licensing
decisions.  Prototype it only if Phase 1 is insufficient.

## Short-term PDF candidates

| Viewer/tool | Persistence and control | Role |
| --- | --- | --- |
| GTK3 Zathura | Existing D-Bus `OpenDocument` | Best embedded path, requiring a pin |
| Current Zathura | D-Bus for an external window | Modern external reader, not tabbed child |
| MuPDF tools | Deterministic rendering, no documented persistent GUI IPC | Phase 1 renderer |
| Okular | `--unique` offers single-instance use | External-only candidate |
| Xpdf | Historic remote-control interface merits a local spike | Do not adopt until current XEmbed behavior is verified |

Treat Sioyek and other GTK/Qt viewers as external unless they document both a
stable embedding contract and a stable remote-control interface.

## Sources

- [Zathura current build requirements](https://github.com/pwmt/zathura/blob/develop/meson.build)
- [MuPDF command-line viewer and tools](https://mupdf.readthedocs.io/_/downloads/en/1.23.0/pdf/)
- [MuPDF `mutool convert`](https://mupdf.readthedocs.io/en/1.28.2/tools/mutool-convert.html)
- [Okular single-instance option](https://docs.kde.org/trunk_kf6/en/okular/okular/command-line-options.html)
