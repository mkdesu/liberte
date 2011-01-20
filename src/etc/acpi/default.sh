#!/bin/sh

group="${1%%/*}"
action="${1#*/}"

device="$2"
id="$3"
value="$4"

log_unhandled() {
    logger -p 6 -t acpi.default -- "Unhandled event: $@"
}

case "${group}" in
    button)
        case "${action}" in
            power)
                # Shutdown only if SysRq wasn't disabled (e.g., via xlock)
                if [ "`cat /proc/sys/kernel/sysrq 2>/dev/null`" = 1 ]; then
                    /sbin/shutdown -h now
                else
                    logger -p 4 -t acpi.default -- "Ignoring event: $@"
                fi
                ;;

            *)
                log_unhandled "$@"
                ;;
        esac
        ;;

    *)
        log_unhandled "$@"
        ;;
esac
