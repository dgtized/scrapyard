#!/bin/bash

set -exuo pipefail

SCRAPYARD=${1:-./scrapyard.rb}
VERBOSE="-v"

rm -rf a_dir a_file scrapyard
mkdir -p a_dir
echo "content" > a_file
echo "content" > a_dir/a_file
YARD=scrapyard
SCRAPYARD="ruby -Ilib bin/scrapyard"

echo "** Search"

$SCRAPYARD $VERBOSE search -k "key-#(a_file)" -y $YARD -p a_dir ||
    echo "SUCCESS"

echo "** Store/Search"

$SCRAPYARD $VERBOSE store -k "key-#(a_file)" -y $YARD -p a_dir &&
    echo "SUCCESS"

$SCRAPYARD $VERBOSE search -i -k "key-#(a_file)" -y $YARD -p a_dir &&
    echo "SUCCESS"

echo "** Multi Key Store/Junk/Search"

$SCRAPYARD $VERBOSE store -k "key-#(a_file)" -y $YARD -p a_dir &&
    echo "SUCCESS"

$SCRAPYARD $VERBOSE store -k "key" -y $YARD -p a_dir &&
    echo "SUCCESS"

$SCRAPYARD $VERBOSE junk -k "key-#(a_file)" -y $YARD &&
    echo "SUCCESS"

$SCRAPYARD $VERBOSE search -k "key-#(a_file)","key","k" -y $YARD -p a_dir &&
    echo "SUCCESS"

$SCRAPYARD $VERBOSE crush -y $YARD &&
    echo "SUCCESS"

$SCRAPYARD $VERBOSE junk -k "key" -y $YARD &&
    echo "SUCCESS"
