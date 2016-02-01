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
	pandoc -smart --filter ./despan.py --to markdown_github $? | iconv -f utf8 -t ascii//TRANSLIT > $@

# Clean up rules.	

clean: clean_csv clean_mdtable clean_md 
	rm sop

clean_csv:
	rm $(sop_specs)
	
clean_mdtable: 
	rm $(sop_mdtables)

clean_md: 
	rm $(sop_md)
