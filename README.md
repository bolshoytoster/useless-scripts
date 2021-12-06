# useless-scripts
Some scripts I may have written/used at some point

# Honorable mention(s)
get pornhub titles:

`curl -s https://www.pornhub.com{,/gayporn}|grep -oP '(?<=  title=").*?(?=")'|cat -b`
