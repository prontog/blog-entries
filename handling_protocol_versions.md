When you work on tools that are protocol-aware, at some point or another, you will have to make them handle different versions of the same protocol.

### Why (create a tool)

Let's say I have a tool that can decode messages of SOP v.1 and am about to release SOP v.2. Most likely my tool will not be able to decode the new messages. The simplest way to deal with this, is to update the tool to work with v.2. But what if you still want to process v.1 messages?

### How

You can either make the tool version-aware or keep two different versions of the tool. The latter is simple but can become a headache after releasing a few versions. For example, fixing a bug in all versions of the tool. The former (version-aware) is more complicated but might lead to the [separation of policy from mechanism](http://www.faqs.org/docs/artu/ch01s06.html#id2877777) and in the end-run, is easier to test and maintain. Personally I apply this separation by using [CSV files for the protocol specifications](https://prontog.wordpress.com/2016/02/02/using-pandoc-and-make-to-extract-specs-from-a-word-document/) and by creating tools that are mostly ignorant of the protocol since this resides in the *CSV* files and not in the tools. The tool only deals with the mechanism. This is the approach I use in all my [Wireshark Dissectors](https://prontog.wordpress.com/2016/01/29/a-simpler-way-to-create-wireshark-dissectors-in-lua/).

#### Design

No matter which approach you choose, you can still handle multiple protocol versions by:

1. **isolating** each version (protocol specs and/or scripts) in a directory and
2. in your tool, use an **environment variable** pointing to one of these directories
3. finally set the env var depending on the protocol version you want to work with

#### Implementation


> Did you know: MENTION SOMETHING COOL I FOUND WHILE WORKING ON THE TOOL

### Usage

The source code  can be found on [Github](https://github.com/prontog/UPDATE THIS PART).

Here's an example on how to use **TOOL NAME HERE**:

```
EXAMPLE GOES HERE
```
