#!/bin/bash

getPersonalAccessToken(){
    dir=$1
    if [ -e $dir ]; then
        token=$(cat $dir)
        echo "$token"
    else
        echo "false"
    fi
}

export -f getPersonalAccessToken