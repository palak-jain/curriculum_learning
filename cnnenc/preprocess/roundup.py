import sys
f = open(sys.argv[1])
for l in f:
    l = l.split('\t')
    print round(float(l[0]), 4),"\t", int(float(l[1])),"\t", int(float(l[2]))
