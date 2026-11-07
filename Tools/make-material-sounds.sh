#!/bin/sh
# Derive material variants from the existing, approved cloth recordings.
set -eu
cd "$(dirname "$0")/.."
for direction in Open Close; do
  input="Resources/Curtain${direction}.wav"
  reverse=""
  if [ "$direction" = Close ]; then reverse="areverse,"; fi
  ffmpeg -nostdin -hide_banner -loglevel error -y -i "$input" \
    -af "${reverse}asetrate=39690,aresample=44100,highpass=f=65,lowpass=f=1500,volume=0.82,afade=t=in:d=0.035,afade=t=out:st=0.76:d=0.11" \
    -ar 44100 -ac 1 -c:a pcm_s16le "Resources/Velvet${direction}.wav"
  ffmpeg -nostdin -hide_banner -loglevel error -y -i "$input" \
    -af "${reverse}atempo=1.25,highpass=f=210,lowpass=f=4800,volume=0.78,afade=t=in:d=0.015,afade=t=out:st=0.54:d=0.085" \
    -ar 44100 -ac 1 -c:a pcm_s16le "Resources/Cotton${direction}.wav"
  ffmpeg -nostdin -hide_banner -loglevel error -y -i "$input" \
    -af "${reverse}atempo=1.08,highpass=f=460,lowpass=f=3300,volume=0.62,afade=t=in:d=0.045,afade=t=out:st=0.61:d=0.115" \
    -ar 44100 -ac 1 -c:a pcm_s16le "Resources/Tulle${direction}.wav"
done
