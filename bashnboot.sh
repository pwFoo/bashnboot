#!/usr/bin/env bash

BUSYBOX="1.25.0"
KERNEL="4.6.5"
JOBS="8"

initrd() {
  mkdir initrd && cd "$_"

  curl -s https://busybox.net/downloads/busybox-${BUSYBOX}.tar.bz2 | tar -jxf -
  cd busybox-${BUSYBOX}/

  make distclean defconfig 2>&1 > /dev/null
  sed -i "s/.*CONFIG_STATIC.*/CONFIG_STATIC=y/" .config
  make -j${JOBS} busybox install 2>&1 > /dev/null
  cd ../..
}

initramfs() {
  mkdir initramfs && cd "$_"
  mkdir -p {bin,sbin,etc,proc,sys,usr/{bin,sbin}}
  cp -a ../initrd/busybox-${BUSYBOX}/_install/* .

  cat > init << EOL
#!/bin/sh

mount -t proc none /proc
mount -t sysfs none /sys

exec /bin/sh
EOL

  chmod +x init
  find . -print0 | cpio --null -o --format=newc | gzip -9 > ../initrd.gz
  cd ..
}

kernel() {
  mkdir kernel && cd "$_"
  curl -sL http://kernel.org/pub/linux/kernel/v4.x/linux-${KERNEL}.tar.xz | tar -Jxf -
  cd linux-${KERNEL}
  make -j${JOBS} ARCH=x86_64 mrproper defconfig bzImage 2>&1 > /dev/null
  make -j${JOBS} isoimage FDINITRD=../../initrd.gz 2>&1 > /dev/null
  cp arch/x86/boot/image.iso ../../bashnboot.iso
  cd ../..
}

initrd
initramfs
kernel

