# Use minimal Ubuntu 24.04 base image
FROM ubuntu:24.04

# Install runtime dependencies only (no dev tools)
RUN apt update && apt install -y \
  libx11-6 \
  libxext6 \
  libxrandr2 \
  libxinerama1 \
  libxss1 \
  libxi6 \
  libasound2t64 \
  pulseaudio \
  pulseaudio-utils \
  libpipewire-0.3-0 \
  libpulse0 \
  libgl1 \
  libegl1 \
  libudev1 \
  libwayland-client0 \
  libwayland-egl1 \
  libwayland-cursor0 \
  libxkbcommon0 \
  libfreetype6 \
  libsdl2-2.0-0 \
  libavcodec60 \
  libavformat60 \
  libavdevice60 \
  libswscale7 \
  fonts-dejavu-core \
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
  xvfb \
  x11vnc \
  websockify \
  novnc \
  && apt clean && rm -rf /var/lib/apt/lists/*

# Create needed dirs
RUN mkdir -p /config /saves /assets /tmp/xdg /roms /cores /shaders

# Copy resources
COPY startup.sh /startup.sh
COPY retroarch /retroarch
COPY cores /cores
COPY roms /roms
COPY shaders /shaders
COPY etc /etc

RUN chmod +x /startup.sh

RUN sed -i 's/^;* *user *=.*/; user = root/' /etc/pulse/daemon.conf

# Runtime env (minimal now)
ENV DISPLAY=:0
ENV XDG_CONFIG_HOME=/config
ENV RETROARCH_CONFIG_DIR=/config
ENV RETROARCH_ASSETS_DIR=/assets

# Run everything as root (PulseAudio system mode requires it)

ENTRYPOINT ["/startup.sh"]