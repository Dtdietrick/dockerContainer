# FILE: Dockerfile

FROM ubuntu:24.04

# Install runtime deps
RUN apt update && apt install -y \
  # Core X and OpenGL
  libx11-6 \
  libxext6 \
  libxrandr2 \
  libxinerama1 \
  libxss1 \
  libxi6 \
  libgl1 \
  libegl1 \
  libudev1 \
  xvfb \
  libfreetype6 \
  libxkbcommon0 \
  libwayland-client0 \
  libwayland-egl1 \
  libwayland-cursor0 \
  # Audio: Pulse + PipeWire + ALSA base
  libasound2t64 \
  libpulse0 \
  libpipewire-0.3-0 \
  # Audio Streaming Support
  gstreamer1.0-tools \
  gstreamer1.0-plugins-base \
  gstreamer1.0-plugins-good \
  gstreamer1.0-plugins-bad \
  gstreamer1.0-plugins-ugly \
  gstreamer1.0-pulseaudio \
  daemontools \
  ucspi-tcp \
  # Media + UI utils
  fonts-dejavu-core \
  libsdl2-2.0-0 \
  libavcodec60 \
  libavformat60 \
  libavdevice60 \
  libswscale7 \
  libqt6core6 \
  libqt6gui6 \
  libqt6widgets6 \
  libqt6dbus6 \
  libqt6network6 \
  libqt6opengl6 \
  libmbedtls14 \
  libsixel1 \
  nvidia-cg-toolkit \
  libv4l-0 \
  # VNC stack
  x11vnc \
  websockify \
  novnc \
  && apt clean && rm -rf /var/lib/apt/lists/*

# Create standard dirs early (before file copy for proper context)
RUN mkdir -p /config /config/pulse /saves /assets /tmp/xdg /roms /cores /shaders /etc/supervisor/conf.d

# Pre-generate PulseAudio cookie
RUN dd if=/dev/urandom bs=256 count=1 of=/config/pulse/cookie

# Copy runtime resources
COPY startup.sh /startup.sh
COPY retroarch /retroarch
COPY cores /cores
COPY roms /roms
COPY etc /etc
COPY webaudio.js /webaudio.js

# Permissions
RUN chmod +x /startup.sh

# Set runtime environment
ENV DISPLAY=:99
ENV XDG_CONFIG_HOME=/config
ENV RETROARCH_CONFIG_DIR=/config
ENV RETROARCH_ASSETS_DIR=/assets
ENV PULSE_SERVER=unix:/tmp/pulseaudio.socket
ENV HOME=/root

#startup script to use server config/save logic
ENTRYPOINT ["/startup.sh"]
