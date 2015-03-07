from collections import OrderedDict
import sys, getopt

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
			skip = True
			startCol = 10

			zeroKeys = []
			zeroCounts = []
			for line in f: 
				ignore = True
				col = line.split("\t")
				if skip == True: 
					for i in range(startCol, len(col)):
						zeroKeys.append(col[i])
						zeroCounts.append(0)
					skip = False
				else:
					for i in range(0, len(col)):
						if i == 4:
							if col[i] != "N" and col[i] != "-":
								ignore = False
						if i >= startCol and ignore == False: 
							if int(col[i]) == 0:
								zeroCounts[i - startCol] += 1

			zeroDict = dict(zip(zeroKeys, zeroCounts))

			sortedDict = OrderedDict(sorted(zeroDict.items(), key=lambda r: r[1], reverse=True))

			print sortedDict

if __name__ == "__main__":
   main(sys.argv[1:])
