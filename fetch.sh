#!/bin/sh
#
# Fetch the FreeBSD sources listed in sources.sha256 from cgit, verify them,
# and install them.
#
# The following env vars are required:
#  - FREEBSD_CGIT
#  - FREEBSD_COMMIT

set -eu

die() {
	printf '[!] fetch: %s\n' "$*" >&2
	exit 1
}

# Usage: dl $1:OUTPUT $2:URL
dl() {
	if command -v curl >/dev/null 2>&1; then
		curl -fsSL --retry 5 --retry-delay 5 -o "$1" "$2"
	elif command -v fetch >/dev/null 2>&1; then
		fetch -q -o "$1" "$2"
	elif command -v wget >/dev/null 2>&1; then
		wget -q -O "$1" "$2"
	else
		die 'need curl, fetch, or wget!'
	fi
}

# Remove a partial download on failure or interruption.
trap 'rm -rf src.tmp' EXIT
trap 'exit 1' HUP INT TERM

cd -P -- "$(dirname -- "$0")"
rm -rf src.tmp
mkdir src.tmp

while read -r _ f; do
	echo "fetch $f"
	mkdir -p "src.tmp/$(dirname -- "$f")"
	dl "src.tmp/$f" "$FREEBSD_CGIT/$f?h=$FREEBSD_COMMIT" || die "download failed: $f"
done < sources.sha256

if ! (cd src.tmp && sha256sum -c --strict --quiet ../sources.sha256); then
	die 'checksum verification failed!'
fi

rm -rf src
mv src.tmp src
