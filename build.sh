#!/usr/bin/env bash -e

function build::examples {
  for D in `find examples/* -type d`
  do
    ponyc "$D" -o bin
  done
}

if [[ ! -x "$(command -v ponyc)" ]]
then
    echo 'Pony compiler (ponyc) not found.'
    echo 'Please, refer to http://www.ponylang.org/'
    exit -1
fi

build::examples
