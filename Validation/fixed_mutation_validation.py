f = open("full_reference.vcf", "r+")
skip = True
startCol = 10
endCol = 13

resultPos = {}

for line in f: 
	ignore = False
	col = line.split("\t")
	if skip == True: 
		skip = False
	else: 
		col4 = col[4].split(",")
		if (len(col4) > 1) and (col4[0] == "-" or col4[0] == "N") and (col4[1] == "A" or col4[1] == "C" or col4[1] == "T" or col4[1] == "G"):
			for i in range(startCol, endCol):
				if col[i] != "2":
					ignore = True
					break
			if ignore == False:
				for i in range(endCol + 1, len(col)):
					if col[i] == "2":
						ignore = True
						break
			if ignore == False:
				resultPos[int(col[1])] = 0
		elif col[4] == "A" or col[4] == "C" or col[4] == "T" or col[4] == "G":
			for i in range(startCol, endCol):
				if col[i] == "0":
					ignore = True
					break
			if ignore == False:
				for i in range(endCol + 1, len(col)):
					if col[i] == "1":
						ignore = True
						break
			if ignore == False:
				resultPos[int(col[1])] = 0

compare = open("compare.txt", "r+")

theirPos = []
similarPos = []
unsimPos = []

for pos in compare:
	theirPos.append(int(pos.strip()))

for i in range(0, len(theirPos)):
	pos = theirPos[i]
	skip2 = False
	if pos in resultPos:
		similarPos.append(pos)
	elif pos + 1 in resultPos:
		similarPos.append(pos)
	elif pos - 1 in resultPos:
		similarPos.append(pos)
	else:
		unsimPos.append(pos)

print "Number from Their Results: " + str(len(theirPos))
print "Number from Our Results: " + str(len(resultPos))
print "Number Similar: " + str(len(similarPos))
print "\n"

print "Similar Positions: "
print similarPos
print "\n"

print "Unsimilar Positions: "
print unsimPos
print "\n"


				


