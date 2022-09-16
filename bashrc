# That's my ~/.bashrc file for Debian computers
#
# To use it just download and save in your user directory as ~/.bashrc

export TERM=xterm-256color

PS1="\[$(tput bold)\]\[\033[48;5;160m\]\u\[$(tput sgr0)\]\[\033[0m\]@\[$(tput sgr0)\]\[\033[38;5;118m\]\h\[$(tput sgr0)\]\[$(tput sgr0)\]\[\033[38;5;15m\]:\[
$(tput sgr0)\]\[\033[0m\]\[\033[38;5;14m\]\w\[$(tput sgr0)\]\[\033[38;5;15m\]\\$\[$(tput sgr0)\] "

umask 022

# You may uncomment the following lines if you want `ls' to be colorized:
export LS_OPTIONS='--color=auto'
eval "`dircolors`"
alias ls='ls $LS_OPTIONS --time-style="+%Y-%m-%d %H:%M:%S"'
alias ll='ls $LS_OPTIONS -l --time-style="+%Y-%m-%d %H:%M:%S"'
alias l='ls $LS_OPTIONS -lA --time-style="+%Y-%m-%d %H:%M:%S"'
alias la='ls -lah --time-style="+%Y-%m-%d %H:%M:%S"'

# I prefer to use NANO instead of VI
alias vi='nano'

# Alias about update and upgrade your repository and installed software
alias upd='sudo apt update && sudo apt upgrade -y && sudo apt clean && sudo apt autoclean && sudo apt autoremove -y --purge'

# Alias that clean apt cache and remove unused dependences
alias clean='sudo apt clean && sudo apt autoclean && sudo apt autoremove -y --purge'

# Some more alias to avoid making mistakes:
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

alias mioip='echo $(wget -qO- http://ipecho.net/plain)'

# Search the KEYWORD in your history and show only matching result
alias h='history | awk '"'"'{$1="";print}'"'"' |sed "s/^ *//" |grep -v "^h " | sort | uniq | grep'

EDITOR=nano
VISUAL=$EDITOR
export EDITOR VISUAL
