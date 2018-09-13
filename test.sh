#!/bin/bash

set -exuo pipefail

VERBOSE="-v"

rm -rf a_dir a_file scrapyard
mkdir -p a_dir
echo "content" > a_file
echo "content" > a_dir/a_file
YARD=scrapyard

echo "** Search"

bin/scrapyard $VERBOSE search -k "key-#(a_file)" -y $YARD -p a_dir ||
    echo "SUCCESS"

echo "** Store/Search"

bin/scrapyard $VERBOSE store -k "key-#(a_file)" -y $YARD -p a_dir &&
    echo "SUCCESS"

bin/scrapyard $VERBOSE search -k "key-#(a_file)" -y $YARD -p a_dir &&
    echo "SUCCESS"

echo "** Multi Key Store/Junk/Search"

bin/scrapyard $VERBOSE store -k "key-#(a_file)","key" -y $YARD -p a_dir &&
    echo "SUCCESS"

bin/scrapyard $VERBOSE store -k "key" -y $YARD -p a_dir &&
    echo "SUCCESS"

bin/scrapyard $VERBOSE junk -k "key-#(a_file)" -y $YARD -p a_dir &&
    echo "SUCCESS"

bin/scrapyard $VERBOSE search -k "key-#(a_file)","key","k" -y $YARD -p a_dir &&
    echo "SUCCESS"

bin/scrapyard $VERBOSE crush -y $YARD &&
    echo "SUCCESS"
