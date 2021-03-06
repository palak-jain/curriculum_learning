#!/bin/bash

# source language (example: fr)
S=$1
# target language (example: en)
T=$2

# path to dl4mt/data
P1=$3
# destination dir
dst=$4
# path to subword NMT scripts (can be downloaded from https://github.com/rsennrich/subword-nmt)
# P2=$4

## merge all parallel corpora
./merge.sh $1 $2 $3 $4

perl ./normalize-punctuation.perl -l ${S} < $dst/all_${S}-${T}.${S} > $dst/all_${S}-${T}.${S}.norm  # do this for validation and test
perl ./normalize-punctuation.perl -l ${T} < $dst/all_${S}-${T}.${T} > $dst/all_${S}-${T}.${T}.norm  # do this for validation and test

# tokenize
perl ./tokenizer_apos.perl -threads 5 -l $S < $dst/all_${S}-${T}.${S}.norm > $dst/all_${S}-${T}.${S}.tok  # do this for validation and test
perl ./tokenizer_apos.perl -threads 5 -l $T < $dst/all_${S}-${T}.${T}.norm > $dst/all_${S}-${T}.${T}.tok  # do this for validation and test

# BPE
#if [ ! -f "../${S}.bpe" ]; then
#    python $P2/learn_bpe.py -s 20000 < all_${S}-${T}.${S}.tok > ../${S}.bpe
#fi
#if [ ! -f "../${T}.bpe" ]; then
#    python $P2/learn_bpe.py -s 20000 < all_${S}-${T}.${T}.tok > ../${T}.bpe
#fi

#python $P2/apply_bpe.py -c ../${S}.bpe < all_${S}-${T}.${S}.tok > all_${S}-${T}.${S}.tok.bpe  # do this for validation and test
#python $P2/apply_bpe.py -c ../${T}.bpe < all_${S}-${T}.${T}.tok > all_${S}-${T}.${T}.tok.bpe  # do this for validation and test

# shuffle 
# python $P1/shuffle.py all_${S}-${T}.${S}.tok.bpe all_${S}-${T}.${T}.tok.bpe all_${S}-${T}.${S}.tok all_${S}-${T}.${T}.tok

# build dictionary
python ./build_dictionary_char.py $dst/all_${S}-${T}.${S}.tok 
python ./build_dictionary_char.py $dst/all_${S}-${T}.${T}.tok 
#python $P1/build_dictionary_word.py all_${S}-${T}.${S}.tok.bpe &
#python $P1/build_dictionary_word.py all_${S}-${T}.${T}.tok.bpe &
