#!/bin/bash
#
# Script to download and preprocess the NIPS, 20 Newsgroups, Reuters and
# Wikipedia corpora
#
ROOTPATH=`pwd`
THIRDPARTYPATH=$ROOTPATH/3rdParty
DATAPATH=$ROOTPATH/data
mkdir -p $DATAPATH
WIKIDUMPEN="http://dumps.wikimedia.org/enwiki/20161101/enwiki-20161101-pages-articles.xml.bz2"
WIKILINKEN="http://dumps.wikimedia.org/enwiki/20160204/enwiki-20160204-langlinks.sql.gz"
WIKITITLEEN="https://dumps.wikimedia.org/enwiki/20160204/enwiki-20160204-page_props.sql.gz"

NIPS=false
REUTERS=false
TWENTYNG=false
WIKIPEDIA=false
WIKIPEDIAEN=false
WIKI2TEXT=false
while getopts ":abcnrtwe" opt; do
    case $opt in
        a)
            NIPS=true
            REUTERS=true
            TWENTYNG=true
            WIKIPEDIA=true
            WIKI2TEXT=true
            ;;
        b)
            WIKI2TEXT=true
            ;;
        n)
            NIPS=true
        ;;
        r)
            REUTERS=true
        ;;
        t)
            TWENTYNG=true
        ;;
        w)
            WIKIPEDIA=true
        ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

if [ ! -f $DATAPATH/stopwords_english.txt ]; then
    echo "Downloading stopwords"
    wget -qO- -O $DATAPATH/stopwords_english.txt \
         https://raw.githubusercontent.com/pan-webis-de/authorid/master/data/stopwords_english.txt
fi

if $NIPS; then
    echo "Preparing NIPS corpus"
    mkdir -p $DATAPATH
    echo "Downloading NIPS corpus"
    wget -qO- -O $DATAPATH/tmp.zip \
         http://arbylon.net/projects/nips/nips-20110223.zip
    unzip $DATAPATH/tmp.zip -d $DATAPATH/
    rm $DATAPATH/tmp.zip
    echo "Done processing NIPS corpus"
fi

if $REUTERS; then
    echo "Preparing Reuters"
    mkdir -p $DATAPATH/reuters
    echo -n "Enter path of Reuters dataset: "
    read REUTERSPATH

    echo "Preprocessing and generating vectors"
    python python/reuters/reuters2corpus.py \
           $REUTERSPATH \
           $DATAPATH/stopwords_english.txt \
           $DATAPATH/reuters
    echo "Done processing Reuters corpus"
fi

if $TWENTYNG; then
    echo "Preparing 20 newsgroups corpus"
    mkdir -p $DATAPATH/20newsgroups
    python python/20newsgroups/20ng2corpus.py \
           $DATAPATH/stopwords_english.txt \
           $DATAPATH/20newsgroups
    echo "Done processing 20 newsgroups corpus"
fi

if $WIKI2TEXT; then
    if ! command -v nim >/dev/null 2>&1; then 
       mkdir -p $THIRDPARTYPATH

       echo "Installing Nim"
       git clone git://github.com/nim-lang/Nim.git $THIRDPARTYPATH/Nim
       cd $THIRDPARTYPATH/Nim
       git clone --depth 1 git://github.com/nim-lang/csources
       cd csources
       sh build.sh
       cd ..
       bin/nim c koch
       ./koch boot -d:release
       export PATH=$PATH:$THIRDPARTYPATH/Nim/bin

       echo "Done installing Nim"
   fi

    echo "Installing wiki2text"
    git clone https://github.com/rspeer/wiki2text.git $THIRDPARTYPATH/wiki2text
    cd $THIRDPARTYPATH/wiki2text
    make
fi

if $WIKIPEDIA; then
    echo "Preparing Wikipedia"    
    mkdir -p $DATAPATH/wikipedia

    if [ ! -f $DATAPATH/wikipedia/wikien.xml.bz2 ]; then
        echo "Downloading Wikipedia dump"
        wget -qO- -O $DATAPATH/wikipedia/wikien.xml.bz2 \
             $WIKIDUMPEN
    fi
    
    echo "Uncompressing and parsing Wikipedia dump"
    bunzip2 -c $DATAPATH/wikipedia/wikien.xml.bz2 \
        | $THIRDPARTYPATH/wiki2text/wiki2text > $DATAPATH/wikipedia/enwiki.txt

    echo "Genereting BOWs"
    python $ROOTPATH/python/wikipedia/wiki2corpus.py \
           $DATAPATH/wikipedia/enwiki.txt \
           --split train 80 \
           --split test 20 \
           --odir $DATAPATH/wikipedia/ \
           --stop-words $DATAPATH/stopwords_english.txt \
           --cutoff 10 \
           --corpus wikien

    echo "Done processing Wikipedia corpus"
fi

if $WIKIPEDIAEN; then
    echo "Preparing Wikipedia"    
    mkdir -p $DATAPATH/wikipedia

    if [ ! -f $DATAPATH/wikipedia/wikien.xml.bz2 ]; then
        echo "Downloading Wikipedia dump"
        wget -qO- -O $DATAPATH/wikipedia/wikien.xml.bz2 \
             $WIKIDUMPEN
    fi

  	if [ ! -f $DATAPATH/wikipedia/wikien.sql.gz ]; then
        echo "Downloading Wikipedia link"
        wget -qO- -O $DATAPATH/wikipedia/wikien.sql.gz \
             $WIKILINKEN
    fi


  	if [ ! -f $DATAPATH/wikipedia/wikien.title.gz ]; then
        echo "Downloading Wikipedia link"
        wget -qO- -O $DATAPATH/wikipedia/wikien.title.gz \
             $WIKITITLEEN
    fi


    echo "Uncompressing and parsing Wikipedia dump"
    bunzip2 -c $DATAPATH/wikipedia/wikien.xml.bz2 \
        | $THIRDPARTYPATH/wiki2text/wiki2text > $DATAPATH/wikipedia/enwiki.txt

    echo "Genereting BOWs"
    python $ROOTPATH/python/wikipedia/wiki2corpus.py \
           $DATAPATH/wikipedia/enwiki.txt \
           --split train 80 \
           --split test 20 \
           --odir $DATAPATH/wikipedia/ \
           --stop-words $DATAPATH/stopwords_english.txt \
           --cutoff 10 \
           --corpus wikien

    echo "Done processing Wikipedia corpus"
fi
