#!/bin/sh
awk '{ if ( $2 == "\[Page" || $4 == "\[Page") { print $0 ;  print "" ; \
	getline ; getline ; getline ; getline ; getline  } else print $0 }' $*
