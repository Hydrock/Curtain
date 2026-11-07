#!/bin/zsh
set -eu
cd "${0:A:h}"
mkdir -p .build/cache build/Curtain.app/Contents/MacOS build/Curtain.app/Contents/Resources
swiftc -O -module-cache-path .build/cache -target "$(uname -m)-apple-macosx14.0" Sources/*.swift -o build/Curtain.app/Contents/MacOS/Curtain -framework AppKit -framework ApplicationServices
cp Resources/*.wav Resources/Sound-LICENSE.txt build/Curtain.app/Contents/Resources/
cp Info.plist build/Curtain.app/Contents/Info.plist
if [[ -f Resources/AppIcon.icns ]]; then cp Resources/AppIcon.icns build/Curtain.app/Contents/Resources/; fi
codesign --force --sign - --identifier dev.curtain.mac build/Curtain.app
print 'Готово: build/Curtain.app'
