#!/bin/bash

VERSION=4.1.0
BUILD_DIR=virt-manager-$VERSION
FILE=$BUILD_DIR.tar.gz
URL_BASE="https://releases.pagure.org/virt-manager/"
URL="$URL_BASE/$FILE"
FAILED="NO"

echo "VERSION: $VERSION"
echo "BUILD_DIR: $BUILD_DIR"
echo "FILE: $FILE"
echo "URL: $URL"
echo ""

sudo apt install -y \
 libgtksourceview-5-dev \
 libosinfo-1.0-dev \
 libgtk-3-dev \
 gir1.2-gtk-vnc-2.0 \
 gir1.2-spiceclientglib-2.0 \
 gir1.2-vte-2.91 \
 python3-libxml2 \
 python3-requests

##python3 -m pip install ipaddress
sudo python3 -m pip install libvirt-python

if [[ ! -f $FILE ]]; then
    echo "Downloading $FILE ..."
    wget "$URL"
fi

if [[ ! -d "$BUILD_DIR" ]]; then

    if [[ -f $FILE ]]; then
        echo "Unpacking $FILE..."
        tar xf $FILE
    fi
fi

#PUSH
cd "$BUILD_DIR" 
echo "Current Directory is: $(pwd)"

echo "Configuring ..." 
./setup.py configure --default-hvs qemu --prefix=/usr
if [[ "$?" = 0 ]]; then
    echo "Configuring suceeded."
else
    echo "Configure failed."
    FAILED="YES"
fi

if [[ $FAILED = "NO" ]]; then
    echo "Building...."
    ./setup.py build
    if [[ "$?" = 0 ]]; then
        echo "Build suceeded."
     else
        echo "Build Failed"
        FAILED="YES"
    fi       
fi

if [[ $FAILED = "NO" ]]; then
    echo "Running tests..."
    python3 -m pytest > ../test-log.txt
    if [[ "$?" = 0 ]]; then
        echo "Tests sucessful."
    else
        echo "Tests failed. BUT there is a known issue with failing test, Issue #648."
        echo  "So failure ignored. See test-log.txt"
        FAILED="NO"
    fi
fi

if [[ $FAILED = "NO" ]]; then
    echo "Installing... SUDO Needed."
    sudo ./setup.py install
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

