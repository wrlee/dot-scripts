## ~/.bashrc: Bash normally calls this only for interactive shells subordinate
## to the first-level login shell. To minimize duplication, this script is also
## called from the corresponding .profile, when running under Bash, for
## bash-specific initialization when login Bash shell is invoked.
##
## .bashrc        - General bash settings that also run in non-login shells
## .alias         - [optional] Defines aliases (and functions)
## .profile_local - [optional] Installation specific settings.
##
## .profile is called in traditional, non-Bash interactive shells. .bashrc
## is called for non-login, interactive Bash shells. This .bashrc .bashrc does
## the bash specific tasks and things that need to be repeated for secondary
## shells (e.g., aliases).

## TODO: Look at $BASH_ARGV to see whether this is being recursively called

## 06/07/2013 WRL Deleted AxxsNet specific settings
## 01/16/2016 WRL Unset INPUTRC if ~/.inputrc exists (override potential default)
## 10/11/2017 WRL Correctly check command (w/o `) before &&, ||: Set shopt properly
## 2021-01-25 WRL Execute .profile_`os-name` .profile_`$USER .profile_$HOSTNAME .profile_local, if they exist
## 2022-10-19 WRL Integrate NVM & RVM settings so they occur before bash_completion
            - WRL Add `_source*()` functions to test and source scripts

## If not running interactively, don't do anything
## Could also check that $- does not contain 'i': case $-; *i*) ...;; *) ...;; esac
[ -z "$PS1" ] && return

[ "$RUN_BASHRC" ] && return
[ -n "$PS1" ] && echo $(basename $BASH_SOURCE)...
## Avoid recursive invocation (this is cleared before exiting)
RUN_BASHRC=true
_sourceFiles() {
	local i
	for i in "$@"; do
			[ -f "$i" -a -s "$i" ] && source "$i"
	done
}

