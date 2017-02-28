#!/bin/sh

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize datapaths:
data="/home/development/palak/curriculum/data/"
exp=`date|cut -f 2,3,4 -d ' '|tr ' ' '_'`
S="bn"
T="hi"
model_path="models/"



for i in "$@"
do
case $i in
    -d=*|--data=*)
    data="${i#*=}"
    shift # past argument=value
    ;;
    -r=*|--refine=*)
    refine="${i#*=}"
    shift # past argument=value
    ;;
    --sort=*)
    sort="${i#*=}"
    shift # past argument=value
    ;;
    --split=*)
    split="${i#*=}"
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

modes=["train" "test" "dev"]

echo "---- DATA PATH ${data} ----"

if [ $refine -eq "1" ]; then
	echo "---- REFINE DATA ----";
	for mode in "train" "test" "dev"
	do
		./preprocess/refine.sh $data/$S$T/$mode/$mode
	done
fi

if [ $sort ]; then  # no split
		echo "---- SORT DATA by $sort and SPLIT IN $split ----" ;
        if [ $split ]
		./preprocess/sort.sh --file="$data/$S$T/train/train_ref" --split=10000 --sort=$sort 
		./preprocess/sort.sh --file="$data/$S$T/test/test_ref" --split=500 --sort=2 #$sort 
		./preprocess/sort.sh --file="$data/$S$T/dev/dev_ref" --split=1000 --sort=2 #$sort 
fi 
    
#  add for not sort option

# echo "---- PREPROCESS ----"

# for mode in "train" "dev" "test"
# do
# 	./preprocess/mypreprocess.sh "$data/$S$T/$mode/" final.$S final.$T 2> /dev/null
# done



	