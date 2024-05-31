#!/bin/bash

## https://download.libvirt.org/glib/libvirt-glib-5.0.0.tar.xz

VERSION=5.0.0
BUILD_DIR=libvirt-glib-$VERSION
FILE=$BUILD_DIR.tar.xz
URL_BASE="https://download.libvirt.org/glib"
URL="$URL_BASE/$FILE"
FAILED="NO"

echo "VERSION: $VERSION"
echo "BUILD_DIR: $BUILD_DIR"
echo "FILE: $FILE"
echo "URL: $URL"
echo ""

sudo apt install -y \
  meson \
  gettext \
  libglib2.0-dev \
  libxml2-dev \
  python3.10-venv \
  python3-pip \
  python3-libxml2 \
  python3-requests

#This will install latest version from PYPI and
# that should match the version downloaded above. Check!
python3 -m pip install libvirt-python
python3 -m pip install PyGObject

if [[ ! -f $FILE ]]; then
    echo "Downloading $FILE ..."
    wget "$URL"
fi

if [[ ! -d "$BUILD_DIR" ]]; then

    if [[ -f $FILE ]]; then
        echo "Unpacking $FILE..."
        tar xJf $FILE
    fi
fi

#PUSH
cd "$BUILD_DIR" 
echo "Current Directory is: $(pwd)"

if [[ -d "mybuild" ]]; then
    echo "Removing the existing build dir."
    rm -rf mybuild
fi
echo "Configuring ..." 
meson setup mybuild --prefix=/usr --buildtype=plain
if [[ "$?" = 0 ]]; then
    echo "Configuring suceeded. Now compiling..."
    ninja -C mybuild
    if [[ "$?" = 0 ]]; then
        echo "Compile suceeded."
        echo "Running tests..."
        ninja -C mybuild test
        if [[ "$?" = 0 ]]; then
            echo "Tests sucessful. Installing SUDO Needed."
            sudo ninja -C mybuild install
            if [[ "$?" = 0 ]]; then
                echo "Install Suceeded."
                echo "Running LDCONFIG..."
                sudo ldconfig
            else
                echo "Install failed."
                FAILED="YES"
            fi
        else
            echo "Tests failed."
            FAILED="YES"
        fi
    else
        echo "Compile Failed"
        FAILED="YES"
    fi
else
    echo "Configure failed."
    FAILED="YES"
fi

#POP
cd ..

exit 0

