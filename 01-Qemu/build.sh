#!/bin/bash

VERSION="9.0.0"
BUILD_DIR="qemu-$VERSION"
FILE="$BUILD_DIR.tar.xz"
PREFIX=/usr

#RUN Dependencies
sudo apt install -y \
  cpu-checker ibverbs-providers ipxe-qemu ipxe-qemu-256k-compat-efi-roms \
  libaio1 libcacard0 libdaxctl1 libfdt1 libgfapi0 libgfrpc0 libgfxdr0 \
  libglusterfs0 libibverbs1 libiscsi7 libndctl6 libpmem1 libpmemobj1 \
  librados2 librbd1 librdmacm1 libslirp0 libspice-server1 liburing2 \
  libusbredirparser1 libvirglrenderer1 msr-tools ovmf seabios

#BUILD Dependencies
sudo apt install -y \
    meson \
    bison \
    curl \
    libcurl4-openssl-dev \
    flex \
    libepoxy-dev \
    libfdt-dev \
    libfluidsynth3 \
    libfwtsiasl1 \
    libglib2.0-dev \
    libgtk-3-dev \
    libgvnc-1.0-dev \
    libinstpatch-1.0-2 \
    libmodplug1 \
    libopusfile0 \
    libpipewire-0.3-dev \
    libpixman-1-dev \
    libsdl2-dev \
    libsdl2-gfx-1.0-0 \
    libsdl2-gfx-dev \
    libsdl2-image-2.0-0 \
    libsdl2-image-dev \
    libsdl2-mixer-2.0-0 \
    libsdl2-mixer-dev \
    libsdl2-net-2.0-0 \
    libsdl2-net-dev \
    libsdl2-ttf-2.0-0 \
    libsdl2-ttf-dev \
    libslirp-dev \
    libspa-0.2-dev \
    libspice-server-dev \
    libsysprof-4-dev \
    libusb-1.0-0-dev \
    libusbredirparser-dev \
    libvirglrenderer-dev \
    python3.10-venv \
    timgm6mb-soundfont


if [[ ! -f $FILE ]]; then
    echo "Downloading..."
    wget "https://download.qemu.org/$FILE"
fi

if [[ ! -d "$BUILD_DIR" ]]; then

    if [[ -f $FILE ]]; then
        echo "Unpacking..."
        tar xJf $FILE
    fi

fi

if [[ -d "$BUILD_DIR" ]]; then
    
    #PUSH
    cd "$BUILD_DIR"    
    pwd
    
    if [[ -d "mybuild" ]]; then
        echo "Removing the existing build dir."
        rm -r mybuild
    fi
    mkdir -p mybuild
    echo "Entering build dir to configure..."
    cd mybuild 
    #Jammy not pipewire: --enable-pipewire
    ../configure --prefix="$PREFIX" \
    --target-list=x86_64-softmmu \
    --enable-opengl \
    --enable-sdl \
    --enable-gtk \
    --enable-kvm \
    --enable-guest-agent \
    --enable-spice \
    --enable-opengl \
    --audio-drv-list="alsa, default, oss, pa, sdl" \
    --enable-libusb \
    --enable-slirp \
    --enable-virglrenderer \
    --disable-docs \
    --disable-pipewire \
    > ../configure-qemu-log.txt
    if [[ "$?" = 0 ]]; then
        echo "Configure suceeded. See ./configuring-qemu.log"
        echo "Compiling using Make ..."
        make
        if [[ "$?" = 0 ]]; then
            echo "Compile Suceeded. Now installing..."
            sudo make install
            if [[ "$?" = 0 ]]; then
                echo "Make Install finished sucessfully."
            else
                echo "Install Failed."
            fi
        else
            echo "Compile Failed."
        fi
    else
        echo "Configure failed."
    fi
fi

#POP
cd ..
pwd
    
exit 0

