#!/bin/sh -e

# Shutdown only if SysRq wasn't disabled (e.g., via xlock)
if [ "`cat /proc/sys/kernel/sysrq 2>/dev/null`" = 1 ]; then
    exec /sbin/shutdown -h now "Power button pressed"
fi
