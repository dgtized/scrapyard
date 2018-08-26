# Scrapyard

A simple cache for faster CI builds

Search allows prefix matching of multiple cache keys for the most recent,
closest match. If a key matches multiple entries, the most recently created
match is returned.

Paths are compressed into a tarball and stored in a local directory or S3.

# Install

# Usage

Search the `yard` for a `key` to restore `paths`

```
scrapyard.rb search --yard /tmp/cache
    --key "junk-$GIT_BRANCH-#(bar)","junk-$GIT_BRANCH","junk-"
```

Save `paths` to the `yard` using the `key`

```
scrapyard.rb store --key "junk-$GIT_BRANCH-#(bar)" \
    --yard /tmp/cache \
    --paths parts.1,parts.2,parts.3
```

Remove a specific `key` from the `yard`:

```
scrapyard.rb junk --key "junk-$GIT_BRANCH-#(bar)" --yard /tmp/cache
```

Expire old `keys` in the `yard`:

```
scrapyard.rb crush --yard /tmp/cache
```

## S3

```
scrapyard.rb store --yard s3://scrapyard/ --key "foo" --paths a
```

```
scrapyard.rb search --yard s3://scrapyard/ --key "foo","bar"
```
