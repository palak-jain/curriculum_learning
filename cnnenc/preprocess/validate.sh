#!/bin/sh

# path to nematus ( https://www.github.com/rsennrich/nematus )
nematus=/home/development/ajayanand/NMT/rsennrich/nematus

# path to moses decoder: https://github.com/moses-smt/mosesdecoder
mosesdecoder=/usr/local/bin/smt/mosesdecoder-3.0

#model prefix
prefix=${parent}model/model.npz # todo : using argument #

#dev=data/newsdev2016.bpe.ro # todo: using argument/ may try using export in master script
#ref=data/newsdev2016.tok.en # todo: using argument

# decode
THEANO_FLAGS=mode=FAST_RUN,floatX=float32,device=$device,on_unused_input=warn python $nematus/nematus/translate.py \
     -m $prefix.dev.npz \
     -i $dev_val \
     -o $dev_val.output.dev \
     -k 12 -n -p 1


./postprocess-dev.sh < ${dev_val}.output.dev > ${dev_val}.output.postprocessed.dev 

## get BLEU for validation
BEST=`cat ${prefix}_best_bleu || echo 0`
$mosesdecoder/scripts/generic/multi-bleu.perl $ref_val < $dev_val.output.postprocessed.dev >> ${prefix}_bleu_scores # Relative path
$mosesdecoder/scripts/generic/multi-bleu.perl $ref_val < $dev_val.output.postprocessed.dev >> ${parent}results/validation_bleu_scores # Relative path
BLEU=`$mosesdecoder/scripts/generic/multi-bleu.perl $ref_val < $dev_val.output.postprocessed.dev | cut -f 3 -d ' ' | cut -f 1 -d ','` #extracting blue score
BETTER=`echo "$BLEU > $BEST" | bc`


# get BLEU for testing
THEANO_FLAGS=mode=FAST_RUN,floatX=float32,device=$device,on_unused_input=warn python $nematus/nematus/translate.py \
     -m $prefix.dev.npz \
     -i $in_test \
     -o $test.output \
     -k 12 -n -p 1

./postprocess-dev.sh < $test.output > $test.output.postprocessed #TODO: postprocess as per new bpe scheme

BLEU_tst=`$mosesdecoder/scripts/generic/multi-bleu.perl $out_test < $test.output.postprocessed | cut -f 3 -d ' ' | cut -f 1 -d ','` #extracting blue score

$mosesdecoder/scripts/generic/multi-bleu.perl $out_test < $test.output.postprocessed >> ${parent}results/test_bleu_scores # Relative path
echo $BLEU_tst >> ${prefix}_test_blue_scores

echo "Validation BLEU = $BLEU"
echo "Testing BLEU = $BLEU_tst"

# save model with highest validation BLEU
if [ "$BETTER" = "1" ]; then
  echo "new best; saving"
  echo $BLEU > ${prefix}_best_bleu
  cp ${prefix}.dev.npz ${prefix}.best_bleu
fi

