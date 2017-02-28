# ./mypreprocess.sh ../../data/bnhi/train/ train_ref.splitsort a
# python char2char/train_bi_char2char.py -max_epochs 10
cp models/bn_hi/bi-char2char.grads.*.best.npz prevmodels/len/
./mypreprocess.sh ../../data/bnhi/train/ train_ref.splitsort b
python char2char/train_bi_char2char.py -max_epochs 5 -re_load
cp models/bn_hi/bi-char2char.grads.*.best.npz prevmodels/len/
./mypreprocess.sh ../../data/bnhi/train/ train_ref.splitsort a
python char2char/train_bi_char2char.py -max_epochs 5 -re_load
cp models/bn_hi/bi-char2char.grads.*.best.npz prevmodels/len/
./mypreprocess.sh ../../data/bnhi/train/ train_ref.splitsort b
python char2char/train_bi_char2char.py -max_epochs 5 -re_load
cp models/bn_hi/bi-char2char.grads.*.best.npz prevmodels/len/
./mypreprocess.sh ../../data/bnhi/train/ train_ref.splitsort c
python char2char/train_bi_char2char.py -max_epochs 5 -re_load
cp models/bn_hi/bi-char2char.grads.*.best.npz prevmodels/len/
./mypreprocess.sh ../../data/bnhi/train/ train_ref.splitsort d
python char2char/train_bi_char2char.py -max_epochs 5 -re_load
cp models/bn_hi/bi-char2char.grads.*.best.npz prevmodels/len/
