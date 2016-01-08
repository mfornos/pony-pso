#!/usr/bin/env bash -e

function build::examples {
  for D in `find examples/* -type d`
  do
    ponyc "$D" -o bin
  done
}

function build::doc {
  ponyc -g pso
}

function usage {
  echo "Usage: $0 [-de]"
  echo -e "-d\tGenerates documentation."
  echo -e "-e\tCompiles the examples. Executables in 'bin/'."
  exit 1
}

if [[ ! -x "$(command -v ponyc)" ]]
then
    echo 'Pony compiler (ponyc) not found.'
    echo 'Please, refer to http://www.ponylang.org/'
    exit -1
fi

[ $# -eq 0 ] && usage

while getopts ":de" opt; do
  case $opt in
    d)
      build::doc
      ;;
    e)
      build::examples
      ;;
    \?)
      usage
      ;;
  esac
done
