dir=$1
fname=$2

python nchar.py $dir/$fname.bn > $dir/$fname.bn.lc 
python nchar.py $dir/$fname.hi > $dir/$fname.hi.lc 
# awk '{print length}' < $dir/$fname.bn > $dir/$fname.bn.lc_
# awk '{print length}' < $dir/$fname.hi > $dir/$fname.hi.lc_
paste $dir/$fname.hi.lc $dir/$fname.bn.lc > $dir/$fname.comb.lc_
awk '{print (($1+$2))}' < $dir/$fname.comb.lc_ > $dir/$fname.sum.lc_
paste $dir/$fname.comb.lc_ $dir/$fname.sum.lc_ > $dir/$fname.lc
paste $dir/$fname.sum.lc_ $dir/$fname.bn > $dir/$fname.bn.lc_
paste $dir/$fname.sum.lc_ $dir/$fname.hi > $dir/$fname.hi.lc_

# sort by length
sort -nk 1 $dir/$fname.bn.lc_ > $dir/$fname.sort.bn_
cut -f 2 $dir/$fname.sort.bn_ > $dir/$fname.sort.bn 
sort -nk 1 $dir/$fname.hi.lc_ > $dir/$fname.sort.hi_
cut -f 2 $dir/$fname.sort.hi_ > $dir/$fname.sort.hi

# remove unwanted files
rm $dir/*_
