## ~/.bashrc: Bash normally calls this only for interactive shells subordinate
## to the first-level login shell. To minimize duplication, this script is also
## called from the corresponding .profile, when running under Bash, for
## bash-specific initialization when login Bash shell is invoked.
##
## .bashrc  - General bash settings that also run in non-login shells
## .alias	- [optional] Defines aliases (and functions)
## .local   - [optional] Installation specific settings.
##
## .profile is called in traditional, non-Bash interactive shells. .bashrc
## is called for non-login, interactive Bash shells. This .bashrc .bashrc does
## the bash specific tasks and things that need to be repeated for secondary
## shells (e.g., aliases).

## 06/07/2013 WRL Deleted AxxsNet specific settings
## 01/16/2016 WRL Unset INPUTRC if ~/.inputrc exists (override potential default)

## If not running interactively, don't do anything
## Could also check that $- does not contain 'i': case $-; *i*) ...;; *) ...;; esac
[ -z "$PS1" ] && return

[ "$RUN_BASHRC" ] && return
#echo `basename $BASH_SOURCE`...
## Avoid recursive invocation (this is cleared before exiting)
RUN_BASHRC=true

## Some implementations invoke /etc/bash.bashrc for non-login, interactive
## shells, then call ~/.bashrc.
if [ -r /etc/bash.bashrc ]; then
	## Execute common things that are bash independent
	[ -n "$SHLVL" -o $SHLVL -eq 1 -a -z "$RUN_PROFILE" -a -r ~/.profile ] && . ~/.profile
fi
if [ "$SHLVL" -a $SHLVL -eq 1 ]; then
#	## source the system wide bashrc if it exists
#	[ -r /etc/bash.bashrc ] && source /etc/bash.bashrc
#	## Execute common things that are bash independent
#	[ -n "$SHLVL" -o $SHLVL -eq 1 -a -r ~/.profile ] && . ~/.profile
	## For completeness, check for ~/.bash_login
	[ -r ~/.bash_login ] && . ~/.bash_login
	## Perform
##	[ -r ~/bash_profile ] && . ~/bash_profile
	## History Options:
	## Don't put duplicate lines in the history.
	export HISTCONTROL=erasedups
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

	# Since this shell is interactive, turn on programmable completion enhancements.
	SUPPORTED_SHOPTS=`shopt`
	ENABLE_SHOPTS=
	[ ! "${SUPPORTED_SHOPTS/autocd /}" = "$SUPPORTED_SHOPTS" ] && ENABLE_SHOPTS+=" autocd"
	[ ! "${SUPPORTED_SHOPTS/completion_strip_exe /}" = "$SUPPORTED_SHOPTS" ] && ENABLE_SHOPTS+=" completion_strip_exe"
    `type shopt &>/dev/null` && shopt -s $ENABLE_SHOPTS cdspell checkwinsize cmdhist histreedit histappend nocasematch no_empty_cmd_completion
	unset SUPPORTED_SHOPTS ENABLE_SHOPTS
	## Use local .inputrc if it exists, rather than predefined
    [ -n "$INPUTRC" -a -r ~/.inputrc ] && unset INPUTRC ## export INPUTRC=~/.inputrc
fi

###############################################################################
## THE FOLLOWING RUNS FOR ALL SHELL LEVELS
## Prefix prompt with shell level
## (only need to set this for level 2 since it propagates down; except for ... ???
## "-o -r /etc/bash.bashrc -a $SHLVL -gt 1" is for those systems where it calls .profile, I think.
#[ "$SHLVL" -a $SHLVL -eq 2 -o -r /etc/bash.bashrc -a $SHLVL -gt 1 ] && export PS1='[$SHLVL] '$PS1
[ "$SHLVL" -a $SHLVL -eq 2 ] && PS1='[$SHLVL] '$PS1

## "complete" def'ns are not inherited in sub-shells
##    Source any global comletions
if [ -r /etc/bash_completion ]; then
	. /etc/bash_completion
	## This assumes that the global bash_completion will call ~/.bash_completion.
	## !!! This might not be true for some systems, need to check that
	##     ~/.bash_completion was invoked by /etc/bash_completion
elif `type complete &>/dev/null`; then
	if [ -r ~/.bash_completion ]; then
		. ~/.bash_completion
	else  ## Some defaults in case .bash_completion doesn't exist
		if [ -r ~/.ssh/config ]; then
			function compl_sshhosts() {
			COMPREPLY=(`grep "^Host\W$2" ~/.ssh/config |sed "s/Host[ \t]*//"|tr "\n" " "`)
			[ "$2" -a "$REPLY" ] && export COMPREPLY
			}
			`complete -p ssh &>/dev/null` || complete -F compl_sshhosts ssh
			`complete -p scp &>/dev/null` || complete -F compl_sshhosts -S ":" -o default scp
		fi
		`complete -p shopt &>/dev/null` || complete -A shopt -W "-p -s -u -q -o" shopt
		`complete -p man &>/dev/null` || complete -c man
		`complete -p cd &>/dev/null` || complete -d cd
		`complete -p svn &>/dev/null` || complete -W "add checkout cleanup commit copy cp delete remove rm diff export help import info list ls lock log merge mkdir move mv rename propdel pdel propedit pedit propget pget proplist plist propset pset ps resolved revert status switch unlock update blame praise annotate" -f svn
	fi
fi
## aliases are not inherited when sub-shell is invoked
[ -r ~/.alias ] && . ~/.alias
[ -r ~/.local -a -f ~/.local ] && . ~/.local

unset RUN_BASHRC

