## ~/.profile:  Interactive login shell startup script. This startup file is 
## called by Bash, directly, if neither .bash_profile nor .bash_login exist. 
##
## .profile - General settings that are not bash specific (but run in interactive shells).
## .bashrc  - General bash settings that also run in non-login shells
## .alias	- [optional] Defines aliases (and functions)
## .local   - [optional] Installation specific settings. 
##
## .profile is called in traditional, non-Bash interactive shells. .bashrc
## is called for non-login, interactive Bash shells. Under Bash, this .profile 
## calls .bashrc to call each other so that common, non-Bash-specific settings 
## are performed here and .bashrc does the bash specific and things that need 
## to be repeated for secondary shells (e.g., aliases). 
##
## TODO: Set ENV to refer to this script for those things that need to be
##       repreated in secondary, non-Bash shells. 
##
[ "$RUN_PROFILE" ] && return
#echo `basename $BASH_SOURCE`...
RUN_PROFILE=true

## Include user's private paths, if they exist
[ -d ~/bin ] && export PATH=~/bin:$PATH
[ -d /Applications/Xcode.app/Contents/Developer/usr/bin ] && export PATH=$PATH:/Applications/Xcode.app/Contents/Developer/usr/bin
[ -d ~/lib ] && export LD_LIBRARY_PATH=~/lib:$LD_LIBRARY_PATH
[ -d "${HOME}/man" ] && export MANPATH=${HOME}/man:${MANPATH}
[ -d "${HOME}/info" ] && export INFOPATH=${HOME}/info:${INFOPATH}
export PATH=.:$PATH

## Ensure interactive shell...
## Could also check that $- does not contain 'i': case $-; *i*) ...;; *) ...;; esac 
#[ -z "$PS1" ] && return
case "$-" in
	*i*)
	;;
	*)	unset RUN_PROFILE
		return
	;;
esac

## Try to set prompt based on generic context. If on a local private machine
## (e.g., cygwin, Mac), just use nice date/time.  If ssh/telnet remotely,
## show hostname. If remoting into a multi-user system show user and host names.
##
## Sets multiple display attribute settings:
##	<ESC>[{attr1};...;{attrn}m
##
##  Attribute	      Colours	Foreground	Background
##   0	Reset all     Black		30	40
##   1	Bright        Red		31	41
##   2	Dim           Green		32	42
##   4	Underscore    Yellow	33	43
##   5	Blink         Blue		34	44
##   7	Reverse       Cyan		36	46
##   8	Hidden        White		37	47
##
if [ -t 1 -a "$TERM" = xterm ]; then 
	t_reset='\[\e[0m\]'
	t_yellow='\[\e[33m\]'
	t_cyan='\[\e[36m\]'
	t_brightCyan='\[\e[01;36m\]'
	t_green='\[\e[32m\]'
	# See also $PROMPT_COMMAND
	[ -n "$BASH_VERSION" ] && trap "echo -ne \"\033[0m\"" DEBUG && PS_input="$t_cyan"
fi
## Set up prompt colors (maybe)
PS_W="$t_brightCyan\w$t_reset"	## Path
PS_H="$t_yellow\h$t_reset"		## Host
PS_U="$t_yellow\u$t_reset"		## User
PS_dT="$t_green\d \T$t_reset"	## Date time
unset t_yellow t_cyan t_brightCyan t_green
# case "$TERM" in
# cygwin|xterm*)
# 	t_reset='\[\033[00m\]'
# 	trap 'echo -ne "\033[00m"' DEBUG && PS_input='\[\033[36m\]'
#     PS_W="\[\033[01;36m\]\w$t_reset"
#     PS_H="\[\033[33m\]\h$t_reset"
#     PS_U="\[\033[33m\]\u$t_reset"
#     ;;
# *)
#     PS_W="\w"
#     PS_H="\h"
#     PS_H="\u"
#     ;;
# esac
PS_CHAR='$'
[ `id -u` -eq 0 ] && PS_CHAR='#'
#export PS1="[`hostname|cut -d . -f 1`] \$PWD \$ "
#echo ...$HOSTNAME---$SSH_CLIENT---$MAIL...
if [ -z "$HOSTNAME" ]; then		## Non-bash--probably remote, embedded.
	PS1=$t_reset$PS_H':'$PS_W' \n\'$PS_CHAR' '$PS_input
