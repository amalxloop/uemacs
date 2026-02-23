# Makefile for uEmacs/PK with extended features
#
# Notes
# - `make install` installs the program binary only.
# - `make configs-install` installs user configuration files.
# - `make install-all` runs both in order.
# - Use `sudo make install` when installing into system directories.

# Make the build silent by default
V =

ifeq ($(strip $(V)),)
	E = @echo
	Q = @
else
	E = @\#
	Q =
endif
export E Q

uname_S := $(shell sh -c 'uname -s 2>/dev/null || echo not')

PROGRAM=em
LINK_NAME=uemacs

SRC=	basic.c bind.c buffer.c colorscheme.c command_mode.c cutln.c display.c eval.c exec.c file.c \
	fileio.c highlight.c input.c isearch.c line.c lock.c globals.c main.c \
	names.c ux.c paste_slot.c pklock.c platform.c posix.c random.c region.c search.c \
	spawn.c tcap.c usage.c utf8.c version.c window.c word.c wrapper.c cscope.c

OBJ=	basic.o bind.o buffer.o colorscheme.o command_mode.o cutln.o display.o eval.o exec.o file.o \
	fileio.o highlight.o input.o isearch.o line.o lock.o globals.o main.o \
	names.o ux.o paste_slot.o pklock.o platform.o posix.o random.o region.o search.o \
	spawn.o tcap.o usage.o utf8.o version.o window.o word.o wrapper.o cscope.o

HDR=	command_mode.h colorscheme.h ebind.h edef.h efunc.h epath.h estruct.h evar.h \
	highlight.h line.h paste_slot.h platform.h usage.h utf8.h util.h \
	version.h video.h wrapper.h ux.h

# DO NOT ADD OR MODIFY ANY LINES ABOVE THIS -- make source creates them

CC=gcc
WARNINGS=-Wall -Wstrict-prototypes -Wuninitialized

DEFINES=-DPOSIX -D_GNU_SOURCE

CFLAGS=-Os -ffunction-sections -fdata-sections $(WARNINGS) $(DEFINES)
LDFLAGS=-Wl,--gc-sections

LIBS=ncurses hunspell
BINDIR=$(HOME)/bin
LIBDIR=$(HOME)/lib

CFLAGS += $(shell pkg-config --cflags $(LIBS)) -I/usr/include/hunspell
LDLIBS += $(shell pkg-config --libs $(LIBS)) -lpcre2-8

$(PROGRAM): $(OBJ)
	$(E) "  LINK     " $@
	$(Q) $(CC) $(LDFLAGS) $(DEFINES) -o $@ $(OBJ) $(LDLIBS)

.c.o:
	$(E) "  CC       " $@
	$(Q) ${CC} ${CFLAGS} -c $<

clean:
	$(E) "  CLEAN"
	$(Q) rm -f $(PROGRAM) core lintout makeout tags makefile.bak *.o

# -----------------------------------------------------------------------------
# Install configuration
#
# PREFIX:
#   - Default install prefix for the program binary.
#   - Typical system install: PREFIX=/usr/local with `sudo make install`.
#   - Per-user install: PREFIX=$(HOME)/.local
#
# Config installation:
#   - User configuration in XDG_CONFIG_HOME (fallback: $(HOME)/.config).
#   - Separated into `configs-install`.
# -----------------------------------------------------------------------------

PREFIX ?= /usr/local
DESTDIR ?=

# Default install path for the executable.
INSTALL_BIN = $(DESTDIR)$(PREFIX)/bin

# User config directory (XDG base directory spec fallback).
XDG_CONFIG_HOME ?= $(HOME)/.config
INSTALL_CONF = $(DESTDIR)$(XDG_CONFIG_HOME)/uemacs

PROG_EXT =

# Adjust for Windows (MinGW/MSYS/Cygwin).
ifneq (,$(findstring MINGW,$(uname_S)))
	PROG_EXT = .exe
	ifeq ($(PREFIX),/usr/local)
		INSTALL_BIN = $(DESTDIR)$(HOME)/bin
	endif
endif
ifneq (,$(findstring CYGWIN,$(uname_S)))
	PROG_EXT = .exe
endif

install: $(PROGRAM)
	$(E) "  INSTALL  " $(PROGRAM) " -> " $(INSTALL_BIN)
	$(Q) install -d "$(INSTALL_BIN)"
	$(Q) install -m 755 "$(PROGRAM)$(PROG_EXT)" "$(INSTALL_BIN)/$(PROGRAM)$(PROG_EXT)"
	$(E) "  LINK     " "$(LINK_NAME) -> $(PROGRAM)"
	$(Q) ln -sf "$(INSTALL_BIN)/$(PROGRAM)$(PROG_EXT)" "$(INSTALL_BIN)/$(LINK_NAME)$(PROG_EXT)"

