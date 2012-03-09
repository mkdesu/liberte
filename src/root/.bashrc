unset HISTFILE
HISTCONTROL=erasedups
HISTSIZE=100

alias l="ls -l"
alias ll="l -a"
alias -- -="less"
alias g="grep"
alias du="du -ks"
alias ..="cd .."

okroot() {
    if [ -n "${TMOUT}" ]; then
        unset TMOUT
        echo 'shell timeout: removed'
    else
        echo 'shell timeout: not set'
    fi

    if grep -q '^root:!' /etc/shadow; then
        usermod -U root
        echo 'root account:  unlocked'
    else
        echo 'root account:  not locked'
    fi
}
