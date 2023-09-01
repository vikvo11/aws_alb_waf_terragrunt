#!/bin/bash

check_url() {
  url=$1
  status_code=$(http --print=h --ignore-stdin "$url" 2>/dev/null | grep HTTP | awk '{print $2}')
  content=$(http --print=b --ignore-stdin "$url" 2>/dev/null)

  if [[ $status_code == 200 ]]; then
    echo "OK $url"
  else
    echo "NA $url"
  fi
}

# 
if [ "$#" -ne 2 ]; then
    echo "Usage: ./script.sh <file_path> <host>"
    exit 1
fi

file_path=$1
host=$2

# 
while IFS= read -r line || [ -n "$line" ]
do
    # Если строка не пустая
    if [ -n "$line" ]; then
        url=$(echo "$line" | sed "s/{host}/$host/")
        check_url "$url"
    fi
done < "$file_path"
