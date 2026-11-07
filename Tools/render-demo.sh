#!/bin/zsh
set -eu
cd "${0:A:h}/.."
command -v ffmpeg >/dev/null || { print -u2 'Install ffmpeg to encode the demo.'; exit 1; }
mkdir -p .build/cache
swiftc -O -module-cache-path .build/cache Sources/Localization.swift Sources/Cloth.swift Sources/FabricView.swift Sources/Welcome.swift Tools/Demo/main.swift -o .build/make-demo -framework AppKit
.build/make-demo
ffmpeg -y -hide_banner -loglevel error -framerate 30 -i .build/demo-frames/frame%03d.png -vf 'format=yuv420p' -c:v libx264 -crf 23 -movflags +faststart docs/assets/demo.mp4
ffmpeg -y -hide_banner -loglevel error -framerate 30 -i .build/demo-frames/frame%03d.png -filter_complex '[0:v]fps=12,scale=600:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=64:stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=4:diff_mode=rectangle' -loop 0 docs/assets/demo.gif
