# Scrapyard

[![CircleCI](https://circleci.com/gh/dgtized/scrapyard.svg?style=svg)](https://circleci.com/gh/dgtized/scrapyard)

A simple command line caching tool for faster CI builds

Search allows prefix matching of multiple cache keys for the most recent,
closest match. If a key matches multiple entries, the most recently created
match is returned.

Paths are compressed into a tarball and stored in a local directory or S3.

# Install

Scrapyard is not yet published as a gem, so recommend installing it with bundler as a git remote source or building the gem locally.

```ruby
# Gemfile
gem 'scrapyard', git: 'https://github.com/dgtized/scrapyard', tag: 'v0.5.1', require: false
```

```bash
git clone https://github.com/dgtized/scrapyard
cd scrapyard
gem build scrapyard.gemspec
gem install scrapyard
```

# Usage

Search the `yard` for a `key` to restore `paths`

```
scrapyard --yard /tmp/cache --paths stuff \
    search --key "stuff-$GIT_BRANCH-#(bar),stuff-$GIT_BRANCH,stuff-"
```

Save `paths` to the `yard` using the `key`

```
scrapyard --yard /tmp/cache --paths stuff.1,stuff.2,stuff.3 \
    store --key "stuff-$GIT_BRANCH-#(bar)"
```

Remove a specific `key` from the `yard`:

```
scrapyard --yard /tmp/cache \
    junk --key "stuff-$GIT_BRANCH-#(bar)"
```

Expire old `keys` in the `yard`:

```
scrapyard crush --yard /tmp/cache
```

## S3

```
scrapyard --aws-region us-east-1 --yard s3://scrapyard.foo.com/
    store --key "foo" --paths a
```

```
scrapyard --aws-region us-east-1 --yard s3://scrapyard.foo.com/
    search --key "foo,bar" --paths a
```

In order to use an S3 bucket as a cache yard, the bucket name must be prefixed with `s3://`, otherwise `scrapyard` will infer the yard is a local directory.

Example IAM permissions for the hypothetical `scrapyard.foo.com` are included in `iam-scrapyard.json`.

Crush is not available for expiring caches in s3 buckets, it is recommended to
use a bucket expiration rule to do this automatically.

# Details

## Search Precedence

Each key is used as a prefix in the directory or bucket specified. If the prefix
matches multiple cache keys, the most recently modified key is selected.

## Legal Keys & Special Syntax

Keys can be any sequence of alphanumeric characters including dash, underscore,
or period. All other characters will be converted into exclamation marks. When
pre-processing keys if the special syntax `#(filename)` is found, that will be
replaced with the `SHA1` checksum of the contents of `filename`, or an empty
string if the file is not present. Multiple keys can be specified delimited
by commas. It is recommended to double quote the key(s) argument.

## Logging

Logging is provided on standard error, and keys found or affected by the command are reported to standard out.

This is particularly useful when searching a list of keys, allowing the script
to record the exact key that matched. The key will include `.tgz` as a suffix or
an empty string if no matching key was found.

```
KEY=`scrapyard -v search -k 'key-#(a_file),key,k' -y scrapyard -p a_dir`
I, [2018-09-20T00:01:21.932126 #24291]  INFO -- : Scrapyard: scrapyard
I, [2018-09-20T00:01:21.932181 #24291]  INFO -- : Searching for ["key-#(a_file)", "key", "k"]
D, [2018-09-20T00:01:21.932243 #24291] DEBUG -- : Including sha1 of a_file
D, [2018-09-20T00:01:21.932854 #24291] DEBUG -- : Scanning key-7fe70820e08a1aac0ef224d9c66ab66831cc4ab1 -> []
D, [2018-09-20T00:01:21.932921 #24291] DEBUG -- : Scanning key -> ["scrapyard/key.tgz"]
D, [2018-09-20T00:01:21.932991 #24291] DEBUG -- : Found scrap in scrapyard/key.tgz
I, [2018-09-20T00:01:21.935875 #24291]  INFO -- : Executing[tar zxf scrapyard/key.tgz] (2.8 ms)
I, [2018-09-20T00:01:21.936562 #24291]  INFO -- : Restored:
8.0K    a_dir
test "$KEY" = "key.tgz"
```

## Options

Paths can be specified both with `--paths` and as any additional arguments after `--`.

`store` accepts a list of keys, but will only create a cache entry for the first
key. This allows scripts to specify the cache key precedence once, with the
most specific key first, and re-use this for populating the cache.
