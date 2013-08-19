#!/bin/sh
set -e

# Required Syslinux version
sysver=SYSVER
sysbin=syslinux
extbin=extlinux
sysmbr=/usr/share/syslinux
sysmbr2=/usr/lib/syslinux
mattrbin=mattrib

# Directories for ldlinux.sys and bundled syslinux binary
sysdir=/liberte/boot/syslinux
systmpdir=
mntexec=

# Filesystem types (for auto mode)
fs_fat=4d44
fs_ext=ef53


if [ ! \( $# = 1 -o \( $# = 2 -a "$2" = nombr \) -o "$1" = automagic \) ]; then
    cat <<EOF
This script installs SYSLINUX or EXTLINUX on a device with
Liberté Linux.

You need the following installed.

    Syslinux ${sysver} (Gentoo: sys-boot/syslinux)
        [if unavailable, bundled 32-bit version will be used]
    udev + sysfs  (Gentoo: sys-fs/udev)
        [available on most modern Linux distributions]
    gdisk (Gentoo: sys-apps/gptfdisk)
        [for GUID partition tables support]

Run setup.sh as:

    setup.sh auto     [nombr]
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


# Error handling
error() {
    echo "$@"
    exit 1
}


# Handle auto mode
if [ "${dev}" = auto ]; then
    echo "*** Determining device name ***"
    shift

    mpoint=`readlink -f "$0"`
    if [ "${mpoint}" = "${mpoint%/liberte/setup.sh}" ]; then
        error "Bad script path"
    fi
    mpoint="${mpoint%/liberte/setup.sh}"

    if ! mountpoint -q "${mpoint}"; then
        error "${mpoint} is not a mount point"
    fi

    fstype=`stat -f -c "%t" "${mpoint}"`
    fsdev=/dev/block/`mountpoint -d "${mpoint}"`
    fsdev=`readlink -f "${fsdev}"`

    case "${fstype}" in
        ${fs_fat})
            echo "${fsdev} is mounted as FAT(32) on ${mpoint}"
            setup=`mktemp`
            cp $0 "${setup}"

            exec /bin/sh "${setup}" automagic "${mpoint}" "${fsdev}" "$@"
            ;;

        ${fs_ext})
            echo "${fsdev} is mounted as ext[234] on ${mpoint}"
            exec /bin/sh "$0" "${fsdev}" "$@"
            ;;

        *)
            error "Unknown filesystem type"
            ;;
    esac

    error "Internal error"
fi

if [ "${dev}" = automagic ]; then
    mpoint="$2"
    shift 2

    echo "Unmounting ${mpoint}"
    umount "${mpoint}"

    /bin/sh "$0" "$@"
    exec rm "$0"

    error "Internal error"
fi


# Check that the argument is a block device
if [ ! -b "${dev}" ]; then
    error "${dev} is not a block device."
fi


# Check for pre-4.x Syslinux (without the -v switch)
sysok=0
extok=0
if ! ${sysbin} -v 1>/dev/null 2>&1; then
    echo "Syslinux v4+ not found, will use bundled binary"
elif [ ! -e ${sysmbr}/mbr.bin  -a  ! -e ${sysmbr2}/mbr.bin ]; then
    echo "${sysmbr} or ${sysmbr2} not found, will use bundled Syslinux"
else
    # Check for wrong Syslinux version (exact match required)
    havesysver=`${sysbin} -v 2>&1 | cut -d' ' -f2`
    if [ "${havesysver}" != ${sysver} ]; then
        echo "Syslinux v${havesysver} detected, need v${sysver}"
    else
        sysok=1
        if [ -e ${sysmbr2}/mbr.bin ]; then
            sysmbr=${sysmbr2}
        fi

        if ! ${extbin} -v 1>/dev/null 2>&1; then
            echo "EXTLINUX not found, will use bundled binary if installing to ext[234]"
        else
            extok=1
        fi
    fi
fi


# udev properties accessor
udevprop() {
    local devpath="$1" prop="$2"
    udevadm info -q property -p "${devpath}" | sed -n "s/^${prop}=//p"
}


