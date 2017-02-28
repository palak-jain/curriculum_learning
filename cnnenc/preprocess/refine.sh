#usage ./refine.sh path/to/dir/filename_before_suffixlang eg. ../data/bnhi/test/test

f=$1
S=bn
T=hi

paste "$f".$S "$f".$T > "$f".$S$T 
#grep -v -e '[a-z]\|[A-Z]' "$f".$S$T > "$f"_noenglish.$S$T 
awk 'BEGIN{FS="\t"}{ if(length($1)<=500 && length($2)<=500){print $1}}' "$f".$S$T > "$f"_ref.$S
awk 'BEGIN{FS="\t"}{ if(length($1)<=500 && length($2)<=500){print $2}}' "$f".$S$T > "$f"_ref.$T

echo "$f refine done!"

rm "$f"*.$S$T
