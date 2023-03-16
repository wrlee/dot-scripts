## ~/.profile:  Interactive login shell startup script. This startup file is 
## called by bash, directly, if neither .bash_profile nor .bash_login exist. 
##
## .bashrc  - General bash settings that also run in non-interactive shells
## .profile - General settings that are not bash specific (but run in interactive shells).
## .local   - Installation specific settings. 
##
[ "$RUN_PROFILE" ] && return
#echo .profile...
RUN_PROFILE=true

## Include user's private paths, if they exist
[ -d ~/bin ] && export PATH=~/bin:$PATH
[ -d ~/lib ] && export LD_LIBRARY_PATH=~/lib:$LD_LIBRARY_PATH
[ -d "${HOME}/man" ] && export MANPATH=${HOME}/man:${MANPATH}
[ -d "${HOME}/info" ] && export INFOPATH=${HOME}/info:${INFOPATH}
export PATH=.:$PATH

## Try to set prompt based on generic context. If on a local private machine
## (e.g., cygwin, Mac), just use nice date/time.  If ssh/telnet remotely,
## show hostname. If remoting into a multi-user system show user and host names.
##
## Sets multiple display attribute settings:
##	<ESC>[{attr1};...;{attrn}m
##
##  Attribute	      Colours	Foreground	Background
##   0	Reset all	Black		30	40
##   1	Bright		Red		31	41
##   2	Dim		Green		32	42
##   4	Underscore	Yellow		33	43
##   5	Blink		Blue		34	44
##   7	Reverse		Cyan		36	46
##   8	Hidden		White		37	47
##
case "$TERM" in
cygwin|xterm*)
    PS_W="\[\033[01;36m\]\w\[\033[00m\]"
    PS_H="\[\033[33m\]\h\[\033[00m\]"
    PS_U="\[\033[33m\]\u\[\033[00m\]"
    ;;
*)
    PS_W="\w"
    PS_H="\h"
    PS_H="\u"
    ;;
esac
#echo ...$HOSTNAME---$SSH_CLIENT---$MAIL...
#export PS1="[`hostname|cut -d . -f 1`] \$PWD \$ "
if [ -z "$HOSTNAME" ]; then		## Non-bash--probably remote, embedded.
   export PS1=$PS_H':'$PS_W' \n\$ '
					## Shared host: username@host
elif [ "$SSH_CLIENT" -o "$MAIL" ] && [ "$USER" != "root" ]; then
   export PS1=$PS_U'@\h:'$PS_W' \n\$ '
else ## Local machine or embedded device
   export PS1='\d \T '$PS_W'\n\$ '
   case $MACHTYPE in
#  *darwin*)
#     ;;
   *cygwin*|*arm*)	## cygwin PS1='\[\e]0;\w\a\]\n\[\e[32m\]\u@\h \[\e[33m\]\w\[\e[0m\]\n\$ '
      export PS1=$PS_H': '$PS1
      ;;
   esac
fi
unset PS_W PS_H PS_U

## Enable history, if available 'set -o history' 'set -H'
[ -z "$HISTCONTROL" ] && export HISTCONTROL=erasedups
[ -z "$HISTFILE" ] && export HISTFILE=~/.bash_history          
[ -z "$HISTFILESIZE" ] && export HISTFILESIZE=500
[ -z "$HISTSIZE" ] && export HISTSIZE=500

export CDPATH=.:$HOME

[ -r ~/.p4config ] && export P4CONFIG=~/.p4config

# Some example functions
# function settitle() { echo -n "^[]2;$@^G^[]1;$@^G"; }

#stty erase 

if [ -r ~/.bashrc -a "$BASH" ]; then
   . ~/.bashrc
else
   [ -r ~/.alias ] && `alias resolve >/dev/null 2>&1` || . ~/.alias
fi

[ -r ~/.cwd ] && cd `tail -1 ~/.cwd`
[ -r ~/.local ] && . ~/.local

unset RUN_PROFILE
