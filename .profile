## ~/.profile:  Interactive login shell startup script. This startup file is
## called by Bash, directly, if neither .bash_profile nor .bash_login exist.
##
## .profile       - General settings that are not bash specific (but run in interactive shells).
## .bashrc        - General bash settings that also run in non-login shells
## .alias         - [optional] Defines aliases (and functions)
## .profile_local - [optional] Installation specific settings.
##
## .profile is called in traditional, non-Bash interactive shells. .bashrc
## is called for non-login, interactive Bash shells. Under Bash, this .profile
## calls .bashrc to call each other so that common, non-Bash-specific settings
## are performed here and .bashrc does the bash specific and things that need
## to be repeated for secondary shells (e.g., aliases).
##
## TODO: Set ENV to refer to this script for those things that need to be
##       repreated in secondary, non-Bash shells.
## TODO: Look at $BASH_ARGV to see whether this is being recursively called
##
## 2017.10.11 Generalize setting of colored PS1 prompt, setting $color_prompt
##          - Include ~/.local/bin to PATH
## 2021-01-25  Execute .profile_`os-name` .profile_`$USER .profile_$HOSTNAME .profile_local, if they exist
## 2022-10-20 Update PATH and MANPATH to reduce duplicates and handle initially undefined
##          - Integrate HOMEBREW settings
##          - Added _setManPath to segregate from _setPath
##          - Add _setPrompt
## 2023-03-14 Added _setInfoPath
##          - Fixes for ash/busybox
##          - Run `iterm2_shell_integration` and conditionally restore last path
[ "$RUN_PROFILE" ] && return
[ -n "$PS1" ] && echo $(basename ${BASH_SOURCE:-${SHELL+$0}${SHELL-.profile}})...
RUN_PROFILE=true

## Find Homebrew paths
for _brew in /opt/homebrew /home/linuxbrew/.linuxbrew /usr/local; do
   if [ -x "$_brew/bin/brew" ]; then
      export HOMEBREW_PREFIX="$_brew"
      break
   fi
done
unset _brew
if [ -n "${HOMEBREW_PREFIX}" ]; then
   export HOMEBREW_REPOSITORY="${HOMEBREW_PREFIX}"
   export HOMEBREW_CELLAR="${HOMEBREW_PREFIX}/Cellar"
fi

## Include user's private paths, if they exist
_setPath() {
   ## Prefix paths (in reverse order)
   local _paths_prefix=('/Applications/Visual Studio Code.app/Contents/Resources/app/bin' ~/.cargo/bin ~/go/bin ~/.local/bin ~/anaconda3/bin ~/pear/bin /usr/local/mysql/bin "${HOMEBREW_PREFIX:+${HOMEBREW_PREFIX}/sbin}" "${HOMEBREW_PREFIX:+${HOMEBREW_PREFIX}/bin}" ~/bin .)

   [ ! -d ~/pear/bin ] && _paths_prefix+=(~/pear)
   for i in "${_paths_prefix[@]}"; do
      [ -d "$i" -a "${PATH##*:"$i":*}" -a "${PATH##"$i":*}" ] && PATH=$i${PATH+:$PATH}
   done
   local _paths_suffix=(/Library/Developer/CommandLineTools/usr/bin /Applications/Xcode.app/Contents/Developer/usr/bin ~/Library/Python/3.9/bin)
   for i in ${_paths_suffix[@]}; do
      [ -d "$i" -a "${PATH##*:"$i":*}" -a "${PATH##"$i":*}" ] && PATH+=${PATH+:}$i
   done
} ## _setPath()
_setPath
unset -f _setPath

[ -d ~/lib ] && export LD_LIBRARY_PATH=~/lib${LD_LIBRARY_PATH+:$LD_LIBRARY_PATH}

## Ensure interactive shell...
## Could also check that $- does not contain 'i': case $-; *i*) ...;; *) ...;; esac
if [ -z "$PS1" ]; then
   unset RUN_PROFILE
   return
fi

