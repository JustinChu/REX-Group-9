# Orders SNPs according to their allele frequency, from highest to lowest. 
# SNPs with allele frequencies greater than the threshold are filtered out. 

import re
from collections import OrderedDict

threshold = 0.95;
countPattern = re.compile(ur'(.:\d.\d+)')

# Hook this up to the pipeline/change the file name
f = open("outputfull.frq", "r+")

result = {}
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
			result[maxFreq] = line

sortedResult = OrderedDict(sorted(result.items(), key=lambda r: r[0], reverse=True))

for result in sortedResult.values():
	print result

	


