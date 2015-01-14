#!usr/bin/make -f
#This is a example makefile
 
#It would probably be better to gzip each file as they are downloaded
#rather than afterwards

all: output.fa.gz

.PHONY: all clean install-deps
.DELETE_ON_ERROR:
.SECONDARY:

clean:
	rm -rf output.fa* -r

#download files
output.fa : download.py download_sources.txt
	python $< -i $(word 2,$^) -o $@

#gzip files
%.fa.gz : %.fa
	gzip -c $< > $@