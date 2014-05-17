_nix-startup
============

Here are set of scripts and init files that can be used across *nix systems (cygwin, Linux, Unix, Busybox, etc.). The point is to bring some consistency to this process and customization across disparate systems. If you are jumping between Unix-style systems—MacOS, Linux, BusyBox, etc.—then it is nice to be able to have a consistent set of command line tools. 

Repository Organization
-----------------------
Because there are different subsets of these scripts that different people may be interested in, I have separated them into separate branches. And I have an integrated branch that merges the separate branches into one. 

- **root**
- **bin**

root
----
First there are the standard startup files that sit in the home directory. I have a fixed set of files to accommodate variations in how different startup environments start. 

- Linux/Unix and cygwin command-line (login shells). 
- Linux/Unix non-"login" command-line startups.
- Traditional Linux (c-shell) and embedded systems.
 
Unix, traditionally, invoked .profile as the startup script. Embedded systems often do the same thing. For modern systems (Linux and cygwin) using **bash**, which startup script that is invoked depends on whether it is a "login-script" or not. Sometimes this can be confusing, so the organization of these scripts attempts to normalize such inconsistencies. 

In particular, starting a cygwin session within Windows, a Terminal session in OS X, or signing into a remote Linux system will invoke the login-scripts. However, opening a Terminal session within a Linux GUI environment will _not_ be started a login session, and call the login-script, because the user is already logged in and, presumably, those scripts have already been invoked. 

Non-login startup scripts are invoked when a Terminal session is started from within Linux GUI environment or new command-line session is started from within an existing session.

These **root** scripts attempt to simplify this while providing a portable set of startup files which work consistently within a multitude of environments. 

- **.profile** will always be invoked. This should be used to define non-bash settings. 
- **.bashrc** will be invoked in **bash** command-lines. 
- **.alias**, if it exists, will be invoked. This can be _sourced_ separately.
- **.bash_completion** will be invoked by .bashrc, if it exists.
- **.bash_completion.d** contain scripts that .bash_completion will _source_, if they are executable; i.e., the existence of a script will be _sourced_ if it is executable and there is a corresponding command of the same name.
 
I should mention **.local**, a file which is _sourced_, if it exists, to perform any tasks that are specific to the particular installation. _This will probably need to change since Ubuntu installs a directory called '.local' in the home directory._

bin
---
Useful utilities. The startup files, above, will include the **bin** directory in PATH if it exists in the home directory. I try to ensure that each script will include help text when invalid (including no) parameters or switches are specified. -? -h and --help should do the same. 

- **deldiff** Compare the current directory with another directory, allowing the deletion of any files which are the same (as determined by **diff**).
- **deldupn** Compare the current directory with another directory, allowing the deletion of any files which are the same (as determined by name, only).
- **lpath** List the components of a path environment value (default **PATH**). 

Change Log
----------
.... initial files
