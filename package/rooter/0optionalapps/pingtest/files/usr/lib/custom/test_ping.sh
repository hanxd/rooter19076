#!/bin/sh

. /lib/functions.sh
 
ROOTER=/usr/lib/rooter
ROOTER_LINK="/tmp/links"

log() {
logger -t "Custom Ping Test " "$@"
}

sleep 20
CURRMODEM=1
while [ true ]
do
	ENB=$(uci get ping.ping.enable)
	if [ $ENB = 0 ]; then
		sleep 20
	else
		CONN=$(uci -q get modem.modem$CURRMODEM.connected)
		if [ $CONN = "1" ]; then
			result=`ps | grep -i "johns_ping.sh" | grep -v "grep" | wc -l`
			if [ $result -lt 1 ]; then
				/usr/lib/custom/johns_ping.sh &
			fi
		fi
		sleep 20
	fi
done