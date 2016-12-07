[Pandoc](http://pandoc.org/) is a fantastic tool for converting documents supporting most common markup formats. I first learned about it when I started using [R Markdown](http://rmarkdown.rstudio.com/) but didn't directly use it until I read ['From Word to Markdown to InDesign'](http://rhythmus.be/md2indd/) by [Dr. Wouter Soudan](http://woutersoudan.be/).

### Why (create a tool)

As I've mentioned in earlier posts, in the company where I work we maintain several text protocols for inter-process communication. The specification for each protocol is described in a *Word* document from which we create a PDF file every time we make a new release. Each message type is described in a separate section in table format. For an example have a look at the specification for an imaginary protocol named [SOP](https://github.com/prontog/SOP/raw/master/specs/sop.docx). Notice that for each type of message there is a table such as:

| Field         | Length | Type    | Description                                                 |
|---------------|--------|---------|-------------------------------------------------------------|
| msgType       | 2      | STRING  | Defines message type ALWAYS FIRST FIELD IN MESSAGE PAYLOAD. |
| clientId      | 16     | STRING  | Unique identifier for Order as assigned by the client.      |
| rejectionCode | 3      | NUMERIC | Rejection Code                                              |
| text          | 48     | STRING  | Text explaining the rejection                               |

#### About my CSV addiction

As you can see from my post on creating [Wireshark dissectors](https://prontog.wordpress.com/2016/01/29/a-simpler-way-to-create-wireshark-dissectors-in-lua/), I use CSV files to create dissectors for our protocols. I also use them to load log files into R and analyze them. The reason I use CSV extensively is that they allow me to separate the protocol specs from the tools I use. This way I can create a CSV-aware tool for fixed-width text protocols and then use it with any protocol of this type with no changes (hopefully).

Perhaps you've already noticed the problem in my workflow.

#### Managing the CSV specs

The specs are stored in Word documents, which means that I have to manually extract them into CSV files. Here's my initial workflow:

1. Copy a table (describing a message type) from the Word document.
2. Paste it into a new *Sheet* in an **Excel** file. Name the *Sheet* after the message type.
3. Use **in2csv** (part of [csvkit](https://csvkit.readthedocs.org/en/0.9.1/#)) to extract each *Sheet* to a CSV file.

Then I had to make sure these steps where repeated every time a Word spec was edited. Not nice. And prone to errors.

### How

The solution is to use **Pandoc** to convert the Word document to another format. One that will allow me to create the CSV files using common text manipulation tools (grep, sed, awk etc.). The most suitable format I can think of is a [Markdown](https://daringfireball.net/projects/markdown/syntax) variant that can handle tables such as `markdown_github` , a [GitHub-Flavored Markdown](https://guides.github.com/features/mastering-markdown/#GitHub-flavored-markdown).

#### Design

The design is simple:

For each message type:

1. Extract the spec table in Markdown format.
2. Save it to a file using the message type for a name.
3. Transform the Markdown table into CSV format.

#### Implementation

After many experiments I ended up with the following command to convert a Word document, such as [sop.docx](https://github.com/prontog/SOP/raw/master/specs/sop.docx), to Markdown:

```shell
#         1      2                           3                       4
pandoc -smart --filter ./despan.py --to markdown_github sop.docx | iconv -f utf8 -t ascii//TRANSLIT > sop.md
```
Let's break it down:

1. The *smart* option will produce typographically correct output.
2. The *filter* option will allow us to use a python filter to remove all *span* elements that pandoc ocassionally produces. See issue [#1893](https://github.com/jgm/pandoc/issues/1893) from the Pandoc repo. This step requires the [pandocfilters](https://pypi.python.org/pypi/pandocfilters) Python module.
3. The *to* option is the most important, specifying the markup of the transformed output. As I mentioned earlier, `markdown_github` supports tables and is a perfect choice.
4. Convert characters from UTF8 to ASCII with transliteration so a character that can't be represented in the target character set, will be approximated through one or more similar looking characters. You can omit this if you want but in my experience it's the safest choice since some of the tools, I use with the CSV files, prefer ASCII characters.

By examining [sop.md](https://github.com/prontog/SOP/raw/master/specs/sop.md) we can see that each message table is preceded by a header with the format: "### MT " where MT is the message type. Hence we can extract each spec table with the following **awk** script:

```js
/### / {
	header = $0
	match(header, /^### ([A-Z]{2}) /, results)
	messageType = results[1]
	if (messageType) {
		spec_file = sprintf("%s.mdtable", messageType)
		print "" > spec_file
	}
}
# Print the message table into a different file.
/^\| /,/^$/{
	if (messageType) {
		print >> spec_file
	}
	
	if ($0 ~ /^$/) {
		messageType = 0
	}
}
```

The script extracts the message type using the regex `/^### ([A-Z]{2}) /` on each line containing the pattern '/### /' and stores it in variable `messageType`. Then create variable `spec_file` with the format *MT*.mdtable where MT is the message type. Finallys it print all lines starting with '| ' (`/^\| /`) to `spec_file` and stops on the first blank line (`/^$/`).

In our example, the script will create 7 new files with extension *mdtable*.

Then we need to transform the *mdtable* files to CSV format. The following **sed** script does the job:
```js
# Delete ** from the first line.
s/\*//g
# Delete lines that start with space. These
# are multirow cells from Remarks column.
/^[[:space:]]/d
# Delete rows with |---.
/^|---/d
# Remove first | and trim.
s/^|[[:space:]]*//
# Remove final | and trim.
s/[[:space:]]*|[[:space:]]*$//
# Trim middle |.
s/[[:space:]]*|[[:space:]]*/|/g
# Delete empty rows.
/^$/d
# Replace | separator with ,
s/|/,/g
```

This might seem like overkill but after using Pandoc with 4 different Word documents, all with different formatting, I ended up needing these replacements and deletions.

#### Adding make to the mix

As a task runner I used [GNU make](https://www.gnu.org/software/make/manual/html_node/index.html) which is ideal for such cases since it works with file time-stamps and will allow for multiple transformation steps. Here's the final Makefile:

```js
sop_types := NO OC TR RJ EN BO
sop_mdtables := $(foreach t, $(sop_types), $(t).mdtable)
sop_specs := $(foreach t, $(sop_types), $(t).csv)
sop_md := sop.md

sop: $(sop_specs)
	touch $@

%.csv: %.mdtable
	./mdtable_to_csv.sh $?

$(sop_mdtables): $(sop_md)
	# Extract the md tables for each message type.
	./sop_split_to_mdtable.sh $?

%.md: %.docx
	# Convert documentation from docx format to md.
	pandoc --smart --filter ./despan.py --to markdown_github $? | iconv -f utf8 -t ascii//TRANSLIT > $@

# Clean up rules.	

clean: clean_csv clean_mdtable clean_md 
	rm sop

clean_csv:
	rm $(sop_specs)
	
clean_mdtable: 
	rm $(sop_mdtables)

clean_md: 
	rm $(sop_md)

```

Note that:

1. Rule `%.md: %.docx` is for conversion from *docx* to *md*.
2. Rule `$(sop_mdtables): $(sop_md)` is for extracting the *mdtable* files from a single *md*. This is done by BASH script [sop_split_to_mdtable.sh](https://github.com/prontog/SOP/blob/master/specs/sop_split_to_mdtable.sh).
3. Rule `%.csv: %.mdtable` is for converting from *mdtable* to *csv*. This is done by BASH script [mdtable_to_csv.sh
](https://github.com/prontog/SOP/blob/master/specs/mdtable_to_csv.sh).
4. Rule `sop: $(sop_specs)` is the final rule that simply touches the dummy file *sop*.
5. The rest of the rules are for cleaning up.

### Trying it yourself

1. Install [Pandoc](http://pandoc.org/installing.html).
1. Install [pandocfilters](https://pypi.python.org/pypi/pandocfilters)
1. git clone https://github.com/prontog/SOP
1. cd SOP/specs
1. make clean
1. make
