#!/bin/bash

set -exuo pipefail

rm -rf a_dir a_file scrapyard
mkdir -p a_dir
echo "content" > a_file
echo "content" > a_dir/a_file

./scrapyard.rb -v search -k "key-#(a_file)" -y scrapyard -p a_dir ||
    echo "SUCCESS"

./scrapyard.rb -v dump -k "key-#(a_file)" -y scrapyard -p a_dir &&
    echo "SUCCESS"

./scrapyard.rb -v search -k "key-#(a_file)" -y scrapyard -p a_dir &&
    echo "SUCCESS"

./scrapyard.rb -v junk -k "key-#(a_file)" -y scrapyard -p a_dir &&
    echo "SUCCESS"

./scrapyard.rb -v search -k "key-#(a_file)" -y scrapyard -p a_dir ||
    echo "SUCCESS"

