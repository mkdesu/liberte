umask 022

if which env-update >&/dev/null; then
	env-update
	source /etc/profile

    # see /root/.cpan/CPAN/MyConfig.pm (currently unused)
    export PERL5LIB=/var/tmp/cpan/lib

    sed "s@VERSION@${VERSION}@" ${HOME}/config/issue > /etc/issue
    echo ">sys-kernel/hardened-sources-`cat ${HOME}/config/kversion`" > /etc/portage/package.mask/kernel

    find /etc/sudoers    -perm 644 -exec chmod 440 {} \;
    find /etc/.auto.lock -perm 644 -exec chmod 600 {} \;

    if id -u anon 1>/dev/null 2>&1; then
        find /home/anon \( -type f -o -type d -o -type l \) \( -not -user anon -o -not -group anon \) -exec chown -h anon:anon {} \;
    fi

    if [ -f /usr/bin/xcdroast ]; then
        find /usr/lib/xcdroast-*/bin/xcdrwrap -not -user root -exec chown root {} \;
        find /usr/lib/xcdroast-*/bin/xcdrwrap -not -perm 4755 -exec chmod 4755 {} \;
    fi

    if [ -f /var/lib/layman/make.conf ]; then
        echo -e "\nsource /var/lib/layman/make.conf" >> /etc/make.conf
    fi
fi

export LESSHISTFILE=-
LESS="${LESS} --shift 16 -Swi -x4"

source ${HOME}/.bashrc
cd
