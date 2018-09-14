#!/bin/bash

set -exuo pipefail

VERBOSE="-v"

rm -rf a_dir a_file scrapyard
mkdir -p a_dir
echo "content" > a_file
echo "content" > a_dir/a_file
YARD=scrapyard
SCRAPYARD=bin/scrapyard

echo "** Search"

$SCRAPYARD $VERBOSE search -k "key-#(a_file)" -y $YARD -p a_dir ||
    echo "SUCCESS"

echo "** Store/Search"

$SCRAPYARD $VERBOSE store -k "key-#(a_file)" -y $YARD -p a_dir &&
    echo "SUCCESS"

$SCRAPYARD $VERBOSE search -k "key-#(a_file)" -y $YARD -p a_dir &&
    echo "SUCCESS"

echo "** Multi Key Store/Junk/Search"

$SCRAPYARD $VERBOSE store -k "key-#(a_file)" -y $YARD -p a_dir &&
    echo "SUCCESS"

$SCRAPYARD $VERBOSE store -k "key" -y $YARD -p a_dir &&
    echo "SUCCESS"

$SCRAPYARD $VERBOSE junk -k "key-#(a_file)" -y $YARD -p a_dir &&
    echo "SUCCESS"

$SCRAPYARD $VERBOSE search -k "key-#(a_file)","key","k" -y $YARD -p a_dir &&
    echo "SUCCESS"

$SCRAPYARD $VERBOSE crush -y $YARD &&
    echo "SUCCESS"
