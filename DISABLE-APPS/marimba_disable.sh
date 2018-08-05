#!/bin/sh
#Created by Inna Gorbati to disabled marimba service on SEM server

service marimba stop

cd /etc/rc3.d/; mv S99marimba disbaled_S99marimba

