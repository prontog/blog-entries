In an earlier post, I described a way to [load a file with lines of fixed-width format](https://prontog.wordpress.com/2016/01/27/reading-a-file-with-lines-of-different-fixed-width-formats/) into *R*. Using *RStudio* (and the `View` function), it is easy to view the data. On the other hand, it is not easy to edit the file when it has lines of different format. My `multifwf` package has a `read.multi.fwf` function but not a `write.multi.fwf` to write changes back to the file. On top of that, it is not easy for someone unfamiliar with *R* to filter/subset the loaded data.

### Why

Reading a fixed-width log file can be very frustrating especially while you are troubleshooting. For example, look at three lines from a [SOP](https://github.com/prontog/SOP/blob/master/logs/sopsrv_2016_12_06.log) log file: 

```
09:20:05.034 < NOSLMT0000666    EVILCORP00010.77SomeClientId    SomeAccountId   
09:20:05.099 > OC000001BLMT0000666    EVILCORP00010.77SomeClientId    SomeAccountId   
09:20:13.421 < NOBLMT0000666 EVILCORP00001.10AnotherClientId AnotherAccountId
```

Confusing, right? And these lines are of a very simple protocol. At the place where I work, we have much longer messages (even longer than 300 characters).  Imagine having to find a certain field in a 350 character message. And under pressure this can be hard even for experienced employees. It would definitely help to be able to view the message fields in a clear way. To be able to quickly and safely locate any field in a given line even if you are new to the message protocol. To be able to do queries and filter out any lines not needed.

Apart from reading a fixed-width log file, sometimes you might need to edit one. For example, you might want to replay a log file but only after changing some values.

### How

A solution is to use [Record Editor](http://record-editor.sourceforge.net/) or its little brother [reCsvEditor](http://recsveditor.sourceforge.net/). Both of these editors can be used to view/edit fixed-width data files as long as they know how the data is laid out. This data layout can be in many formats called **Copybooks**. After some experimentation I decided to use the *XML Copybook* since it allows for multiple data layouts in a single file. This way a single *XML* file can hold the specs for all the message types of the protocol. Another reason behind this choice is that the *XML* examples of *Record Editor* were the most intuitive.

Having decided on the layout format, I only had to create one for each of the four protocols I work with. Of course, this is tedious and error prone and since I already have the [message specs in CSV format](https://prontog.wordpress.com/2016/02/02/using-pandoc-and-make-to-extract-specs-from-a-word-document/)), I decided to create a tool that converts *CSV* specs to the *XML Copybook* format.

Here's a simplified version of the **"ams PO Download.Xml"** example that comes with *Record Editor*:

```xml
<?xml version="1.0" ?>
<RECORD RECORDNAME="ams PO Download" COPYBOOK="" DELIMITER="&lt;Tab&gt;" FILESTRUCTURE="Default" STYLE="0"
        RECORDTYPE="GroupOfRecords" LIST="Y" QUOTE="" RecSep="default">
    <RECORDS>
        <RECORD RECORDNAME="ams PO Download: Detail" COPYBOOK="" DELIMITER="&lt;Tab&gt;"
                DESCRIPTION="PO Download: Detail" FILESTRUCTURE="Default" STYLE="0" RECORDTYPE="RecordLayout"
            LIST="N" QUOTE="" RecSep="default" TESTFIELD="Record Type" TESTVALUE="D1">
            <FIELDS>
                <FIELD NAME="Record Type"  POSITION="1" LENGTH="2" TYPE="Char"/>
                <FIELD NAME="Pack Qty"     POSITION="3" LENGTH="9" DECIMAL="4" TYPE="Num Assumed Decimal (Zero padded)"/>
                <FIELD NAME="Pack Cost"    POSITION="12" LENGTH="13" DECIMAL="4" TYPE="Num Assumed Decimal (Zero padded)"/>
                <FIELD NAME="APN"          POSITION="25" LENGTH="13" TYPE="Num (Right Justified zero padded)"/>
                <FIELD NAME="Filler"       POSITION="38" LENGTH="1" TYPE="Char"/>
                <FIELD NAME="Product"      POSITION="39" LENGTH="8" TYPE="Num (Right Justified zero padded)"/>
                <FIELD NAME="pmg dtl tech key" POSITION="72" LENGTH="15" TYPE="Char"/>
                <FIELD NAME="Case Pack id" POSITION="87" LENGTH="15" TYPE="Char"/>
                <FIELD NAME="Product Name" POSITION="101" LENGTH="50" TYPE="Char"/>
            </FIELDS>
        </RECORD>
        <RECORD RECORDNAME="ams PO Download: Header" COPYBOOK="" DELIMITER="&lt;Tab&gt;"
                DESCRIPTION="PO Download: Header" FILESTRUCTURE="Default" STYLE="0" RECORDTYPE="RecordLayout" LIST="N"
            QUOTE="" RecSep="default" TESTFIELD="Record Type" TESTVALUE="H1">
            <FIELDS>
                <FIELD NAME="Record Type"     POSITION="1" LENGTH="2" TYPE="Char"/>
                <FIELD NAME="Sequence Number" POSITION="3" LENGTH="5" DECIMAL="3" TYPE="Num Assumed Decimal (Zero padded)"/>
                <FIELD NAME="Vendor"          POSITION="8" LENGTH="10" TYPE="Num (Right Justified zero padded)"/>
                <FIELD NAME="PO"              POSITION="18" LENGTH="12" TYPE="Num Assumed Decimal (Zero padded)"/>
                <FIELD NAME="Entry Date" DESCRIPTION="Format YYMMDD" POSITION="30" LENGTH="6" TYPE="Char"/>
                <FIELD NAME="Filler"          POSITION="36" LENGTH="8" TYPE="Char"/>
                <FIELD NAME="beg01 code"      POSITION="44" LENGTH="2" TYPE="Char"/>
                <FIELD NAME="beg02 code"      POSITION="46" LENGTH="2" TYPE="Char"/>
                <FIELD NAME="Department"      POSITION="48" LENGTH="4" TYPE="Char"/>
                <FIELD NAME="Expected Reciept Date" DESCRIPTION="Format YYMMDD" POSITION="52" LENGTH="6" TYPE="Char"/>
                <FIELD NAME="Cancel by date" DESCRIPTION="Format YYMMDD" POSITION="58" LENGTH="6" TYPE="Char"/>
                <FIELD NAME="EDI Type"       POSITION="68" LENGTH="1" TYPE="Char"/>
                <FIELD NAME="Add Date" DESCRIPTION="Format YYMMDD" POSITION="69" LENGTH="6" TYPE="Char"/>
                <FIELD NAME="Filler"         POSITION="75" LENGTH="1" TYPE="Char"/>
                <FIELD NAME="Department Name" POSITION="76" LENGTH="10" TYPE="Char"/>
                <FIELD NAME="Prcoess Type" DESCRIPTION="C/N Conveyable/Non-Conveyable" POSITION="86" LENGTH="1" TYPE="Char"/>
                <FIELD NAME="Order Type" POSITION="87" LENGTH="2" TYPE="Char"/>
            </FIELDS>
        </RECORD>
    </RECORDS>
</RECORD>
```

It is easy to see that for each record type there's a separate `RECORD` tag. Each RECORD has a `FIELDS` tag that contains the fields of the record type. For each field there's a separate `FIELD` tag with NAME, POSITION, LENGTH and TYPE attributes. Finally each RECORD tag has a `TESTFIELD` and a `TESTVALUE` attributes. These two will help *Record Editor* decide which RECORD to use for parsing a line by comparing the value of the field in TESTFIELD with the value of TESTVALUE. When they are equal, the FIELDS of the RECORD will be used to parse the line.

#### Design

Hence the following design:

1. Print the XML part up to, and including, the opening `RECORDS` tag. The RECORDNAME attribute of the main `RECORD` tag should be the name of the protocol
1. for each *CSV* file:
    1. add a `RECORD` tag with the RECORDNAME and DESCRIPTION attributes set to the protocol name followed by the *CSV* filename
    1. for each field:
        1. add a `FIELD` tag with the NAME and LENGTH attributes taken from the *CSV* and the POSITION set to the offset of the field. TYPE will be `Char` for every field.
1. close the `RECORDS` and main `RECORD` tags.

#### Implementation

Here's a BASH implementation for the [SOP](https://github.com/prontog/SOP) protocol.

Step 1:

```bash
cat <<EOF
<?xml version="1.0" ?>
<RECORD RECORDNAME="SOP" COPYBOOK="" DELIMITER="&lt;Tab&gt;" FILESTRUCTURE="Default" STYLE="0" 
        RECORDTYPE="GroupOfRecords" LIST="Y" QUOTE="" RecSep="default">
	<RECORDS>
EOF
```

Step 2:

```bash
for s in $*; do
	SPEC_NAME=${s/.csv/}
cat <<EOF
		<RECORD RECORDNAME="SOP: $SPEC_NAME" COPYBOOK="" DELIMITER="&lt;Tab&gt;" 
		        DESCRIPTION="SOP: $SPEC_NAME" FILESTRUCTURE="Default" STYLE="0" RECORDTYPE="RecordLayout"
			LIST="N" QUOTE="" RecSep="default" TESTFIELD="MessageType" TESTVALUE="$SPEC_NAME">
			<FIELDS>
EOF

	awk '
	BEGIN {
		FS = ","
		f_position = 1
	}
	NR != 1 {
		f_name = $1
		f_length = $2
		printf "\t\t\t\t<FIELD NAME=\"%s\"  POSITION=\"%d\" LENGTH=\"%d\" TYPE=\"Char\"/>\n", f_name, f_position, f_length
		f_position += f_length
	}
	' $s
cat <<EOF
			</FIELDS>
		</RECORD>
EOF
done
```

And finally step *3*:

```bash
cat <<EOF
	</RECORDS>
</RECORD>
EOF
```

The complete **csv2xmlcopybook.sh** script can be found [here](https://github.com/prontog/SOP/blob/master/specs/csv2xmlcopybook.sh). It includes options for the protocol name and header length.

### Usage

To try out *csv2xmlcopybook.sh* on SOP:

1. Download [reCsvEditor](https://sourceforge.net/projects/recsveditor/files/reCsvEditor/).
1. git clone https://github.com/prontog/SOP
1. cd SOP
1. ./csv2xmlcopybook.sh -H 15 -p "SOP log" *.csv > sop.xml
1. Run *reCsvEditor*
1. On the left part of the *Open File* window, select the **sopsrv_2016_12_06.log** found in the *log* directory of the *SOP* repo. Do not click the *Open* button yet.
1. On the right part of the *Open File* window, select the *Fixed Width* tab.
1. Select the **sop.xml** Copybook created in step 4.
1. Click the *Open* button.

![Fig 1: The Opened *sopsrv_2016_12_06.log* file](https://raw.githubusercontent.com/prontog/blog-entries/master/record_editor/opened_log.jpg)

Notice that only a couple of lines are displayed correctly. This is because the SOP log we opened has lines of different formats. One line has an OC message while another a TR and for each message type there's a different data layout. You can use the **Layouts** combobox to select the layout of the line you want to parse.

![Fig 2: Changing layout ](https://raw.githubusercontent.com/prontog/blog-entries/master/record_editor/changing_layouts.jpg)

Clicking the small button on the left of the row will open a *detail* tab. 

![Fig 3: A detailed view of a line ](https://raw.githubusercontent.com/prontog/blog-entries/master/record_editor/msg_detail.jpg)

It is also easy to filter lines. Click the *filter* button (with the horizontal arrows) to open the filter window.

![Fig 3: Keeping only OC messages (filter) ](https://raw.githubusercontent.com/prontog/blog-entries/master/record_editor/filtering_msgs.jpg)

Finally you can make changes and save them back to the original file!

For further info have a look at the locally installed help file. You can access it from *Help* menu.
