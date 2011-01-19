# Sourced at the end of halt.sh
# Add -f so that reboot works for runlevel 0, too
opts="-fdk"
[ "${RC_DOWN_INTERFACE}" = "yes" ] && opts="${opts}i"

/sbin/reboot "${opts}" 2>/dev/null

echo KEXEC-based reboot/shutdown failed
/sbin/poweroff -nf