_setPrompt() {
   local color_prompt force_color_prompt
   # set a fancy prompt (non-color, unless we know we "want" color)
   case "$TERM" in
   xterm | xterm-color | *-256color | cygwin)
      color_prompt=yes
      ;;
   *)
      which tput >/dev/null && [ $(tput colors) -ge 8 ] && color_prompt=yes
      ;;

   esac

   # uncomment for a colored prompt, if the terminal has the capability; turned
   # off by default to not distract the user: the focus in a terminal window
   # should be on the output of commands, not on the prompt
   #force_color_prompt=yes
   if [ -n "$force_color_prompt" ]; then
      if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
         # We have color support; assume it's compliant with Ecma-48
         # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
         # a case would tend to support setf rather than setaf.)
         color_prompt=yes
      else
         color_prompt=
      fi
   fi

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
   local t_reset t_yellow t_cyan t_brightCyan t_green PS_input PS_W PS_H PS_U PS_dT _ESC
   _ESC=''
   [ -n "$BASH" ] && _ESC='\e' ## optional for a more readable PS1
   #if [ -t 1 -a -z "${TERM##xterm*}" -o "$TERM" = cygwin ]; then
   if [ -t 1 -a "$color_prompt" = yes ]; then
      t_reset='\['$_ESC'[0m\]'
      t_yellow='\['$_ESC'[33m\]'
      t_cyan='\['$_ESC'[36m\]'
      t_brightCyan='\['$_ESC'[01;36m\]'
      t_green='\['$_ESC'[32m\]'
      # See also $PROMPT_COMMAND
      [ -n "$BASH_VERSION" ] && trap "echo -n "$'\e[0m' DEBUG && PS_input="$t_cyan"
   fi

   ## Set up prompt colors (maybe)
   PS_W="$t_brightCyan\w$t_reset" ## Path
   PS_H="$t_yellow\h$t_reset"     ## Host
   PS_U="$t_yellow\u$t_reset"     ## User
   PS_dT="$t_green\d \t$t_reset"  ## Date time

   local PS_CHAR='$' _title
   if [ -z "$HOSTNAME" ]; then   ## Non-bash--probably remote, embedded.
      PS1=$t_reset$PS_H':'$PS_W' \n\'$PS_CHAR' '$PS_input
      _title='\h:\w'
      ## Shared host: username@host
   elif [ "$SSH_CLIENT" -o "$MAIL" ]; then
      PS1=$t_reset$PS_U'@\h:'$PS_W' \n\'$PS_CHAR' '$PS_input
      _title='[\u@\h] \w'
   else ## Local machine or embedded device
      PS1="$t_reset$PS_dT $PS_W\n"$PS_CHAR" $PS_input"
      case $OSTYPE in
      cygwin*) ;;
      *arm*) ## cygwin PS1='\['$_ESC']0;\w\a\]\n\['$_ESC'[32m\]\u@\h \['$_ESC'[33m\]\w\['$_ESC'[0m\]\n\'$PS_CHAR' '
         PS1=$t_reset$PS_H': '$PS1
         ;;
      esac
      _title='\w'
      [ "$MACHTYPE" == "i686-pc-cygwin" ] && _title=$MACHTYPE
   fi
   [ -n "$_title" ] && PS1='\['$_ESC']0;${TERMTITLE:-'$_title'}\a\]'$PS1
   export PS1 ps1="$PS1"
} ## _setPrompt

#echo "==== .profile: [$SHLVL] $(date) $(tty)::$- ======================================">>~/login.log
#env|sort>>~/login.log

_setPrompt

unset -f _setPrompt
if [ "$1" = "PS" -o "$1" = "prompt" ]; then
   unset RUN_PROFILE
   return
fi

_setManPath() {
   local i
   for i in ~/man ~/.local/man ~/.local/share/man "${HOMEBREW_PREFIX:+${HOMEBREW_PREFIX}/share/man}"; do #/usr/share/man /usr/local/share/man
      [ -d "$i" ] && [ -z "$MANPATH" -o "${MANPATH##*:"$i":*}" -a "${MANPATH##*:"$i"}" -a "${MANPATH##"$i":*}" ] && MANPATH+=${MANPATH+:}$i
   done
   [ -n "$MANPATH" ] && export MANPATH
   ## If $MANPATH set, ensure it includes man config file since $MANPATH supercedes the file
   if [ -n "$MANPATH" ]; then
      [ -s /etc/man.conf ] && local man_config=/etc/man.conf
      [ -s /etc/manpath.config -a -n "$man_config" ] && echo "$(basename $0) both /etc/man.conf & /etc/manpath.config exist"
      [ -s /etc/manpath.config ] && local man_config=/etc/manpath.config
      if [ -n $man_config ]; then
         local path mapfor mapto
         ## TODO Is the following appended in the correct order?
         for path in $(sed -E $'/^[ \t]*(MANDATORY_)?MANPATH[ \t]+/!d' $man_config); do
            [ -d "$path" ] && [ -z "$MANPATH" -o "${MANPATH##*:$path:*}" -a "${MANPATH##*:$path}" -a "${MANPATH##$path:*}" -a "$MANPATH" != "$path" ] && MANPATH+=${MANPATH+:}$path
         done
         for path in $(sed -E $'/^[ \t]*MANPATH_MAP[ \t]/!d; s/^[ \t]*MANPATH_MAP[ \t]+([^ \t]+)[ \t]+([^ \t]+)$/\\1:\\2/' $man_config); do
            IFS=: read -r mapfor mapto <<<"$path"
            if [ -d "$mapto" ] && [ -z "${PATH##*:${mapfor}:*}" -o -z "${PATH##*:${mapfor}}" -o -z "${PATH##${mapfor}:*}" -o "$PATH" = "$mapfor" ]; then
               [ -z "$MANPATH" -o "${MANPATH##*:$mapto:*}" -a "${MANPATH##*:$mapto}" -a "${MANPATH##$mapto:*}" -a "$MANPATH" != "$mapto" ] && MANPATH+=${MANPATH+:}$mapto
            fi
         done
      fi
   fi
} ## _setManPath()

