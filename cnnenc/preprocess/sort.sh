split_size=0
S="bn"
T="hi"

for i in "$@"
do
case $i in
    --file=*)
    file="${i#*=}"
    shift # past argument=value
    ;;
    --split=*)
    split_size="${i#*=}"
    shift # past argument=value
    ;;
    --src=*)
    S="${i#*=}"
    shift # past argument=value
    ;;
    --trgt=*)
    T="${i#*=}"
    shift # past argument=value
    ;;
     --sort=*)
    sort="${i#*=}"
    shift # past argument=value
    ;;
    --default=*)
    DEFAULT=YES
    shift # past argument with no value
    ;;
    *)
            # unknown option
    ;;
esac
done

dir=`echo $file|sed 's:/[^/]*$::g'`
paste $file.$S $file.$T > "$file.$S$T"_

if [ $sort -eq 1 ]; then
	cut -f 1 $dir/lcsr.txt > $file.metric_ ;
elif [ $sort -eq 2 ]; then
	python preprocess/nchar.py "$file.$S$T"_ > $file.metric_ ;
fi

paste $file.metric_ "$file.$S$T"_ > $file.comb_
sort -nk 1 $file.comb_ > $file.sort_

if [ $split_size != 0 ]; then
	split -a 2 -l $split_size $file.sort_ $file.
fi

for f in $file.a*
do
	shuf $f > $f.shuf_
	cut -f 2 $f.shuf_ > $f.$S
	cut -f 3 $f.shuf_ > $f.$T
done


# dir=$1
# fname=$2
# python preprocess/nchar.py $dir/$fname.bn > $dir/$fname.bn.lc 
# python preprocess/nchar.py $dir/$fname.hi > $dir/$fname.hi.lc 
# # awk '{print length}' < $dir/$fname.bn > $dir/$fname.bn.lc_
# # awk '{print length}' < $dir/$fname.hi > $dir/$fname.hi.lc_
# paste $dir/$fname.hi.lc $dir/$fname.bn.lc > $dir/$fname.comb.lc_
# awk '{print (($1+$2))}' < $dir/$fname.comb.lc_ > $dir/$fname.sum.lc_
# paste $dir/$fname.comb.lc_ $dir/$fname.sum.lc_ > $dir/$fname.lc
# paste $dir/$fname.sum.lc_ $dir/$fname.bn > $dir/$fname.bn.lc_
# paste $dir/$fname.sum.lc_ $dir/$fname.hi > $dir/$fname.hi.lc_

# # sort by length
# sort -nk 1 $dir/$fname.bn.lc_ > $dir/$fname.sort.bn_
# cut -f 2 $dir/$fname.sort.bn_ > $dir/$fname.sort.bn 
# sort -nk 1 $dir/$fname.hi.lc_ > $dir/$fname.sort.hi_
# cut -f 2 $dir/$fname.sort.hi_ > $dir/$fname.sort.hi

# remove unwanted files
rm -f $dir/*_ $dir/*.aa $dir/*.ab $dir/*.ac $dir/*.ad $dir/*.ae 

