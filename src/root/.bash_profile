umask 022

if type -p env-update 1>/dev/null; then
    env-update
    source /etc/profile
fi

export LESSHISTFILE=-
LESS="${LESS} --shift 16 -Swi -x4"

source ${HOME}/.bashrc
cd
