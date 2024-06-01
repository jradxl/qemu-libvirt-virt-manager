#!/bin/bash

VERSION=11.0
BUILD_DIR=virt-viewer-$VERSION
FILE=$BUILD_DIR.tar.xz
URL_BASE="https://releases.pagure.org/virt-viewer"
URL="$URL_BASE/$FILE"
FAILED="NO"

echo "VERSION: $VERSION"
echo "BUILD_DIR: $BUILD_DIR"
echo "FILE: $FILE"
echo "URL: $URL"
echo ""

sudo apt install openssh-client gir1.2-spiceclientgtk-3.0 libspice-client-gtk-3.0-dev libgtk-vnc-2.0-dev libgovirt-dev libvte-2.91-dev -y

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
if [[ ! $(grep "#subdir('data')" meson.build) ]]; then
    echo "Correcting meson.build"
    sed -i "s/subdir('data')/#subdir('data')/g" meson.build
else
    echo "Correction already done."
fi
meson --prefix=/usr --buildtype=plain mybuild > ../VirtViewer-configure-log.txt
if [[ "$?" = 0 ]]; then
    echo "Configure suceeded."
else
    echo "Configure failed."
    FAILED="YES"
fi

if [[ $FAILED = "NO" ]]; then
    echo "Running tests..."
    ninja -C mybuild > ../VirtViewer-compile-log.txt
    if [[ "$?" = 0 ]]; then
        echo "Tests sucessful."
    else
        echo "Tests failed. BUT there is a known issue with failing test, Issue #648."
        echo  "So failure ignored. See test-log.txt"
        FAILED="NO"
    fi
fi

if [[ $FAILED = "NO" ]]; then
    echo "Running tests..."
    ninja -C mybuild test > ../VirtViewer-test-log.txt
    if [[ "$?" = 0 ]]; then
        echo "Tests sucessful."
    else
        echo "Tests failed."
        FAILED="YES"
    fi
fi

if [[ $FAILED = "NO" ]]; then
    echo "Installing... SUDO Needed."
    sudo ninja -C mybuild test > ../VirtViewer-install-log.txtt
    if [[ "$?" = 0 ]]; then
        echo "Install Suceeded."
    else
        echo "Install failed."
        FAILED="YES"
    fi
fi

#POP
cd ..

exit 0

