Sometimes you will need to know what your tool is currently doing. This is often described as [transparency] (http://www.faqs.org/docs/artu/ch01s06.html#id2878054). 

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

- A function that sets the environment variable for verbosity. This should be called in the `case` statement that handles the CLI options.
- A function that returns true if verbosity is enabled.

### Usage



You will find more details concerning transparency in [Chapter 6. Tranparency](http://www.faqs.org/docs/artu/transparencychapter.html) of the *The Art of Unix Programming* by Eric S. Raymond.