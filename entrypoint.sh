#!/bin/bash
/usr/sbin/asterisk -U asterisk -G asterisk -vvvg 
while true; do
  asterisk -x"sip reload"
  sleep 10
done
