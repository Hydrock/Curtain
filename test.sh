#!/bin/zsh
set -eu
cd "${0:A:h}"
mkdir -p .build/cache
swiftc -O -module-cache-path .build/cache Sources/Cloth.swift Tests/main.swift -o .build/physics-tests
.build/physics-tests
swiftc -O -module-cache-path .build/cache Sources/Cloth.swift Sources/FabricView.swift Sources/WindowTracker.swift Sources/TransparencyControl.swift Sources/VolumeControl.swift Tests/Integration/main.swift -o .build/window-tests -framework AppKit -framework ApplicationServices
.build/window-tests

swiftc -O -module-cache-path .build/cache Sources/AppearanceSettings.swift Tests/Appearance/main.swift -o .build/appearance-tests
.build/appearance-tests

swiftc -O -module-cache-path .build/cache Sources/Cloth.swift Sources/CurtainSound.swift Tests/Sound/main.swift -o .build/sound-tests -framework AppKit
.build/sound-tests
