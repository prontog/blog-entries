In a previous post I have shown a way to [load a file with lines of fixed-width format](https://prontog.wordpress.com/2016/01/27/reading-a-file-with-lines-of-different-fixed-width-formats/) into *R*. After doing so, it is easy to view the data using *RStudio* (the `View` function) but it is not easy to edit the file if it contains lines of different formats. My `multifwf` package has `read.multi.fwf` function but not a `write.multi.fwf` for writing back to a file. Having said that, it is also not easy for someone unfamiliar with *R* to filter/subset the loaded data.

### Why

Reading a fixed-width log file can be very frustrating especially while you are troubleshooting. For example have a look at some lines from a [SOP](https://github.com/prontog/SOP/blob/master/logs/sopsrv_2016_12_06.log) log file: 

> 09:20:05.034 < NOSLMT0000666    EVILCORP00010.77SomeClientId    SomeAccountId   
09:20:05.099 > OC000001BLMT0000666    EVILCORP00010.77SomeClientId    SomeAccountId   
09:20:13.421 < NOBLMT0000666 EVILCORP00001.10AnotherClientId AnotherAccountId

And note that the messages in these lines are of a very simple protocol. At the place where I work, we have to deal with much bigger messages (some even longer than 300 characters).  Imagine having to find a certain field somewhere in the message. And under pressure. This is not easy even for experienced employees. What would definitely help is to be able to view the message fields in a clear way. To be able to quickly and safely locate any field in a given line even if you are new to the message protocol. To be able to perform queries and filter out any lines not needed.

Appart from reading a fixed-width log file, sometimes you might need to edit one. Let's say you want to replay a log file but after changing the value of a field.

### How

A solution is using [Record Editor](http://record-editor.sourceforge.net/) or its little brother [reCsvEditor](http://recsveditor.sourceforge.net/). Both of these editors can be used to view/edit fixed-width data files as long as they know how the data is layed out. This data layout can be in many formats and after some experimentation I decided to use the *XML Copybook* format since it allows for multiple data layouts in a single file. This way a single *xml* file can hold the specs for all the message types of the protocol. Other than that, the *XML* examples that come with *Record Editor* were very straighforward, something that I cannot say for the *CSV* examples.

Having decided on the layout format, I only had to create one for each of the protocols I work with. Of course, this can be tedious and error prone and since I already have the [message specs in CSV format](https://prontog.wordpress.com/2016/02/02/using-pandoc-and-make-to-extract-specs-from-a-word-document/)), I decided to create a tool that converts *CSV* specs to the *XML Copybook* format.

Here's a simplified version of the **"ams PO Download.Xml"** copybook that comes preinstalled with *Record Editor*:

```xml
<?xml version="1.0" ?>
<RECORD RECORDNAME="ams PO Download" COPYBOOK="" DELIMITER="&lt;Tab&gt;" FILESTRUCTURE="Default" STYLE="0"
        RECORDTYPE="GroupOfRecords" LIST="Y" QUOTE="" RecSep="default">
    <RECORDS>
        <RECORD RECORDNAME="ams PO Download: Detail" COPYBOOK="" DELIMITER="&lt;Tab&gt;"
                DESCRIPTION="PO Download: Detail" FILESTRUCTURE="Default" STYLE="0" ECORDTYPE="RecordLayout"
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

It is not difficult to see that for each record-type there is separate `RECORD` tag. Each RECORD has `FIELDS` tag where all the fields of the record-type are specified. Each field in a separate `FIELD` tag with NAME, POSITION, LENGTH and TYPE attributes. Finally each RECORD tag has a `TESTFIELD` and a `TESTVALUE` attribute. These two attributes will help *Record Editor* to decide which RECORD to use for parsing a line by comparing the value of the field in TESTFIELD with the value of TESTVALUE. When these are the same, we have a match and the FIELDS of the RECORD will be used to parse the line.

#### Design

Hence the following design:

1. Print the XML part up to, and including, the opening `RECORDS` tag. The RECORDNAME attribute of the main `RECORD` tag should be the name of the protocol
1. for each *CSV* file:
    1. add a `RECORD` tag with the RECORDNAME and DESCRIPTION attributes set to the protocol name followed by the *CSV* filename
    1. for each field:
        1. add a `FIELD` tag with the NAME and LENGTH attributes taken from the *CSV* and the POSITION set to the offset of the field. For now, the TYPE will be `Char` for all fields.
1. close the `RECORDS` and main `RECORD` tags.

#### Implementation

The whole script can be found found [here](https://github.com/prontog/SOP/blob/master/specs/csv2xmlcopybook.sh).

### Usage

```bash
./csv2xmlcopybook.sh -H 15 -p "SOP log" *.csv
```

Now that we have created a Copybook describing our protocol, we can [view](http://record-editor.sourceforge.net/Record05.htm), [filter](http://record-editor.sourceforge.net/Record08.htm) and edit our fixed-width log file:)
