PREFIX ?= /usr/local
DESTDIR ?=
BINDIR = $(DESTDIR)$(PREFIX)/bin
DATADIR = $(DESTDIR)$(PREFIX)/share/uview

all:
	@echo "Run 'make install' to install the scripts."

check-conflicts:
	@target="$(PREFIX)/bin/uview"; existing="$$(command -v uview 2>/dev/null || :)"; \
	[ -z "$$existing" ] || [ "$$existing" = "$$target" ] || { \
		printf '%s\n' "uview: existing command found at $$existing" >&2; \
		printf '%s\n' "uview: this install will place $(PREFIX)/bin/uview ahead of it when PATH prefers $(PREFIX)/bin." >&2; \
		if [ ! -t 0 ] && [ "$(CONFIRM_CONFLICT)" != 1 ]; then \
			printf '%s\n' "uview: refusing non-interactive install; rerun with CONFIRM_CONFLICT=1 to continue." >&2; exit 1; \
		fi; \
		[ "$(CONFIRM_CONFLICT)" = 1 ] || { \
			printf '%s' 'Continue without removing the existing command? [y/N] ' >&2; \
			IFS= read -r answer; case "$$answer" in [yY]|[yY][eE][sS]) ;; *) exit 1;; esac; }; \
	}

install:
	@if [ -z "$(DESTDIR)" ]; then $(MAKE) check-conflicts; fi
	install -d $(BINDIR)
	install -m 755 uview $(BINDIR)
	install -d $(DATADIR)
	install -m 644 config $(DATADIR)/config
