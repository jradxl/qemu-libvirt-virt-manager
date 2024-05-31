 # Qemu, Libvirt and Virt-Manager from Sources
Qemu, Libvirt and Virt-Manager compiled from sources

Scripts to install the latest versions of Qemu, Libvirt and Virt-Manager into Ubuntu Jammy and Noble. 
It's expected to run scripts in the 01,02,03 etc order

ENSURE all apt packages for Qemu, Libvirt etc etc are removed.

## Qemu
01-Qemu, build.sh will build Qemu v9.0.0 and install into /usr

## Libvirt
02-Libvirt, build.sh will build Libvirt v10.3.0 and install into /usr

## Virt-Manager
03-Virt-Manager, build.sh will build Virt-Manager v4.1.0 and install into /usr
I was having problems with the Libraries Libvirt-Python and libvirt-glib connecting to each other,
and it appears to work if Libvirt-Python is install as root, (sudo pip install libvirt-python).
   
## Libvirt-Glib
04-Libvirt_Glib, build.sh will build libvirt-glib-5.0.0 and install into /usr
This is needed for Virt-Manager


