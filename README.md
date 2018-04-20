# Scrapyard

A simple disk cache for faster CI builds

# Install

# Usage

Search the `yard` for a `key` to restore `paths`

```
scrapyard search --key "junk-$GIT_BRANCH-#{bar}"
    --yard /tmp/cache
    --paths parts.1 parts.2 parts.3
```

Save `paths` to the `yard` using the `key`

```
scrapyard dump --key "junk-$GIT_BRANCH-#{bar}"
    --yard /tmp/cache
    --paths parts.1 parts.2 parts.3
```

Remove a specific `key` from the `yard`:

```
scrapyard junk --key "junk-$GIT_BRANCH-#{bar}" 
    --yard /tmp/cache
```

Expire old `keys` in the `yard`:

```
scrapyard crush --yard /tmp/cache
```

