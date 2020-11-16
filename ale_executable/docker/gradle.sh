#!/usr/bin/env bash

echo "gradle $(pwd): $@" >/tmp/test
name=p_$(pwd | tr / - )
docker ps | grep $name ||
docker run --rm -i --name $name -d -v "$(pwd):/data" gradle:jdk8 /bin/bash
exec docker exec -i $name sh -c "cd /data && ${*}"