configs-install:
	$(E) "  CONFIG   " "configs/uemacs -> " $(INSTALL_CONF)
	$(Q) install -d "$(INSTALL_CONF)"
	$(Q) find configs/uemacs -type f -not -name '.editorconfig' | while read f; do \
		rel=$${f#configs/uemacs/}; \
		dir=$(INSTALL_CONF)/$$(dirname $$rel); \
		install -d "$$dir"; \
		if [ -f "$(INSTALL_CONF)/$$rel" ]; then \
			cp "$(INSTALL_CONF)/$$rel" "$(INSTALL_CONF)/$$rel.bak"; \
		fi; \
		cp "$$f" "$(INSTALL_CONF)/$$rel"; \
	done
	$(Q) install -m 644 syntax.ini "$(INSTALL_CONF)/syntax.ini"
	$(Q) cp -n emacs.hlp "$(INSTALL_CONF)/emacs.hlp" 2>/dev/null || true

backups-clean:
	$(E) "  CLEAN BACKUPS"
	$(Q) find "$(INSTALL_CONF)" -name "*.bak" -delete

install-all: install configs-install

source:
	@mv Makefile Makefile.bak
	@echo "# Makefile for uEmacs/PK, updated `date`" >Makefile
	@echo '' >>Makefile
	@echo SRC=`ls *.c` >>Makefile
	@echo OBJ=`ls *.c | sed s/c$$/o/` >>Makefile
	@echo HDR=`ls *.h` >>Makefile
	@echo '' >>Makefile
	@sed -n -e '/^# DO NOT ADD OR MODIFY/,$$p' <Makefile.bak >>Makefile

depend: ${SRC}
	@for i in ${SRC}; do $(CC) ${DEFINES} -MM $$i; done >makedep
	@echo '/^# DO NOT DELETE THIS LINE/+2,$$d' >eddep
	@echo '$$r ./makedep' >>eddep
	@echo 'w' >>eddep
	@cp Makefile Makefile.bak
	@ed - Makefile <eddep
	@rm eddep makedep
	@echo '' >>Makefile
	@echo '# DEPENDENCIES MUST END AT END OF FILE' >>Makefile
	@echo '# IF YOU PUT STUFF HERE IT WILL GO AWAY' >>Makefile
	@echo '# see make depend above' >>Makefile

# DO NOT DELETE THIS LINE -- make depend uses it

basic.o: basic.c estruct.h edef.h efunc.h line.h utf8.h
bind.o: bind.c estruct.h edef.h efunc.h epath.h line.h utf8.h util.h
buffer.o: buffer.c estruct.h edef.h efunc.h line.h utf8.h
colorscheme.o: colorscheme.c colorscheme.h platform.h util.h
command_mode.o: command_mode.c command_mode.h estruct.h edef.h efunc.h line.h
cscope.o: cscope.c estruct.h edef.h efunc.h line.h utf8.h util.h
cutln.o: cutln.c estruct.h edef.h efunc.h line.h paste_slot.h
display.o: display.c estruct.h edef.h efunc.h line.h utf8.h version.h wrapper.h ux.h highlight.h video.h
eval.o: eval.c estruct.h edef.h efunc.h evar.h line.h utf8.h util.h version.h
exec.o: exec.c estruct.h edef.h efunc.h line.h utf8.h
file.o: file.c estruct.h edef.h efunc.h line.h utf8.h util.h
fileio.o: fileio.c estruct.h edef.h efunc.h
globals.o: globals.c estruct.h edef.h
highlight.o: highlight.c highlight.h colorscheme.h platform.h util.h
input.o: input.c estruct.h edef.h efunc.h wrapper.h
isearch.o: isearch.c estruct.h edef.h efunc.h line.h utf8.h
line.o: line.c line.h utf8.h estruct.h edef.h efunc.h
lock.o: lock.c estruct.h edef.h efunc.h
main.o: main.c estruct.h edef.h efunc.h ebind.h line.h utf8.h version.h ux.h command_mode.h
names.o: names.c estruct.h edef.h efunc.h line.h utf8.h
paste_slot.o: paste_slot.c estruct.h edef.h efunc.h utf8.h util.h video.h
pklock.o: pklock.c estruct.h edef.h efunc.h
platform.o: platform.c platform.h
posix.o: posix.c estruct.h edef.h efunc.h utf8.h
random.o: random.c estruct.h edef.h efunc.h line.h utf8.h
region.o: region.c estruct.h edef.h efunc.h line.h utf8.h
search.o: search.c estruct.h edef.h efunc.h line.h utf8.h
spawn.o: spawn.c estruct.h edef.h efunc.h
tcap.o: tcap.c estruct.h edef.h efunc.h
usage.o: usage.c usage.h
utf8.o: utf8.c utf8.h
ux.o: ux.c ux.h estruct.h edef.h efunc.h line.h util.h version.h highlight.h platform.h colorscheme.h paste_slot.h
version.o: version.c version.h
window.o: window.c estruct.h edef.h efunc.h line.h utf8.h wrapper.h
word.o: word.c estruct.h edef.h efunc.h line.h utf8.h
wrapper.o: wrapper.c usage.h

# DEPENDENCIES MUST END AT END OF FILE
# IF YOU PUT STUFF HERE IT WILL GO AWAY
# see make depend above
