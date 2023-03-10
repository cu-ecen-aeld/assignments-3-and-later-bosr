#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
# KERNEL_VERSION=v5.1.10
KERNEL_VERSION=v5.19.9
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath "$(dirname $0)")
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-
XC_GCC=/home/bosr/Travail/arm-gnu-toolchain-12.2.rel1-x86_64-aarch64-none-linux-gnu/

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p "$OUTDIR"

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e "${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image" ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # TODO: ✅ Add your kernel build steps here
    make ARCH=$ARCH       CROSS_COMPILE=$CROSS_COMPILE mrproper   # clean tree
    make ARCH=$ARCH       CROSS_COMPILE=$CROSS_COMPILE defconfig  # prepare the default .config
    make ARCH=$ARCH -j16  CROSS_COMPILE=$CROSS_COMPILE all        # compile the kernel
    make ARCH=$ARCH       CROSS_COMPILE=$CROSS_COMPILE modules    # compile the modules
    make ARCH=$ARCH       CROSS_COMPILE=$CROSS_COMPILE dtbs       # prepare the device tree

    cd ..
fi

echo "Adding the Image in outdir"
cp "${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image" "${OUTDIR}/Image"

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm -rf "${OUTDIR}/rootfs"
fi

# TODO: ✅ Create necessary base directories
ROOTFS="${OUTDIR}/rootfs"
mkdir "$ROOTFS" && cd "$ROOTFS"
mkdir -p bin dev etc lib lib64 proc sbin sbin tmp usr/sbin usr/lib usr/bin var/log home


cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO: ✅ Configure busybox
    make distclean
    make defconfig
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
else
    cd busybox
fi

# TODO: ✅ Make and install busybox
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} CONFIG_PREFIX="${ROOTFS}" install

echo "Library dependencies"
${CROSS_COMPILE}readelf -a "${ROOTFS}/bin/busybox" | grep "program interpreter"
${CROSS_COMPILE}readelf -a "${ROOTFS}/bin/busybox" | grep "Shared library"

cd "$ROOTFS"

# TODO: ✅ Add library dependencies to rootfs
cp "${FINDER_APP_DIR}/../cross-compiler-libs/ld-linux-aarch64.so.1" lib/
cp "${FINDER_APP_DIR}/../cross-compiler-libs/libm.so.6"             lib64/
cp "${FINDER_APP_DIR}/../cross-compiler-libs/libresolv.so.2"        lib64/
cp "${FINDER_APP_DIR}/../cross-compiler-libs/libc.so.6"             lib64/

# TODO: ✅ Make device nodes
sudo mknod -m 666 dev/null c 1 3
sudo mknod -m 666 dev/console c 5 1

# TODO: Clean and build the writer utility
cd "$FINDER_APP_DIR"
make clean
make CROSS_COMPILE=$CROSS_COMPILE

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
cp writer "${ROOTFS}/home/"
cp -r ../conf finder.sh finder-test.sh autorun-qemu.sh "${ROOTFS}/home/"

# TODO: ✅ Chown the root directory
cd "$ROOTFS"

# TODO: ✅ Create initramfs.cpio.gz
find . | cpio -H newc -ov --owner root:root > "${OUTDIR}/initramfs.cpio"
gzip -f "${OUTDIR}/initramfs.cpio"
