#usage ./refine.sh path/to/dir/filename_before_suffixlang eg. ../data/bnhi/test/test

f=$1
S=bn
T=hi

paste "$f".$S "$f".$T > "$f".$S$T 
grep -v -e '[a-z]\|[A-Z]' "$f".$S$T > "$f"_noenglish.$S$T 
awk 'BEGIN{FS="\t"}{ if(length($1)<=400 && length($2)<=400){print $1}}' "$f"_noenglish.$S$T > "$f"_ref.$S
awk 'BEGIN{FS="\t"}{ if(length($1)<=400 && length($2)<=400){print $2}}' "$f"_noenglish.$S$T > "$f"_ref.$T

rm "$f"*.$S$T
