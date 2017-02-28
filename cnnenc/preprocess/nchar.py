import sys

filename = sys.argv[1]

with open(filename, 'r') as f:
        e = f.readlines()
        for line in e:
            words_in = line.strip()
            words_in = list(words_in)
            print len(words_in)