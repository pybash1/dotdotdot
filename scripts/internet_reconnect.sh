#!/bin/sh

function am_online {
   ping -c 1 example.com  >/dev/null 2>&1
   echo $?
}

while [ 1 ]; do
    if [ "`am_online`" -eq 0 ]; then
        echo "Connected! Skipping..."
    else
        echo "Internet lost! Reconnecting to Internet!"
        curl --request POST --url http://2.2.2.2/login --header 'Content-Type: application/x-www-form-urlencoded' --header 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36' --data username=[redacted] --data 'password=[redacted]!'
    fi

    sleep 1
done