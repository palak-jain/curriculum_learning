#!/bin/sh


# No preprocessing
# Check on entire validation set, employ early stop
# Store result on validation set, use it to decide best model
# Data partition schemes: a, b, c, d


# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize datapaths:
data="/home/development/palak/curriculum/data/"
exp=`date|cut -f 2,3,4 -d ' '|tr ' ' '_'`
S="bn"
T="hi"
model_path="models/split/"


# Experiment params
lr="0.0001"
enc_dim=512
dec_dim=512
batch_size=64
dropout_gru=1
dropout_softmax=1
max_epochs=25


for i in "$@"
do
case $i in
    -d=*|--data=*)
    data="${i#*=}"
    shift # past argument=value
    ;;
    -e=*|--exp=*)
    exp="${i#*=}"
    shift # past argument=value
    ;;
    --max_epochs=*)
    max_epochs="${i#*=}"
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
echo "DATA PATH  = ${data}"
echo "EXPERIMENT  = ${exp}"

# ./prepdata.sh --data=${data} --sort=${sort} --refine=1
mkdir -p exp/${exp}/model/ exp/${exp}/translation/ exp/${exp}/results/
model_path="models/${exp}/"
# model_path="exp/${exp}/model/"
trns_path="exp/${exp}/translation/"
res_path="exp/${exp}/results/"

inpS="processed/all_${S}-${T}.${S}.tok"
inpT="processed/all_${S}-${T}.${T}.tok"

train_path="${data}/${S}${T}/train/"
dev_path="$data/$S$T/dev"
test_path="$data/$S$T/test"

# prepare dev and test
cp "$test_path/test_ref.$S" "$test_path/$inpS"   
cp "$test_path/test_ref.$T" "$test_path/$inpT"

cp "$dev_path/dev_ref.$S" "$dev_path/$inpS"   
cp "$dev_path/dev_ref.$T" "$dev_path/$inpT"

# prepare for training 

# a

# parameters
lr=0.0005
batch_size=64
patience=1
max_epochs=100
maxlen=500
maxlen_trg=500

round=1
for x in 'ab' 'ac' 'ad' 'ae';   # ADD aa
do
    train_file="$train_path/train_ref.$x"
    cp "$train_file.$S" "$train_path/$inpS"   
    cp "$train_file.$T" "$train_path/$inpT"   


    echo "==== ROUND $round : Training on $train_file ==== " > $model_path/valid_err.txt
    echo "PARAMETERS { lr: $lr | batch_size: $batch_size | patience: $patience | max_epochs: $max_epochs | maxlen: $maxlen |    maxlen_trg: $maxlen_trg } " 
    echo " ----------------------------- "

    python char2char/train_bi_char2char.py -learning_rate $lr -batch_size $batch_size -patience $patience -max_epochs $max_epochs -model_path $model_path -data_path $data -maxlen $maxlen -maxlen_trg $maxlen_trg -re_load || { echo "Train $train_file failed "; exit 1; }
    
    echo > $model_path/valid_err.txt
    round=${round+1}
done


# ------------- DECODE 1 -------------
model=`ls $model_path/c2c.grads.[0-9]* |sort -nk 8|tail -n 2|head -n 1`
ep=`echo $model | sed 's/[^0-9]//g'`
echo " ==== DECODE for model $model ==== "
# test
python char2char/translate_char2char.py -model $model -saveto $trns_path/$ep.trns -source "$test_path/$inpS"
perl preprocess/multi-bleu.perl "$test_path/$inpT" < $trns_path/$ep.test.trns > $res_path/$ep.test.txt
# dev
python char2char/translate_char2char.py -model $model -saveto $trns_path/$ep.trns -source "$dev_path/$inpS"
perl preprocess/multi-bleu.perl "$dev_path/$inpT" < $trns_path/$ep.dev.trns > $res_path/$ep.dev.txt

# ------------- DECODE 2 -------------
model=`ls $model_path/c2c.grads.[0-9]* |sort -nk 8|tail -n 3|head -n 1`
ep=`echo $model | sed 's/[^0-9]//g'`
echo " ==== DECODE for model $model ==== "
# test
python char2char/translate_char2char.py -model $model -saveto $trns_path/$ep.trns -source "$test_path/$inpS"
perl preprocess/multi-bleu.perl "$test_path/$inpT" < $trns_path/$ep.test.trns > $res_path/$ep.test.txt
# dev
python char2char/translate_char2char.py -model $model -saveto $trns_path/$ep.trns -source "$dev_path/$inpS"
perl preprocess/multi-bleu.perl "$dev_path/$inpT" < $trns_path/$ep.dev.trns > $res_path/$ep.dev.txt


