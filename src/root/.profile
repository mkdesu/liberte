export LESSHISTFILE=-
export LESS="-R -M --shift 16 -Swi -x4"
export GZIP=-9

export LANG=en_GB.UTF-8
export TZ=Zulu

if [ "${TERM}" = linux ]; then
    setterm -blength 0
    echo -ne "\033[?17;0;64c"

    TMOUT=120

    echo 'Type "okroot" to enable root account (password: liberte).'
    echo 'This login session will time out after 2 minutes.'
fi

. ${HOME}/.bashrc
