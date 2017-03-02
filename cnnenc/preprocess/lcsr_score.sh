if [ $# -lt 5 ]; then
    echo "USAGE: ./preprocess/lcsr_score.sh src_fname trgt_fname out_fname src trgt"
    exit 1;
fi

src_fname=$1
trgt_fname=$2
out_fname=$3
src=$4
trgt=$5

python preprocess/utilities.py linguistic_similarity $src_fname $trgt_fname $out_fname $src $trgt