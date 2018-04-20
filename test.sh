#!/bin/bash

set -exuo pipefail

rm -rf a_dir a_file scrapyard
mkdir -p a_dir
echo "content" > a_file
echo "content" > a_dir/a_file

echo "** Search"

./scrapyard.rb -v search -k "key-#(a_file)" -y scrapyard -p a_dir ||
    echo "SUCCESS"

echo "** Dump/Search"

./scrapyard.rb -v dump -k "key-#(a_file)" -y scrapyard -p a_dir &&
    echo "SUCCESS"

./scrapyard.rb -v search -k "key-#(a_file)" -y scrapyard -p a_dir &&
    echo "SUCCESS"

echo "** Multi Key Dump/Junk/Search"

./scrapyard.rb -v dump -k "key-#(a_file)","key-" -y scrapyard -p a_dir &&
    echo "SUCCESS"

./scrapyard.rb -v junk -k "key-#(a_file)" -y scrapyard -p a_dir &&
    echo "SUCCESS"

./scrapyard.rb -v search -k "key-#(a_file)","key-" -y scrapyard -p a_dir &&
    echo "SUCCESS"

./scrapyard.rb -v crush -y scrapyard &&
    echo "SUCCESS"
