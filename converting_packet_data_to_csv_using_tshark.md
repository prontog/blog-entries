If you have created your own [Wireshark](https://www.wireshark.org/) dissector, you might want to further analyze your network captures. Let's say to measure performance. You could do this using Wireshark (MATE, listeners, statistics) but if you already use other tools for this kind of thing, it is easier to extract packet info to some text format and use your own toolset. In my case the most suitable text format is *CSV* since I can easily load it in *R* and use the same functions I use to analyze my application's logs.

### Why (create a tool)
[TShark](https://www.wireshark.org/docs/man-pages/tshark.html) has options (-T, -E and -e) for printing the packet fields in a delimeted text format but there is a catch. If your application batches messages then TShark will export all messages from a packet to a single line. But what you will most likely need is one message per line. 

Let's see an example using a [capture file](https://github.com/prontog/ws_dissector_helper/raw/master/examples/sop.pcapng) containing packets of the [SOP](https://github.com/prontog/ws_dissector_helper/tree/master/examples/README.md) protocol:

```bash
$ tshark -Y sop -Tfields -e frame.number -e _ws.col.Time -e sop.msgtype \
  -E separator=',' -E aggregator=';' -E header=y -r sop.pcapng
```

What this command does is print fields (-T) `frame.number`, `_ws.col.Time` and `sop.msgtype` from the `sop` packets (-Y) using comma as a field separator and semicolon as an aggregator. Here's the output:

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

As you can see there are two frames (packets) that contain multiple SOP messages. Notice that *TShark* outputs a single line with the fields that appear multiple times (in our case in different messages in a frame) delimeted by the character set with the **aggregator** option.

Furthermore notice what happens when you export a field (`sop.clientid`) that is not present in all message types of the protocol.

```bash
$ tshark -Y sop -Tfields -e frame.number -e _ws.col.Time -e sop.msgtype -e sop.clientid \
  -E separator=',' -E aggregator=';' -E header=y -r sop.pcapng
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

You can see that in the frames containing multiple messages, the number of *sop.msgtype* and the number of *sop.clientid* are not equal. For example in the third frame there are 8 msgtypes but only 6 clientids and this can also be verified by counting the semicolons (the aggregator option) and adding 1. This means that *TShark* is not adding empty (or NA) values for missing fields. In frame 17 this is more obvious since it looks like the messages with "TR" *msgtype* have a *clientid* value which is actually not true. The last three clientids are extracted from the "NO", "OC" and "RJ" messages that follow.

### How
A solution would be a BASH script that calls **TShark** and then **awk** to split the frames with multiple messages into separate lines. The script can take one or more capture files as argument and output a single line per message.

#### Design

Hence the following design:

1. Print the header. This must be done once, since the script accepts many files as arguments.
2. for each capture file:
    1. run *TShark* to output fields in *DSV* format
    2. run *awk* to split frames with multiple messages into separate lines. Filter out any messages that don't contain all the exported fields. This solves the problem of aggregated fields of unequal length. This last part is not necessary if the exported fields are common to all messages of your protocol.

#### Implementation
the problem with multiple messages per packet when no all messages include the exported fields.

### How to use it
