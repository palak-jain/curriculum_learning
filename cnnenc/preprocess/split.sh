# split file into batches

dir=$1
file=$2
S="bn"
T="hi"

if [ $# -ge 3 ]; then
	batch=$3
else 
	batch=10000
fi


cd "$dir";
split -a 1 -l $batch $file.sort.$S $file.split.$S.
split -a 1 -l $batch $file.sort.$T $file.split.$T.


for f in *.split.*;
do
    g=`echo $f|sed 's/split/shuf/g'`
    shuf $f > $g;
done

rm *split*

