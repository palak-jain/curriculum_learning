#/bin/sh

# path to moses decoder: https://github.com/moses-smt/mosesdecoder
mosesdecoder=/usr/local/bin/smt/mosesdecoder-3.0

# suffix of target language files
lng=$1 #todo using argument /try using export using master script

sed 's/\@\@ //g' | \
$mosesdecoder/scripts/recaser/detruecase.perl
