Sometimes you will need to know what your tool is currently doing. This is often described as [transparency](http://www.faqs.org/docs/artu/ch01s06.html#id2878054) and many popular tools offer it. *cURL* and *ssh* have the *-v* option while *phantomjs* has the *--debug* option. In any case, the effect is the same, making the program more talkative.

### Why

Most likely this will be for troubleshooting. Perhaps, a command that takes forever to complete, or finishes but without doing what it was supposed to do. Personally I often need it to troubleshoot networking programs and complicated scripts that perform actions on many files/directories.

### How

The usual way to add verbosity to a **CLI** program is by adding an option (such as -v or --verbose) and then, as the program executes, by printing useful info on the terminal if this option is passed as an argument.

Applications with a **GUI** can either append info to a log file or open a new window containing a text-area that plays the role of a "live" log.

For the rest of this article I'll focus on CLI programs and specifically BASH scripts, since it's my first choice whenever I decide to make a new tool.

Note that most tools (especially ones used in pipelines) follow the [rule of silence](http://www.faqs.org/docs/artu/ch01s06.html#id2878450) and have it disabled by default.

#### Design

Hence the following design:

1. By default, verbosity is disabled. The option -v will enable it.
1. When this option is used, an environment variable will be set.
1. If this environment variable is present, the tool will echo details to *stderr*. Echoing to *stderr* is necessary for programs that are usually part of a pipeline.

#### Implementation

Her's a simple implementation for BASH:

- Function **set_verbosity** will set the environment variable for verbosity. This should be called in the *case* statement handling the CLI options.
- Function **trace** will echo to *stderr* if verbosity is enabled.

```bash
# Handle the verbosity option. Use it in the `case` 
# statement handling the program options.
set_verbosity() {
	verbosity=1
}

# Echo all passed arguments to stderr if verbosity is on.
trace() {
	[[ $verbosity -gt 0 ]] && echo $* >&2
}
```

A complete sample can be found [here](https://github.com/prontog/blog-entries/blob/master/verbosity/script_with_simple_verbosity.sh).

There are also tools that might need multiple levels of verbosity. For an example look at the -v option of *ssh*. Here's new versions of the *set_verbosity* and *trace*, extended to support many levels of verbosity: 

```bash
# Handle the verbosity option. Use it in the `case` 
# statement handling the program options.
set_verbosity() {
	verbosity_level=$((verbosity_level + 1))
}

# Echo all passed arguments to stderr if verbosity is on. 
# If the first parameter is numeric then the message will 
# only be echoed if the verbosity level is >= to it (the 
# message level). Otherwise the message level will be 1.
trace() {
	local msg_level=$(($1 + 0))
	if [[ $msg_level -gt 0 ]]; then
		shift
	else
		msg_level=1
	fi
	
	verbosity_level=$(($verbosity_level + 0))
	
	if [[ $verbosity_level -ge $msg_level ]]; then
		echo $* >&2
	fi
}
```

A complete sample can be found [here](https://github.com/prontog/blog-entries/blob/master/verbosity/script_with_advanced_verbosity.sh).

### Usage

1. Copy the *set_verbosity* and *trace* functions to your BASH script or even better move them to your **bashrc** file.
2. Handle the -v option in the beginning of your script. A common approach is with the *getopts* BASH built-in:

    ```bash
    # Handle CLI options.
    while getopts "v" option
    do
	case $option in
		v) set_verbosity
		;;
	esac
    done
    shift $(( $OPTIND - 1 ))
    ```
3. Use *trace* in your script to print useful info:

    ```bash
    trace "This will go to stderr if -v is passed!"
    trace 2 This also if verbosity level is at least 2
    ```
    
Finally, you might want to enable verbosity of a program called inside your script. This can be done by setting an environment variable with the option that will enable verbosity on this other program. We only need to make a small addition to the *case* statement:

```bash
case $option in
	v) set_verbosity
	   curl_verbosity=-v # This is for cURL!
	;;
esac
```

Then use this env var when you call the program:
```bash
curl $curl_verbosity https://duckduckgo.com
```

You will find more details concerning transparency in [Chapter 6. Transparency](http://www.faqs.org/docs/artu/transparencychapter.html) of *The Art of Unix Programming* by Eric S. Raymond.