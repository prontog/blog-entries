[Wireshark](https://www.wireshark.org/) is an amazing tool. It is open source, works on most major platforms, has powerful capture/display filters, has a strong developer and user communities and it even has an annual [conference](http://sharkfest.wireshark.org/). At the company where I work, coworkers are using it daily to analyze packets and troubleshoot our network. Personally I don't use Wireshark daily but when I need to troubleshoot the communication between our programs it becomes a valuable tool to have.

### Why (create a tool)

As I mentioned before, Wireshark has filtering capabilities, which you can use to search for distinctive parts of your message. For example, you can use `tcp.port == 9001` to get the communication on port 9001 (source or target). This type of filtering works because a *TCP* dissector is installed with Wireshark. In the *Protocols* section of the *Preferences* dialog you will find all the available dissectors.

If you want to filter messages of a protocol with no dissector you can use the frame object. For example to look for messages containing the string "EVIL" you can use `frame contains "EVIL"`. To be exact, this filter will return all frames containing the string. Not the actual messages. If for example each frame has 10 messages, then good luck finding them. As you can imagine, this can become tiresome and sometimes, give you headaches. 

### How

A solution is to create a custom dissector your protocol and there are many ways to do so, using the *C API*, the *Lua API*, from a *CORBA IDL* file or using the *Generic Dissector*. The last two had their own format for the protocol specification something I wanted to avoid since I had the specs in **CSV** format. This left the two APIs, both very flexible and would allow me to use the CSV specs. In the end I chose the *Lua* as an excuse to try out the language.

#### Preparation

After going through an [introduction to Lua](http://www.lua.org/pil/contents.html), I searched for a function/module to read a CSV file. The standard libraries do not include such a function so I chose Geoff Leyland's [lua-csv](https://github.com/geoffleyland/lua-csv) which had all the features I needed (and more). The next part was finding and reading tutorials and examples on Lua Dissectors. Here's a list of the ones that helped me most:

- The [Lua/Dissectors](https://wiki.wireshark.org/Lua/Dissectors) from Wireshark's Wiki. Apart from an example, it includes links to pages describing the most useful objects and a section describing **TCP reassembly**.
- [Lua Scripting in Wireshark](http://sharkfest.wireshark.org/sharkfest.09/DT06_Bjorlykke_Lua%20Scripting%20in%20Wireshark.pdf) by Stig Bjorlykke. A presentation covering not only the basics but also introducing *protocol preferences*, *post-dissectors* and *listeners*.
- The [Athena dissector](http://paperlined.org/apps/wireshark/ArchivedLuaExamples/athena.lua) by FlavioJS and the Athena Dev Teams. A complete implementation of a dissector that was a great influence.

As I mentioned earlier, in the company where I work, we maintain many text protocols. Each protocol includes many message types with different format, described in CSV files with columns for name, length, type and description.

#### Design

Hence the following design:

1. For each message type, read its CSV spec and create **field objects** and a message **parser**
2. Create a **dissector** function that locates the message type, reassembles it if needed, and calls the appropriate parser. 

Before moving to the implementation, I decided that the first part could be encapsulated in a common module to be used by all dissectors.

#### Implementation

The first dissector I created was for a *fixed width* text protocol with fields of fixed size and type **STRING**.

Then I worked on another text protocol which included repeating groups. These are groups of fields that are repeated N times where N is specified from another field in the message.

For example, image a message describing a contact. The contact can have many phone numbers, each described by a name and number:

Field | Length | Type | Description
-----|---------|------|------
First name | 20 | STRING | First name of the contact
Last name | 40 | STRING | Last name of the contact
Number of phones | 2 | NUMERIC | The number of phones in the message
Phone | Number of phones | REPEATING |
PhoneName | 16 | STRING | The phone name (Home, Work, Mobile1, Mobile2 etc.)
PhoneNumber | 16 | STRING | The phone number

As we can see:

1. The 'Phone' field is of type **REPEATING**. This signifies a repeating group.
2. The *Length* of the 'Phone' field is not a number, but it references another field in the message.
3. The end of the repeating group is implicitly the last field of the message. Otherwise we need to add a "fake" field with type **REPEATING-END**. Then the group will contain all fields between the ones with type REPEATING and REPEATING-END.

The third dissector was for a protocol that containing string of variable length. I added the type **VARLEN**. Fields of this type have to reference another field that specifies their length. The same way a repeating group references the number of repeats:

Field | Length | Type | Description
-----|---------|------|------
Last name length | 2 | NUMERIC | The length of the Last Name field.
Last name | Last name length | VARLEN | Last name of the contact
First name | 20 | STRING | First name of the contact

Here we see that:

1. The 'Last name' field is of type **VARLEN**. 
2. The *Length* of the 'Last name' field is not a number, but it references another field in the message.
3. Other fields can follow a 'VARLEN' field.

Naturally, the implementation of dissectors for three protocols helped me locate more parts that could be moved to the common module named **ws_dissector_helper**. The source code is available on [Github](https://github.com/prontog/ws_dissector_helper).

> Did you know: That Wireshark can be used in the command line with the [TShark](https://www.wireshark.org/docs/man-pages/tshark.html) utility?

### Creating you own dissector

Here's an example on how to use *ws_dissector_helper* an imaginary protocol called [SOP](https://github.com/prontog/ws_dissector_helper/tree/master/examples/README.md)(Simple Order Protocol):

Create a lua script for our new dissector. Let's name it *sop.lua* since the dissector we will create will be for the SOP protocol (an imaginary protocol used in this example).

Add the following lines at the end of Wireshark's **init.lua** script:
```
WSDH_SCRIPT_PATH='path to the directory src of the repo'
SOP_SPECS_PATH='path to the directory of the CSV specs'
dofile('path to sop.lua')
```

Then in the **sop.lua** file:

Create a Proto object for your dissector. The Proto class is part of Wireshark's Lua API.
```
sop = Proto('SOP', 'Simple Order Protocol')
```

Load the ws_dissector_helper script. We will use the `wsdh` object to access various helper functions.
```
local wsdh = dofile(WSDH_SCRIPT_PATH..'ws_dissector_helper.lua')
```

Create the proto helper. Note that we pass the Proto object to the `createProtoHelper` factory function.
```
local helper = wsdh.createProtoHelper(sop)
```

Create a table with the values for the default settings. The values can be changed from the *Protocols* section of Wireshark's *Preferences* dialog.
```
local defaultSettings = {
	ports = '9001-9010',
	trace = true
}
helper:setDefaultPreference(defaultSettings)
```

Define the protocol's message types. Each message type has a *name* and *file* property. The file property is the filename of the CSV file that contains the specification of the fields for the message type. Note that the CSV files should be located in *SOP_SPECS_PATH*.
```
local msg_types = { { name = 'NO', file = 'NO.csv' }, 
				    { name = 'OC', file = 'OC.csv' },
					{ name = 'TR', file = 'TR.csv' },
					{ name = 'RJ', file = 'RJ.csv' } }
```

Define fields for the header and trailer. If your CSV files contain all the message fields then there is no need to manually create fields for the header and trailer. In our example, the CSV files contain the specification of the payload of the message.
```
local SopFields = {
	SOH = wsdh.Field.FIXED(1,'sop.header.SOH', 'SOH', '\x01','Start of Header'),
	LEN = wsdh.Field.NUMERIC(3,'sop.header.LEN', 'LEN','Length of the payload (i.e. no header/trailer)'),	
	ETX = wsdh.Field.FIXED(1, 'sop.trailer.ETX', 'ETX', '\x03','End of Message')
}
```

Then define the Header and Trailer objects. Note that these objects are actually composite fields.
```
local header = wsdh.Field.COMPOSITE{
	title = 'Header',
	SopFields.SOH,
	SopFields.LEN
}

local trailer = wsdh.Field.COMPOSITE{
	title = 'Trailer',	
	SopFields.ETX
}
```

Now let's load the specs using the `loadSpecs` function of the `helper` object. The parameters of this function are:

1. msgTypes		this is a table of message types. Each type has two properties: name and file.
1. dir			the directory were the CSV files are located
1. columns is a table with the mapping of columns:
	- name is the name of the field name column. 
	- length is the name of the field legth column. 
	- type is the name of the field type column. Optional. Defaults to STRING.
	- desc is the name of the field description column. Optional.
1. offset		the starting value for the offset column. Optional. Defaults to 0.
1. sep			the separator used in the csv file. Optional. Defaults to ','.
1. header		a composite or fixed length field to be added before the fields found in spec.
1. trailer		a composite or fixed length field to be added after the fields found in spec.

The function returns two tables. One containing the message specs and another containing parsers for the message specs. Each message spec has an id, a description and all the fields created from the CSV in a similar fashion to the one we used previously to create `SopFields`. Each message parser is specialized for a specific message type and they include the boilerplate code needed to handle the parsing of a message.

```
-- Column mapping. As described above.
local columns = { name = 'Field', 
				  length = 'Length', 
				  type = 'Type',
				  desc = 'Description' }

local msg_specs, msg_parsers = helper:loadSpecs(msg_types,
											    SOP_SPECS_PATH,
											    columns,
											    header:len(),
											    ',',
											    header,
											    trailer)
```

Now let's create a few helper functions that will simplify the main parse function.

```
-- Returns the length of the message from the end of header up to the start 
-- of trailer.
local function getMsgDataLen(msgBuffer)
	return helper:getHeaderValue(msgBuffer, SopFields.LEN)
end

-- Returns the length of whole the message. Includes header and trailer.
local function getMsgLen(msgBuffer)
	return header:len() + 
		   getMsgDataLen(msgBuffer) + 
		   trailer:len()
end
```

One of the last steps and definatelly the most complicated is to create the function that validates a message, parses the message using one of the automatically generated message parsers and finally populates the tree in the *Packet Details* pane.
```
local function parseMessage(buffer, pinfo, tree)
	-- The minimum buffer length in that can be used to identify a message
	-- must include the header and the MessageType.
	local msgTypeLen = 2
	local minBufferLen = header:len() + msgTypeLen
	-- Messages start with SOH.

	if SopFields.SOH:value(buffer) ~= SopFields.SOH.fixedValue then
		helper:trace('Frame: ' .. pinfo.number .. ' No SOH.')
		return 0
	end	

	-- Return missing message length in the case when the header is split 
	-- between packets.	
	if buffer:len() <= minBufferLen then
		return -DESEGMENT_ONE_MORE_SEGMENT
	end

	-- Look for valid message types.
	local msgType = buffer(header:len(), msgTypeLen):string()
	local msgSpec = msg_specs[msgType]
	if not msgSpec then
		helper:trace('Frame: ' .. pinfo.number .. 
					 ' Unknown message type: ' .. msgType)
		return 0
	end

	-- Return missing message length in the case when the data is split 
	-- between packets.
	local msgLen = getMsgLen(buffer)
	local msgDataLen = getMsgDataLen(buffer)
	if buffer:len() < msgLen then
		helper:trace('Frame: ' .. pinfo.number .. ' buffer:len < msgLen')
		return -DESEGMENT_ONE_MORE_SEGMENT
	end

	local msgParse = msg_parsers[msgType]
	-- If no parser is found for this type of message, reject the whole 
	-- packet.
	if not msgParse then
		helper:trace('Frame: ' .. pinfo.number .. 
					 ' Not supported message type: ' .. msgType)
		return 0
	end
	
	local bytesConsumed, subtree = msgParse(buffer, pinfo, tree, 0)
	subtree:append_text(', Type: ' .. msgType)	
	subtree:append_text(', Len: ' .. msgLen)

	pinfo.cols.protocol = sop.name	
	return bytesConsumed
end
```

Now that the parse function for the SOP protocol is ready, we need to create the dissector function using the `getDissector` helper function which returns a dissector function containing the basic while loop that pretty much all dissectors need to have. 
```
sop.dissector = helper:getDissector(parseMessage)
```

Finally enable the dissector. `enableDissector` registers the ports to the TCP dissector table. 
```
helper:enableDissector()
```

### Testing your dissector

What I usually do to test my dissector is to create a text file with many messages and do the following:

1. Start a server with `nc -l 9001`
2. Start *tshark* with a display filter with the protocol name: `tshark -Y 'sop'`. Note that sometimes this approach might hide some Lua errors. Then you can repeat the test using `Wireshark` instead of `tshark`.
3. Connect with a client and send one or more messages from a file: `cat messages.txt | nc SERVER_IP 9001`
4. If lines appear in the filtered *tshark* output then the test was successful.

If you finish testing, you can save the captured frame to a file for future tests.

### Installing your dissector

Add the following lines at the end of Wireshark's `init.lua` script:

```
WSDH_SCRIPT_PATH='path to the directory src of the repo'
SOP_SPECS_PATH='path to the directory of the CSV specs'
dofile('path to your dissector file')
```
