# Sourced at the end of halt.sh
opts="-fdk"
[ "${RC_DOWN_INTERFACE}" = "yes" ] && opts="${opts}i"

/sbin/reboot "${opts}"

echo Normal reboot failed
/sbin/reboot -fn
