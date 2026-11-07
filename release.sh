#!/bin/zsh
set -eu
cd "${0:A:h}"
release_version="${1:-}"
if [[ ! "$release_version" =~ '^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$' ]]; then
  print -u2 'Usage: ./release.sh 1.0.0 (or 1.0.0-beta.1)'
  exit 2
fi
export CURTAIN_VERSION="${release_version%%-*}"
export CURTAIN_BUILD_NUMBER="${GITHUB_RUN_NUMBER:-1}"
./build.sh --universal
release_archs="$(lipo -archs build/Curtain.app/Contents/MacOS/Curtain)"
if [[ " $release_archs " != *" arm64 "* || " $release_archs " != *" x86_64 "* ]]; then
  print -u2 "Missing universal architecture: $release_archs"; exit 1
fi
mkdir -p build/releases
release_archive="Curtain-$release_version-universal.zip"
ditto -c -k --sequesterRsrc --keepParent build/Curtain.app "build/releases/$release_archive"
(cd build/releases && shasum -a 256 "$release_archive" > SHA256SUMS.txt)
cat > build/releases/RELEASE-NOTES.md <<NOTES
Native curtains for macOS windows, with cloth physics, transparency and sound controls.

- Requires macOS 14 or later. Universal app: Apple Silicon and Intel.
- Download **$release_archive**, unzip, and move Curtain.app to Applications.
- The demo needs no permissions. External windows require macOS Accessibility access.
- This build is ad hoc signed and **not notarized**. macOS may block first launch.
  Developer ID signing and Apple notarization are not configured for these releases.
- SHA256SUMS.txt contains the archive checksum.

English is the default. Choose Language → English / Русский to switch without restarting.
NOTES
print "Release archive: build/releases/$release_archive"
