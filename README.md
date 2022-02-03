# useless-scripts
Some scripts I may have written/used at some point

# Honorable mention(s)
get pornhub titles:

`curl -s https://www.pornhub.com{,/gayporn}|grep -oP '(?<=  title=").*?(?=")'|cat -b`

spam url:

`yes -- -Ikso/dev/null pornhub.com|xargs -P $THREADS curl`
- `yes`
A command that prints a string as fast as possible
`--` tells `yes` to not parse any more arguments
`-Ikso/dev/null pornhub.com` are the arguments that get passed to `curl`

- `xargs`
A command that shlurps it's STDIN and passes it along multiple commands.
In this case, it takes `-Ikso/dev/null pornhub.com` from `yes` and passes it as many times as it can to one `curl`, then creates a new `curl` and does the same.
The result is a command like:
```
curl -Ikso/dev/null pornhub.com -Ikso/dev/null pornhub.com -Ikso/dev/null pornhub.com ...
```
This means that each `curl` instance will request the url many times, then exit. This is more efficient than each `curl` requesting it once and exiting.

`-P` Tells `xargs` to use a pool of threads, $THREADS big. This prevents it from taking all of your resources.
