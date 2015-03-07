# Orders SNPs according to their allele frequency, from highest to lowest. 
# SNPs with allele frequencies greater than the threshold are filtered out. 

import re
import sys, getopt
from collections import OrderedDict

threshold = 0.95;
countPattern = re.compile(ur'(.:\d.\d+)')

# Hook this up to the pipeline/change the file name


def main(argv):
	f = ''
	try:
		opts, args = getopt.getopt(argv,"hi:",["ifile="])
	except getopt.GetoptError:
		print 'test.py -i <inputfile>'
		sys.exit(2)
	for opt, arg in opts:
		if opt == '-h':
			print 'test.py -i <inputfile>'
			sys.exit()
		elif opt in ("-i", "--ifile"):
			f = open(arg, "r+")
			result = {}
			i = 0 
			for line in f:
				countList = re.findall(countPattern, line)
				if len(countList) > 0:
					maxFreq = -1
					for c in countList:
						count = c.split(":", 1)
						allele = count[0]
						freq = float(count[1])
						# finds the max allele frequency for each snp 
						if freq > maxFreq:
							maxFreq = freq
							# filters max allele frequency
					if maxFreq <= threshold:
						result[i] = line
						i+=1
			sortedResult = OrderedDict(sorted(result.items(), key=lambda r: sortByFreq(r[1]), reverse=True))
		for result in sortedResult.values():
			print result

def sortByFreq(r):
	countList = re.findall(countPattern, r)
	maxFreq = -1
	for c in countList:
		count = c.split(":", 1)
		freq = float(count[1])
		if freq > maxFreq:
			maxFreq = freq
	return maxFreq


if __name__ == "__main__":
   main(sys.argv[1:])
	


