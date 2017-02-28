dir=$1
fname=$2
paste $dir/lcsr.txt $dir/$fname.bn $dir/$fname.hi > $dir/lcsr.bnhi_

# sort by lcsr score
sort -nrk 1 $dir/lcsr.bnhi_ > $dir/$fname_lcsr.bn_
cut -f 4 $dir/$fname_lcsr.bn_ > $dir/lcsr.bn 
sort -nrk 1 $dir/lcsr.bnhi_ > $dir/$fname_lcsr.hi_
cut -f 5 $dir/$fname_lcsr.hi_ > $dir/lcsr.hi

# cleaning up
rm $dir/*_ 