# 32-bit executability checker
checkexec() {
    local binary="$1"

    # 32-bit: /lib/ld-linux.so.2, 64-bit: /lib/ld-linux-x86-64.so.2
    if [ ! -e /lib/ld-linux.so.2 ]; then
        echo "WARNING: it looks like 32-bit ELF binaries are unsupported on this system"
    # Use test(1) from coreutils (it calls access(2), honoring MS_NOEXEC and MS_RDONLY)
    elif [ ! -x "${binary}" ] || { [ -e /usr/bin/test ] && ! /usr/bin/test -x "${binary}"; }; then
        echo "WARNING: executing bundled binaries will fail"

        binary=`dirname "$(readlink -f "${binary}")"`
        while ! mountpoint -q ${binary}; do
            binary=`dirname "${binary}"`
        done

        if grep -q " ${binary} .*\<noexec\>" /proc/mounts; then
            mntexec="${binary}"
            echo "WARNING: ${mntexec} is mounted with noexec option"
            echo "Remounting ${mntexec} with exec permissions"
            mount -o remount,exec "${mntexec}"
        fi
    fi
}


# Check for wrong block device type (highly unlikely)
devpath=`udevadm info -q path -n "${dev}"`
devtype=`udevprop ${devpath} DEVTYPE`
if [ "${devtype}" != partition -a "${devtype}" != disk ]; then
    error "${dev} is neither a disk nor a disk partition"
fi


# Check and normalize filesystem type
devfs=`udevprop "${devpath}" ID_FS_TYPE`
case "${devfs}" in
    '')
        error "${dev} is not formatted, format it as FAT/ext2 or specify a partition instead"
        ;;
    vfat|msdos)
        echo "Detected FAT(32) filesystem, will install using SYSLINUX"
        devfs=fat
        ;;
    ext[234])
        echo "Detected ext[234] filesystem, will install using EXTLINUX"
        devfs=ext2
        ;;
    *)
        error "${dev} has a [${devfs}] filesystem type, need FAT/ext2"
        ;;
esac


if [ ${devfs} = fat ]; then

    # Check for mounted filesystem (be a bit paranoid, so no '$' after ${dev})
    if cut -d' ' -f1 /proc/mounts | grep -q "^${dev}"; then
        error "${dev} is mounted, unmount it or wait for auto-unmount"
    fi


    # Check for installation directory
    mntdir=`mktemp -d`
    mount -r -t vfat -o noatime,nosuid,nodev,noexec "${dev}" ${mntdir}
    if [ -e ${mntdir}${sysdir}/syslinux-x86.tbz ]; then
        hassysdir=1
    else
        hassysdir=0
    fi

    # Copy bundled syslinux binary if system versions are wrong
    if [ ${hassysdir} = 1  -a  ${sysok} = 0 ]; then
        echo "Using bundled 32-bit SYSLINUX/Mtools binaries and MBR"

        systmpdir=`mktemp -d`
        tar -xpjf ${mntdir}${sysdir}/syslinux-x86.tbz -C ${systmpdir}

        sysbin=${systmpdir}/syslinux
        sysmbr=${systmpdir}

        mattrbin=${systmpdir}/mattrib
        export PATH=${systmpdir}:"${PATH}"

        checkexec ${sysbin}
    fi

    # Create OTFE directory so that it can be hidden, too
    if [ ! -e ${mntdir}/otfe ]; then
        mount -o remount,rw ${mntdir}
        mkdir ${mntdir}/otfe
    fi

    umount -l ${mntdir}
    rmdir     ${mntdir}

    if [ ${hassysdir} = 0 ]; then
        error "Directory ${sysdir} not found or incorrect on ${dev}"
    fi


    # Install SYSLINUX
    echo "*** Installing SYSLINUX on ${dev} ***"
    ${sysbin} -i -d ${sysdir} "${dev}"

    # Hide directories
    echo "*** Hiding top-level directories ***"

    unset  MTOOLSRC
    export MTOOLS_SKIP_CHECK=1
    export MTOOLS_FAT_COMPATIBILITY=1

    ${mattrbin} -i "${dev}" +h ::/liberte ::/otfe
    ${mattrbin} -i "${dev}" +h ::/EFI 2>/dev/null || :

    if [ -n "${mntexec}" ]; then
        echo "Remounting ${mntexec} with noexec option"
        mount -o remount,noexec "${mntexec}"
    fi

