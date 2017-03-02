#!/bin/bash

# usage : ./preprocess/mypreprocess.sh filepath src trgt

# source language (example: fr)
S=$2
# target language (example: en)
T=$3

if [ $# -lt 3 ]; then
    echo "usage : ./preprocess/mypreprocess.sh filepath src_lang trgt_lang"
    exit 1;
fi

# path to data
file=$1
src=${file}.${S}
trgt=${file}.${T}
mkdir -p $data/processed
rm -rf $data/processed/*tok

data=`echo ${file} | sed 's:[^\/]*$::'`

# normalize
python ./preprocess/indic_normalize.py ${src} ${data}/processed/all_${S}-${T}.${S}.norm  ${S}
python ./preprocess/indic_normalize.py ${trgt} ${data}/processed/all_${S}-${T}.${T}.norm  ${T}

# tokenize
python ./preprocess/indic_tokenize.py  $data/processed/all_${S}-${T}.${S}.norm  $data/processed/all_${S}-${T}.${S}.tok ${S}
python ./preprocess/indic_tokenize.py $data/processed/all_${S}-${T}.${T}.norm $data/processed/all_${S}-${T}.${T}.tok ${T} 

rm $data/processed/*.norm
