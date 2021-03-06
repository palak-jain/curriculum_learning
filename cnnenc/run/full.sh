#!/bin/sh

# Indic preprocessing
# Upto 120-130 epochs
# Store result on validation set, use it to decide best model

# TODO
# Shuffle per epoch
# ppl ordering


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
max_epochs=100


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
    --restart=*)
    restart="${i#*=}"
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

if [ ! -d ${data} ]; then
    echo "Data path ${data} does not exist. Exitting.";
    exit 1;
fi

if [[ $restart == 1 ]]; then
    echo "Deleting existing models"
    rm -rf exp/${exp}
fi

# SET PATHS
model_path="exp/${exp}/model/"
trns_path="exp/${exp}/translation/"
res_path="exp/${exp}/results/"
log_path="exp/${exp}/log"
data="${data}/"
    
mkdir -p ${model_path} ${trns_path} ${res_path} ${log_path}

inpS="/processed/all_${S}-${T}.${S}.tok"
inpT="/processed/all_${S}-${T}.${T}.tok"

train_path="${data}/${S}${T}/train/"
dev_path="$data/$S$T/dev"
test_path="$data/$S$T/test"


# build dictionary
# ./prepdata.sh --data=${data} --sort=${sort} --refine=1

train_file="${train_path}/train_ref"
./preprocess/mypreprocess.sh ${train_path}/train_ref ${S} ${T}
# ./preprocess/build_dictionary_char.py ${train_path}/${inpS} > dict_src_size 
# ./preprocess/build_dictionary_char.py ${train_path}/${inpT} > dict_trgt_size

# prepare dev and test
./preprocess/mypreprocess.sh $test_path/test_ref ${S} ${T}  
./preprocess/mypreprocess.sh $dev_path/dev_ref ${S} ${T}  

# parameters
lr="0.0001"
max_epochs=130
maxlen=500
maxlen_trg=500
n_words_src=161
n_words_trgt=174

round=1

log_file=${log_path}/${round}.log

echo "==== ROUND $round : Training on $train_file ==== " 
echo "==== ROUND $round : Training on $train_file ==== " > $log_file
echo "PARAMETERS { lr: $lr | batch_size: $batch_size | patience: $patience | max_epochs: $max_epochs | maxlen: $maxlen |    maxlen_trg: $maxlen_trg } " >> $log_file
echo >> $log_file

python char2char/train_bi_char2char.py -learning_rate $lr -batch_size $batch_size -max_epochs $max_epochs \
-model_path $model_path -data_path $data -maxlen $maxlen -maxlen_trg $maxlen_trg -log_file_name ${log_file} \
-n_words_src $n_words_src -n_words_trgt $n_words_trgt -re_load -saveFreq=5 -validFreq=5 \
|| { echo "Train $train_file failed "; exit 1; } 


# ------------- DECODE 1 -------------

model=`ls $model_path/ctoc.[0-9]* |sort -nk 8|tail -n 2|head -n 1`
ep=`echo $model | sed 's/[^0-9]//g'`
echo " ==== DECODE for model $model ==== "
# test
python char2char/translate_char2char.py -model $model -saveto $trns_path/$ep.test.trns -source "$test_path/$inpS" 2> /dev/null
perl preprocess/multi-bleu.perl "$test_path/$inpT" < $trns_path/$ep.test.trns > $res_path/$ep.test.txt 2> /dev/null
# dev
python char2char/translate_char2char.py -model $model -saveto $trns_path/$ep.dev.trns -source "$dev_path/$inpS" 2> /dev/null
perl preprocess/multi-bleu.perl "$dev_path/$inpT" < $trns_path/$ep.dev.trns > $res_path/$ep.dev.txt 2> /dev/null


# ------------- DECODE 2 -------------
ep2=`python char2char/least_valid_err.py ${model_path} | cut -d' ' -f 1`
model=${model_path}/ctoc.${ep2}.npz

if [ $ep -eq $ep2]; then echo " ==== END OF SCRIPT $exp ==== "; exit 1; fi

echo " ==== DECODE for model $model ==== "
# test
python char2char/translate_char2char.py -model $model -saveto $trns_path/${ep2}.test.trns -source "$test_path/$inpS" 2> /dev/null
perl preprocess/multi-bleu.perl "$test_path/$inpT" < $trns_path/${ep2}.test.trns > $res_path/${ep2}.test.txt 2> /dev/null
# dev
python char2char/translate_char2char.py -model $model -saveto $trns_path/${ep2}.dev.trns -source "$dev_path/$inpS" 2> /dev/null
perl preprocess/multi-bleu.perl "$dev_path/$inpT" < $trns_path/${ep2}.dev.trns > $res_path/${ep2}.dev.txt 2> /dev/null

# ----------- End of Script ------------
echo " ==== END OF SCRIPT $exp ==== ";
