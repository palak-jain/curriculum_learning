# split file into batches

dir=$1
if [ $# -ge 2 ]; then
	batch=$2
else 
	batch=10000
fi

cd "$dir";
split -a 1 -l $batch train.sort.hi train.splitsort.hi.
split -a 1 -l $batch train.sort.bn train.splitsort.bn.