#!/bin/zsh
set -eu
cd "${0:A:h}"
case "${1:-}" in
  '') build_architectures=("$(uname -m)") ;;
  --universal) build_architectures=(arm64 x86_64) ;;
  *) print -u2 'Usage: ./build.sh [--universal]'; exit 2 ;;
esac
app_bundle=build/Curtain.app
mkdir -p .build/cache "$app_bundle/Contents/MacOS" "$app_bundle/Contents/Resources"
for build_arch in "${build_architectures[@]}"; do
  mkdir -p ".build/$build_arch"
  swiftc -O -module-cache-path .build/cache -target "$build_arch-apple-macosx14.0" Sources/*.swift -o ".build/$build_arch/Curtain" -framework AppKit -framework ApplicationServices
done
if (( ${#build_architectures[@]} == 2 )); then
  lipo -create .build/arm64/Curtain .build/x86_64/Curtain -output "$app_bundle/Contents/MacOS/Curtain"
else
  cp ".build/${build_architectures[1]}/Curtain" "$app_bundle/Contents/MacOS/Curtain"
fi
cp Resources/*.wav Resources/*.txt "$app_bundle/Contents/Resources/"
cp Info.plist "$app_bundle/Contents/Info.plist"
if [[ -n "${CURTAIN_VERSION:-}" ]]; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $CURTAIN_VERSION" "$app_bundle/Contents/Info.plist"
fi
if [[ -n "${CURTAIN_BUILD_NUMBER:-}" ]]; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $CURTAIN_BUILD_NUMBER" "$app_bundle/Contents/Info.plist"
fi
if [[ -f Resources/AppIcon.icns ]]; then cp Resources/AppIcon.icns "$app_bundle/Contents/Resources/"; fi
codesign --force --sign - --identifier dev.curtain.mac "$app_bundle"
codesign --verify --deep --strict "$app_bundle"
print "Built: $app_bundle"
