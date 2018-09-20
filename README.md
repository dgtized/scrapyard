# Scrapyard

[![CircleCI](https://circleci.com/gh/dgtized/scrapyard.svg?style=svg)](https://circleci.com/gh/dgtized/scrapyard)

A simple cache for faster CI builds

Search allows prefix matching of multiple cache keys for the most recent,
closest match. If a key matches multiple entries, the most recently created
match is returned.

Paths are compressed into a tarball and stored in a local directory or S3.

# Install

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
scrapyard --aws-region us-east-1 --yard s3://scrapyard/
    store --key "foo" --paths a
```

```
scrapyard --aws-region us-east-1 --yard s3://scrapyard/
    search --key "foo,bar" --paths a
```

# Details

## Logging

Logging is provided on standard error, and keys found or affected by the command are reported to standard out.

This is particularly useful when searching a list of keys, allowing the script
to record the exact key that matched. The key will include `.tgz` as a suffix or
an empty string if no matching key was found.

```
KEY=`scrapyard search --key "foo-#(scrapyard.gemspec),foo-"`
test $KEY = "foo-b56283b49631c067195425e0d5851dd536d8b299.tgz"
```

## Options

Paths can be specified both with `--paths` and as any additional arguments after `--`.


