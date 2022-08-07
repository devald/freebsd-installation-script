# freebsd-installation-script
This script installs FreeBSD root on ZFS that expects BIOS
## Download FreeBSD memstick installer and verify the checksum
```sh
curl -O https://download.freebsd.org/releases/amd64/amd64/ISO-IMAGES/13.1/FreeBSD-13.1-RELEASE-amd64-memstick.img.xz
curl -O https://download.freebsd.org/releases/amd64/amd64/ISO-IMAGES/13.1/CHECKSUM.SHA512-FreeBSD-13.1-RELEASE-amd64
gunzip FreeBSD-13.1-RELEASE-amd64-memstick.img.xz
shasum -a 512 --ignore-missing -c CHECKSUM.SHA512-FreeBSD-13.1-RELEASE-amd64
```
## Copy the image to pendrive
```sh
sudo dd if=FreeBSD-13.1-RELEASE-amd64-memstick.img of=/dev/disk3 bs=1m conv=sync status=progress
```
## Boot from USB and choose shell access
### List available devices that will be passed to the installer script
```sh
camcontrol devlist
```
### Download the installer script and run it
```sh
fetch https://raw.githubusercontent.com/devald/freebsd-installation-script/main/freebsd_install.sh
./freebsd_install.sh ada0 ada1
```
