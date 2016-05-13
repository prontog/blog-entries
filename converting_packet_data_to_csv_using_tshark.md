Now that you have created your own dissector, you might want to further analyze your network captures. Let's say to measure performance. If you use your own protocol you will need to build a tool.

### Why (create a tool)
You can do it using Wireshark (MATE, listeners, statistics) but if you already have other tools for this it is easier to extract packet info to some other format and use your tools. Let's say CSV? Tshark can do this but there is a catch. If your application batches messages then TShark will export all messages from a packet to a single line. But what you will need is one message per line.

### How
Bash script that calls tshark and awk to convert to CSV.

#### Design
need to handle multiple files
neet to handle packets with mulitple messages

#### Implementation
the problem with multiple messages per packet when no all messages include the exported fields.

### How to use it