elif [ ${devfs} = ext2 ]; then

    devdir=`grep "^${dev} " /proc/mounts | head -n 1 | cut -d' ' -f2`
    if [ -n "${devdir}" ]  &&  mountpoint -q "${devdir}"; then
        echo "Detected ${dev} mount on ${devdir}"
    else
        error "${dev} is not mounted, please manually mount or auto-mount it"
    fi

    if [ ! -e "${devdir}"${sysdir}/syslinux-x86.tbz ]; then
        error "Directory ${sysdir} not found or incorrect in ${devdir}"
    elif [ ${extok} = 0 ]; then
        echo "Using bundled 32-bit EXTLINUX binary and MBR"

        systmpdir=`mktemp -d`
        tar -xpjf "${devdir}"${sysdir}/syslinux-x86.tbz -C ${systmpdir}

        extbin=${systmpdir}/extlinux
        sysmbr=${systmpdir}

        checkexec ${extbin}
    fi

    # Install EXTLINUX
    echo "*** Installing EXTLINUX in ${devdir} ***"
    ${extbin} -i "${devdir}"${sysdir}

    if [ -n "${mntexec}" ]; then
        echo "Remounting ${mntexec} with noexec option"
        mount -o remount,noexec "${mntexec}"
    fi

else
    error "Internal error"
fi


# If necessary, install Syslinux-supplied MBR
if [ -z "${nombr}" -a ${devtype} = partition ]; then
    # Get the parent device
    rdevpath=`dirname "${devpath}"`
    rdev=`udevprop "${rdevpath}" DEVNAME`

    echo "*** Installing bootloader to the MBR of ${rdev} ***"

    # Check that the parent device is a block device
    if [ ! -b "${rdev}" ]; then
        error "${rdev} is not a block device."
    fi


    # Check that the parent device is indeed a disk
    rdevtype=`udevprop "${rdevpath}" DEVTYPE`
    if [ "${rdevtype}" != disk ]; then
        error "${rdev} is not a disk, but ${rdevtype}, aborting"
    fi


    # Check that the disk is a removable device
    if [ -e /sys"${rdevpath}"/removable ]; then
        if [ "`cat /sys"${rdevpath}"/removable`" = 0 ]; then
            echo "WARNING: ${rdev} is not a removable device"'!'
            echo "Press Ctrl-C now to abort (waiting 10 seconds)..."
            sleep 10
        fi
    fi


    # Check that the partition table is MSDOS
    ptable=`udevprop "${rdevpath}" ID_PART_TABLE_TYPE`
    if [ "${ptable}" = dos ]; then
        sysmbr=${sysmbr}/mbr_c.bin
    elif [ "${ptable}" = gpt ]; then
        sysmbr=${sysmbr}/gptmbr_c.bin
    else
        error "Partition table is of type [${ptable}], need MS-DOS or GUID"
    fi


    # Determine partition number
    if [ ! -e /sys"${devpath}"/partition ]; then
        error "Unable to reliably determine partition number of ${dev}"
    fi
    devpart=`cat /sys"${devpath}"/partition`


    # Install Syslinux's MBR (less than 512B, doesn't overwrite the partition table)
    if [ "${ptable}" = dos ]; then
        if ! type sfdisk 1>/dev/null 2>&1; then
            error "sfdisk not found, cannot mark partition ${devpart} active"
        fi
        sfdisk -q -A"${devpart}" "${rdev}"
    elif [ "${ptable}" = gpt ]; then
        if ! type sgdisk 1>/dev/null 2>&1; then
            error "sgdisk not found, cannot mark partition ${devpart} legacy-bootable"
        fi
        sgdisk -A "${devpart}":set:2 "${rdev}"
    fi

    dd bs=440 count=1 iflag=fullblock conv=notrunc if=${sysmbr} of="${rdev}"
fi


# Remove temporary directories
if [ -n "${systmpdir}" ]; then
    rm -r ${systmpdir}
fi


# Synchronize
echo "*** Synchronizing ***"
sync

echo "*** Done ***"
