CC = clang
AR = llvm-ar
CFLAGS = -O2 -g
LDFLAGS = -fuse-ld=lld
PREFIX = /usr/local
DESTDIR =

FREEBSD_COMMIT = 318895df272fa6d63ba2e5b5cc71e3b8a2bf9f5a
FREEBSD_CGIT = https://cgit.freebsd.org/src/plain

NV = src/sys/contrib/libnv
LIB = src/lib/libnv

NV_CC = $(CC) -std=gnu11 -fPIC -Wall -Wextra -Wno-sign-compare -Wno-unused-parameter \
	`pkg-config --cflags libbsd-overlay` -D'__unused=__attribute__((__unused__))' \
	-I$(LIB) -I$(NV) -Isrc/sys $(CFLAGS)

# Linux PKG_MAX_SIZE exceeds SCM_MAX_FD (253), so use the generic value.
MSGIO_CFLAGS = -U__linux__ -DMCLBYTES=2048

OBJS = cnvlist.o dnvlist.o nvlist.o bsd_nvpair.o msgio.o

.PHONY: all fetch checksums install clean distclean

all: libnv.so.1 libnv.so libnv.a
fetch: src

src: sources.sha256 fetch.sh
	@FREEBSD_COMMIT='$(FREEBSD_COMMIT)' FREEBSD_CGIT='$(FREEBSD_CGIT)' sh ./fetch.sh

checksums:
	(cd src && find * -type f | LC_ALL=C sort | xargs sha256sum) > sources.sha256

cnvlist.o: src
	$(NV_CC) -c -o $@ $(NV)/cnvlist.c
dnvlist.o: src
	$(NV_CC) -c -o $@ $(NV)/dnvlist.c
nvlist.o: src
	$(NV_CC) -c -o $@ $(NV)/nvlist.c
bsd_nvpair.o: src
	$(NV_CC) -c -o $@ $(NV)/bsd_nvpair.c
msgio.o: src
	$(NV_CC) $(MSGIO_CFLAGS) -c -o $@ $(LIB)/msgio.c

# Version.map lists FreeBSD-only cred_send/cred_recv.
libnv.so.1: $(OBJS)
	$(CC) -shared -Wl,-soname,libnv.so.1 -Wl,--version-script=$(LIB)/Version.map \
	    -Wl,--undefined-version -Wl,-z,defs $(LDFLAGS) -o $@ $(OBJS)

libnv.so: libnv.so.1
	ln -sf libnv.so.1 $@

libnv.a: $(OBJS)
	$(AR) rcs $@ $(OBJS)

DEST = $(DESTDIR)$(PREFIX)
install: all
	install -d $(DEST)/lib/pkgconfig $(DEST)/include/libnv/sys
	install -m 644 libnv.so.1 libnv.a $(DEST)/lib/
	ln -sf libnv.so.1 $(DEST)/lib/libnv.so
	sed 's|@PREFIX@|$(PREFIX)|' libnv.pc.in > $(DEST)/lib/pkgconfig/libnv.pc
	install -m 644 src/sys/sys/*.h $(DEST)/include/libnv/sys/

clean:
	rm -f $(OBJS) libnv.so.1 libnv.so libnv.a

distclean: clean
	rm -rf src src.tmp
