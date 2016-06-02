If you have created your own [Wireshark](https://www.wireshark.org/) dissector, you might want to further analyze your network captures. Let's say to measure performance and although you could do this using Wireshark (MATE, listeners, statistics) it can be complicated and not flexible compared to a statistics-friendly environment (R, Octave, PSPP, iPython etc.). Furthermore if you use another tool to analyze your application's log files, it's easier to extract packet info to a text format and use your own toolset. In my case the most suitable text format is *CSV* since I can easily load it in *R* and use the same functions I use to analyze my application's logs.

### Why (create a tool)
[TShark](https://www.wireshark.org/docs/man-pages/tshark.html) has options (-T, -E and -e) for printing the packet fields in a delimited text format but there's a catch. If your application batches messages then TShark will export all messages from a packet to a single line. But what you will most likely need is one message per line. 

Let's see an example using a [capture file](https://github.com/prontog/ws_dissector_helper/raw/master/examples/sop.pcapng) containing packets of the [SOP](https://github.com/prontog/ws_dissector_helper/tree/master/examples/README.md) protocol:

```bash
tshark -Y sop -Tfields -e frame.number -e _ws.col.Time \
  -e sop.msgtype -E separator=',' -E aggregator=';'    \
  -E header=y -r sop.pcapng
```

This command prints fields (-T) `frame.number`, `_ws.col.Time` and `sop.msgtype` from the `sop` packets (-Y) using comma as a field separator and semicolon as an aggregator. Here's the output:

| frame.number  | \_ws.col.Time   | sop.msgtype                             |
|---------------|-----------------|-----------------------------------------|
|  1            | 14:15:15.603164 | BO                                      |
|  3            | 14:15:16.608027 | NO;OC;NO;RJ;NO;OC;TR;TR                 |
|  5            | 14:15:17.612279 | EN                                      |
|  7            | 14:15:18.617432 | NO                                      |
|  9            | 14:15:19.622369 | OC                                      |
|  11           | 14:15:20.627967 | RJ                                      |
|  13           | 14:15:21.632463 | TR                                      |
|  15           | 14:15:30.903667 | BO                                      |
|  17           | 14:15:31.103467 | NO;OC;NO;RJ;NO;OC;TR;TR;EN;NO;OC;RJ;TR  |

As you can see, there are two frames (packets) containing multiple SOP messages. Notice that *TShark* outputs a single line with the fields that appear multiple times (in our case in different messages in a frame) delimited by the character set with the **aggregator** option.

Furthermore, watch what happens when you export a field (`sop.clientid`) not present in every message type of the protocol.

```bash
tshark -Y sop -Tfields -e frame.number -e _ws.col.Time \
  -e sop.msgtype -e sop.clientid -E separator=','      \
  -E aggregator=';' -E header=y -r sop.pcapng
```

Here's the output with the aggregated fields `sop.msgtype` and `sop.clientid` slightly modified so that each field is in a single line:

|  frame.number | \_ws.col.Time    | sop.msgtype                            | sop.clientid                                                                                                                                              |
|---------------|-----------------|----------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------|
|  1            | 14:15:15.603164 | BO                                     |                                                                                                                                                           |
|  3            | 14:15:16.608027 | NO;<br>OC;<br>NO;<br>RJ;<br>NO;<br>OC;<br>TR;<br>TR                | SomeClientId;<br>SomeClientId;<br>AnotherClientId;<br>AnotherClientId;<br>AnotherClientId;<br>AnotherClientId                                                      |
|  5            | 14:15:17.612279 | EN                                     |                                                                                                                                                           |
|  7            | 14:15:18.617432 | NO                                     | SomeClientId                                                                                                                                              |
|  9            | 14:15:19.622369 | OC                                     | SomeClientId                                                                                                                                              |
|  11           | 14:15:20.627967 | RJ                                     | AnotherClientId                                                                                                                                           |
|  13           | 14:15:21.632463 | TR                                     |                                                                                                                                                           |
|  15           | 14:15:30.903667 | BO                                     |                                                                                                                                                           |
|  17           | 14:15:31.103467 | NO;<br>OC;<br>NO;<br>RJ;<br>NO;<br>OC;<br>TR;<br>TR;<br>EN;<br>NO;<br>OC;<br>RJ;<br>TR | SomeClientId;<br>SomeClientId;<br>AnotherClientId;<br>AnotherClientId;<br>AnotherClientId;<br>AnotherClientId;<br>SomeClientId;<br>SomeClientId;<br>AnotherClientId   |

You can see that in the frames containing multiple messages, the number of *sop.msgtype* and the number of *sop.clientid* are not equal. For example, in the third frame there are 8 msgtypes but only 6 clientids which can be verified by counting the semicolons (the aggregator option) and adding 1. This means that *TShark* is not adding empty (or NA) values for missing fields. In frame 17 it's more obvious since it looks like the messages with "TR" *msgtype* have a *clientid* value which is not true. The last three clientids are extracted from the "NO", "OC" and "RJ" messages that follow.

### How
A solution is a BASH script calling **TShark** and then **awk** to split the frames with multiple messages into separate lines. The script can take one or more capture files as argument and output a single line per message.

#### Design

Hence the following design:

1. Print the header. This must be done once since the script accepts many files as arguments.
2. for each capture file:
    1. run *TShark* to output fields in *CSV* format
    2. run *awk* to split frames with multiple messages into separate lines. Filter out any messages that don't contain every exported field. This solves the problem of aggregated fields of unequal length. Of course, this last part is not necessary if the exported fields are common to every message of your protocol.

#### Implementation

Part 1 is a simple echo.

```bash
echo frame,dateTime,msgType,clientId
```

Part 2.1 is also straight forward. Note that if an argument is not a file, a warning is echoed in *stderr* (line 4). This way *stdout* is not polluted by warnings and only an error will stop the script (line 9).

```bash
until [[ -z $1 ]]
do
	if [[ ! -f $1 ]]; then
		echo $1 is not a file > /dev/stderr
	fi
	
	CAP_FILE=$1

	set -o errexit
	
	tshark -Y sop -Tfields -e frame.number -e _ws.col.Time \
        -e sop.msgtype -e sop.clientid -E separator=','    \
        -E aggregator=';' -E header=y -r $CAP_FILE | awk '
        # Part 2.2. See below for a detailed description.'
	
    shift
done
```

Now let's focus on the *AWK* script of part 2.2. This is also straightforward if the exported fields are present in every message of your protocol:

```bash
BEGIN {
    # Input and output should be CSV.
	FS = ","
	OFS = ","
}

{
	frame = $1
	dateTime = $2
	# Message types are split into an array using the
	# aggregator delimeter from part 2.1.
	split($3, msgTypes, ";")
	
	# Print a separate line for each message type in 
	# the packet (frame).
	for(i in msgTypes) {
		print frame, dateTime, msgTypes[i]
	}
}
```

Nothing special here, the *msgType* column is split using the aggregator delimiter of *TShark* and for each *msgType* a separate line is printed. Note that for this simple case the 4th column from part 2.1 is ignored.

Let's move to the more complicated case where the exported fields are **not** present in every message:

```bash
BEGIN { 
	FS = ","
	OFS = ","
	# These are the msg types that contain the clientId
	# field. All other message types will be discarded.
	msgTypesToPrint = "NO,OC,RJ"
}

{
	frame = $1
	dateTime = $2
	# Message types and clientIds are split into arrays.
	split($3, msgTypes, ";")
	split($4, clientIds, ";")
	
	# Copy the messages types that are included in 
	# msgTypesToPrint to array filteredMsgTypes.
	fi = 0
	for(i in msgTypes) {
		if (match(msgTypesToPrint, msgTypes[i])) {
			fi++
			filteredMsgTypes[fi] = msgTypes[i]			
		}
	}
	
	# Skip line if there was no messages to print.
	if (fi == 0) {
		next
	}
	
	# filteredMsgTypes should have the same length 
	# with clientIds.
	if (length(filteredMsgTypes) != length(clientIds)) {
		printf("Skipping frame %d because of missing fields (%d, %d).", 
				frame, 
				length(filteredMsgTypes), 
				length(clientIds)) > "/dev/stderr"
		next
	}
	
	for(i in filteredMsgTypes) {
		print frame, dateTime, 
		      filteredMsgTypes[i], clientIds[i]
	}
	
	# Clean up array filteredMsgTypes before moving to 
	# the next line.
	delete filteredMsgTypes
}
```

As you can see string `msgTypesToPrint` (line 6) includes the names of the message types containing every exported field. The rest of the messages will be filtered out (lines 18-24) and new array `filteredMsgTypes` will contain the messages to output. If the remaining message types are not equal to the number of *clientIds* (not present in every message), then skip the frame entirely and print a warning in *stderr* (lines 33-39). Finally, array `filteredMsgTypes` is deleted before moving to the next line. This is necessary since it's a global variable.

That's about it. You can examine the whole script *cap2sop.sh*  [here](https://github.com/prontog/ws_dissector_helper/blob/master/examples/cap2sop.sh).

### Usage

To extract SOP capture data from a single file:

```bash
./cap2sop.sh sop.pcapng
```

Here's the final output.

|  frame | dateTime        | msgType | clientId         |
|--------|-----------------|---------|------------------|
|  3     | 14:15:16.608027 | NO      | SomeClientId     |
|  3     | 14:15:16.608027 | OC      | SomeClientId     |
|  3     | 14:15:16.608027 | NO      | AnotherClientId  |
|  3     | 14:15:16.608027 | RJ      | AnotherClientId  |
|  3     | 14:15:16.608027 | NO      | AnotherClientId  |
|  3     | 14:15:16.608027 | OC      | AnotherClientId  |
|  7     | 14:15:18.617432 | NO      | SomeClientId     |
|  9     | 14:15:19.622369 | OC      | SomeClientId     |
|  11    | 14:15:20.627967 | RJ      | AnotherClientId  |
|  17    | 14:15:31.103467 | NO      | SomeClientId     |
|  17    | 14:15:31.103467 | OC      | SomeClientId     |
|  17    | 14:15:31.103467 | NO      | AnotherClientId  |
|  17    | 14:15:31.103467 | RJ      | AnotherClientId  |
|  17    | 14:15:31.103467 | NO      | AnotherClientId  |
|  17    | 14:15:31.103467 | OC      | AnotherClientId  |
|  17    | 14:15:31.103467 | NO      | SomeClientId     |
|  17    | 14:15:31.103467 | OC      | SomeClientId     |
|  17    | 14:15:31.103467 | RJ      | AnotherClientId  |

To extract SOP capture data from multiple files:

```bash
./cap2sop.sh *.pcapng
```
