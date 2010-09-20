# This script is sourced by /sbin/rc and /etc/init.d/halt.sh
# It replaces the one in app-misc/livecd-tools.

livecd_read_commandline() {
    # CDBOOT also persists for init.d scripts launched by /sbin/rc
    export CDBOOT=yes

    # Additions to /etc/init.d/halt.sh:
    #   /dev/shm            - tmpfs
    #   /mnt/cdrom          - ro on boot, must be ro before halt.sh
    #   /mnt/livecd         - ro squashfs
    #   /mnt/hidden/newroot - tmpfs
    export RC_NO_UMOUNTS='^(/|/dev|/dev/pts|/dev/shm|/lib/rcscripts/init.d|/proc|/proc/.*|/sys|/mnt/cdrom|/mnt/livecd|/mnt/hidden/newroot)$'
}

livecd_fix_inittab() {
    return
}
