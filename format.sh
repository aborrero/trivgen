#!/bin/bash

[ -z "$1" ] && echo "E: No input file" >&2 && exit 1

for i in {1..100} ; do
	echo ""		>> $1
	echo "${i}Q: "	>> $1
	echo "${i}A: "	>> $1
done
