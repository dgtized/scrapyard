#!/bin/bash

set -exuo pipefail

VERBOSE="-v"

rm -rf a_dir a_file scrapyard
mkdir -p a_dir
echo "content" > a_file
echo "content" > a_dir/a_file

echo "** Search"

./scrapyard.rb $VERBOSE search -k "key-#(a_file)" -y scrapyard -p a_dir ||
    echo "SUCCESS"

echo "** Store/Search"

./scrapyard.rb $VERBOSE store -k "key-#(a_file)" -y scrapyard -p a_dir &&
    echo "SUCCESS"

./scrapyard.rb $VERBOSE search -k "key-#(a_file)" -y scrapyard -p a_dir &&
    echo "SUCCESS"

echo "** Multi Key Store/Junk/Search"

./scrapyard.rb $VERBOSE store -k "key-#(a_file)","key" -y scrapyard -p a_dir &&
    echo "SUCCESS"

./scrapyard.rb $VERBOSE store -k "key" -y scrapyard -p a_dir &&
    echo "SUCCESS"

./scrapyard.rb $VERBOSE junk -k "key-#(a_file)" -y scrapyard -p a_dir &&
    echo "SUCCESS"

./scrapyard.rb $VERBOSE search -k "key-#(a_file)","key","k" -y scrapyard -p a_dir &&
    echo "SUCCESS"

./scrapyard.rb $VERBOSE crush -y scrapyard &&
    echo "SUCCESS"
