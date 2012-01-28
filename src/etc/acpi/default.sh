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

            lid)
                case "${id}" in
                    close)
                        lidevents=/var/run/lid-events
                        if [ ! -e ${lidevents} ]; then
                            mkdir -m 750   ${lidevents} 2>/dev/null
                            chgrp -h video ${lidevents}
                        fi
                        touch ${lidevents}/close.flag
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
        ;;

    *)
        log_unhandled "$@"
        ;;
esac
