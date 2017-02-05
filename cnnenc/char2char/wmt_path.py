#!/usr/bin/python
# Paths to training / valid / test corpus & dictionaries
# For the bilingual models

bnhi={
    "dic": [
                ["bnhi/train/processed/all_bn-hi.bn.tok.pkl",
                 "bnhi/train/processed/all_bn-hi.hi.tok.pkl",],

                ["bnhi/train/processed/all_bn-hi.bn.tok.bpe.word.pkl"],
            ],

    "train": [
                ["bnhi/train/processed/all_bn-hi.bn.tok",
                 "bnhi/train/processed/all_bn-hi.hi.tok",],

                ["bnhi/train/processed/all_bn-hi.bn.tok.bpe.shuf",
                 "bnhi/train/processed/all_bn-hi.hi.tok.bpe.shuf",],
            ],

    "dev": [
                ["bnhi/dev/processed/all_bn-hi.bn.tok",
                 "bnhi/dev/processed/all_bn-hi.hi.tok",],

                ["bnhi/dev/processed/all_bn-hi.bn.tok.bpe",
                 "bnhi/dev/processed/all_bn-hi.hi.tok.bpe",],
            ],

    "test1" :[
                ["bnhi/test/processed/all_bn-hi.bn.tok",
                 "bnhi/test/processed/all_bn-hi.hi.tok",],

                ["bnhi/test/newstest2014-bnhi-ref.bn.tok.bpe",
                 "bnhi/test/newstest2014-bnhi-src.hi.tok.bpe",],
            ],

    "test2":[
                ["bnhi/test2/processed/all_bn-hi.bn.tok",
                 "bnhi/test2/processed/all_bn-hi.hi.tok",],

                ["bnhi/test/newstest2015-bnhi-ref.bn.tok.bpe",
                 "bnhi/test/newstest2015-bnhi-src.hi.tok.bpe",],
            ],
}

deen={
    "dic": [
                ["deen/train/all_de-en.de.tok.304.pkl",
                 "deen/train/all_de-en.en.tok.300.pkl",],

                ["deen/train/all_de-en.de.tok.bpe.word.pkl"],
            ],

    "train": [
                ["deen/train/all_de-en.de.tok.shuf",
                 "deen/train/all_de-en.en.tok.shuf",],

                ["deen/train/all_de-en.de.tok.bpe.shuf",
                 "deen/train/all_de-en.en.tok.bpe.shuf",],
            ],

    "dev": [
                ["deen/dev/newstest2013.de.tok",
                 "deen/dev/newstest2013.en.tok",],

                ["deen/dev/newstest2013.de.tok.bpe",
                 "deen/dev/newstest2013.en.tok.bpe",],
            ],

    "test1" :[
                ["deen/test/newstest2014-deen-ref.de.tok",
                 "deen/test/newstest2014-deen-src.en.tok",],

                ["deen/test/newstest2014-deen-ref.de.tok.bpe",
                 "deen/test/newstest2014-deen-src.en.tok.bpe",],
            ],

    "test2":[
                ["deen/test/newstest2015-deen-ref.de.tok",
                 "deen/test/newstest2015-deen-src.en.tok",],

                ["deen/test/newstest2015-deen-ref.de.tok.bpe",
                 "deen/test/newstest2015-deen-src.en.tok.bpe",],
            ],
}

