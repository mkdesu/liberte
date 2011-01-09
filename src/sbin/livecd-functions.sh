# This script is sourced by /sbin/rc and /etc/init.d/halt.sh
# It replaces the one in app-misc/livecd-tools.

livecd_read_commandline() {
    # CDBOOT also persists for init.d scripts launched by /sbin/rc
    export CDBOOT=1

    # Additions to /etc/init.d/halt.sh:
    #   /dev/shm           - tmpfs
    #   /mnt/boot          - ro on boot, must be ro before halt.sh
    #   /mnt/live          - ro squashfs
    #   /mnt/hidden/rwroot - tmpfs
    export RC_NO_UMOUNTS='^(/|/dev|/dev/pts|/dev/shm|/lib/rcscripts/init.d|/proc|/proc/.*|/sys|/mnt/boot|/mnt/live|/mnt/hidden/rwroot)$'
}

livecd_fix_inittab() {
    return
}
