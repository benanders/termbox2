prefix?=/usr/local

termbox_cflags:=-std=c99 -Wall -Wextra -pedantic -Wno-unused-result -g -O0 -D_XOPEN_SOURCE -D_DEFAULT_SOURCE $(CFLAGS)
termbox_demos:=$(patsubst demo/%.c,demo/%,$(wildcard demo/*.c))
termbox_so:=libtermbox.so
termbox_a:=libtermbox.a
termbox_o:=termbox.o
termbox_h:=termbox.h
termbox_ffi_h:=termbox.ffi.h

all: $(termbox_demos)

$(termbox_demos): %: %.c
	$(CC) -DTB_OPT_TRUECOLOR -DTB_OPT_EGC $(termbox_cflags) $^ -o $@

$(termbox_o): $(termbox_h)
	$(CC) -DTB_IMPL -DTB_OPT_TRUECOLOR -DTB_OPT_EGC -fPIC -xc -c $(termbox_cflags) $(termbox_h) -o $@

$(termbox_so): $(termbox_o)
	$(CC) -shared $(termbox_o) -o $@

$(termbox_a): $(termbox_o)
	$(AR) rcs $@ $(termbox_o)

$(termbox_ffi_h): $(termbox_h)
	awk '/__ffi_start/{p=1} p==1 || /__TERMBOX_H/{print}' $^ | $(CC) -DTB_OPT_TRUECOLOR -DTB_OPT_EGC $(termbox_cflags) -P -E - >$@

terminfo:
	awk -vg=0 'g==0{print} /BEGIN codegen h/{g=1; system("./codegen.sh h")} /END codegen h/{g=0; print} g==1{next}' termbox.h >termbox.h.tmp && mv -vf termbox.h.tmp termbox.h
	awk -vg=0 'g==0{print} /BEGIN codegen c/{g=1; system("./codegen.sh c")} /END codegen c/{g=0; print} g==1{next}' termbox.h >termbox.h.tmp && mv -vf termbox.h.tmp termbox.h

test: $(termbox_so) $(termbox_ffi_h)
	docker build -f tests/Dockerfile --build-arg=cflags="$(termbox_cflags)" .

test_local: $(termbox_so) $(termbox_ffi_h)
	./tests/run.sh

install:
	install -d $(DESTDIR)$(prefix)/include
	install -p -m 644 $(termbox_h) $(DESTDIR)$(prefix)/include/$(termbox_h)

clean:
	rm -f $(termbox_demos) $(termbox_o) $(termbox_a) $(termbox_so) $(termbox_ffi_h) tests/**/observed.ansi

.PHONY: all terminfo test test_local install clean