_sourceDotFiles() {
	_sourceFiles ${@/#/$HOME\/}
}

#if [ -n "$SESSION_MANAGER" -o -n "$SESSION" ]; then	## Generic way to determine whether to run .profile
if [ -z "$PS1" ]; then
	## Execute common things that are bash independent
#	[ -n "$SHLVL" -o $SHLVL -eq 1 -a -z "$RUN_PROFILE" ] && _sourceDotFiles .profile
	_sourceDotFiles .profile
fi
#if [ "$SHLVL" -a $SHLVL -eq 1 ]; then
## Ubuntu terminal sessions:
if [ -n "$SESSION_MANAGER" -a $SHLVL -le 2 -o -z "$SESSION_MANAGER" -a $SHLVL -eq 1 ]; then
#	## source the system wide bashrc if it exists
#	_sourceFiles /etc/bash.bashrc
#	## Execute common things that are bash independent
#	[ -n "$SHLVL" -o $SHLVL -eq 1 ] && _sourceDotFiles .profile
	## For completeness, check for ~/.bash_login
	_sourceDotFiles .bash_login
	## Perform
##	_sourceDotFiles .bash_profile
	## History Options:
	## Delete previous duplicate lines from history.
#	export HISTCONTROL=erasedups
	## Ignore some controlling instructions
	# export HISTIGNORE="[   ]*:&:bg:fg:exit"
	export HISTIGNORE="d:e:l:l :ll:ll :ls:ls :cd:cd :exit:history"

	# make less more friendly for non-text input files, see lesspipe(1)
	#[ -x /usr/bin/lesspipe ] && eval "$(lesspipe)"

	# If this is an xterm set the title to user@host:dir
#	[ -z "$PROMPT_COMMAND" ] && case "$TERM" in
#    xterm*|rxvt*|cygwin)
#		PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD/$HOME/~}\007"'
#		;;
#    *)
#		;;
#    esac
	[ "${BASH_VERSINFO[0]}" -ge 4 ] && export PROMPT_DIRTRIM=3
fi

###############################################################################
## THE FOLLOWING RUNS FOR ALL SHELL LEVELS
## Prefix prompt with shell level
## (only need to set this for level 2 since it propagates down; except for ... ???
## "-o -r /etc/bash.bashrc -a $SHLVL -gt 1" is for those systems where it calls .profile, I think.
#[ "$SHLVL" -a $SHLVL -eq 2 -o -r /etc/bash.bashrc -a $SHLVL -gt 1 ] && export PS1='[$SHLVL] '$PS1
#[ "$SHLVL" -a $SHLVL -eq 2 ] && PS1='[$SHLVL] '$PS1
#remove '\n' from PS1 until we can fix it so that .profile's PS1 setting
#is called for sub-shells too.
#[ -n "$SHLVL" -a $SHLVL -gt 1 ] && PS1='[$SHLVL] '${PS1/\\n/}
## Flag > primary shells w/shellcount
#echo "==== .bashrc: [$SHLVL] $(date) $(tty)::$- ======================================">>~/login.log
#env|sort>>~/login.log
if [ -n "$SESSION_MANAGER" -a $SHLVL -gt 2 ]; then
	export PS1=$t_green'[$(($SHLVL-1))] '${ps1:-"$PS1"}
elif [ -z "$SESSION_MANAGER" -a $SHLVL -gt 1 ]; then
	export PS1=$t_green'[$SHLVL] '${ps1:-"$PS1"}
fi

# Since this shell is interactive, turn on programmable completion enhancements.
if type shopt &>/dev/null; then
	SUPPORTED_SHOPTS=$(shopt|sed 's/^\([^ 	]*\).*/:\1:/')
	ENABLE_SHOPTS=
	for i in autocd completion_strip_exe checkjobs globstar; do
		[ "${SUPPORTED_SHOPTS/:$i:/}" != "$SUPPORTED_SHOPTS" ] && ENABLE_SHOPTS+=" $i"
	done
	shopt -s $ENABLE_SHOPTS cdspell checkwinsize cmdhist histreedit histappend nocasematch no_empty_cmd_completion
	unset i SUPPORTED_SHOPTS ENABLE_SHOPTS
fi
## Use local .inputrc if it exists, rather than predefined
[ -n "$INPUTRC" -a -r ~/.inputrc ] && unset INPUTRC ## export INPUTRC=~/.inputrc

#export NVM_DIR="$HOME/.nvm"
#[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -n "$NVM_DIR" ] && _sourceFiles "$NVM_DIR/nvm.sh"
[ -z "$NVM_DIR" ] && _sourceDotFiles ".nvm/nvm.sh"
#[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

## "complete" def'ns are not inherited in sub-shells
##    Source any global comletions
if [ -r /etc/bash_completion ]; then
	. /etc/bash_completion
	## This assumes that the global bash_completion will call ~/.bash_completion.
	## !!! This might not be true for some systems, need to check that
	##     ~/.bash_completion was invoked by /etc/bash_completion
elif type complete &>/dev/null; then
	if [ -r ~/.bash_completion ]; then
		. ~/.bash_completion
	else  ## Some defaults in case .bash_completion doesn't exist
		if [ -r ~/.ssh/config ]; then
			function compl_sshhosts() {
				COMPREPLY=($(grep "^Host\W$2" ~/.ssh/config |sed "s/Host[ \t]*//"|tr "\n" " "))
				[ "$2" -a "$REPLY" ] && export COMPREPLY
			}
			complete -p ssh &>/dev/null || complete -F compl_sshhosts ssh
			complete -p scp &>/dev/null || complete -F compl_sshhosts -S ":" -o default scp
		fi
		complete -p shopt &>/dev/null || complete -A shopt -W "-p -s -u -q -o" shopt
		complete -p man &>/dev/null || complete -c man
		complete -p cd &>/dev/null || complete -d cd
#		complete -p svn &>/dev/null || complete -W "add checkout cleanup commit copy cp delete remove rm diff export help import info list ls lock log merge mkdir move mv rename propdel pdel propedit pedit propget pget proplist plist propset pset ps resolved revert status switch unlock update blame praise annotate" -f svn
	fi
fi

## aliases are not inherited when sub-shell is invoked
_sourceDotFiles .alias
# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
# export PATH="$PATH:$HOME/.rvm/bin"
_sourceDotFiles .rvm/scripts/rvm # Load RVM into a shell session *as a function*

## When I used to use .local rather than .profile_local: rename to .profile_local
[ -f ~/.local -a ! -e ~/.profile_local ] && mv ~/.local ~/.profile_local
## Scripts specific to OS type, user name, machine name, 'local'
_sourceDotFiles ".profile_`uname -s`" ".profile_${USER:-`id -un`}" ".profile_${HOSTNAME%.local}" .profile_local

unset -f _sourceFiles _sourceDotFiles

unset RUN_BASHRC
#export JAVA_TOOL_OPTIONS="-Dlog4j2.formatMsgNoLookups=true"