#	PS1='\[\e]0;\h:\w\a\]'$PS1
	_title='\h:\w'
											## Shared host: username@host
elif [ "$SSH_CLIENT" -o "$MAIL" ] && [ "$USER" != "root" ]; then
	PS1=$t_reset$PS_U'@\h:'$PS_W' \n\'$PS_CHAR' '$PS_input
#	PS1='\[\e]0;\u@\h:\w\a\]'$PS1
	_title='\u:\w'
else 										## Local machine or embedded device
	PS1="$t_reset$PS_dT $PS_W\n"$PS_CHAR" $PS_input"
	case $OSTYPE in
	cygwin*)
		;;
	*arm*)	## cygwin PS1='\[\e]0;\w\a\]\n\[\e[32m\]\u@\h \[\e[33m\]\w\[\e[0m\]\n\'$PS_CHAR' '
		PS1=$t_reset$PS_H': '$PS1
		;;
	esac
	_title='\w'
	[ "$MACHTYPE" == "i686-pc-cygwin" ] && _title=$MACHTYPE
fi
[ -n "$_title" ] && PS1='\[\e]0;'$_title'\a\]'$PS1
unset _title
unset t_reset PS_input PS_W PS_H PS_U PS_dT PS_CHAR

## Enable history, if available 'set -o history' 'set -H'
[ -z "$HISTCONTROL" ] && export HISTCONTROL=erasedups
[ -z "$HISTFILE" ] && export HISTFILE=~/.bash_history          
[ -z "$HISTFILESIZE" ] && export HISTFILESIZE=1500
[ -z "$HISTSIZE" ] && export HISTSIZE=700

## TODO: Test to see if path alrady exists in CDPATH
## Generic *nix
export CDPATH=.
## Mac OS
[ -d $HOME/Documents ] && export CDPATH=$CDPATH:$HOME/Documents
## Generic *nix
export CDPATH=$CDPATH:$HOME
## Windows/cygwin
if [ "$OSTYPE" = "cygwin" ]; then
	[ -n "$USERPROFILE" -a -d `cygpath "$USERPROFILE\\Documents"` ] && export CDPATH=$CDPATH:`cygpath $USERPROFILE/Documents`
	[ "$HOME" != "`cygpath $USERPROFILE`"  ] && export CDPATH=$CDPATH:`cygpath $USERPROFILE`
	[ -d `cygpath $HOMEDRIVE` ] && export CDPATH=$CDPATH:`cygpath $HOMEDRIVE`:/cygdrive
fi

[ -r ~/.p4config ] && export P4CONFIG=~/.p4config

# function settitle() { echo -n "^[]2;$@^G^[]1;$@^G"; }

if [ "$OSTYPE" = "cygwin" ]; then
	## Ignore these filetypes in autocompletion, even if they are executable
	FIGNORE=.DLL:.dll
fi

## If 
if [ -r ~/.bashrc -a "$BASH" ]; then
   [ -z "$RUN_BASHRC" ] && . ~/.bashrc
else
#  [ -n "$PS1" -a -r ~/.alias ] && `alias resolve >/dev/null 2>&1` || . ~/.alias
   [ -n "$PS1" -a -r ~/.alias ] && . ~/.alias
   [ -r ~/.local -a -f ~/.local ] && . ~/.local
fi

if [ -r ~/.cwd ]; then
	[ -d "`tail -1 ~/.cwd`" ] && cd `tail -1 ~/.cwd`
fi

unset RUN_PROFILE
