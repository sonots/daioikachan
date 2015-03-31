#!/bin/sh
curl -d 'channel=#notify&message=*test* _daioikachan_ `www-form-urlencoded`' http://localhost:4979/notice
curl -F 'channel=#notify' -F 'message=*test* _daioikachan_ `multipart/form-data`' http://localhost:4979/privmsg
