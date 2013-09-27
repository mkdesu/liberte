# Modules to force-load during initramfs stage (see modules.init)
# (no module autoloading on mount in Busybox)
force_load_fs="vfat isofs ext4 hfsplus nls_cp437 nls_iso8859-1 nls_utf8"


# Default filesystem mount flags
# (see also /usr/local/sbin/ps-mount)
luser=2101
lgroup=9000

fs_flags_vfat=noatime,noexec,flush,iocharset=iso8859-1,utf8,uid=${luser},gid=${lgroup},umask=0177,dmask=077
fs_flags_iso9660=nosuid,nodev,iocharset=iso8859-1,utf8
fs_flags_ext2=noatime,nosuid,nodev,acl,user_xattr
fs_flags_ext3=${fs_flags_ext2}
fs_flags_ext4=${fs_flags_ext3}
fs_flags_hfsplus=noatime,nosuid,nodev,uid=${luser},gid=${lgroup},umask=077
fs_flags_squashfs=nodev
fs_flags_auto=noatime,nosuid,nodev


# Sets:
#   + param_cdroot_type   legal filesystem type ('auto' if unset or unknown)
#   + param_cdroot_flags  ${fs_flags_${param_cdroot_type}} if unset
#   + had_cdroot_flags    0 if param_cdroot_flags was empty, 1 otherwise
set_cdroot_type() {
    case "${param_cdroot_type:=auto}" in
        vfat|iso9660|ext[234]|hfsplus|auto)
            ;;
        *)
            warn_msg "Unknown cdroot_type, using 'auto'"
            param_cdroot_type=auto
            ;;
    esac

    had_cdroot_flags=1
    if [ -z "${param_cdroot_flags}" ]; then
        had_cdroot_flags=0
        eval param_cdroot_flags=\"\${fs_flags_${param_cdroot_type}}\"
    fi
}
