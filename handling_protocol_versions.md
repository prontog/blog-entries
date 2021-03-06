When you work on tools that are protocol-aware, at some point or another, you will have to make them handle different versions of the same protocol.

### Why (create a tool)

﻿Let's say I have a tool that can decode messages of SOP v.1 and am about to release SOP v.2. Most likely my tool will not decode the new messages. A simple way to handle it, is by updating the tool to be v.2 compatible. But what if you still want to process v.1 messages? And what if you want to analyze your old log files?

### How (to deal with this problem)

You can either:

a. keep two different versions of the tool, or
b. make the tool version-aware.

The former (a) is simple but can become a headache after releasing a few versions. For example, fixing a bug in all versions of the tool. Another example is when you add a new feature to the latest version of your tool. What will happen to the older versions? Will you add the feature and re-process your log files?

The latter (b) is more complicated but might lead to the [separation of policy from mechanism](http://www.faqs.org/docs/artu/ch01s06.html#id2877777) and in the long-run, is easier to test and maintain. Personally, I apply this separation by using [CSV files for the protocol specifications](https://prontog.wordpress.com/2016/02/02/using-pandoc-and-make-to-extract-specs-from-a-word-document/) and by creating tools that are ignorant of the protocol since it resides in the *CSV* files and not in the tools. As an example, have a look at how you can use [*CSV* files in a Wireshark Dissector](https://prontog.wordpress.com/2016/01/29/a-simpler-way-to-create-wireshark-dissectors-in-lua/).

#### Design

No matter which approach you choose, you can still handle multiple protocol versions by:

1. **isolating** each version (protocol specs and/or scripts) in a directory
2. updating your tool, to use an **environment variable** pointing to one of these directories
3. setting the *environment variable* depending on the protocol version you want to work with

#### Implementation

For an example implementation, let's look at [init.lua](https://github.com/prontog/SOP/blob/master/network/init.lua) and [sop.lua](https://github.com/prontog/SOP/blob/master/network/sop.lua), the *Wireshark Dissector* for the [SOP](https://github.com/prontog/SOP) protocol.

As you can see in the method call to `loadSpecs`, the second parameter, **SOP_SPECS_PATH**, is declared in *init.lua* and set with the value of the environment variable with the same name.
```js
-- From init.lua
SOP_SPECS_PATH = os.getenv("SOP_SPECS_PATH")
-- From sop.lua
local msg_specs, msg_parsers = helper:loadSpecs(msg_types, SOP_SPECS_PATH,
												columns, header:len(),
												',', header, trailer)
```

Then we can set *SOP_SPECS_PATH* to the directory with the specs of a specific version of *SOP*.
```bash
$ SOP_SPECS_PATH=/path/to/version tshark -Y sop -r file_containing_sop_msgs.cap
```

### Usage

The source code is on [Github](https://github.com/prontog/SOP). The easiest way to test it is using [Vagrant](https://github.com/prontog/SOP#trying-it-out). After starting up the Vagrant box and connecting to it (ssh):

```bash
# Trying out an older capture file with the latest SOP version:
tshark -Y sop -r /vagrant/logs/sop_2016-01-21.pcapng | wc -l
# output: 8
# Then with the correct SOP version:
SOP_SPECS_PATH=$SOP_SPECS_PATH/1.0 tshark -Y sop -r /vagrant/logs/sop_2016-01-21.pcapng | wc -l
# output: 9

# To test a new capture file that supports the latest SOP version:
tshark -Y sop -r /vagrant/logs/sop_2017-07-17.pcapng | wc -l
# output: 9
# Then with the older SOP version:
SOP_SPECS_PATH=$SOP_SPECS_PATH/1.0 tshark -Y sop -r /vagrant/logs/sop_2017-07-17.pcapng | wc -l
# output: 8
```

#### Taking it one step further

We can take it one step further and automate the setup of this environment variable when a date is found in the filename. The script can then find the active version at this date and update SOP_SPECS_PATH.

So, with *SOP* protocol, we can:

1. add [versions.csv](https://github.com/prontog/SOP/blob/master/specs/versions.csv) with all *SOP* versions:

	|  version | release_date | info                                    |
	|----------|--------------|-----------------------------------------|
	|  1.0     | 2016-01-01   | First release of SOP.                   |
	|  2.0     | 2017-07-01   | Second release with larger RJ.text!!!!  |

2. create script [sop_specs_path.sh](https://github.com/prontog/SOP/blob/master/specs/sop_specs_path.sh), that given a filename containing a date (YYYY-MM-DD/YYYY_MM_DD), it looks in *versions.csv* for the *SOP* version released before that date.
3. update [cap2sop.sh](https://github.com/prontog/SOP/blob/master/network/cap2sop.sh), to use *sop_specs_path.sh* before calling *tshark*.

Then we can even call *cap2sop.sh* with capture files of different *SOP* versions.

```bash
cap2sop.sh /vagrant/logs/sop_20*.pcapng
```

Here's the output. Notice that all *RJ* messages are decoded although *sop_2016-01-21.pcapng* has messages of SOP v.**1** and *sop_2017-07-17.pcapng* has messages of v.**2**.

|  frame | dateTime        | msgType | clientId         | ethSrc            | ethDst            | ipSrc          | ipDst        | capFile                |
|--------|-----------------|---------|------------------|-------------------|-------------------|----------------|--------------|------------------------|
|  3     | 14:15:16.608027 | NO      | SomeClientId     | 00:0c:29:c8:76:1d | 00:50:56:c0:00:00 | 192.168.58.128 | 192.168.58.1 | sop_2016-01-21.pcapng  |
|  3     | 14:15:16.608027 | OC      | SomeClientId     | 00:0c:29:c8:76:1d | 00:50:56:c0:00:00 | 192.168.58.128 | 192.168.58.1 | sop_2016-01-21.pcapng  |
|  3     | 14:15:16.608027 | NO      | AnotherClientId  | 00:0c:29:c8:76:1d | 00:50:56:c0:00:00 | 192.168.58.128 | 192.168.58.1 | sop_2016-01-21.pcapng  |
|  3     | 14:15:16.608027 | **RJ**      | AnotherClientId  | 00:0c:29:c8:76:1d | 00:50:56:c0:00:00 | 192.168.58.128 | 192.168.58.1 | **sop_2016-01-21.pcapng**  |
|  3     | 14:15:16.608027 | NO      | AnotherClientId  | 00:0c:29:c8:76:1d | 00:50:56:c0:00:00 | 192.168.58.128 | 192.168.58.1 | sop_2016-01-21.pcapng  |
|  3     | 14:15:16.608027 | OC      | AnotherClientId  | 00:0c:29:c8:76:1d | 00:50:56:c0:00:00 | 192.168.58.128 | 192.168.58.1 | sop_2016-01-21.pcapng  |
|  7     | 14:15:18.617432 | NO      | SomeClientId     | 00:0c:29:c8:76:1d | 00:50:56:c0:00:00 | 192.168.58.128 | 192.168.58.1 | sop_2016-01-21.pcapng  |
|  9     | 14:15:19.622369 | OC      | SomeClientId     | 00:0c:29:c8:76:1d | 00:50:56:c0:00:00 | 192.168.58.128 | 192.168.58.1 | sop_2016-01-21.pcapng  |
|  11    | 14:15:20.627967 | **RJ**      | AnotherClientId  | 00:0c:29:c8:76:1d | 00:50:56:c0:00:00 | 192.168.58.128 | 192.168.58.1 | **sop_2016-01-21.pcapng**  |
|  17    | 14:15:31.103467 | NO      | SomeClientId     | 00:0c:29:c8:76:1d | 00:50:56:c0:00:00 | 192.168.58.128 | 192.168.58.1 | sop_2016-01-21.pcapng  |
|  17    | 14:15:31.103467 | OC      | SomeClientId     | 00:0c:29:c8:76:1d | 00:50:56:c0:00:00 | 192.168.58.128 | 192.168.58.1 | sop_2016-01-21.pcapng  |
|  17    | 14:15:31.103467 | NO      | AnotherClientId  | 00:0c:29:c8:76:1d | 00:50:56:c0:00:00 | 192.168.58.128 | 192.168.58.1 | sop_2016-01-21.pcapng  |
|  17    | 14:15:31.103467 | **RJ**      | AnotherClientId  | 00:0c:29:c8:76:1d | 00:50:56:c0:00:00 | 192.168.58.128 | 192.168.58.1 | **sop_2016-01-21.pcapng**  |
|  17    | 14:15:31.103467 | NO      | AnotherClientId  | 00:0c:29:c8:76:1d | 00:50:56:c0:00:00 | 192.168.58.128 | 192.168.58.1 | sop_2016-01-21.pcapng  |
|  17    | 14:15:31.103467 | OC      | AnotherClientId  | 00:0c:29:c8:76:1d | 00:50:56:c0:00:00 | 192.168.58.128 | 192.168.58.1 | sop_2016-01-21.pcapng  |
|  17    | 14:15:31.103467 | NO      | SomeClientId     | 00:0c:29:c8:76:1d | 00:50:56:c0:00:00 | 192.168.58.128 | 192.168.58.1 | sop_2016-01-21.pcapng  |
|  17    | 14:15:31.103467 | OC      | SomeClientId     | 00:0c:29:c8:76:1d | 00:50:56:c0:00:00 | 192.168.58.128 | 192.168.58.1 | sop_2016-01-21.pcapng  |
|  17    | 14:15:31.103467 | **RJ**      | AnotherClientId  | 00:0c:29:c8:76:1d | 00:50:56:c0:00:00 | 192.168.58.128 | 192.168.58.1 | **sop_2016-01-21.pcapng**  |
|  3     | 09:17:09.240402 | NO      | SomeClientId     | 08:00:27:6f:12:9e | 0a:00:27:00:00:0e | 192.168.56.11  | 192.168.56.1 | sop_2017-07-17.pcapng  |
|  4     | 09:17:10.246698 | OC      | SomeClientId     | 08:00:27:6f:12:9e | 0a:00:27:00:00:0e | 192.168.56.11  | 192.168.56.1 | sop_2017-07-17.pcapng  |
|  5     | 09:17:11.248273 | NO      | AnotherClientId  | 08:00:27:6f:12:9e | 0a:00:27:00:00:0e | 192.168.56.11  | 192.168.56.1 | sop_2017-07-17.pcapng  |
|  6     | 09:17:12.249938 | **RJ**      | AnotherClientId  | 08:00:27:6f:12:9e | 0a:00:27:00:00:0e | 192.168.56.11  | 192.168.56.1 | **sop_2017-07-17.pcapng**  |
|  7     | 09:17:13.252035 | NO      | AnotherClientId  | 08:00:27:6f:12:9e | 0a:00:27:00:00:0e | 192.168.56.11  | 192.168.56.1 | sop_2017-07-17.pcapng  |
|  8     | 09:17:14.254140 | OC      | AnotherClientId  | 08:00:27:6f:12:9e | 0a:00:27:00:00:0e | 192.168.56.11  | 192.168.56.1 | sop_2017-07-17.pcapng  |
|  11    | 09:17:17.260084 | NO      | SomeClientId     | 08:00:27:6f:12:9e | 0a:00:27:00:00:0e | 192.168.56.11  | 192.168.56.1 | sop_2017-07-17.pcapng  |
|  11    | 09:17:17.260084 | OC      | SomeClientId     | 08:00:27:6f:12:9e | 0a:00:27:00:00:0e | 192.168.56.11  | 192.168.56.1 | sop_2017-07-17.pcapng  |
|  11    | 09:17:17.260084 | NO      | AnotherClientId  | 08:00:27:6f:12:9e | 0a:00:27:00:00:0e | 192.168.56.11  | 192.168.56.1 | sop_2017-07-17.pcapng  |
|  11    | 09:17:17.260084 | **RJ**      | AnotherClientId  | 08:00:27:6f:12:9e | 0a:00:27:00:00:0e | 192.168.56.11  | 192.168.56.1 | **sop_2017-07-17.pcapng**  |
|  11    | 09:17:17.260084 | NO      | AnotherClientId  | 08:00:27:6f:12:9e | 0a:00:27:00:00:0e | 192.168.56.11  | 192.168.56.1 | sop_2017-07-17.pcapng  |
|  11    | 09:17:17.260084 | OC      | AnotherClientId  | 08:00:27:6f:12:9e | 0a:00:27:00:00:0e | 192.168.56.11  | 192.168.56.1 | sop_2017-07-17.pcapng  |
