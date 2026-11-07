#!/bin/zsh
set -eu
cd "${0:A:h}"
case "${1:-}" in
  ''|--headless) ;;
  *) print -u2 'Usage: ./test.sh [--headless]'; exit 2 ;;
esac
mkdir -p .build/cache
swiftc -O -module-cache-path .build/cache Sources/FabricMaterial.swift Sources/Cloth.swift Tests/main.swift -o .build/physics-tests
.build/physics-tests
if [[ "${1:-}" != --headless ]]; then
swiftc -O -module-cache-path .build/cache Sources/Localization.swift Sources/FabricMaterial.swift Sources/Cloth.swift Sources/FabricView.swift Sources/WindowTracker.swift Sources/TransparencyControl.swift Sources/VolumeControl.swift Sources/WindControl.swift Tests/Integration/main.swift -o .build/window-tests -framework AppKit -framework ApplicationServices
.build/window-tests
fi

swiftc -O -module-cache-path .build/cache Sources/FabricMaterial.swift Sources/AppearanceSettings.swift Tests/Appearance/main.swift -o .build/appearance-tests
.build/appearance-tests

swiftc -O -module-cache-path .build/cache Sources/FabricMaterial.swift Sources/Cloth.swift Sources/CurtainSound.swift Tests/Sound/main.swift -o .build/sound-tests -framework AppKit
.build/sound-tests

swiftc -O -module-cache-path .build/cache Sources/Localization.swift Tests/Localization/main.swift -o .build/localization-tests
.build/localization-tests

swiftc -O -module-cache-path .build/cache Sources/FabricMaterial.swift Sources/Cloth.swift Sources/WindSettings.swift Tests/Wind/main.swift -o .build/wind-tests
.build/wind-tests

swiftc -O -module-cache-path .build/cache Sources/FabricMaterial.swift Sources/Cloth.swift Sources/AppearanceSettings.swift Tests/Materials/main.swift -o .build/material-tests
.build/material-tests
