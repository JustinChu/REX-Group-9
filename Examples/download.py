#!/usr/bin/env python
# encoding: utf-8
'''
Downloader -- A simple python script for fasta file give a NCBI gene id (GI)

This code serves as an example.

@author:     cjustin
@contact:    cjustin@bcgsc.ca
'''

import os
import urllib2
from optparse import OptionParser
from Bio import Entrez

class Downloader:
    
    def __init__(self, downloadSourceFile, email):
        """Constructor"""
        Entrez.email = email
        self._files = []
        fileHandle = open(downloadSourceFile, "r")
        for i in fileHandle:
            self._files.append(i.rstrip())
        fileHandle.close()
    
    def downloadFiles(self, output):
        """Uses biopython to get fasta file in output"""
        
        #check output older
        if not os.path.exists(output):
            os.makedirs(output)
            
        ## We instead upload the list of IDs        
        request = Entrez.epost("nucleotide",id=", ".join(map(str,self._files)))
        result = Entrez.read(request)
        webEnv = result["WebEnv"]
        queryKey = result["QueryKey"]
        handle = Entrez.efetch(db="nucleotide",retmode="xml", webenv=webEnv, query_key=queryKey)
        for r in Entrez.parse(handle):
            # Grab the GI 
            try:
                gi=int([x for x in r['GBSeq_other-seqids'] if "gi" in x][0].split("|")[1])
            except ValueError:
                gi=None
            
            outputStr = ">GI " + str(gi) + " " + r["GBSeq_primary-accession"] + " " \
                        + r["GBSeq_definition"] + "\n" + r["GBSeq_sequence"]
            
            #write to file
            out = open(output + "/" + str(gi) + ".fa", 'w')
            out.write(outputStr)
            out.close()

    
if __name__ == '__main__':

    parser = OptionParser()
    parser.add_option("-i", "--input", dest="input", metavar="INPUT",
                      help="input file of list of NCBI GI numbers to download in fasta format")
    parser.add_option("-o", "--out", dest="out", metavar="OUTPUT", 
                      help="output folder for downloaded files")
    parser.add_option("-e", "--email", dest="email", metavar="EMAIL", default = "email@email.com",
                      help="email used as login ID")
                
    (options, args) = parser.parse_args()
        
    if options.input and options.out:
        runner = Downloader(options.input, options.email)
        runner.downloadFiles(options.out)        
    else:
        print 'ERROR: Missing Required Options. Use -h for help'
