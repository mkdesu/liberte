umask 022

if which env-update >&/dev/null; then
	env-update
	source /etc/profile

    # see /root/.cpan/CPAN/MyConfig.pm (currently unused)
    export PERL5LIB=/var/tmp/cpan/lib

    sed "s@VERSION@${VERSION}@" ${HOME}/config/issue > /etc/issue
    echo ">sys-kernel/hardened-sources-`cat ${HOME}/config/kversion`" \
        > /etc/portage/package.mask/kernel

    if id -u anon 1>/dev/null 2>&1; then
        find /home/anon \( -type f -o -type d -o -type l \) \
                        \( ! -user anon -o ! -group anon \) \
                        -exec chown -h anon:anon {} \;
    fi

    if [ -e /usr/bin/xcdroast ]; then
        find /usr/lib/xcdroast-*/bin/xcdrwrap ! -user root -exec chown root {} \;
        find /usr/lib/xcdroast-*/bin/xcdrwrap ! -perm 4755 -exec chmod 4755 {} \;
    fi

    # if [ -e /usr/bin/eix-update ]; then
    #    export FEATURES="metadata-transfer"
    #    sed -i 's/^# MODULE //' /etc/portage/modules/sqlite
    #    sed -i 's/^# SQLITE //' /etc/eixrc
    # fi

    if [ -e /var/lib/layman/make.conf ]; then
        sed -i 's/^# LAYMAN //' /etc/make.conf
    fi
fi

export LESSHISTFILE=-
LESS="${LESS} --shift 16 -Swi -x4"

source ${HOME}/.bashrc
cd