_setInfoPath() {
   for i in "${HOMEBREW_PREFIX:+${HOMEBREW_PREFIX}/share/info}" ~/info ~/.local/share/info; do
      [ -d "$i" ] && [ -z "$INFOPATH" -o "${INFOPATH##*:"$i":*}" -a "${INFOPATH##*:"$i"}" -a "${INFOPATH##"$i":*}" -a "$INFOPATH" != "$i" ] && INFOPATH=$i${INFOPATH+:$INFOPATH}
   done
   [ -n "$INFOPATH" ] && export INFOPATH
} ## _setInfoPath()

[ -n "$SHELL" ] && _setManPath
_setInfoPath
unset -f _setManPath _setInfoPath

## Enable history, if available 'set -o history' 'set -H'
if type history >/dev/null 2>&1; then
   [ -z "$HISTCONTROL" ] && export HISTCONTROL=erasedups
   [ -z "$HISTFILE" ] && export HISTFILE=~/.bash_history
   [ -z "$HISTFILESIZE" ] && export HISTFILESIZE=5000
   [ -z "$HISTSIZE" ] && export HISTSIZE=2500
fi

## TODO: Test to see if path alrady exists in CDPATH
CDPATH=.
# Windows/cygwin
if [ "$OSTYPE" = "cygwin" ]; then
   ## If Windows user's Documents directory != ~/Documents, add to CDPATH
   #	[ -n "$USERPROFILE" -a -d "$(cygpath "$USERPROFILE\\Documents")" ] && CDPATH=$CDPATH:`cygpath $USERPROFILE/Documents`
   _docdir=$(cygpath "$(tr -d '\0' <"/proc/registry/HKEY_CURRENT_USER/Software/Microsoft/Windows/CurrentVersion/Explorer/Shell Folders/Personal")")
   [ -n "$_docdir" -a -d "$_docdir" -a ! "$_docdir" -ef "$HOME/Documents" ] && CDPATH=$CDPATH:$_docdir
   unset _docdir
   ## If Windows user's home != $HOME, add to CDPATH
   [ ! "$HOME" -ef "$(cygpath $USERPROFILE)" ] && CDPATH=$CDPATH:$(cygpath $USERPROFILE)
   #	[ -d `cygpath $HOMEDRIVE` ] && CDPATH=$CDPATH:`cygpath $HOMEDRIVE`:/cygdrive
   ## Allow single letter shortcuts to various drives' roots
   [ -d /cygdrive ] && CDPATH=$CDPATH:/cygdrive

   export CYGWIN=winsymlinks:nativestrict
   ## Ignore these filetypes in autocompletion, even if they are executable
   FIGNORE=.DLL:.dll
else
   ## Generic *nix & MacOS
   [ -d $HOME/Documents ] && CDPATH=$CDPATH:$HOME/Documents
fi
export CDPATH=$CDPATH:$HOME
[ -d /mnt ] && export CDPATH=$CDPATH:/mnt

## If Bash is running, there's a local .bashrc, & it hasn't been run...
if [ -r ~/.bashrc -a "$BASH" ]; then
   [ -z "$RUN_BASHRC" ] && . ~/.bashrc
else
   ##	Stuff that needs to be run when .bashrc isn't run
   #  [ -n "$PS1" -a -r ~/.alias ] && `alias resolve >/dev/null 2>&1` || . ~/.alias
   [ -n "$PS1" -a -r ~/.alias ] && . ~/.alias
   ## When I used to use .local rather than .profile_local: rename to .profile_local
   [ -f ~/.local -a ! -e ~/.profile_local ] && mv ~/.local ~/.profile_local
   ## Scripts specific to OS type, user name, machine name, 'local'
   for _profile in ".profile_$(uname -s)" ".profile_${USER:-$(id -un)}" ".profile_${HOSTNAME%.local}" .profile_local; do
      if [ -s "$HOME/$_profile" ]; then
         echo "$_profile..."
         . "$HOME/$_profile"
      fi
   done
   unset _profile
fi

## Restore last current directory (as remembered by ~/.cwd)
if [ "$LC_TERMINAL" = iTerm2 ]; then
   [ -s ~/bin/iterm2_shell_integration.$(basename "$SHELL") ] && . ~/bin/iterm2_shell_integration.$(basename "$SHELL")
elif [ -r ~/.cwd ] && [ -d "$(tail -1 ~/.cwd)" ]; then
   cd "$(tail -1 ~/.cwd)"
fi

unset RUN_PROFILE
#export JAVA_TOOL_OPTIONS="-Dlog4j2.formatMsgNoLookups=true"
