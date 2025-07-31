#!/bin/bash

ROM="$1"
if [ -z "$ROM" ]; then
  echo "No ROM specified!"
  exit 1
fi

# Environment: PulseAudio socket and D-Bus suppression
export PULSE_SERVER=unix:/tmp/pulseaudio.socket
export DBUS_SESSION_BUS_ADDRESS=/dev/null
export DBUS_SYSTEM_BUS_ADDRESS=/dev/null

# Check PulseAudio socket mount
if [ ! -S /tmp/pulseaudio.socket ]; then
  echo "PulseAudio socket not found at /tmp/pulseaudio.socket"
  exit 1
fi

# Start Xvfb virtual display
echo "Starting Xvfb virtual display..."
Xvfb :99 -screen 0 1280x720x24 &
export DISPLAY=:99

# Wait for Xvfb to be ready
echo "Waiting for Xvfb to be ready..."
for i in {1..10}; do
  xdpyinfo -display :99 > /dev/null 2>&1 && break
  echo "Waiting for X display..."
  sleep 1
done

# Start RetroArch in the background
echo "Launching RetroArch with ROM: $ROM"
(
  /retroarch \
    --config /config/retroarch.cfg \
    -L cores/mgba_libretro.so \
    "roms/$ROM" \
    --verbose > /saves/retroarch.log 2>&1
) &
RETRO_PID=$!

# Start GStreamer audio pipeline (to WebSocket stream)
echo "Starting GStreamer audio pipeline..."
tcpserver 127.0.0.1 5902 \
  gst-launch-1.0 -q pulsesrc server=/tmp/pulseaudio.socket \
    ! audio/x-raw,channels=2,rate=24000 \
    ! opusenc ! webmmux ! fdsink fd=1 \
  | websockify 8081 127.0.0.1:5902 &

# Start VNC and WebSocket proxy for noVNC
echo "Starting x11vnc and websockify (for noVNC)..."
x11vnc -display :99 -nopw -listen localhost -xkb -forever &
websockify --web=/usr/share/novnc 52300 localhost:5900 &

# Wait for VNC client
sleep 20
while true; do
  CLIENTS=$(netstat -an | grep ":5900" | grep ESTABLISHED | wc -l)
  if [ "$CLIENTS" -eq 0 ]; then
    echo "No active VNC clients, shutting down..."
    break
  fi
  sleep 15
done

# Cleanup
echo "Cleaning up processes..."
pkill -P $RETRO_PID
pkill x11vnc
pkill websockify
pkill Xvfb