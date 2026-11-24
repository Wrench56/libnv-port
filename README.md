# libnv-port

Provides a portable way to build the upstream FreeBSD [libnv](https://man.freebsd.org/cgi/man.cgi?query=libnv) library.

## Installation

### Requirements

Usually need to be installed:

- `clang`
- `lld`
- `llvm-ar`
- `libbsd` (technically the headers are enough)

Usually already installed:

- `curl`, `wget`, or `fetch`
- `sha256sum`
- `pkg-config`
- `make` (both BSD and GNU make work)

### Build

```sh
make
make install
```

`make` builds `libnv.so.1`, `libnv.so` and `libnv.a`. `make clean` removes
them, and `make distclean` also removes `src/`.

#### Custom PREFIX and DESTDIR

`PREFIX` (default `/usr/local`) is where files are installed. `DESTDIR`
stages the install, e.g. for packaging:

```sh
make install PREFIX=/usr DESTDIR="$pkgdir"
```

## Usage

The headers are installed as `<sys/nv.h>`, `<sys/cnv.h>` and `<sys/dnv.h>`
under `include/libnv`. pkg-config adds that path, libbsd's header flags and
`-lnv`:

```sh
cc -o prog prog.c $(pkg-config --cflags --libs libnv)
```

## Reason for existence

There have been previous attempts to do this:

- [Zer0-One/libnv-portable](https://github.com/Zer0-One/libnv-portable) is outdated and contains the two CVEs from 2026: [CVE-2026-35547](https://nvd.nist.gov/vuln/detail/cve-2026-35547) and [CVE-2026-39457](https://nvd.nist.gov/vuln/detail/cve-2026-39457).
- [fudosecurity/nvlist](https://github.com/fudosecurity/nvlist) has the same issue.
