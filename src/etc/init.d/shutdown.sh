# Sourced at the end of halt.sh
# Add -f so that reboot works for runlevel 0, too
opts="-fdk"
[ "${RC_DOWN_INTERFACE}" = "yes" ] && opts="${opts}i"

if [ "`cat /sys/kernel/kexec_loaded 2>/dev/null`" = 1 ]; then
    /sbin/reboot   "${opts}"
else
    /sbin/poweroff "${opts}"
fi

echo Normal shutdown failed
/sbin/poweroff -fn
/sbin/halt     -fn
