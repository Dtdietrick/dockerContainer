#!/bin/bash
ROM="$1"
if [ -z "$ROM" ]; then
  echo "No ROM specified!"
  exit 1
fi

# Start virtual display
Xvfb :99 -screen 0 1280x720x24 &
sleep 1
export DISPLAY=:99

# Start PulseAudio in system mode with PipeWire compatibility
echo "🔊 Starting PulseAudio in system mode..."
pulseaudio --system \
  --disallow-exit \
  --exit-idle-time=-1 \
  --log-level=info \
  --log-target=stderr \
  -nF /etc/pulse/default.pa &
sleep 2

# Wait for PulseAudio to become available
for i in {1..10}; do
  if pactl info &>/dev/null; then
    echo "✅ PulseAudio is ready."
    break
  fi
  echo "📡 pactl info:"
  pactl info || echo "❌ pactl failed"
  sleep 1
done

echo "👤 Current user: $(whoami)"
echo "🖥 DISPLAY = $DISPLAY"
echo "🚀 Launching RetroArch..."

# Start RetroArch (make sure libpipewire is installed in image)
./retroarch \
  --config /config/retroarch.cfg \
  -L cores/mgba_libretro.so \
  "roms/$ROM" \
  --verbose > /saves/retroarch.log 2>&1 &

sleep 2
pgrep retroarch > /dev/null || echo "💥 RetroArch died immediately"

# Start VNC + WebSocket proxy
x11vnc -display :99 -nopw -listen localhost -xkb -forever &
websockify --web=/usr/share/novnc 52300 localhost:5900 &

# Wait for VNC client and exit if none
sleep 20
while true; do
  CLIENTS=$(netstat -an | grep ":5900" | grep ESTABLISHED | wc -l)
  if [ "$CLIENTS" -eq 0 ]; then
    echo "🛑 No active VNC clients, shutting down..."
    break
  fi
  sleep 15
done

pkill retroarch
pkill x11vnc
pkill websockify
pkill Xvfb
pkill pulseaudio