#!/bin/sh -e

# Required Syslinux version
sysver=SYSVER
sysbin=syslinux
sysmbr=/usr/share/syslinux/mbr.bin
sysmbr2=/usr/lib/syslinux/mbr.bin

# Directory for ldlinux.sys and bundled syslinux binary
sysdir=/liberte/boot/syslinux


if [ ! \( $# = 1 -o \( $# = 2 -a "$2" = nombr \) \) ]; then
    cat <<EOF
This script installs SYSLINUX on a device with Liberté Linux.

You need the following installed.

    Syslinux ${sysver} (Gentoo: sys-boot/syslinux)
        [if unavailable, bundled 32-bit version will be used]
    GNU Parted    (Gentoo: sys-apps/parted)
        [if unavailable, partition must be made bootable manually]
    udev + sysfs  (Gentoo: sys-fs/udev)
        [available on most modern Linux distributions]

Run setup.sh as:

    setup.sh /dev/XXX [nombr]

If the optional <nombr> parameter is specified, and /dev/XXX
is a partition, then the block device's master boot record
will be unaffected. Use this parameter when a custom bootloader
is installed in the MBR.
EOF
    exit 1
fi


# Arguments
dev="$1"
nombr="$2"


# Check that the argument is a block device
if [ ! -b "${dev}" ]; then
    echo "${dev} is not a block device."
    exit 1
fi


# Check for pre-4.x Syslinux (without the -v switch)
sysok=1
if ! ${sysbin} -v 1>/dev/null 2>&1; then
    echo "Syslinux v4+ not found, will use bundled binary"
    sysok=0
elif [ ! -e ${sysmbr}  -a  ! -e ${sysmbr2} ]; then
    echo "${sysmbr} or ${sysmbr2} not found, will use bundled Syslinux"
    sysok=0
else
    # Check for wrong Syslinux version (exact match required)
    havesysver=`${sysbin} -v 2>&1 | cut -d' ' -f2`
    if [ "${havesysver}" != ${sysver} ]; then
        echo "Syslinux v${havesysver} detected, need v${sysver}"
        sysok=0
    elif [ -e ${sysmbr2} ]; then
        sysmbr=${sysmbr2}
    fi
fi


# Check for wrong block device type (highly unlikely)
devpath=`udevadm info -q path -n "${dev}"`
devtype=`udevadm info -q property -p ${devpath} | grep '^DEVTYPE=' | cut -d= -f2`
if [ "${devtype}" != partition -a "${devtype}" != disk ]; then
    echo "${dev} is neither a disk nor a disk partition"
    exit 1
fi


# Check for wrong filesystem type
devfs=`udevadm info -q property -p ${devpath} | grep '^ID_FS_VERSION=' | cut -d= -f2`
if [ -z "${devfs}" ]; then
    echo "${dev} is not formatted, format it as FAT/FAT32 or specify a partition instead"
    exit 1
elif [ "${devfs}" != FAT16 -a "${devfs}" != FAT32 ]; then
    devfstype=`udevadm info -q property -p ${devpath} | grep '^ID_FS_TYPE=' | cut -d= -f2`
    echo "${dev} has a [${devfstype} ${devfs}] filesystem type, need FAT/FAT32"
    exit 1
fi


# Check for mounted filesystem (be a bit paranoid, so no '$' after ${dev})
if cut -d' ' -f1 /proc/mounts | grep -q "^${dev}"; then
    echo "${dev} is mounted, unmount it or wait for auto-unmount"
    exit 1
fi


# Check for installation directory
mntdir=`mktemp -d`
mount -r -t vfat -o noatime,nosuid,nodev,noexec "${dev}" ${mntdir}
if [ -e ${mntdir}${sysdir}/syslinux-x86 ]; then
    hassysdir=1
else
    hassysdir=0
fi

# Copy bundled syslinux binary if system versions are wrong
if [ ${hassysdir} = 1  -a  ${sysok} = 0 ]; then
    systmpdir=`mktemp -d`

    cp ${mntdir}${sysdir}/syslinux-x86 ${systmpdir}/syslinux
    cp ${mntdir}${sysdir}/mtools-x86   ${systmpdir}/mtools
    ln -s mtools ${systmpdir}/mcopy
    ln -s mtools ${systmpdir}/mmove
    ln -s mtools ${systmpdir}/mattrib
    chmod 755 ${systmpdir}/syslinux ${systmpdir}/mtools

    cp ${mntdir}${sysdir}/mbr.bin ${systmpdir}
    sysmbr=${systmpdir}/mbr.bin

    echo "Using bundled 32-bit Syslinux/Mtools binaries and MBR"
    export PATH=${systmpdir}:"${PATH}"
fi

umount ${mntdir}
rmdir  ${mntdir}

if [ ${hassysdir} = 0 ]; then
    echo "Directory ${sysdir} not found or incorrect on ${dev}"
    exit 1
fi


# Install SYSLINUX
echo "*** Installing SYSLINUX on ${dev} ***"
${sysbin} -i -d ${sysdir} "${dev}"


# If necessary, install Syslinux-supplied MBR
if [ -z "${nombr}" -a ${devtype} = partition ]; then
    # Get the parent device
    rdevpath=`dirname ${devpath}`
    rdev=`udevadm info -q property -p ${rdevpath} | grep '^DEVNAME=' | cut -d= -f2`


    # Check that the parent device is a block device
    if [ ! -b "${rdev}" ]; then
        echo "${rdev} is not a block device."
        exit 1
    fi


    # Check that the parent device is indeed a disk
    rdevtype=`udevadm info -q property -p ${rdevpath} | grep '^DEVTYPE=' | cut -d= -f2`
    if [ "${rdevtype}" != disk ]; then
        echo "${rdev} is not a disk, but ${rdevtype}, aborting"
        exit 1
    fi


    # Check that the disk is a removable device
    if [ -e "/sys${rdevpath}/removable" ]; then
        if [ "`cat /sys${rdevpath}/removable`" = 0 ]; then
            echo "WARNING: ${rdev} is not a removable device"'!'
            echo "Press Ctrl-C now to abort (waiting 10 seconds)..."
            sleep 10
        fi
    fi


    # Check that the partition table is MSDOS
    ptable=`udevadm info -q property -p ${rdevpath} | grep '^ID_PART_TABLE_TYPE=' | cut -d= -f2`
    if [ "${ptable}" != dos ]; then
        echo "Partition table is of type [${ptable}], need MS-DOS"
        exit 1
    fi


    # Determine partition number
    if [ ! -e /sys${devpath}/partition ]; then
        echo "Unable to reliably determine partition number of ${dev}"
        exit 1
    fi
    devpart=`cat /sys${devpath}/partition`


    # Make the partition with SYSLINUX active if GNU Parted is available
    echo "*** Making ${dev} the active partition ***"
    if type parted 1>/dev/null 2>&1; then
        parted -s "${rdev}" set "${devpart}" boot on
    else
        echo "--> GNU Parted not found, please run \"cfdisk ${rdev}\""
        echo "--> and make partition #${devpart} bootable."
    fi


    # Install Syslinux's MBR (less than 512B, doesn't overwrite the partition table)
    echo "*** Installing bootloader to the MBR of ${rdev} ***"
    cat ${sysmbr} > ${rdev}
fi


# Erase temporary directories
if [ ${sysok} = 0 ]; then
    rm -r ${systmpdir}
fi


# Synchronize
echo "*** Synchronizing ***"
sync
