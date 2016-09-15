Sometimes you will need to know what your tool is currently doing. This is often described as [transparency](http://www.faqs.org/docs/artu/ch01s06.html#id2878054). 

### Why

Most likely this will be for troubleshooting purposes.

### How

The usual way to add verbosity to a CLI tool is by adding an option (such as -v or --verbose) that enables it. Most tools follow the [rule of silence](http://www.faqs.org/docs/artu/ch01s06.html#id2878450) and have it disabled by default.

On the other hand tools with a GUI can either append to a log file or open a new window with a text area that is appended.

#### Design

Hence the following design:

1. The option -v that enables verbosity. By default, verbosity is off.
1. When this option is used, an environment variable will be set.
1. If this environment variable is present, the tool will echo details to *stderr*. Echoing to *stderr* is necessary for programs that are usually part of a pipeline.

#### Implementation

A bash implementation can include the following:

- Function **set_verbosity** that sets the environment variable for verbosity. This should be called in the `case` statement that handles the CLI options.
- Function **trace** that echoes to *stderr* if verbosity is enabled.

```bash
# Function that handles the verbosity option.
set_verbosity() {
	verbosity=1
}

# Function that echoes all passed arguments to stderr if 
# verbosity is on.
trace() {
	[[ $verbosity -gt 0 ]] && echo $* >&2
}
```

A complete sample can be found [here](https://github.com/prontog/blog-entries/blob/master/verbosity/script_with_simple_verbosity.sh).

There are also tools that might need multiple levels of verbosity. For an example look at the -v option of ssh.

```bash
# Function that handles the verbosity option.
set_verbosity() {
	verbosity_level=$((verbosity_level + 1))
}

# Function that echoes all passed arguments to stderr if 
# verbosity is on. If the first parameter is numeric then 
# the message will only be echoed if the verbosity level 
# is >= to it (the first param).
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

1. Copy the *set_verbosity* and *trace* function to your BASH script or even better move them to your **bashrc** file.
2. Handle the -v in the beginning of your script. One way to do this is:
```bash
# Handle CLI options.
while getopts "hv" option
do
	case $option in
		v) set_verbosity
		;;
	esac
done
shift $(( $OPTIND - 1 ))
```
3. Start using the *trace* function:
```bash
trace This will go to stderr if -v is passed!
```

You will find more details concerning transparency in [Chapter 6. Tranparency](http://www.faqs.org/docs/artu/transparencychapter.html) of the *The Art of Unix Programming* by Eric S. Raymond.