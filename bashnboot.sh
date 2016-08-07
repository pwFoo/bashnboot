#!/bin/sh

set -o allexport
[ -f ./.env ] && source ./.env

BUSYBOX_VER=${BUSYBOX:-"1.25.0"}
KERNEL_VER=${KERNEL:-"4.6.5"}
JOBS_NUM=${JOBS:-"8"}
ISO_NAME=${NAME:-"bashnboot"}

sources() {
  mkdir -p sources && cd "$_"

  # Check if we have already downloaded busybox.
  if [ -f busybox-${BUSYBOX_VER}.tar.bz2 ]; then
    echo "Skipping download of busybox; exists"
  else
    echo "Downloading busybox ${BUSYBOX_VER}."
    curl -sO https://busybox.net/downloads/busybox-${BUSYBOX_VER}.tar.bz2
  fi

  # Check if we have already downloaded the kernel.
  if [ -f linux-${KERNEL_VER}.tar.xz ]; then
    echo "Skipping download of linux; exists"
  else
    echo "Downloading Linux ${KERNEL_VER}."
    curl -sLO http://kernel.org/pub/linux/kernel/v4.x/linux-${KERNEL_VER}.tar.xz
  fi

  cd ..
}

# Creates a clean directory to download/extract and compile busybox.
busybox() {
  # Extract busybox.
  tar -jxf sources/busybox-${BUSYBOX_VER}.tar.bz2

  cd busybox-${BUSYBOX_VER}/

  echo "Compiling busybox ${BUSYBOX_VER}."

  make distclean defconfig 2>&1 > /dev/null

  # Set busybox to be statically compiled so it can run on it's own.
  sed -i "s/.*CONFIG_STATIC.*/CONFIG_STATIC=y/" .config
  # Compile busybox.
  make -j${JOBS_NUM} busybox install 2>&1 > /dev/null

  cd ..
}

# Creates the base structure for the file system and creates a simple init.
initrd() {
  mkdir -p initrd && cd "$_"

  # Create the base filesystem.
  mkdir -p {bin,sbin,etc,proc,sys,usr/{bin,sbin}}

  # Copy all of our executables from busybox into their respective directories.
  cp -a ../busybox-${BUSYBOX_VER}/_install/* .

  echo "Creating init script."

  # Nothing special in the init file, simply mount proc and sysfs and then exec sh.
  cat > init << EOL
#!/bin/sh

mount -t proc none /proc
mount -t sysfs none /sys

exec /bin/sh
EOL

  # Ensure our init is executable.
  chmod +x init

  echo "Generating initrd."

  # Wrap up our filesystem, format it as cpio and then gzip it.
  find . -print0 | cpio --null -o --format=newc | gzip -9 > ../initrd.gz

  cd ..
}

# Compile our kernel and generate our iso.
linux() {
  # Extract the kernel.
  tar -Jxf sources/linux-${KERNEL_VER}.tar.xz

  cd linux-${KERNEL_VER}

  echo "Compiling Linux ${KERNEL_VER}."

  # Compile our kernel (the bzImage part) using the default config (defconfig.)
  make -j${JOBS_NUM} ARCH=x86_64 mrproper defconfig bzImage 2>&1 > /dev/null

  # Construct our isoimage using initrd from the previous step.
  make -j${JOBS_NUM} isoimage FDINITRD=../initrd.gz 2>&1 > /dev/null

  # Copy our iso and rename.
  cp arch/x86/boot/image.iso ../${ISO_NAME}.iso

  cd ..
}

sources
busybox
initrd
linux

