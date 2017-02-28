#!/bin/sh

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
    -m=*|--model=*)
    model_path="${i#*=}"
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
echo "MODEL PATH  = ${model_path}"
echo "EXPERIMENT  = ${exp}"

# ./prepdata.sh --data=${data} --sort=${sort} --refine=1


# files=`ls -C $data/$S$T/$mode/`
# echo "Enter training file ... $files"
# read x; read y;

# a
x=aa
./preprocess/mypreprocess.sh "$data/$S$T/train/" train_ref.$x.$S train_ref.$x.$T 2> /dev/null
./preprocess/mypreprocess.sh "$data/$S$T/dev/" dev_ref.$x.$S dev_ref.$x.$T 2> /dev/null

python char2char/train_bi_char2char.py -learning_rate 0.0005 -batch_size 16 -patience 1 -max_epochs 100 -model_path $model_path -data_path $data -maxlen 500 -maxlen_trg 500    # changed to 250

# b
x=ab
./preprocess/mypreprocess.sh "$data/$S$T/train/" train_ref.$x.$S train_ref.$x.$T 2> /dev/null
# ./preprocess/mypreprocess.sh "$data/$S$T/dev/" dev_ref.$x.$S dev_ref.$x.$T 2> /dev/null

python char2char/train_bi_char2char.py -learning_rate 0.0005 -batch_size 16 -patience 1 -max_epochs 100 -model_path $model_path -data_path $data -maxlen 500 -maxlen_trg 500 -re_load

pre=$data/$S$T/train/train_ref

# ab
cat $pre.aa.$S $pre.ab.$S > $pre.aab.$S
cat $pre.aa.$T $pre.ab.$T > $pre.aab.$T
x=aab
./preprocess/mypreprocess.sh "$data/$S$T/train/" train_ref.$x.$S train_ref.$x.$T 2> /dev/null
./preprocess/mypreprocess.sh "$data/$S$T/dev/" dev_ref.$S dev_ref.$T 2> /dev/null  # keep all dev from now

python char2char/train_bi_char2char.py -learning_rate 0.0001 -batch_size 16 -patience 2 -max_epochs 100 -model_path $model_path -data_path $data -maxlen 500 -maxlen_trg 500 -re_load

# abc
cat $pre.aab.$S  $pre.ac.$S > $pre.abc.$S
cat $pre.aab.$T  $pre.ac.$T > $pre.abc.$T

./preprocess/mypreprocess.sh "$data/$S$T/train/" train_ref.abc.$S train_ref.abc.$T 2> /dev/null

python char2char/train_bi_char2char.py -learning_rate 0.0001 -batch_size 64 -patience 3 -max_epochs 100 -model_path $model_path -data_path $data -maxlen 500 -maxlen_trg 500 -re_load

# all
./preprocess/mypreprocess.sh "$data/$S$T/train/" train_ref.$S train_ref.$T 2> /dev/null

python char2char/train_bi_char2char.py -learning_rate 0.0001 -batch_size 64 -patience 3 -max_epochs 100 -model_path $model_path -data_path $data -maxlen 500 -maxlen_trg 500 -re_load


./preprocess/mypreprocess "$data/$S$T/test/" test_ref.$S test_ref.$T

# ------------- DECODE 1 -------------
model=`ls models/split/bi-char2char.grads.[0-9]* |sort -nk 8|tail -n 2|head -n 1`
ep=`sed 's/[^0-9]//g'`

python char2char/translate_char2char.py -model $model -saveto translation/"$exp".trns -source "$data/$S$T/test/processed/all_bn-hi.bn.tok"

# eval
perl preprocess/multi-bleu.perl $data/$S$T/test/test_ref.$T < translation/"$exp"_$ep.trns > results/"$exp"_$ep.txt

# ------------- DECODE 2 -------------
model=`ls models/split/bi-char2char.grads.[0-9]* |sort -nk 8|tail -n 2|head -n 1`
ep=`sed 's/[^0-9]//g'`

python char2char/translate_char2char.py -model $model -saveto translation/"$exp".trns -source "$data/$S$T/test/processed/all_bn-hi.bn.tok"

# eval
perl preprocess/multi-bleu.perl $data/$S$T/test/test_ref.$T < translation/"$exp"_$ep.trns > results/"$exp"_$ep.txt



