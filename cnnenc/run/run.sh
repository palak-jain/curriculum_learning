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
    -l=*|--lr=*)
    learning_rate="${i#*=}"
    shift # past argument=value
    ;;
    --dec_dim=*)
    dec_dim="${i#*=}"
    shift # past argument=value
    ;;
    --enc_dim=*)
    enc_dim="${i#*=}"
    shift # past argument=value
    ;;
    --batch_size=*)
    batch_size="${i#*=}"
    shift # past argument=value
    ;;
    --dropout_softmax=*)
    dropout_softmax="${i#*=}"
    shift # past argument=value
    ;;
    --dropout_gru=*)
    dropout_gru="${i#*=}"
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

# aa
# x=aa
./preprocess/mypreprocess.sh "$data/$S$T/train/" train_ref.$x.$S train_ref.$x.$T 2> /dev/null
./preprocess/mypreprocess.sh "$data/$S$T/dev/" dev_ref.$x.$S dev_ref.$x.$T 2> /dev/null

python char2char/train_bi_char2char.py -learning_rate 0.0005 -batch_size 16 -max_epochs 11 -model_path $model_path -data_path $data -maxlen 500 -maxlen_trg 500

# ab
x=ab
./preprocess/mypreprocess.sh "$data/$S$T/train/" train_ref.$x.$S train_ref.$x.$T 2> /dev/null
# ./preprocess/mypreprocess.sh "$data/$S$T/dev/" dev_ref.$x.$S dev_ref.$x.$T 2> /dev/null

python char2char/train_bi_char2char.py -learning_rate 0.0005 -batch_size 64 -max_epochs 11 -model_path $model_path -data_path $data -maxlen 500 -maxlen_trg 500 -re_load

# ac
x=ac
./preprocess/mypreprocess.sh "$data/$S$T/train/" train_ref.$x.$S train_ref.$x.$T 2> /dev/null
./preprocess/mypreprocess.sh "$data/$S$T/dev/" dev_ref.$S dev_ref.$T 2> /dev/null  # keep this now

python char2char/train_bi_char2char.py -learning_rate 0.0001 -batch_size 64 -max_epochs 11 -model_path $model_path -data_path $data -maxlen 500 -maxlen_trg 500 -re_load

# abc
pre=$data/$S$T/train/train_ref
cat $pre.aa.$S $pre.ab.$S $pre.ac.$S > $pre.abc.$S
cat $pre.aa.$T $pre.ab.$T $pre.ac.$T > $pre.abc.$T

./preprocess/mypreprocess.sh "$data/$S$T/train/" train_ref.abc.$S train_ref.abc.$T 2> /dev/null

python char2char/train_bi_char2char.py -learning_rate 0.0001 -batch_size 64 -max_epochs 11 -model_path $model_path -data_path $data -maxlen 500 -maxlen_trg 500 -re_load

# all
./preprocess/mypreprocess.sh "$data/$S$T/train/" train_ref.$S train_ref.$T 2> /dev/null

python char2char/train_bi_char2char.py -learning_rate 0.0001 -batch_size 64 -max_epochs 21 -model_path $model_path -data_path $data -maxlen 500 -maxlen_trg 500 -re_load

# python char2char/train_bi_char2char.py -learning_rate $lr -enc_dim $enc_dim -dec_dim $dec_dim -batch_size $batch_size -dropout_gru $dropout_gru -dropout_softmax $dropout_softmax -max_epochs $max_epochs -model_path $model_path -data_path $data_path

# mkdir -p prevmodels/bn_hi/$exp
# mv $model_path/* prevmodels/bn_hi/$exp/

# decode
./preprocess/mypreprocess "$data/$S$T/test/" test_ref.$S test_ref.$T
python char2char/translate_char2char.py -model $model_path/bi-char2char.grads.npz -saveto translation/"$exp".txt

# eval
perl preprocess/multi-bleu.perl $data/$S$T/test/test_ref.$T < translation/"$exp".txt > result/"$exp."txt



