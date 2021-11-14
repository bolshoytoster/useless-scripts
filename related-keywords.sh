#!/bin/bash

IFS=+

TEXT=$(curl -s "https://suggestqueries-clients6.youtube.com/complete/search?client=youtube&q=$*&xhr=t"|jq .[1][][0])

while read VIDEO
# Get the page ov the video
do VIDEO=$(curl -s https://www.youtube.com/watch?v=$VIDEO)

# Get video title, tags and description;
# With the description we remove every second line, which contain links
TEXT+="$(echo $VIDEO|grep -Po '(?<=<title>).*?(?= - YouTube<\/title>)|(?<=:"#).*?(?=")'|sort -u) $(echo $VIDEO|grep -Po '(?<=iption":{"runs":).*?}]'|jq .[].text -c|awk '(NR)%2') "

# Get urls of the recommended videos and pass them to the loop
done < <(curl -HContent-Type:application/json -sXPOST --data-raw "{\"context\":{\"client\":{\"clientName\":\"WEB\",\"clientVersion\":\"2.20211026.01.00\"}},\"continuation\":\"$(curl -s "https://www.youtube.com/results?search_query=$*"|grep -Po '(?<=token":").*?(?=")')\"}" https://www.youtube.com/youtubei/v1/search?key=AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8|jq -r .onResponseReceivedCommands[].appendContinuationItemsAction.continuationItems[0].itemSectionRenderer.contents[][].videoId)

# Seperate each with newlines, remove lines with less than 5 characters, then count occurrences of words.
echo -e $TEXT |tr -c '[:alpha:]' '[\n*]'|sed -r '/^.{,5}$/d'|sort|uniq -ci|sort -n
