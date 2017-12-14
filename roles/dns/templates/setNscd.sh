#!/bin/bash

FILE=/etc/nscd.conf

lineNumber=$(cat -n "${FILE}" | grep 'enable-cache' | grep 'hosts' | awk '{print $1}')
sed -i "$lineNumber s/no/yes/g" "${FILE}"

lineNumber=$(cat -n "${FILE}" | grep 'positive-time-to-live' | grep 'hosts' | awk '{print $1}')
sed -i "$lineNumber s/[0-9]\+/300/g" "${FILE}"

lineNumber=$(cat -n "${FILE}" | grep 'negative-time-to-live' | grep 'hosts' | awk '{print $1}')
sed -i "$lineNumber s/[0-9]\+/10/g" "${FILE}"

lineNumber=$(cat -n "${FILE}" | grep 'persistent' | grep 'hosts' | awk '{print $1}')
sed -i "$lineNumber s/no/yes/g" "${FILE}"
