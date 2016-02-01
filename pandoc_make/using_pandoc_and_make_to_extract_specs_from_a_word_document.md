[Pandoc](http://pandoc.org/) is a fantastic tool for converting documents supporting most common markup formats. I first learned about it when I started using [R Markdown](http://rmarkdown.rstudio.com/) but didn't directly use it until I came accross [From Word to Markdown to InDesign](http://rhythmus.be/md2indd/) by [Dr Wouter Soudan](http://woutersoudan.be/).

### Why (create a tool)

As I've mentioned in previous posts, in the company where I work we maintain several text protocols for inter-process communication. The specification for each protocol is described in a *Word* document from which we create a PDF file everytime we make a new release. Each message type is described in a separate section in table format. For an example have a look at the specification for an imaginary protocol named [SOP](https://github.com/prontog/blog-entries/raw/master/pandoc_make/sop.docx). You will see a table with the fields of each message type such as:

| Field         | Length | Type    | Description                                                 |
|---------------|--------|---------|-------------------------------------------------------------|
| msgType       | 2      |         | Defines message type ALWAYS FIRST FIELD IN MESSAGE PAYLOAD. |
| clientId      | 16     |         | Client Id                                                   |
| rejectionCode | 3      | NUMERIC | Rejection Code                                              |
| text          | 48     |         | Text explaining the rejection                               |

#### About my CSV addiction

As you can see from my previous post on creating [Wireshark Dissectors](https://prontog.wordpress.com/2016/01/29/a-simpler-way-to-create-wireshark-dissectors-in-lua/), I use CSV files to automatically create dissectors for our protocols. I also use these CSV files in other tools that I haven't blogged about yet. The reason I use CSV extensively is because they help me separate the protocol specs from the tools I use. This way I can create a CSV-aware tool for fixed-width text protocols and then use it with any protocol of this type without any changes (hopefuly).

Perhaps you have already noticed the problem in my workflow.

#### Managing the CSV specs.

The specs are stored in Word documents, which means that I have to manually extract them into CSV files. The way I approached this (before pandoc) was:

1. Copy a table (describing a message type) from the Word document.
2. Paste it into a new *Sheet* in an **Excel** file. Name the *Sheet* after the message type.
3. Use **in2csv** (part of [csvkit](https://csvkit.readthedocs.org/en/0.9.1/#)) to extract each *Sheet* to a CSV file.

Then I had to make sure these steps where repeated everytime a change was made to a Word document. Not nice. And prone to errors.

The main problem

### How

The solution is to use **Pandoc** to convert the Word document to another format that will allow me to use my favourite text manipulation tools (grep, sed, awk etc.) to create the CSV files. The most suitable format I can think of is an [Markdown](https://daringfireball.net/projects/markdown/syntax) variant that can handle tables such as `markdown_github` , a [GitHub-Flavored Markdown](https://guides.github.com/features/mastering-markdown/#GitHub-flavored-markdown).

#### Design

The design is quite simple:

For each message type:

1. Extract the spec table in Markdown format.
2. Save it to a file using the message type for a name.
3. Transform the Markdown table into CSV format.

#### Implementation

After many experiments I ended up with the following command to convert a Word document, such as [sop.docx](https://github.com/prontog/blog-entries/raw/master/pandoc_make/sop.docx), to Markdown:

```
#         1      2                           3                       4
pandoc -smart --filter ./despan.py --to markdown_github sop.docx | iconv -f utf8 -t ascii//TRANSLIT > sop.md
```
Let's break it down:

1. The *smart* option will produce typographically correct output.
2. The *filter* option will allow us to use a python filter to remove all *span* elements that pandoc ocassionaly produces. See issue [#1893](https://github.com/jgm/pandoc/issues/1893) from the Pandoc repo. This step requires the [pandocfilters](https://pypi.python.org/pypi/pandocfilters) Python module.
3. The *to* option is the most important, specifying the markup of the transformed output. As I mentioned earlier, `markdown_github` supports tables and is a perfect choice.
4. Convert characters from UTF8 to ASCII with transliteration which means that a character that can't be represented in the target character set, will be approximated through one or more similar looking characters. You can ommit this if you want but in my experience it is the safest choice since some of the tools, I use with the CSV files, prefere ASCII characters.

By examining [sop.md](https://raw.githubusercontent.com/prontog/blog-entries/master/pandoc_make/sop.md) we can see that each message table is preseded by a header with the format: "### MT " where MT is the message type. Hence we can extract each spec table with the following **awk** script:

```
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

What this does is find the message type using the regex `/^### ([A-Z]{2}) /` on each line containing the pattern '/### /' and save it in variable `messageType`. Then create variable `spec_file` with the format *MT*.mdtable where MT is the message type. Then print all lines strating with '| ' (`/^\| /`) to `spec_file` until we find a blank line (`/^$/`).

In our example, the script will create 7 new files with extension *mdtable*.

Then we need to transform the *mdtable* files to CSV format. The following **sed** script does the job:
```
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
```

This might seem like overkill but after using Pandoc with 4 different Word documents with different formattings I ended up needing all of these replacements and deletions.

#### Adding make to the mix

For the implemenation I decided to use [GNU make](https://www.gnu.org/software/make/manual/html_node/index.html) as task runner. **make** is ideal for such cases since it works with file timestamps and will allow for multiple transformation steps. Here's the final Makefile:

```
sop_types := NO OC TR RJ EN BO
sop_types_not_supported := LO
sop_mdtables := $(foreach t, $(sop_types), $(t).mdtable)
sop_specs := $(foreach t, $(sop_types), $(t).csv)
sop_md := sop.md

sop: $(sop_specs)
	./sop_update_csv.sh $? && touch $@
	echo $(sop_types_not_supported) are not supported. Please make sure you update their CSV manually.

%.csv: %.mdtable
	./mdtable_to_csv.sh $?

$(sop_mdtables): $(sop_md)
	# Extract the md tables for each message type.
	./sop_split_to_mdtable.sh $?

%.md: %.docx
	# Convert documentation from docx format to md.
	pandoc --standalone -smart --filter ./despan.py --to markdown_github $? | iconv -f utf8 -t ascii//TRANSLIT > $@

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

1. Rule `%.md: %.docx` is for convertion from *docx* to *md*.
2. Rule `$(sop_mdtables): $(sop_md)` is for extracting the *mdtable* files from a single *md*. This is done by BASH script [sop_split_to_mdtable.sh](https://github.com/prontog/blog-entries/blob/master/pandoc_make/sop_split_to_mdtable.sh).
3. Rule `%.csv: %.mdtable` is for converting from *mdtable* to *csv*. This is done by BASH script [mdtable_to_csv.sh
](https://github.com/prontog/blog-entries/blob/master/pandoc_make/mdtable_to_csv.sh).
4. Rule `sop: $(sop_specs)` is the final rule that executes BASH script [sop_update_csv.sh](https://github.com/prontog/blog-entries/blob/master/pandoc_make/sop_update_csv.sh) on each CSV included in variable `sop_specs`. This final part replaces the '|' separator with ','. This last part could be ommited or moved to the previous rule.
5. The rest of the rules are for cleaning up.

### How to try it yourself

1. Install Pandoc sudo dpkg --install pandoc-1.15.2-1-amd64.deb
1. Install pandocfilters  pip install pandocfilters
1. Download archive [blog-entries](https://github.com/prontog/blog-entries/archive/master.zip)
1. Unzip master.zip
1. cd blog-entries/pandoc_make
1. make clean
1. make

