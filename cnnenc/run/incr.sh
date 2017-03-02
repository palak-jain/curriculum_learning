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
restart=0

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

if [ $restart -eq "1" ]; then
    echo "Deleting existing models"
    rm -rf exp/${exp}
fi

# SET PATHS
model_path="exp/${exp}/model/"
trns_path="exp/${exp}/translation/"
res_path="exp/${exp}/results/"
log_path="exp/${exp}/log"

mkdir -p ${model_path} ${trns_path} ${res_path} ${log_path}

inpS="/processed/all_${S}-${T}.${S}.tok"
inpT="/processed/all_${S}-${T}.${T}.tok"

train_path="${data}/${S}${T}/train/"
dev_path="$data/$S$T/dev"
test_path="$data/$S$T/test"


# # build dictionary
# ./prepdata.sh --data=${data} --sort=${sort} --refine=1
# ./preprocess/mypreprocess.sh ${train_path}/train_ref ${S} ${T}
# n_words_src=`./preprocess/build_dictionary_char.py ${train_path}/${inpS}`
# n_words_trgt=`./preprocess/build_dictionary_char.py ${train_path}/${inpT}`

# prepare dev and test
./preprocess/mypreprocess.sh $test_path/test_ref ${S} ${T}  
./preprocess/mypreprocess.sh $dev_path/dev_ref ${S} ${T}  

# get train files
cat $train_path/train_ref.aa.${S} $train_path/train_ref.ab.${S} > $train_path/train_ref.aab.${S}
cat $train_path/train_ref.aab.${S} $train_path/train_ref.ac.${S} > $train_path/train_ref.abc.${S}
cat $train_path/train_ref.abc.${S} $train_path/train_ref.ad.${S} > $train_path/train_ref.abcd.${S}
cat $train_path/train_ref.abcd.${S} $train_path/train_ref.ae.${S} > $train_path/train_ref.abcde.${S}

cat $train_path/train_ref.aa.${T} $train_path/train_ref.ab.${T} > $train_path/train_ref.aab.${T}
cat $train_path/train_ref.aab.${T} $train_path/train_ref.ac.${T} > $train_path/train_ref.abc.${T}
cat $train_path/train_ref.abc.${T} $train_path/train_ref.ad.${T} > $train_path/train_ref.abcd.${T}
cat $train_path/train_ref.abcd.${T} $train_path/train_ref.ae.${T} > $train_path/train_ref.abcde.${T}

# parameters
lr="0.0001"
batch_size=64
max_epochs=300
maxlen=500
maxlen_trg=500
n_words_src=161
n_words_trgt=174

round=1

# ROUND 1 ............ aa
patience=1
max_epochs=70

x="aa"

train_file="$train_path/train_ref.$x"
log_file="${log_path}/${round}.log"

./preprocess/mypreprocess.sh ${train_file} ${S} ${T}  

echo "==== ROUND $round : Training on $train_file ==== " 
#echo "==== ROUND $round : Training on $train_file ==== " > $log_file
#echo "PARAMETERS { lr: $lr | batch_size: $batch_size | patience: $patience | max_epochs: $max_epochs | maxlen: $maxlen |    #maxlen_trg: $maxlen_trg } " >> $log_file
#echo >> $log_file

#python char2char/train_bi_char2char.py -learning_rate $lr -batch_size $batch_size -patience $patience -max_epochs $max_epochs \
#-model_path $model_path -data_path $data -maxlen $maxlen -maxlen_trg $maxlen_trg -log_file_name ${log_file} \
#-n_words_src $n_words_src -n_words_trgt $n_words_trgt -re_load \
#|| { echo "Train $train_file failed "; exit 1; } 


# Rest .......................

patience=1
max_epochs=300

for x in 'aab' 'abc' 'abcd' 'abcde';   
do
    
    round=$((round+1))
    train_file="$train_path/train_ref.$x"
    log_file="${log_path}/${round}.log"

    ./preprocess/mypreprocess.sh ${train_file} ${S} ${T}  

    echo "==== ROUND $round : Training on $train_file ==== " 
    echo "==== ROUND $round : Training on $train_file ==== " > $log_file
    echo "PARAMETERS { lr: $lr | patience: $patience | max_epochs: $max_epochs | maxlen: $maxlen | maxlen_trg: $maxlen_trg } " >> $log_file
    echo >> $log_file

    python char2char/train_bi_char2char.py -learning_rate $lr -patience $patience -max_epochs $max_epochs \
    -model_path $model_path -data_path $data -maxlen $maxlen -maxlen_trg $maxlen_trg -log_file_name ${log_file} \
    -n_words_src $n_words_src -n_words_trgt $n_words_trgt -re_load \
    || { echo "Train $train_file failed "; exit 1; } 

done

rm $train_path/train_ref.abc* $train_path/train_ref.aab

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