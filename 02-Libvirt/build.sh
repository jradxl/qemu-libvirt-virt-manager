#!/bin/bash

VERSION="10.3.0"
BUILD_DIR="libvirt-$VERSION"
FILE="$BUILD_DIR.tar.xz"

echo "$VERSION"
echo "$BUILD_DIR"
echo "$FILE"

FAILED="NO"

#Install extra packages required by LibVirt
#It is assumed that you have built and installed Qemu first.
sudo apt install ament-cmake-xmllint xsltproc libxml2-dev libyajl-dev -y

#### NOTES ###
# After this Build, the *.pc files found by "find / -name libvirt.pc -print", 
#  are in "/usr/lib64/pkgconfig/libvirt.pc"
# BUT, "pkg-config --variable pc_path pkg-config" shows current search paths
#  /usr/local/lib/x86_64-linux-gnu/pkgconfig:
#  /usr/local/lib/pkgconfig:
#  /usr/local/share/pkgconfig:
#  /usr/lib/x86_64-linux-gnu/pkgconfig:
#  /usr/lib/pkgconfig:
#  /usr/share/pkgconfig
# RESOLUTION
# cp /usr/lib64/pkgconfig/libvirt* /usr/share/pkgconfig

if [[ ! -f $FILE ]]; then
    echo "Downloading $FILE ..."
    wget "https://download.libvirt.org/$FILE"
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
    echo "Current Directory is: $(pwd)"
    
    if [[ -d "mybuild" ]]; then
        echo "Removing the existing build dir."
        rm -rf mybuild
    fi
    
    echo "Configuring ..."
    meson setup mybuild \
       --prefix=/usr \
       -Dsystem=true \
       -Ddriver_qemu=enabled \
       -Drunstatedir=/run \
       -Dsecdriver_selinux=disabled \
       -Dselinux=disabled \
       -Dapparmor=disabled \
       -Ddriver_openvz=disabled \
       -Ddriver_lxc=disabled \
       -Ddriver_esx=disabled \
       -Ddriver_ch=disabled \
       -Ddriver_vmware=disabled \
       -Ddriver_vbox=disabled  \
       > ../configure-libvirt-log.txt 
    if [[ $? = 0 ]]; then
        echo "Configure suceeded. See configure-libvirt-log.txt"
        echo "Building..."
        ninja -C mybuild
        if [[ $? = 0 ]]; then
            echo "Build suceeded. Now try: ninja -C mybuild test && sudo ninja -C mybuild install"
            echo "Running Tests..."
            ninja -C mybuild test
            if [[ $? = 0 ]]; then
                echo "Tests sucessful. Now installing"
                sudo ninja -C mybuild install
                if [[ $? = 0 ]]; then
                    echo "Install Succeded."
                else
                    echo "Install Failed."
                    FAILED="YES"
                fi
            else
                echo "Tests Failed."
                FAILED="YES"
            fi
        else
            echo "Build failed"
            FAILED="YES"
        fi
    else
        echo "Configure failed"
        FAILED="YES"
    fi
fi

#POP
cd ..

if [[ "$FAILED" == "NO" ]]; then

    #If install has succeded, then these files must be present.
    if [[ -f /usr/lib64/pkgconfig/libvirt.pc ]]; then
        echo "Fixing location of *.pc files... SUDO needed."
        sudo cp /usr/lib64/pkgconfig/libvirt* /usr/share/pkgconfig
    fi
    
    # NOTES: No libvirt User, only Group
    echo "Adding Users and Groups if they don't exist: SUDO needed"
    if ! getent group kvm >/dev/null; then
        sudo addgroup --quiet --system kvm
    fi

    if ! getent group libvirt >/dev/null; then
        sudo addgroup --quiet --system libvirt
    fi

    if ! getent group libvirt-qemu >/dev/null; then
        sudo addgroup --quiet --system libvirt-qemu
    fi

    if ! getent group libvirt-dnsmasq >/dev/null; then
        sudo addgroup --quiet --system libvirt-dnsmasq
    fi

    if ! getent group swtpm >/dev/null; then
        sudo addgroup --quiet --system swtpm
    fi

    if ! getent passwd libvirt-qemu >/dev/null; then
        sudo adduser --quiet \
                --system \
                --ingroup kvm \
                --quiet \
                --disabled-login \
                --disabled-password \
                --home /var/lib/libvirt \
                --no-create-home \
                --gecos "Libvirt Qemu" \
                libvirt-qemu
        sudo adduser --quiet libvirt-qemu libvirt-qemu > /dev/null
    fi

    if ! getent passwd libvirt-dnsmasq >/dev/null; then
        sudo adduser --quiet \
                --system \
                --ingroup libvirt-dnsmasq \
                --disabled-login \
                --disabled-password \
                --home /var/lib/libvirt/dnsmasq \
                --no-create-home \
                --gecos "Libvirt Dnsmasq" \
                libvirt-dnsmasq
    fi

    if ! getent passwd swtpm >/dev/null; then
        sudo adduser --quiet \
          --system \
          --ingroup swtpm \
          --shell /bin/false \
          --home /var/lib/libvirt/swtpm \
          --no-create-home \
          --gecos "virtual TPM software stack" \
          swtpm
    fi
fi

sudo systemctl enable virtstoraged
sudo systemctl enable virtlockd
sudo systemctl enable virtlogd
sudo systemctl enable virtqemud
sudo systemctl enable libvirtd


echo "BEST TO REBOOT to start services..."

exit 0

