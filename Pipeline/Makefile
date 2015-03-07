#!usr/bin/make -f
#This is a example makefile
 
#It would probably be better to gzip each file as they are downloaded
#rather than afterwards

all: output.fa.gz output.afa output.vcf output.afa output.frq output_sorted.frq

ref: output.fa.gz output.afa

tree: output.ctx.phy RAxML_bestTree.T1 RAxML_bestTree.tre

.PHONY: all clean install-deps
.DELETE_ON_ERROR:
.SECONDARY:

clean:
	rm -rf output* -r 
	rm -rf RAxML* -r

#download files
output.fa : download.py download_sources_small.txt
	python $< -i $(word 2,$^) -o $@

#gzip files
%.fa.gz : %.fa
	gzip -c $< > $@

#muscle alignment
output.afa : output.fa
	bin/muscle -in $< -out $@

#variant calling
output.vcf : output.afa
	python3 FastaToVCF.py output.afa output.vcf

#frequency
output.frq : output.vcf
	bin/vcftools --vcf $< --freq --out output

#snp filtering
output_sorted.frq : snpparser.py output.frq
	python $< -i output.frq > $@

#encode 
output.ctx.phy : output.afa
	perl -w encodename.pl output.afa

#construct tree
RAxML_bestTree.T1 : output.ctx.phy
	bin/raxmlHPC -m GTRGAMMA -p 1225 -s output.ctx.phy -\# 20 -n T1

#decode
RAxML_bestTree.tre : RAxML_bestTree.T1
	perl -w decodename.pl -h output.ctx.lut -i RAxML_bestTree.T1
	rm -rf *.T1.* #comment out if want to keep the RUN files

