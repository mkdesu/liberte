#!/bin/sh -e

# TODO: add "-device virtio-rng" once it is supported by QEMU

title="Virtualized Liberté (no persistence)"
mem=192M
bootdir=`dirname $0`/boot

cdrom="if=virtio,format=raw,media=cdrom,aio=native,cache=none"

params="looptype=noloop loop=/etc/hosts cdroot
        cdroot_type=squashfs unionfs nopata nosata nousb
        video=uvesafb:800x600-32,mtrr:3,ywrap quiet
        splash=silent,theme:liberty console=tty1"

export QEMU_AUDIO_DRV=alsa


if [ -n "$1" ]; then
    bootdir="$1"
    shift
fi

if [ ! -d "${bootdir}" ]; then
    echo "Error:  ${bootdir} not found (already virtualized?)"
    echo "Format: $0 [bootdir [extra kernel params ...]]"
    exit 1
fi


if type qemu-kvm 1>/dev/null 2>&1; then
    qemu=qemu-kvm

    if [ ! -e /dev/kvm ]; then
        echo "Warning: no KVM driver has been loaded"
        vmflag=`sed -n 's/^flags\>.*\<\(vmx\|svm\)\>.*$/\1/p' /proc/cpuinfo | head -n 1`

        if [ "${vmflag}" = vmx ]; then
            echo "Intel VT detected, loading KVM-Intel driver"
            sudo -n modprobe kvm-intel
        elif [ "${vmflag}" = svm ]; then
            echo "AMD-V detected, loading KVM-AMD driver"
            sudo -n modprobe kvm-amd
        fi

        if [ ! -e /dev/kvm ]; then
            qemu="${qemu} -no-kvm -cpu qemu32"
        fi
    fi
elif type qemu 1>/dev/null 2>&1; then
    qemu=qemu
else
    echo "QEMU/QEMU-KVM not found"
    exit 1
fi


exec ${qemu} -name "${title}" -m ${mem} -nodefaults          \
             -sdl -balloon virtio -vga cirrus -monitor vc    \
             -soundhw es1370 -net nic,model=virtio -net user \
             -kernel "${bootdir}/kernel-x86.zi"              \
             -initrd "${bootdir}/initrd-x86.lzm"             \
             -drive file="${bootdir}/root-x86.sfs,${cdrom}"  \
             -append "`echo ${params} $*`"