csen={

    "dic":[
                ["csen/train/all_cs-en.cs.tok.304.pkl",
                 "csen/train/all_cs-en.en.tok.300.pkl",],

                ["csen/train/all_cs-en.cs.tok.bpe.word.pkl"],
            ],

    "train":[
                ["csen/train/all_cs-en.cs.tok",
                 "csen/train/all_cs-en.en.tok",],

                ["csen/train/all_cs-en.cs.tok.bpe",
                 "csen/train/all_cs-en.en.tok.bpe",],
            ],

    "dev": [
                ["csen/dev/newstest2013-ref.cs.tok",
                 "csen/dev/newstest2013-src.en.tok",],

                ["csen/dev/newstest2013-ref.cs.tok.bpe",
                 "csen/dev/newstest2013-src.en.tok.bpe",],
            ],

    "test1":[
                ["csen/test/newstest2014-csen-ref.cs.tok",
                 "csen/test/newstest2014-csen-src.en.tok",],

                ["csen/test/newstest2014-csen-ref.cs.tok.bpe",
                 "csen/test/newstest2014-csen-src.en.tok.bpe",],
        ],

    "test2":[
                ["csen/test/newstest2015-csen-ref.cs.tok",
                 "csen/test/newstest2015-csen-src.en.tok",],

                ["csen/test/newstest2015-csen-ref.cs.tok.bpe",
                 "csen/test/newstest2015-csen-src.en.tok.bpe",],
        ]
}

fien={
    "dic":[
                ["fien/train/all_fi-en.fi.tok.304.pkl",
                 "fien/train/all_fi-en.en.tok.300.pkl",],

                ["fien/train/all_fi-en.fi.tok.bpe.word.pkl"],
        ],

    "train":[
                ["fien/train/all_fi-en.fi.tok",
                 "fien/train/all_fi-en.en.tok",],

                ["fien/train/all_fi-en.fi.tok.bpe",
                 "fien/train/all_fi-en.en.tok.bpe",],
        ],

    "dev":[
                ["fien/dev/newsdev2015-enfi-ref.fi.tok",
                 "fien/dev/newsdev2015-enfi-src.en.tok",],

                ["fien/dev/newsdev2015-enfi-ref.fi.tok.bpe",
                 "fien/dev/newsdev2015-enfi-src.en.tok.bpe",],
        ],

    "test1":[
                ["fien/test/newstest2015-fien-ref.fi.tok",
                 "fien/test/newstest2015-fien-src.en.tok",],

                ["fien/test/newstest2015-fien-ref.fi.tok.bpe",
                 "fien/test/newstest2015-fien-src.en.tok.bpe",],
        ],
}

ruen={

    "dic":[
                ["ruen/train/all_ru-en.ru.tok.304.pkl",
                 "ruen/train/all_ru-en.en.tok.300.pkl",],

                ["ruen/train/all_ru-en.ru.tok.bpe.word.pkl"],
        ],

    "train":[
                ["ruen/train/all_ru-en.ru.tok",
                 "ruen/train/all_ru-en.en.tok",],

                ["ruen/train/all_ru-en.ru.tok.bpe",
                 "ruen/train/all_ru-en.en.tok.bpe",],
        ],

    "dev":[
                ["ruen/dev/newstest2013-ref.ru.tok",
                 "ruen/dev/newstest2013-src.en.tok",],

                ["ruen/dev/newstest2013-ref.ru.tok.bpe",
                 "ruen/dev/newstest2013-src.en.tok.bpe",],
        ],

    "test1":[
                ["ruen/test/newstest2014-ruen-ref.ru.tok",
                 "ruen/test/newstest2014-ruen-src.en.tok",],

                ["ruen/test/newstest2014-ruen-ref.ru.tok.bpe",
                 "ruen/test/newstest2014-ruen-src.en.tok.bpe",],
        ],

    "test2":[
                ["ruen/test/newstest2015-ruen-ref.ru.tok",
                 "ruen/test/newstest2015-ruen-src.en.tok",],

                ["ruen/test/newstest2015-ruen-ref.ru.tok.bpe",
                 "ruen/test/newstest2015-ruen-src.en.tok.bpe",],
        ]
}

manyen = {
    "dic":[
            ["char-source-for-dic.300.pkl",
             "char-target-for-dic.300.pkl"],

            ["bpe-source-for-dic.word.pkl"]
        ]
}

wmts = dict()
wmts["bn_hi"] = bnhi
wmts["de_en"] = deen
wmts["cs_en"] = csen
wmts["fi_en"] = fien
wmts["ru_en"] = ruen
wmts["many_en"] = manyen