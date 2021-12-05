FROM fedora:latest

WORKDIR /builddir

# Create cache location
RUN --mount=type=cache,target=/ccache
ENV CCACHE_DIR=/ccache
# Install ccache
RUN dnf install -y ccache
# Set up ccache to pretend to be the other compilers
      RUN ln -s /usr/bin/ccache /usr/local/bin/gcc && \
      ln -s /usr/bin/ccache /usr/local/bin/g++ && \
      ln -s /usr/bin/ccache /usr/local/bin/cc && \
      ln -s /usr/bin/ccache /usr/local/bin/c++

# Add rpmfusion for ffmpeg, vlc and x264 devels
RUN dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
# Get deps
RUN dnf install -y cmake ffmpeg-devel fontconfig-devel freetype-devel gcc gcc-c++ gcc-objc git glib2-devel libcurl-devel libdrm-devel libglvnd-devel libv4l-devel libX11-devel libXcomposite-devel libXdamage libXinerama-devel luajit-devel make mbedtls-devel pulseaudio-libs-devel python3-devel qt5-qtbase-devel qt5-qtbase-private-devel qt5-qtsvg-devel qt5-qtwayland-devel qt5-qtx11extras-devel speexdsp-devel swig systemd-devel vlc-devel wayland-devel x264-devel
# Dependencies the obs website doesn't list bc don't care
RUN dnf install -y jack-audio-connection-kit  pipewire-devel alsa-lib-devel --allowerasing

# Install wget and bzip2 cef can get unzipped
RUN dnf install -y curl bzip2 git
# spotify hosts CEF builds but ffs they don't seem to work https://cef-builds.spotifycdn.com/index.html#linux64
ENV cef=https://cef-builds.spotifycdn.com/cef_binary_97.0.8%2Bg4eb2da6%2Bchromium-97.0.4692.36_linux64_beta_minimal.tar.bz2
RUN curl -o cef.tar.bz2 $cef
RUN mkdir ./cef
RUN tar -xjf ./cef.tar.bz2 --directory ./cef --strip-components=1

# Get obs source
RUN git clone --recursive https://github.com/obsproject/obs-studio.git
RUN mkdir /build

RUN cd /build && cmake -DUNIX_STRUCTURE=1 -DBUILD_BROWSER=ON -DCEF_ROOT_DIR="/builddir/cef" /builddir/obs-studio
RUN cd /build && ccache make -j$(nproc)

# export to mount
RUN mkdir /exports
CMD cp ./build/. /exports/. && chmod 777 -R /exports/*
