# Build-time profile, replaces ~/.profile
umask 022

# Update environment variables
if type -p env-update 1>/dev/null; then
    env-update
    source /etc/profile
fi

# Tools environment variables
export LESSHISTFILE=-
LESS="${LESS} --shift 16 -Swi -x4"

# Build-time environment variables
# e.g.: kversion  = 3.14.5-hardened-r2
#       hsversion = 3.14.5-r2 (contents of config/kversion)
export helpdir=${HOME}/helpers
export hsversion=`cat ${HOME}/config/kversion`
export kversion=${hsversion/-/-hardened-}
[ ${kversion} != ${hsversion} ] || kversion=${hsversion}-hardened

# Build-time aliases
alias kconfmain="sudo -u bin make -C /usr/src/linux O=/usr/src/linux-main menuconfig"
alias kconfkexec="sudo -u bin make -C /usr/src/linux O=/usr/src/linux-kexec ARCH=x86_64 CROSS_COMPILE=x86_64- menuconfig"

# Chainload shell settings
source ${HOME}/.bashrc

# Change to home directory is not autommatic in a chroot
cd
