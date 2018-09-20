#!/bin/bash

set -exuo pipefail

rm -rf a_dir a_file scrapyard
mkdir -p a_dir
echo "content" > a_file
echo "content" > a_dir/a_file
YARD=scrapyard
SCRAPYARD="ruby -Ilib bin/scrapyard -v"

echo "** Search"

$SCRAPYARD search -k "key-#(a_file)" -y $YARD -p a_dir ||
    echo "SUCCESS"

echo "** Store/Search"

$SCRAPYARD store -k "key-#(a_file)" -y $YARD -p a_dir &&
    echo "SUCCESS"

$SCRAPYARD search -i -k "key-#(a_file)" -y $YARD -p a_dir &&
    echo "SUCCESS"

echo "** Multi Key Store/Junk/Search"

$SCRAPYARD store -k "key-#(a_file)" -y $YARD -p a_dir &&
    echo "SUCCESS"

$SCRAPYARD store -k "key" -y $YARD -p a_dir &&
    echo "SUCCESS"

$SCRAPYARD junk -k "key-#(a_file)" -y $YARD &&
    echo "SUCCESS"

$SCRAPYARD search -k "key-#(a_file)","key","k" -y $YARD -p a_dir &&
    echo "SUCCESS"

$SCRAPYARD crush -y $YARD &&
    echo "SUCCESS"

$SCRAPYARD junk -k "key" -y $YARD &&
    echo "SUCCESS"
