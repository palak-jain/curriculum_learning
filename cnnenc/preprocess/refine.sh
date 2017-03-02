#usage ./refine.sh path/to/dir/ filename_before_suffixlang src trgt 
# eg. ./refine.sh ../data/bnhi/test test bn hi

dir=$1
file=$2
S=$3
T=$4

if [ $# -le 4 ]; then
    echo "USAGE: ./refine.sh path/to/dir/ filename_before_suffixlang src trgt";
    echo "EXAMPLE:  ./refine.sh ../data/bnhi/test test bn hi";
    exit 1;
fi

paste "${dir}/${file}".$S "${dir}/${file}".$T > "${dir}/${file}".${S}${T}_ 
#grep -v -e '[a-z]\|[A-Z]' "$f".$S$T > "$f"_noenglish.$S$T 
awk 'BEGIN{FS="\t"}{ if(length($1)<=500 && length($2)<=500){print $1}}' ${dir}/${file}.${S}${T}_ > ${dir}/corpus.$S
awk 'BEGIN{FS="\t"}{ if(length($1)<=500 && length($2)<=500){print $2}}' ${dir}/${file}.${S}${T}_ > ${dir}/corpus.$T

echo "$dir/$file refine done!"

rm "${dir}/${file}".${S}${T}_ 
